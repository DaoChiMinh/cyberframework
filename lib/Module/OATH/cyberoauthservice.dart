import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:http/http.dart' as http;

/// Kết quả trả về từ OAuth login
class OAuthResult {
  final bool success;
  final String? provider;
  final String? email;
  final String? token;
  final String? displayName;
  final String? photoUrl;
  final String? errorMessage;

  OAuthResult({
    required this.success,
    this.provider,
    this.email,
    this.token,
    this.displayName,
    this.photoUrl,
    this.errorMessage,
  });

  factory OAuthResult.success({
    required String provider,
    required String email,
    required String token,
    String? displayName,
    String? photoUrl,
  }) {
    return OAuthResult(
      success: true,
      provider: provider,
      email: email,
      token: token,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  factory OAuthResult.failure(String errorMessage) {
    return OAuthResult(success: false, errorMessage: errorMessage);
  }

  factory OAuthResult.cancelled() {
    return OAuthResult(success: false, errorMessage: null);
  }

  bool get isCancelled => !success && errorMessage == null;

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'email': email,
    'token': token,
    'display_name': displayName,
    'photo_url': photoUrl,
  };
}

/// Cấu hình OAuth
class OAuthConfig {
  // Google
  final String? googleClientId;
  final String? googleServerClientId;
  final List<String> googleScopes;

  // Microsoft
  final String microsoftTenantId;
  final String microsoftClientId;
  final String microsoftRedirectUri;
  final String microsoftScope;

  OAuthConfig({
    this.googleClientId,
    this.googleServerClientId,
    this.googleScopes = const ['email', 'profile', 'openid'],
    required this.microsoftTenantId,
    required this.microsoftClientId,
    required this.microsoftRedirectUri,
    this.microsoftScope = 'openid profile email User.Read',
  });

  /// Cấu hình mặc định - CẦN THAY THẾ BẰNG GIÁ TRỊ THỰC
  factory OAuthConfig.defaults() {
    return OAuthConfig(
      googleClientId: null,
      googleServerClientId: null,
      microsoftTenantId: 'common',
      microsoftClientId: 'YOUR_MICROSOFT_CLIENT_ID',
      microsoftRedirectUri: 'msauth://com.yourcompany.yourapp/callback',
    );
  }
}

/// Service xử lý OAuth Login cho Google và Microsoft
/// Sử dụng google_sign_in 7.x API
class OAuthService {
  static OAuthService? _instance;
  static OAuthConfig? _config;

  AadOAuth? _msOAuth;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool _googleInitialized = false;
  GoogleSignInAccount? _currentGoogleUser;

  // Private constructor
  OAuthService._();

  /// Khởi tạo service với cấu hình
  static void initialize(OAuthConfig config) {
    _config = config;
    _instance = null;
  }

  /// Lấy instance (Singleton)
  static OAuthService get instance {
    if (_config == null) {
      _config = OAuthConfig.defaults();
    }
    _instance ??= OAuthService._();
    return _instance!;
  }

  /// Getter cho navigatorKey (cần cho Microsoft OAuth)
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Lazy initialization cho Microsoft OAuth
  AadOAuth get _microsoft {
    _msOAuth ??= AadOAuth(
      Config(
        tenant: _config!.microsoftTenantId,
        clientId: _config!.microsoftClientId,
        scope: _config!.microsoftScope,
        redirectUri: _config!.microsoftRedirectUri,
        navigatorKey: _navigatorKey,
      ),
    );
    return _msOAuth!;
  }

  // ==================== GOOGLE LOGIN (7.x API) ====================

  /// Khởi tạo Google Sign In (chỉ cần gọi 1 lần)
  Future<void> _initializeGoogle() async {
    if (_googleInitialized) return;

    try {
      await GoogleSignIn.instance.initialize(
        clientId: _config!.googleClientId,
        serverClientId: _config!.googleServerClientId,
      );
      _googleInitialized = true;
    } catch (e) {
      debugPrint('Google Sign In initialization error: $e');
      rethrow;
    }
  }

  /// Đăng nhập bằng Google (7.x API - đơn giản hóa)
  Future<OAuthResult> loginWithGoogle() async {
    try {
      // Khởi tạo nếu chưa
      await _initializeGoogle();

      GoogleSignInAccount? user;

      // Thử đăng nhập nhẹ trước (silent/lightweight)
      try {
        user = await GoogleSignIn.instance.attemptLightweightAuthentication();
      } catch (e) {
        debugPrint('Lightweight auth failed: $e');
      }

      // Nếu không có user từ silent, dùng authenticate
      if (user == null) {
        if (GoogleSignIn.instance.supportsAuthenticate()) {
          user = await GoogleSignIn.instance.authenticate();
        } else {
          return OAuthResult.failure(
            'Nền tảng không hỗ trợ xác thực Google tự động. Vui lòng sử dụng nút đăng nhập Google.',
          );
        }
      }

      // User đã cancel hoặc không đăng nhập được
      if (user == null) {
        return OAuthResult.cancelled();
      }

      _currentGoogleUser = user;

      // Lấy token - thử nhiều cách
      String? token = await _getGoogleToken(user);

      // Fallback: dùng user ID nếu không có token
      token ??= user.id;

      return OAuthResult.success(
        provider: 'google',
        email: user.email,
        token: token,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
      );
    } catch (error) {
      debugPrint('Google Sign In Error: $error');

      // Kiểm tra nếu user cancel
      if (error.toString().contains('canceled') ||
          error.toString().contains('cancelled') ||
          error.toString().contains('user_cancel')) {
        return OAuthResult.cancelled();
      }

      return OAuthResult.failure('Đăng nhập Google thất bại: $error');
    }
  }

  /// Lấy token từ Google user
  Future<String?> _getGoogleToken(GoogleSignInAccount user) async {
    String? token;

    // Cách 1: Thử lấy authorization với scopes
    try {
      final authorization = await user.authorizationClient
          .authorizationForScopes(_config!.googleScopes);
      token = authorization?.accessToken;
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('Error getting authorization: $e');
    }

    // Cách 2: Thử authorize scopes mới
    try {
      final authorization = await user.authorizationClient.authorizeScopes(
        _config!.googleScopes,
      );
      token = authorization.accessToken;
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('Error authorizing scopes: $e');
    }

    // Cách 3: Thử lấy server auth code
    try {
      final serverAuth = await user.authorizationClient.authorizeServer(
        _config!.googleScopes,
      );
      token = serverAuth?.serverAuthCode;
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('Error getting server auth: $e');
    }

    return token;
  }

  /// Kiểm tra đã đăng nhập Google chưa
  bool isGoogleSignedIn() {
    return _currentGoogleUser != null;
  }

  /// Lấy user Google hiện tại
  GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;

  /// Đăng nhập Google im lặng (silent)
  Future<OAuthResult> signInGoogleSilently() async {
    try {
      await _initializeGoogle();

      final user = await GoogleSignIn.instance
          .attemptLightweightAuthentication();

      if (user == null) {
        return OAuthResult.cancelled();
      }

      _currentGoogleUser = user;

      String? token = await _getGoogleToken(user);
      token ??= user.id;

      return OAuthResult.success(
        provider: 'google',
        email: user.email,
        token: token,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
      );
    } catch (error) {
      return OAuthResult.failure('Silent sign in failed: $error');
    }
  }

  /// Đăng xuất Google
  Future<void> signOutGoogle() async {
    try {
      await GoogleSignIn.instance.signOut();
      _currentGoogleUser = null;
    } catch (e) {
      debugPrint('Google Sign Out Error: $e');
    }
  }

  /// Ngắt kết nối Google (revoke access)
  Future<void> disconnectGoogle() async {
    try {
      await GoogleSignIn.instance.disconnect();
      _currentGoogleUser = null;
    } catch (e) {
      debugPrint('Google Disconnect Error: $e');
    }
  }

  // ==================== MICROSOFT LOGIN ====================

  /// Đăng nhập bằng Microsoft
  Future<OAuthResult> loginWithMicrosoft() async {
    try {
      // Thực hiện đăng nhập
      await _microsoft.login();

      // Lấy access token
      final String? accessToken = await _microsoft.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        return OAuthResult.failure('Không thể lấy token từ Microsoft');
      }

      // Lấy thông tin user từ Microsoft Graph API
      final userInfo = await _getMicrosoftUserInfo(accessToken);

      if (userInfo == null) {
        return OAuthResult.failure(
          'Không thể lấy thông tin người dùng từ Microsoft',
        );
      }

      final String email =
          userInfo['mail'] ?? userInfo['userPrincipalName'] ?? '';

      if (email.isEmpty) {
        return OAuthResult.failure('Không thể lấy email từ Microsoft');
      }

      return OAuthResult.success(
        provider: 'microsoft',
        email: email,
        token: accessToken,
        displayName: userInfo['displayName'],
        photoUrl: null,
      );
    } catch (error) {
      debugPrint('Microsoft Sign In Error: $error');

      // Kiểm tra nếu user cancel
      if (error.toString().contains('cancelled') ||
          error.toString().contains('canceled')) {
        return OAuthResult.cancelled();
      }

      return OAuthResult.failure('Đăng nhập Microsoft thất bại: $error');
    }
  }

  /// Lấy thông tin user từ Microsoft Graph API
  Future<Map<String, dynamic>?> _getMicrosoftUserInfo(
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      debugPrint('Microsoft Graph API Error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error getting Microsoft user info: $e');
      return null;
    }
  }

  /// Lấy ảnh profile từ Microsoft (optional)
  Future<String?> getMicrosoftPhoto(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me/photo/\$value'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting Microsoft photo: $e');
      return null;
    }
  }

  /// Đăng xuất Microsoft
  Future<void> signOutMicrosoft() async {
    try {
      await _microsoft.logout();
    } catch (e) {
      debugPrint('Microsoft Sign Out Error: $e');
    }
  }

  // ==================== UTILITIES ====================

  /// Đăng xuất tất cả providers
  Future<void> signOutAll() async {
    await Future.wait([signOutGoogle(), signOutMicrosoft()]);
  }

  /// Reset service
  static void reset() {
    _instance?._msOAuth = null;
    _instance?._googleInitialized = false;
    _instance?._currentGoogleUser = null;
    _instance = null;
  }
}

import 'package:cyberframework/cyberframework.dart';

class AppOAuthConfig {
  // ============ GOOGLE ============
  // Để null cho Android/iOS (tự động detect)
  // Chỉ cần set cho Web
  static const String? googleClientId = null;
  // 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  static const String? googleServerClientId = null;
  // 'YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com';

  static const List<String> googleScopes = ['email', 'profile', 'openid'];

  // ============ MICROSOFT ============
  // 'common' cho multi-tenant, hoặc tenant ID cụ thể
  static const String microsoftTenantId = 'multi-tenant';

  // Application (client) ID từ Azure Portal
  static const String microsoftClientId =
      '9aa69300-285e-4097-9d9b-6713758f99cc';

  // Redirect URI (khớp với Azure Portal)
  static const String microsoftRedirectUri =
      'msauth://vn.com.cybersoft.cyberflutter_nb/Sovyrfx3qhBR8jl9rkzVULAQXo4%3D';

  static const String microsoftScope = 'User.Read';

  // ============ HELPER ============
  static OAuthConfig getConfig() {
    return OAuthConfig(
      googleClientId: googleClientId,
      googleServerClientId: googleServerClientId,
      googleScopes: googleScopes,
      microsoftTenantId: microsoftTenantId,
      microsoftClientId: microsoftClientId,
      microsoftRedirectUri: microsoftRedirectUri,
      microsoftScope: microsoftScope,
    );
  }
}

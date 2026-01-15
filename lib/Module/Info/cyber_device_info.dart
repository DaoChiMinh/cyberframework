import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CyberDeviceInfo {
  // ============================================================================
  // SINGLETON PATTERN
  // ============================================================================

  static final CyberDeviceInfo _instance = CyberDeviceInfo._internal();
  factory CyberDeviceInfo() => _instance;
  CyberDeviceInfo._internal();

  // ============================================================================
  // PRIVATE VARIABLES
  // ============================================================================

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PackageInfo? _packageInfo;
  AndroidDeviceInfo? _androidInfo;
  IosDeviceInfo? _iosInfo;
  WebBrowserInfo? _webInfo;
  bool _isInitialized = false;

  // ============================================================================
  // ✅ INITIALIZATION
  // ============================================================================

  /// Initialize device info (gọi khi app start)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get package info
      _packageInfo = await PackageInfo.fromPlatform();

      // Get device info based on platform
      if (kIsWeb) {
        _webInfo = await _deviceInfo.webBrowserInfo;
      } else if (Platform.isAndroid) {
        _androidInfo = await _deviceInfo.androidInfo;
      } else if (Platform.isIOS) {
        _iosInfo = await _deviceInfo.iosInfo;
      }

      _isInitialized = true;
    } catch (e) {}
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  // ============================================================================
  // ✅ APP INFORMATION
  // ============================================================================

  /// App name
  String get appName => _packageInfo?.appName ?? 'Unknown';

  /// Package name (com.example.app)
  String get packageName => _packageInfo?.packageName ?? 'Unknown';

  /// App version (1.0.0)
  String get appVersion => _packageInfo?.version ?? '0.0.0';

  /// Build number (1)
  String get buildNumber => _packageInfo?.buildNumber ?? '0';

  /// Full version string (1.0.0+1)
  String get fullVersion => '$appVersion+$buildNumber';

  // ============================================================================
  // ✅ PLATFORM INFORMATION
  // ============================================================================

  /// Platform name (Android, iOS, Web, Windows, macOS, Linux)
  String get platform {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Check if mobile platform
  bool get isMobile => Platform.isAndroid || Platform.isIOS;

  /// Check if desktop platform
  bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Check if web platform
  bool get isWeb => kIsWeb;

  // ============================================================================
  // ✅ ANDROID DEVICE INFORMATION
  // ============================================================================

  /// Android version (e.g., "13")
  String get androidVersion {
    if (_androidInfo == null) return 'N/A';
    return _androidInfo!.version.release;
  }

  /// Android SDK version (e.g., 33)
  int get androidSdkVersion {
    if (_androidInfo == null) return 0;
    return _androidInfo!.version.sdkInt;
  }

  /// Device manufacturer (e.g., "Samsung")
  String get manufacturer {
    if (_androidInfo == null) return 'N/A';
    return _androidInfo!.manufacturer;
  }

  /// Device model (e.g., "SM-G998B")
  String get model {
    if (_androidInfo == null) return 'N/A';
    return _androidInfo!.model;
  }

  /// Device brand (e.g., "samsung")
  String get brand {
    if (_androidInfo == null) return 'N/A';
    return _androidInfo!.brand;
  }

  /// Device name (e.g., "Galaxy S21")
  String get deviceName {
    if (_androidInfo != null) {
      return '${_androidInfo!.brand} ${_androidInfo!.model}';
    }
    if (_iosInfo != null) {
      return _iosInfo!.name;
    }
    return 'Unknown Device';
  }

  /// Device ID (unique identifier)
  String get deviceId {
    if (_androidInfo != null) {
      return _androidInfo!.id;
    }
    if (_iosInfo != null) {
      return _iosInfo!.identifierForVendor ?? 'Unknown';
    }
    return 'Unknown';
  }

  /// Is physical device (not emulator)
  bool get isPhysicalDevice {
    if (_androidInfo != null) {
      return _androidInfo!.isPhysicalDevice;
    }
    if (_iosInfo != null) {
      return _iosInfo!.isPhysicalDevice;
    }
    return true;
  }

  // ============================================================================
  // ✅ iOS DEVICE INFORMATION
  // ============================================================================

  /// iOS version (e.g., "16.5")
  String get iosVersion {
    if (_iosInfo == null) return 'N/A';
    return _iosInfo!.systemVersion;
  }

  /// iOS device model (e.g., "iPhone14,2")
  String get iosModel {
    if (_iosInfo == null) return 'N/A';
    return _iosInfo!.model;
  }

  /// iOS device name (e.g., "iPhone 13 Pro")
  String get iosDeviceName {
    if (_iosInfo == null) return 'N/A';
    return _iosInfo!.name;
  }

  /// iOS system name (e.g., "iOS")
  String get iosSystemName {
    if (_iosInfo == null) return 'N/A';
    return _iosInfo!.systemName;
  }

  // ============================================================================
  // ✅ WEB BROWSER INFORMATION
  // ============================================================================

  /// Browser name
  String get browserName {
    if (_webInfo == null) return 'N/A';
    return _webInfo!.browserName.name;
  }

  /// Browser version
  String get browserVersion {
    if (_webInfo == null) return 'N/A';
    return _webInfo!.appVersion ?? 'Unknown';
  }

  /// User agent
  String get userAgent {
    if (_webInfo == null) return 'N/A';
    return _webInfo!.userAgent ?? 'Unknown';
  }

  // ============================================================================
  // ✅ SCREEN INFORMATION
  // ============================================================================

  /// Get screen size (requires BuildContext)
  Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Get screen width (requires BuildContext)
  double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height (requires BuildContext)
  double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get screen pixel ratio (requires BuildContext)
  double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Get screen orientation (requires BuildContext)
  Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// Check if portrait mode (requires BuildContext)
  bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if landscape mode (requires BuildContext)
  bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // ============================================================================
  // ✅ DEVICE CATEGORY
  // ============================================================================

  /// Get device category based on screen width
  DeviceCategory getDeviceCategory(BuildContext context) {
    final width = getScreenWidth(context);

    if (width < 600) {
      return DeviceCategory.mobile;
    } else if (width < 900) {
      return DeviceCategory.tablet;
    } else {
      return DeviceCategory.desktop;
    }
  }

  /// Check if mobile size
  bool isMobileSize(BuildContext context) {
    return getDeviceCategory(context) == DeviceCategory.mobile;
  }

  /// Check if tablet size
  bool isTabletSize(BuildContext context) {
    return getDeviceCategory(context) == DeviceCategory.tablet;
  }

  /// Check if desktop size
  bool isDesktopSize(BuildContext context) {
    return getDeviceCategory(context) == DeviceCategory.desktop;
  }

  // ============================================================================
  // ✅ FORMATTED OUTPUT
  // ============================================================================

  /// Get device info summary
  Map<String, dynamic> getDeviceInfoMap() {
    return {
      // App Info
      'app_name': appName,
      'package_name': packageName,
      'app_version': appVersion,
      'build_number': buildNumber,
      'full_version': fullVersion,

      // Platform Info
      'platform': platform,
      'is_mobile': isMobile,
      'is_desktop': isDesktop,
      'is_web': isWeb,

      // Device Info
      'device_name': deviceName,
      'device_id': deviceId,
      'is_physical_device': isPhysicalDevice,

      // Platform Specific
      if (Platform.isAndroid) ...{
        'android_version': androidVersion,
        'android_sdk': androidSdkVersion,
        'manufacturer': manufacturer,
        'model': model,
        'brand': brand,
      },

      if (Platform.isIOS) ...{
        'ios_version': iosVersion,
        'ios_model': iosModel,
        'ios_system_name': iosSystemName,
      },

      if (kIsWeb) ...{
        'browser_name': browserName,
        'browser_version': browserVersion,
      },
    };
  }

  /// Get formatted device info string
  String getDeviceInfoString() {
    final info = getDeviceInfoMap();
    final buffer = StringBuffer();

    buffer.writeln('📱 DEVICE & APP INFORMATION');
    buffer.writeln('=' * 50);

    info.forEach((key, value) {
      buffer.writeln('$key: $value');
    });

    return buffer.toString();
  }

  /// Print device info to console
  void printDeviceInfo() {
    debugPrint(getDeviceInfoString());
  }

  // ============================================================================
  // ✅ USER-FRIENDLY DISPLAY
  // ============================================================================

  /// Get display name for device (user-friendly)
  String get displayDeviceName {
    if (Platform.isAndroid) {
      // Convert "samsung SM-G998B" → "Samsung Galaxy S21"
      return _getFriendlyAndroidName();
    } else if (Platform.isIOS) {
      // Already friendly: "iPhone 13 Pro"
      return iosDeviceName;
    } else if (kIsWeb) {
      return '$browserName Browser';
    }
    return deviceName;
  }

  /// Get friendly Android device name
  String _getFriendlyAndroidName() {
    if (_androidInfo == null) return 'Android Device';

    final brand = _androidInfo!.brand.toUpperCase();
    final model = _androidInfo!.model;

    // Common device mappings
    if (brand == 'SAMSUNG') {
      if (model.startsWith('SM-G')) return 'Samsung Galaxy S Series';
      if (model.startsWith('SM-N')) return 'Samsung Galaxy Note';
      if (model.startsWith('SM-A')) return 'Samsung Galaxy A Series';
    } else if (brand == 'XIAOMI') {
      if (model.contains('Redmi')) return 'Xiaomi Redmi';
      return 'Xiaomi';
    } else if (brand == 'OPPO') {
      return 'OPPO';
    } else if (brand == 'VIVO') {
      return 'VIVO';
    }

    return '$brand $model';
  }

  /// Get OS version string (user-friendly)
  String get osVersion {
    if (Platform.isAndroid) {
      return 'Android $androidVersion';
    } else if (Platform.isIOS) {
      return 'iOS $iosVersion';
    } else if (kIsWeb) {
      return browserName;
    }
    return 'Unknown OS';
  }
}

enum DeviceCategory { mobile, tablet, desktop }

extension DeviceCategoryExtension on DeviceCategory {
  String get name {
    switch (this) {
      case DeviceCategory.mobile:
        return 'Mobile';
      case DeviceCategory.tablet:
        return 'Tablet';
      case DeviceCategory.desktop:
        return 'Desktop';
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:camera/camera.dart';

/// Device performance level
enum DevicePerformanceLevel {
  high, // Flagship devices (2-3 năm gần đây)
  medium, // Mid-range devices
  low, // Entry-level devices
  unknown, // Không detect được
}

/// Configuration được recommend dựa trên device performance
class PerformanceConfig {
  final ResolutionPreset resolutionPreset;
  final int frameSkipCount;
  final double confidenceThreshold;
  final int debounceMs;

  const PerformanceConfig({
    required this.resolutionPreset,
    required this.frameSkipCount,
    required this.confidenceThreshold,
    required this.debounceMs,
  });
}

/// Detector để xác định performance level của device
class DevicePerformanceDetector {
  static DevicePerformanceLevel? _cachedLevel;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get performance level của device (cached)
  static Future<DevicePerformanceLevel> getPerformanceLevel() async {
    if (_cachedLevel != null) {
      return _cachedLevel!;
    }

    try {
      if (Platform.isAndroid) {
        _cachedLevel = await _detectAndroidPerformance();
      } else if (Platform.isIOS) {
        _cachedLevel = await _detectIOSPerformance();
      } else {
        _cachedLevel = DevicePerformanceLevel.medium;
      }
    } catch (e) {
      // debugPrint('Error detecting device performance: $e');
      _cachedLevel = DevicePerformanceLevel.medium;
    }

    // debugPrint('Device Performance Level: $_cachedLevel');
    return _cachedLevel!;
  }

  /// Detect Android device performance
  static Future<DevicePerformanceLevel> _detectAndroidPerformance() async {
    final androidInfo = await _deviceInfo.androidInfo;

    // Get hardware info
    final manufacturer = androidInfo.manufacturer.toLowerCase();
    final model = androidInfo.model.toLowerCase();
    final sdkInt = androidInfo.version.sdkInt;

    // Factors để đánh giá
    int performanceScore = 0;

    // 1. Android version (newer = better)
    if (sdkInt >= 33) {
      performanceScore += 3; // Android 13+
    } else if (sdkInt >= 31) {
      performanceScore += 2; // Android 12
    } else if (sdkInt >= 29) {
      performanceScore += 1; // Android 10-11
    }

    // 2. RAM (if available)
    // Note: Cần thêm plugin hoặc native code để get RAM chính xác
    // Tạm thời estimate based on other factors

    // 3. Manufacturer + Model detection (heuristic)
    performanceScore += _getManufacturerScore(manufacturer, model);

    // 4. Hardware string analysis
    final hardware = androidInfo.hardware?.toLowerCase() ?? '';
    if (hardware.contains('snapdragon')) {
      final snapdragonGen = _extractSnapdragonGen(hardware);
      if (snapdragonGen >= 800) {
        performanceScore += 3; // Flagship
      } else if (snapdragonGen >= 700) {
        performanceScore += 2; // Upper mid-range
      } else if (snapdragonGen >= 600) {
        performanceScore += 1; // Mid-range
      }
    } else if (hardware.contains('exynos')) {
      performanceScore += 2; // Samsung Exynos usually mid-high
    } else if (hardware.contains('mediatek') || hardware.contains('helio')) {
      performanceScore += 1; // MediaTek usually mid-range
    }

    // 5. Supported ABIs (64-bit = better)
    if (androidInfo.supportedAbis.any((abi) => abi.contains('64'))) {
      performanceScore += 1;
    }

    // debugPrint('Android Performance Score: $performanceScore');
    // debugPrint('Manufacturer: $manufacturer, Model: $model');
    // debugPrint('SDK: $sdkInt, Hardware: $hardware');

    // Classify based on score
    if (performanceScore >= 7) {
      return DevicePerformanceLevel.high;
    } else if (performanceScore >= 4) {
      return DevicePerformanceLevel.medium;
    } else {
      return DevicePerformanceLevel.low;
    }
  }

  /// Detect iOS device performance
  static Future<DevicePerformanceLevel> _detectIOSPerformance() async {
    final iosInfo = await _deviceInfo.iosInfo;

    final model = iosInfo.model?.toLowerCase() ?? '';
    final name = iosInfo.name?.toLowerCase() ?? '';
    final systemVersion = iosInfo.systemVersion ?? '';

    // Parse iOS version
    final iosVersion = _parseIOSVersion(systemVersion);

    int performanceScore = 0;

    // 1. iOS version
    if (iosVersion >= 16) {
      performanceScore += 3; // iOS 16+
    } else if (iosVersion >= 15) {
      performanceScore += 2; // iOS 15
    } else if (iosVersion >= 14) {
      performanceScore += 1; // iOS 14
    }

    // 2. Device model detection
    if (model.contains('iphone')) {
      // Try to extract iPhone generation
      final generation = _extractiPhoneGeneration(name);
      if (generation >= 13) {
        performanceScore += 4; // iPhone 13+
      } else if (generation >= 11) {
        performanceScore += 3; // iPhone 11-12
      } else if (generation >= 8) {
        performanceScore += 2; // iPhone 8-X
      } else {
        performanceScore += 1; // iPhone 7 và cũ hơn
      }
    } else if (model.contains('ipad')) {
      performanceScore += 3; // iPads usually powerful
      if (name.contains('pro')) {
        performanceScore += 1; // iPad Pro even more
      }
    }

    // debugPrint('iOS Performance Score: $performanceScore');
    // debugPrint('Model: $model, Name: $name, iOS: $iosVersion');

    // Classify
    if (performanceScore >= 6) {
      return DevicePerformanceLevel.high;
    } else if (performanceScore >= 3) {
      return DevicePerformanceLevel.medium;
    } else {
      return DevicePerformanceLevel.low;
    }
  }

  /// Get manufacturer score based on brand and model
  static int _getManufacturerScore(String manufacturer, String model) {
    // Flagship brands
    if (manufacturer.contains('samsung')) {
      if (model.contains('s23') ||
          model.contains('s24') ||
          model.contains('s22') ||
          model.contains('fold') ||
          model.contains('flip')) {
        return 3; // Flagship
      } else if (model.contains('a7') || model.contains('a8')) {
        return 2; // Mid-range
      } else if (model.contains('a') || model.contains('m')) {
        return 1; // Entry-level
      }
    } else if (manufacturer.contains('google')) {
      if (model.contains('pixel')) {
        final pixelGen = _extractNumber(model);
        if (pixelGen >= 6) {
          return 3; // Pixel 6+
        } else if (pixelGen >= 4) {
          return 2; // Pixel 4-5
        }
      }
    } else if (manufacturer.contains('xiaomi') ||
        manufacturer.contains('redmi')) {
      if (model.contains('mi 1') || model.contains('poco f')) {
        return 3; // Flagship
      } else if (model.contains('note') || model.contains('poco')) {
        return 2; // Mid-range
      } else {
        return 1; // Entry-level
      }
    } else if (manufacturer.contains('oppo') ||
        manufacturer.contains('vivo') ||
        manufacturer.contains('realme')) {
      if (model.contains('find') || model.contains('x')) {
        return 2; // Upper mid-range
      } else {
        return 1; // Mid-range
      }
    } else if (manufacturer.contains('oneplus')) {
      return 2; // OnePlus usually mid-high
    }

    return 1; // Default mid-range
  }

  /// Extract Snapdragon generation from hardware string
  static int _extractSnapdragonGen(String hardware) {
    final regex = RegExp(r'snapdragon.*?(\d{3})');
    final match = regex.firstMatch(hardware);
    if (match != null && match.groupCount >= 1) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  /// Extract iPhone generation from name
  static int _extractiPhoneGeneration(String name) {
    // iPhone 14 Pro, iPhone 13, iPhone SE, etc.
    final regex = RegExp(r'iphone\s*(\d+)');
    final match = regex.firstMatch(name);
    if (match != null && match.groupCount >= 1) {
      return int.tryParse(match.group(1)!) ?? 0;
    }

    // Handle special cases
    if (name.contains('se')) {
      if (name.contains('2022') || name.contains('3rd')) {
        return 13; // iPhone SE 3rd gen (2022) ~ iPhone 13 chip
      } else if (name.contains('2020') || name.contains('2nd')) {
        return 11; // iPhone SE 2nd gen (2020) ~ iPhone 11 chip
      }
      return 8; // Original SE
    } else if (name.contains('x')) {
      if (name.contains('xs') || name.contains('xr')) {
        return 10;
      }
      return 10; // iPhone X
    }

    return 0;
  }

  /// Parse iOS version string
  static int _parseIOSVersion(String version) {
    final parts = version.split('.');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0]) ?? 0;
    }
    return 0;
  }

  /// Extract first number from string
  static int _extractNumber(String text) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  /// Get recommended performance config based on device level
  static Future<PerformanceConfig> getRecommendedConfig({
    ResolutionPreset? resolutionPreset,
    int? frameSkipCount,
    double? confidenceThreshold,
    int? debounceMs,
  }) async {
    final level = await getPerformanceLevel();

    // Default configs for each level
    final configs = {
      DevicePerformanceLevel.high: const PerformanceConfig(
        resolutionPreset: ResolutionPreset.high,
        frameSkipCount: 1,
        confidenceThreshold: 0.75,
        debounceMs: 500,
      ),
      DevicePerformanceLevel.medium: const PerformanceConfig(
        resolutionPreset: ResolutionPreset.medium,
        frameSkipCount: 3,
        confidenceThreshold: 0.7,
        debounceMs: 1000,
      ),
      DevicePerformanceLevel.low: const PerformanceConfig(
        resolutionPreset: ResolutionPreset.low,
        frameSkipCount: 5,
        confidenceThreshold: 0.65,
        debounceMs: 1500,
      ),
      DevicePerformanceLevel.unknown: const PerformanceConfig(
        resolutionPreset: ResolutionPreset.medium,
        frameSkipCount: 3,
        confidenceThreshold: 0.7,
        debounceMs: 1000,
      ),
    };

    final defaultConfig = configs[level]!;

    // Use provided values or fall back to detected config
    return PerformanceConfig(
      resolutionPreset: resolutionPreset ?? defaultConfig.resolutionPreset,
      frameSkipCount: frameSkipCount ?? defaultConfig.frameSkipCount,
      confidenceThreshold:
          confidenceThreshold ?? defaultConfig.confidenceThreshold,
      debounceMs: debounceMs ?? defaultConfig.debounceMs,
    );
  }

  /// Get detailed device info for logging
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final Map<String, dynamic> info = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info['platform'] = 'Android';
        info['manufacturer'] = androidInfo.manufacturer;
        info['model'] = androidInfo.model;
        info['androidVersion'] = androidInfo.version.sdkInt;
        info['hardware'] = androidInfo.hardware;
        info['supported64bit'] = androidInfo.supported64BitAbis.isNotEmpty;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info['platform'] = 'iOS';
        info['model'] = iosInfo.model;
        info['name'] = iosInfo.name;
        info['systemVersion'] = iosInfo.systemVersion;
        info['isPhysicalDevice'] = iosInfo.isPhysicalDevice;
      }

      info['performanceLevel'] = (await getPerformanceLevel()).toString();
    } catch (e) {
      //debugPrint('Error getting device info: $e');
    }

    return info;
  }

  /// Clear cached performance level (for testing)
  static void clearCache() {
    _cachedLevel = null;
  }

  /// Manual override performance level (for testing)
  static void setPerformanceLevel(DevicePerformanceLevel level) {
    _cachedLevel = level;
    //debugPrint('Performance level manually set to: $level');
  }
}

// lib/Module/Language/cyberlanguageservice.dart

import 'package:cyberframework/cyberframework.dart';

/// Enum for supported languages
enum CyberLanguage {
  vietnamese,
  english;

  String get code {
    switch (this) {
      case CyberLanguage.vietnamese:
        return 'vi';
      case CyberLanguage.english:
        return 'en';
    }
  }

  String get name {
    switch (this) {
      case CyberLanguage.vietnamese:
        return 'Tiếng Việt';
      case CyberLanguage.english:
        return 'English';
    }
  }

  String get displayName {
    switch (this) {
      case CyberLanguage.vietnamese:
        return '🇻🇳 Tiếng Việt';
      case CyberLanguage.english:
        return '🇬🇧 English';
    }
  }

  static CyberLanguage fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'e':
      case 'en':
      case 'english':
        return CyberLanguage.english;
      case 'v':
      case 'vi':
      case 'vietnamese':
        return CyberLanguage.vietnamese;
      default:
        return CyberLanguage.vietnamese; // Default
    }
  }
}

/// ✅ OPTIMIZED: Language service with proper storage integration
class CyberLanguageService extends ChangeNotifier {
  static final CyberLanguageService _instance =
      CyberLanguageService._internal();
  factory CyberLanguageService() => _instance;

  CyberLanguageService._internal();

  static const String _storageKey = 'cyber_language';
  CyberLanguage _currentLanguage = CyberLanguage.vietnamese;
  bool _isInitialized = false;

  // ============================================================================
  // GETTERS
  // ============================================================================

  CyberLanguage get currentLanguage => _currentLanguage;
  String get currentLanguageCode => _currentLanguage.code;
  bool get isVietnamese => _currentLanguage == CyberLanguage.vietnamese;
  bool get isEnglish => _currentLanguage == CyberLanguage.english;
  bool get isInitialized => _isInitialized;

  // ============================================================================
  // ✅ FIXED: Initialize with proper AppStorage integration
  // ============================================================================

  /// Initialize language service
  /// Call this in main.dart before runApp()
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Language service already initialized');
      return;
    }

    try {
      // ✅ FIX: Handle null return from AppStorage.get()
      final savedLanguage = await AppStorage.get(_storageKey);

      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        _currentLanguage = CyberLanguage.fromCode(savedLanguage);
        debugPrint('✅ Loaded saved language: ${_currentLanguage.name}');
      } else {
        debugPrint(
          'ℹ️ No saved language, using default: ${_currentLanguage.name}',
        );
        // ✅ Save default language for next time
        await AppStorage.set(_storageKey, _currentLanguage.code);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing language service: $e');
      _currentLanguage = CyberLanguage.vietnamese;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ============================================================================
  // ✅ IMPROVED: Set language with validation
  // ============================================================================

  /// Change current language
  Future<void> setLanguage(CyberLanguage language) async {
    if (_currentLanguage == language) {
      debugPrint('ℹ️ Language already set to: ${language.name}');
      return;
    }

    try {
      _currentLanguage = language;

      // ✅ Save to storage
      await AppStorage.set(_storageKey, language.code);

      notifyListeners();

      // ✅ Update server if user is logged in
      await _updateLanguageOnServer();

      debugPrint('✅ Language changed to: ${language.name}');
    } catch (e) {
      debugPrint('❌ Error setting language: $e');
      rethrow;
    }
  }

  /// Toggle between Vietnamese and English
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == CyberLanguage.vietnamese
        ? CyberLanguage.english
        : CyberLanguage.vietnamese;
    await setLanguage(newLanguage);
  }

  /// Reset to default language (Vietnamese)
  Future<void> resetToDefault() async {
    await setLanguage(CyberLanguage.vietnamese);
  }

  // ============================================================================
  // TEXT TRANSLATION
  // ============================================================================

  /// Get text based on current language
  String getText(String vietnamese, String english) {
    return _currentLanguage == CyberLanguage.vietnamese ? vietnamese : english;
  }

  /// Get text with fallback to default
  String getTextOrDefault(
    String? vietnamese,
    String? english,
    String defaultText,
  ) {
    final vi = vietnamese ?? '';
    final en = english ?? '';

    if (vi.isEmpty && en.isEmpty) {
      return defaultText;
    }

    final text = getText(vi, en);
    return text.isEmpty ? defaultText : text;
  }

  // ============================================================================
  // ✅ FIXED: Server sync with proper error handling
  // ============================================================================

  /// Update language preference on server
  Future<void> _updateLanguageOnServer() async {
    try {
      // Check if user is logged in
      final strTokenId = await UserInfo.strTokenId;

      if (strTokenId == null || strTokenId.isEmpty) {
        debugPrint('ℹ️ User not logged in, skipping server update');
        return;
      }

      final context = AppNavigator.context;
      if (context == null || !context.mounted) {
        debugPrint('⚠️ No valid context, skipping server update');
        return;
      }

      // Convert to server format: 'V' for Vietnamese, 'E' for English
      final languageParam = _currentLanguage == CyberLanguage.vietnamese
          ? 'V'
          : 'E';

      // ✅ Call server API to update language
      final result = await context.callApi(
        functionName: "Cp_SysUpdateLangGuage",
        parameter: "$languageParam##",
        showLoading: false,
        showError: false,
      );

      if (result != null && result.isValid()) {
        debugPrint('✅ Language updated on server: $languageParam');
      } else {
        debugPrint('⚠️ Server update failed, but continuing...');
      }
    } catch (e) {
      // ✅ Don't rethrow - language change should work even if server update fails
      debugPrint('❌ Error updating language on server: $e');
    }
  }

  // ============================================================================
  // ✅ CLEANUP (for testing)
  // ============================================================================

  /// Clear saved language (for testing)
  Future<void> clearSavedLanguage() async {
    await AppStorage.remove(_storageKey);
    _currentLanguage = CyberLanguage.vietnamese;
    _isInitialized = false;
    notifyListeners();
    debugPrint('🗑️ Cleared saved language');
  }
}

/// Global singleton instance
final cyberLanguage = CyberLanguageService();

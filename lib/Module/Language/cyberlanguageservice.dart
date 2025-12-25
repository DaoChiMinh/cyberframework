import 'package:cyberframework/cyberframework.dart';

/// Enum cho các ngôn ngữ được hỗ trợ
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

  static CyberLanguage fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'vi':
      case 'vietnamese':
        return CyberLanguage.vietnamese;
      case 'en':
      case 'english':
        return CyberLanguage.english;
      default:
        return CyberLanguage.vietnamese; // Default
    }
  }
}

class CyberLanguageService extends ChangeNotifier {
  static final CyberLanguageService _instance =
      CyberLanguageService._internal();
  factory CyberLanguageService() => _instance;

  CyberLanguageService._internal() {
    //debugPrint('🏗️ Creating CyberLanguageService instance: ${hashCode}');
  }

  static const String _storageKey = 'cyber_language';
  CyberLanguage _currentLanguage = CyberLanguage.vietnamese;

  CyberLanguage get currentLanguage {
    //debugPrint(
    // '📖 Reading currentLanguage from instance ${hashCode}: $_currentLanguage',
    // );
    return _currentLanguage;
  }

  String get currentLanguageCode => _currentLanguage.code;
  bool get isVietnamese => _currentLanguage == CyberLanguage.vietnamese;
  bool get isEnglish => _currentLanguage == CyberLanguage.english;

  Future<void> initialize() async {
    //debugPrint('🔧 Initialize called on instance: ${hashCode}');

    try {
      //debugPrint('🔄 Loading saved language...');
      final savedLanguage = await AppStorage.get(_storageKey);
      //debugPrint('📦 Saved language value: "$savedLanguage"');

      if (savedLanguage.isNotEmpty) {
        _currentLanguage = CyberLanguage.fromCode(savedLanguage);
        //debugPrint(
        //  '✅ Instance ${hashCode} - Loaded language: ${_currentLanguage.name}',
        // );
      } else {
        //debugPrint(
        // '⚠️ No saved language, using default: ${_currentLanguage.name}',
        // );
      }

      notifyListeners();
    } catch (e) {
      //debugPrint('❌ Error loading language: $e');
      _currentLanguage = CyberLanguage.vietnamese;
      notifyListeners();
    }
  }

  Future<void> setLanguage(CyberLanguage language) async {
    //debugPrint('🔧 setLanguage called on instance ${hashCode}: $language');
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    await AppStorage.set(_storageKey, language.code);
    notifyListeners();

    //debugPrint('✅ Language changed to: ${language.name}');
  }

  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == CyberLanguage.vietnamese
        ? CyberLanguage.english
        : CyberLanguage.vietnamese;
    await setLanguage(newLanguage);
  }

  String getText(String vietnamese, String english) {
    //debugPrint('🌐 getText on instance ${hashCode}: $_currentLanguage');
    return _currentLanguage == CyberLanguage.vietnamese ? vietnamese : english;
  }

  String getTextOrDefault(
    String? vietnamese,
    String? english,
    String defaultText,
  ) {
    final text = getText(vietnamese ?? '', english ?? '');
    return text.isEmpty ? defaultText : text;
  }
}

final cyberLanguage = CyberLanguageService();

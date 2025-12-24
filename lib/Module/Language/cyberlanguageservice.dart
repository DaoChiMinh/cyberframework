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

/// Service quản lý ngôn ngữ với ChangeNotifier để auto-rebuild
class CyberLanguageService extends ChangeNotifier {
  static final CyberLanguageService _instance =
      CyberLanguageService._internal();
  factory CyberLanguageService() => _instance;
  CyberLanguageService._internal();

  static const String _storageKey = 'cyber_language';
  CyberLanguage _currentLanguage = CyberLanguage.vietnamese;
  bool _isInitialized = false;

  /// Lấy ngôn ngữ hiện tại
  CyberLanguage get currentLanguage => _currentLanguage;

  /// Lấy language code hiện tại (vi/en)
  String get currentLanguageCode => _currentLanguage.code;

  /// Check xem có phải tiếng Việt không
  bool get isVietnamese => _currentLanguage == CyberLanguage.vietnamese;

  /// Check xem có phải tiếng Anh không
  bool get isEnglish => _currentLanguage == CyberLanguage.english;

  /// Khởi tạo và load ngôn ngữ đã lưu
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final savedLanguage = await AppStorage.get(_storageKey);
      if (savedLanguage.isNotEmpty) {
        _currentLanguage = CyberLanguage.fromCode(savedLanguage);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading language: $e');
      _currentLanguage = CyberLanguage.vietnamese;
    }
  }

  /// Thay đổi ngôn ngữ và lưu vào storage
  Future<void> setLanguage(CyberLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;

    // Lưu vào storage
    await AppStorage.set(_storageKey, language.code);

    // Notify tất cả listeners để rebuild
    notifyListeners();

    debugPrint('✅ Language changed to: ${language.name}');
  }

  /// Toggle giữa 2 ngôn ngữ
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == CyberLanguage.vietnamese
        ? CyberLanguage.english
        : CyberLanguage.vietnamese;
    await setLanguage(newLanguage);
  }

  /// Lấy text theo ngôn ngữ hiện tại
  /// Usage: getText('Xin chào', 'Hello')
  String getText(String vietnamese, String english) {
    return _currentLanguage == CyberLanguage.vietnamese ? vietnamese : english;
  }

  /// Lấy text với fallback
  String getTextOrDefault(
    String? vietnamese,
    String? english,
    String defaultText,
  ) {
    final text = getText(vietnamese ?? '', english ?? '');
    return text.isEmpty ? defaultText : text;
  }
}

/// Global instance để dễ truy cập
final cyberLanguage = CyberLanguageService();

import 'package:flutter/material.dart';
import 'CyberLanguageService.dart';

/// Extension on String for multilingual text
extension CyberLanguageStringExtension on String {
  /// Translate with English text
  /// Usage: "Xin chào".tr("Hello")
  String tr(String english) {
    return ngonngu(this, english);
  }

  /// Operator >> for translation
  /// Usage: "Xin chào" >> "Hello"
  String operator >>(String english) {
    return ngonngu(this, english);
  }
}

/// Extension on BuildContext for easy access to language service
extension CyberLanguageBuildContext on BuildContext {
  /// Get current language
  CyberLanguage get language => cyberLanguage.currentLanguage;

  /// Translate text based on current language
  String tr(String vietnamese, String english) {
    return ngonngu(vietnamese, english);
  }

  /// Check if current language is Vietnamese
  bool get isVietnamese => cyberLanguage.isVietnamese;

  /// Check if current language is English
  bool get isEnglish => cyberLanguage.isEnglish;
}

/// Global function to get text based on current language
/// This is the main API for multilingual text
/// Usage: Text(ngonngu("Xin chào", "Hello"))
String ngonngu(String vietnamese, String english) {
  return cyberLanguage.getText(vietnamese, english);
}

/// CyberLanguageBuilder - Auto-rebuild widget when language changes
/// Wrap your widgets that need to update when language changes
class CyberLanguageBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, CyberLanguage language) builder;

  const CyberLanguageBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cyberLanguage,
      builder: (context, _) => builder(context, cyberLanguage.currentLanguage),
    );
  }
}

/// CyberLangText widget with automatic language switching
/// Use this widget for text that needs to change based on current language
/// Note: Renamed from CyberText to avoid conflict with existing CyberText control
class CyberLangText extends StatelessWidget {
  final String vietnamese;
  final String english;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const CyberLangText(
    this.vietnamese,
    this.english, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return CyberLanguageBuilder(
      builder: (context, language) => Text(
        ngonngu(vietnamese, english),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// CyberLanguageSwitch - Toggle button to switch between Vietnamese and English
class CyberLanguageSwitch extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? activeColor;
  final Color? inactiveColor;
  final TextStyle? textStyle;

  const CyberLanguageSwitch({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.activeColor,
    this.inactiveColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return CyberLanguageBuilder(
      builder: (context, language) {
        final isVi = language == CyberLanguage.vietnamese;
        return InkWell(
          onTap: () => cyberLanguage.toggleLanguage(),
          child: Container(
            width: width ?? 80,
            height: height ?? 36,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: activeColor ?? Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  isVi ? 'VI' : 'EN',
                  style:
                      textStyle ??
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// CyberLanguageSelector - Bottom sheet to select language
class CyberLanguageSelector extends StatelessWidget {
  final String? title;
  final TextStyle? titleStyle;
  final TextStyle? optionStyle;

  const CyberLanguageSelector({
    super.key,
    this.title,
    this.titleStyle,
    this.optionStyle,
  });

  void show(BuildContext context) {
    showModalBottomSheet(context: context, builder: (context) => this);
  }

  @override
  Widget build(BuildContext context) {
    return CyberLanguageBuilder(
      builder: (context, language) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? ngonngu('Chọn ngôn ngữ', 'Select Language'),
              style:
                  titleStyle ??
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _LanguageOption(
              language: CyberLanguage.vietnamese,
              icon: '🇻🇳',
              label: 'Tiếng Việt',
              isSelected: language == CyberLanguage.vietnamese,
              textStyle: optionStyle,
            ),
            const Divider(),
            _LanguageOption(
              language: CyberLanguage.english,
              icon: '🇬🇧',
              label: 'English',
              isSelected: language == CyberLanguage.english,
              textStyle: optionStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final CyberLanguage language;
  final String icon;
  final String label;
  final bool isSelected;
  final TextStyle? textStyle;

  const _LanguageOption({
    required this.language,
    required this.icon,
    required this.label,
    required this.isSelected,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 32)),
      title: Text(
        label,
        style:
            textStyle ??
            TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        cyberLanguage.setLanguage(language);
        Navigator.pop(context);
      },
    );
  }
}

/// Optional: Common language constants
class CyberLanguageConstants {
  static String get ok => ngonngu('Đồng ý', 'OK');
  static String get cancel => ngonngu('Hủy', 'Cancel');
  static String get save => ngonngu('Lưu', 'Save');
  static String get delete => ngonngu('Xóa', 'Delete');
  static String get edit => ngonngu('Sửa', 'Edit');
  static String get add => ngonngu('Thêm', 'Add');
  static String get search => ngonngu('Tìm kiếm', 'Search');
  static String get error => ngonngu('Lỗi', 'Error');
  static String get success => ngonngu('Thành công', 'Success');
  static String get warning => ngonngu('Cảnh báo', 'Warning');
  static String get info => ngonngu('Thông tin', 'Information');
  static String get confirm => ngonngu('Xác nhận', 'Confirm');
  static String get confirmDelete =>
      ngonngu('Bạn có chắc muốn xóa?', 'Are you sure you want to delete?');
  static String get saveSuccess =>
      ngonngu('Lưu thành công', 'Saved successfully');
  static String get deleteSuccess =>
      ngonngu('Xóa thành công', 'Deleted successfully');
}

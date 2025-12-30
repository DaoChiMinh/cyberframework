// lib/Module/Language/cyberlanguageextension.dart

import 'package:cyberframework/cyberframework.dart';

// ============================================================================
// STRING EXTENSIONS
// ============================================================================

/// Extension on String for multilingual text
extension CyberLanguageStringExtension on String {
  /// Translate with English text
  /// Usage: "Xin chào".tr("Hello")
  String tr(String english) {
    return setText(this, english);
  }

  /// Operator >> for translation
  /// Usage: "Xin chào" >> "Hello"
  String operator >>(String english) {
    return setText(this, english);
  }
}

// ============================================================================
// BUILDCONTEXT EXTENSIONS
// ============================================================================

/// Extension on BuildContext for easy access to language service
extension CyberLanguageBuildContext on BuildContext {
  /// Get current language
  CyberLanguage get language => cyberLanguage.currentLanguage;

  /// Translate text based on current language
  String tr(String vietnamese, String english) {
    return setText(vietnamese, english);
  }

  /// Check if current language is Vietnamese
  bool get isVietnamese => cyberLanguage.isVietnamese;

  /// Check if current language is English
  bool get isEnglish => cyberLanguage.isEnglish;
}

// ============================================================================
// GLOBAL TRANSLATION FUNCTION
// ============================================================================

/// Global function to get text based on current language
/// This is the main API for multilingual text
/// Usage: Text(setText("Xin chào", "Hello"))
String setText(String vietnamese, String english) {
  return cyberLanguage.getText(vietnamese, english);
}

// ============================================================================
// ✅ OPTIMIZED: Auto-rebuild widgets
// ============================================================================

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

// ============================================================================
// ✅ IMPROVED: Text widget with proper overflow handling
// ============================================================================

/// CyberLangText widget with automatic language switching
class CyberLangText extends StatelessWidget {
  final String vietnamese;
  final String english;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const CyberLangText(
    this.vietnamese,
    this.english, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    return CyberLanguageBuilder(
      builder: (context, language) => Text(
        setText(vietnamese, english),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      ),
    );
  }
}

// ============================================================================
// ✅ IMPROVED: Language switch button
// ============================================================================

/// CyberLanguageSwitch - Toggle button to switch between Vietnamese and English
class CyberLanguageSwitch extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? activeColor;
  final Color? inactiveColor;
  final TextStyle? textStyle;
  final bool showIcon;
  final bool showText;

  const CyberLanguageSwitch({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.activeColor,
    this.inactiveColor,
    this.textStyle,
    this.showIcon = true,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return CyberLanguageBuilder(
      builder: (context, language) {
        final isVi = language == CyberLanguage.vietnamese;

        return InkWell(
          onTap: () => cyberLanguage.toggleLanguage(),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: width ?? (showIcon && showText ? 80 : 50),
            height: height ?? 36,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: activeColor ?? Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showIcon) ...[
                  const Icon(Icons.language, size: 18, color: Colors.white),
                  if (showText) const SizedBox(width: 6),
                ],
                if (showText)
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

// ============================================================================
// ✅ IMPROVED: Language selector bottom sheet
// ============================================================================

/// CyberLanguageSelector - Bottom sheet to select language
class CyberLanguageSelector extends StatelessWidget {
  final String? title;
  final TextStyle? titleStyle;
  final TextStyle? optionStyle;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const CyberLanguageSelector({
    super.key,
    this.title,
    this.titleStyle,
    this.optionStyle,
    this.backgroundColor,
    this.borderRadius,
  });

  /// Show selector as bottom sheet
  static void show(
    BuildContext context, {
    String? title,
    TextStyle? titleStyle,
    TextStyle? optionStyle,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CyberLanguageSelector(
        title: title,
        titleStyle: titleStyle,
        optionStyle: optionStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CyberLanguageBuilder(
      builder: (context, language) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius:
              borderRadius ??
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Text(
              title ?? setText('Chọn ngôn ngữ', 'Select Language'),
              style:
                  titleStyle ??
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Language options
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

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Language option in selector
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
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () {
        cyberLanguage.setLanguage(language);
        Navigator.pop(context);
      },
    );
  }
}

// ============================================================================
// ✅ COMMON LANGUAGE CONSTANTS
// ============================================================================

/// Common translated strings
class CyberLanguageConstants {
  // Actions
  static String get ok => setText('Đồng ý', 'OK');
  static String get cancel => setText('Hủy', 'Cancel');
  static String get save => setText('Lưu', 'Save');
  static String get delete => setText('Xóa', 'Delete');
  static String get edit => setText('Sửa', 'Edit');
  static String get add => setText('Thêm', 'Add');
  static String get search => setText('Tìm kiếm', 'Search');
  static String get close => setText('Đóng', 'Close');
  static String get back => setText('Quay lại', 'Back');
  static String get next => setText('Tiếp theo', 'Next');
  static String get previous => setText('Trước', 'Previous');
  static String get done => setText('Xong', 'Done');
  static String get retry => setText('Thử lại', 'Retry');

  // Status
  static String get error => setText('Lỗi', 'Error');
  static String get success => setText('Thành công', 'Success');
  static String get warning => setText('Cảnh báo', 'Warning');
  static String get info => setText('Thông tin', 'Information');
  static String get loading => setText('Đang tải...', 'Loading...');

  // Confirmation
  static String get confirm => setText('Xác nhận', 'Confirm');
  static String get confirmDelete =>
      setText('Bạn có chắc muốn xóa?', 'Are you sure you want to delete?');

  // Messages
  static String get saveSuccess =>
      setText('Lưu thành công', 'Saved successfully');
  static String get deleteSuccess =>
      setText('Xóa thành công', 'Deleted successfully');
  static String get updateSuccess =>
      setText('Cập nhật thành công', 'Updated successfully');
  static String get noData => setText('Không có dữ liệu', 'No data');
  static String get networkError =>
      setText('Lỗi kết nối mạng', 'Network error');
}

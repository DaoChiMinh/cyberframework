import 'package:cyberframework/cyberframework.dart';

/// Extension cho String để dễ dàng tạo multilingual text
extension CyberLanguageStringExtension on String {
  /// Lấy text theo ngôn ngữ hiện tại
  /// Usage: "Xin chào".tr("Hello")
  /// hoặc: "Xin chào" >> "Hello"
  String tr(String english) {
    return cyberLanguage.getText(this, english);
  }

  /// Operator >> để viết ngắn gọn hơn
  /// Usage: "Xin chào" >> "Hello"
  String operator >>(String english) {
    return cyberLanguage.getText(this, english);
  }
}

/// Extension cho BuildContext để dễ dùng
extension CyberLanguageContextExtension on BuildContext {
  /// Lấy service ngôn ngữ
  CyberLanguageService get language => cyberLanguage;

  /// Lấy text theo ngôn ngữ
  String tr(String vietnamese, String english) {
    return cyberLanguage.getText(vietnamese, english);
  }

  /// Check ngôn ngữ hiện tại
  bool get isVietnamese => cyberLanguage.isVietnamese;
  bool get isEnglish => cyberLanguage.isEnglish;
}

/// Helper function để dùng ở bất kỳ đâu
/// Usage: ngonngu("Tiếng Việt", "English")
String ngonngu(String vietnamese, String english) {
  return cyberLanguage.getText(vietnamese, english);
}

/// Widget để tự động rebuild khi ngôn ngữ thay đổi
class CyberLanguageBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, CyberLanguage language) builder;

  const CyberLanguageBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cyberLanguage,
      builder: (context, child) {
        return builder(context, cyberLanguage.currentLanguage);
      },
    );
  }
}

/// Widget Text tự động chuyển đổi ngôn ngữ
class CyberText extends StatelessWidget {
  final String vietnamese;
  final String english;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const CyberText(
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
      builder: (context, language) {
        return Text(
          ngonngu(vietnamese, english),
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Widget để chuyển đổi ngôn ngữ dễ dàng
class CyberLanguageSwitch extends StatelessWidget {
  final ValueChanged<CyberLanguage>? onChanged;
  final bool showLabel;

  const CyberLanguageSwitch({super.key, this.onChanged, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    return CyberLanguageBuilder(
      builder: (context, language) {
        return InkWell(
          onTap: () async {
            await cyberLanguage.toggleLanguage();
            onChanged?.call(cyberLanguage.currentLanguage);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  language == CyberLanguage.vietnamese
                      ? Icons.language
                      : Icons.translate,
                  size: 20,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    language == CyberLanguage.vietnamese ? 'VI' : 'EN',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget để chọn ngôn ngữ với bottom sheet
class CyberLanguageSelector extends StatelessWidget {
  final ValueChanged<CyberLanguage>? onChanged;

  const CyberLanguageSelector({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CyberLanguageBuilder(
      builder: (context, currentLanguage) {
        return InkWell(
          onTap: () => _showLanguageSheet(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 20),
                const SizedBox(width: 8),
                Text(
                  currentLanguage.name,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageSheet(onChanged: onChanged),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final ValueChanged<CyberLanguage>? onChanged;

  const _LanguageSheet({this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    ngonngu('Chọn ngôn ngữ', 'Select Language'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Language options
            _buildLanguageOption(
              context,
              CyberLanguage.vietnamese,
              Icons.flag,
              Colors.red,
            ),
            _buildLanguageOption(
              context,
              CyberLanguage.english,
              Icons.flag,
              Colors.blue,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    CyberLanguage language,
    IconData icon,
    Color iconColor,
  ) {
    return CyberLanguageBuilder(
      builder: (context, currentLanguage) {
        final isSelected = currentLanguage == language;

        return InkWell(
          onTap: () async {
            await cyberLanguage.setLanguage(language);
            onChanged?.call(language);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    language.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blue),
              ],
            ),
          ),
        );
      },
    );
  }
}

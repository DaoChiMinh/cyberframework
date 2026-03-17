import 'package:cyberframework/cyberframework.dart';

/// CyberButtonUpload - Upload file trigger dùng CyberLabel làm giao diện.
///
/// - Label: đầy đủ tính năng CyberLabel (text/icon, binding, ripple, style...)
/// - text: binding nhận kết quả URL/base64 sau upload
/// - Bên dưới hiện tên file đã upload, có thể tap để mở
///
/// ```dart
/// // Text label
/// CyberButtonUpload(
///   label: 'Tải lên hợp đồng',
///   text: dr.bind('contract_url'),
///   types: [FilePickerType.pdf, FilePickerType.camera],
///   uploadFilePath: '/contracts/',
///   onUploaded: (r) => print(r?.urlFile),
/// )
///
/// // Icon label
/// CyberButtonUpload(
///   label: 'e5c9',
///   isIcon: true,
///   iconSize: 28,
///   textcolor: Colors.blue,
///   text: dr.bind('avatar_url'),
///   types: [FilePickerType.image, FilePickerType.camera],
/// )
/// ```
class CyberButtonUpload extends StatefulWidget {
  // ============================================================
  // LABEL — toàn bộ props của CyberLabel
  // ============================================================
  /// Text hoặc icon code point. Hỗ trợ CyberBindingExpression.
  final dynamic label;

  final String? format;
  final TextStyle? style;
  final TextAlign? textalign;
  final Color? textcolor;
  final Color? backgroundColor;

  final dynamic isVisible;

  /// true = hiển thị label như icon
  final bool isIcon;
  final double? iconSpacing;
  final double? iconSize;

  final bool? showRipple;
  final Color? rippleColor;
  final BorderRadius? rippleBorderRadius;
  final EdgeInsets? tapPadding;

  final int? maxLines;
  final TextOverflow? overflow;

  // ============================================================
  // TEXT — field nhận kết quả URL sau upload
  // ============================================================
  /// Binding nhận URL/base64 kết quả upload.
  /// Hỗ trợ CyberBindingExpression hoặc String tĩnh.
  final dynamic text;

  /// Hiện tên file bên dưới label sau khi upload
  final bool showText;

  /// Format hiển thị text
  final String? textFormat;

  /// Callback khi tap vào đường dẫn file
  final Function(dynamic url)? onTextTap;

  // ============================================================
  // GENERAL
  // ============================================================
  final bool isReadOnly;

  // ============================================================
  // FILE PICKER CONFIG
  // ============================================================
  /// Nhãn hiển thị trong ActionSheet.
  /// Nếu null → mặc định: ['Chọn ảnh', 'Chụp ảnh', 'Chọn file']
  final List<String>? actions;

  /// Loại file tương ứng với [actions].
  /// Nếu null → mặc định: [image, camera, file]
  final List<FilePickerType>? types;

  /// true = tự động upload lên server, false = chỉ lấy base64
  final bool autoUpload;

  /// Thư mục upload trên server (vd: '/contracts/')
  final String? uploadFilePath;

  /// Tiêu đề ActionSheet
  final String? pickerTitle;

  /// Hiện dialog đổi tên trước khi upload
  final bool isChangeName;

  // ============================================================
  // CALLBACKS
  // ============================================================
  final Function(CyberFilePickerResult? result)? onUploaded;

  const CyberButtonUpload({
    super.key,
    // Label (CyberLabel props)
    this.label = 'Tải lên',
    this.format,
    this.style,
    this.textalign,
    this.textcolor,
    this.backgroundColor,
    this.isVisible = true,
    this.isIcon = false,
    this.iconSpacing,
    this.iconSize,
    this.showRipple,
    this.rippleColor,
    this.rippleBorderRadius,
    this.tapPadding,
    this.maxLines,
    this.overflow,
    // Text binding
    this.text,
    this.showText = true,
    this.textFormat,
    this.onTextTap,
    // General
    this.isReadOnly = false,
    // File picker
    this.actions,
    this.types,
    this.autoUpload = true,
    this.uploadFilePath,
    this.pickerTitle,
    this.isChangeName = false,
    // Callback
    this.onUploaded,
  });

  @override
  State<CyberButtonUpload> createState() => _CyberButtonUploadState();
}

class _CyberButtonUploadState extends State<CyberButtonUpload> {
  CyberDataRow? _textBoundRow;
  String? _textBoundField;

  @override
  void initState() {
    super.initState();
    _resolveTextBinding();
  }

  @override
  void didUpdateWidget(covariant CyberButtonUpload oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _resolveTextBinding();
  }

  void _resolveTextBinding() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _textBoundRow = expr.row;
      _textBoundField = expr.fieldName;
    } else {
      _textBoundRow = null;
      _textBoundField = null;
    }
  }

  static const _defaultActions = ['Chọn ảnh', 'Chụp ảnh', 'Chọn file'];
  static const _defaultTypes = [
    FilePickerType.image,
    FilePickerType.camera,
    FilePickerType.file,
  ];

  Future<void> _handleUpload() async {
    if (widget.isReadOnly) return;

    try {
      final result = await context.showFilePickerActionSheet(
        actions: widget.actions ?? _defaultActions,
        types: widget.types ?? _defaultTypes,
        autoUpload: widget.autoUpload,
        uploadFilePath: widget.uploadFilePath,
        title: widget.pickerTitle,
        isChangeName: widget.isChangeName,
      );

      if (result != null) {
        if (_textBoundRow != null && _textBoundField != null) {
          final value = widget.autoUpload
              ? (result.urlFile ?? result.strBase64 ?? '')
              : (result.strBase64 ?? '');
          _textBoundRow!.setValue(_textBoundField!, value);
        }
        widget.onUploaded?.call(result);
      }
    } catch (_) {}
  }

  // ── label dùng CyberLabel trực tiếp ──────────────────────────
  Widget _buildLabel() {
    return CyberLabel(
      text: widget.label,
      format: widget.format,
      style: widget.style,
      textalign: widget.textalign,
      textcolor: widget.textcolor,
      backgroundColor: widget.backgroundColor,
      isVisible: widget.isVisible,
      isIcon: widget.isIcon,
      iconSpacing: widget.iconSpacing,
      iconSize: widget.iconSize,
      showRipple: widget.showRipple,
      rippleColor: widget.rippleColor,
      rippleBorderRadius: widget.rippleBorderRadius,
      tapPadding: widget.tapPadding,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      onLeaver: widget.isReadOnly ? null : (_) => _handleUpload(),
    );
  }

  // ── text display ──────────────────────────────────────────────
  Widget _buildTextDisplay() {
    if (!widget.showText) return const SizedBox.shrink();

    dynamic rawValue;
    if (_textBoundRow != null && _textBoundField != null) {
      rawValue = _textBoundRow![_textBoundField!];
    } else if (widget.text is String) {
      rawValue = widget.text as String;
    }

    final urlStr = rawValue?.toString() ?? '';
    if (urlStr.isEmpty) return const SizedBox.shrink();

    String displayText;
    if (widget.textFormat != null && widget.textFormat!.isNotEmpty) {
      displayText = widget.textFormat!.format([urlStr]);
    } else {
      displayText = urlStr.contains('/')
          ? urlStr.split('/').last
          : urlStr.contains('\\')
          ? urlStr.split('\\').last
          : urlStr;
      if (urlStr.length > 200 && !urlStr.startsWith('http')) {
        displayText = setText('[Dữ liệu file]', '[File data]');
      }
    }

    final bool hasTap = widget.onTextTap != null;

    Widget textRow = Row(
      children: [
        Icon(
          Icons.attach_file,
          size: 13,
          color: hasTap ? Colors.blue[600] : Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 13,
              color: hasTap ? Colors.blue[600] : Colors.grey[700],
              decoration: hasTap ? TextDecoration.underline : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasTap) ...[
          const SizedBox(width: 4),
          Icon(Icons.open_in_new, size: 12, color: Colors.blue[600]),
        ],
      ],
    );

    if (hasTap) {
      textRow = GestureDetector(
        onTap: () => widget.onTextTap!(rawValue),
        child: textRow,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(width: double.infinity, child: textRow),
    );
  }

  // ── build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLabel(),
        if (_textBoundRow != null)
          ListenableBuilder(
            listenable: _textBoundRow!,
            builder: (_, __) => _buildTextDisplay(),
          )
        else
          _buildTextDisplay(),
      ],
    );
  }
}

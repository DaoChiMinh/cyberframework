import 'package:cyberframework/cyberframework.dart';

/// CyberButtonUpload - Button upload file với binding support
///
/// Kết hợp tính năng của:
/// - [CyberButton]: Styling button
/// - [CyberLabel]: Label có thể là text hoặc icon, hỗ trợ binding
/// - [showFilePickerActionSheet]: File picker & upload
///
/// Usage:
/// ```dart
/// // Basic upload button
/// CyberButtonUpload(
///   label: 'Tải lên hợp đồng',
///   text: dr.bind('contract_url'),
///   actions: ['Chọn PDF', 'Chụp ảnh'],
///   types: [FilePickerType.pdf, FilePickerType.camera],
///   uploadFilePath: '/contracts/',
///   onUploaded: (result) => print(result?.urlFile),
/// )
///
/// // Icon button
/// CyberButtonUpload(
///   label: 'e5c9', // Material icon code point
///   isIcon: true,
///   text: dr.bind('avatar_url'),
///   types: [FilePickerType.image, FilePickerType.camera],
/// )
/// ```
class CyberButtonUpload extends StatefulWidget {
  // ============================================================
  // LABEL (Nội dung hiển thị trên button)
  // ============================================================
  /// Text hoặc icon code point. Hỗ trợ CyberBindingExpression.
  final dynamic label;

  /// true = hiển thị label như icon (parse code point)
  final bool isIcon;

  /// Kích thước icon (khi isIcon = true)
  final double? iconSize;

  /// Style cho text label
  final TextStyle? labelStyle;

  /// Màu icon (mặc định dùng textColor)
  final Color? iconColor;

  // ============================================================
  // TEXT (File URL - binding output)
  // ============================================================
  /// Field binding nhận kết quả URL sau upload.
  /// Hỗ trợ CyberBindingExpression (dr.bind('field')) hoặc String tĩnh.
  final dynamic text;

  /// Hiện đường dẫn file bên dưới button sau khi upload
  final bool showText;

  /// Format hiển thị text (ít dùng, để mở rộng sau)
  final String? textFormat;

  /// Callback khi user tap vào đường dẫn file
  final Function(dynamic url)? onTextTap;

  // ============================================================
  // BUTTON STYLING
  // ============================================================
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double paddingVertical;
  final double paddingHorizontal;

  /// Chiếm toàn bộ chiều ngang (mặc định true, giống CyberButton)
  final bool fullWidth;

  /// Chỉ đọc - không cho phép upload
  final bool isReadOnly;

  // ============================================================
  // FILE PICKER CONFIG
  // ============================================================
  /// Danh sách nhãn hiển thị trong ActionSheet
  /// Nếu null → dùng mặc định: ['Chọn ảnh', 'Chụp ảnh', 'Chọn file']
  final List<String>? actions;

  /// Loại file tương ứng với [actions]
  /// Nếu null → dùng mặc định: [image, camera, file]
  final List<FilePickerType>? types;

  /// true = tự động upload và lưu URL, false = chỉ lấy base64
  final bool autoUpload;

  /// Đường dẫn thư mục upload trên server (vd: '/contracts/')
  final String? uploadFilePath;

  /// Tiêu đề của ActionSheet picker
  final String? pickerTitle;

  /// Hiển thị dialog đổi tên trước khi upload
  final bool isChangeName;

  // ============================================================
  // CALLBACKS
  // ============================================================
  /// Callback sau khi upload xong (hoặc chọn file xong nếu autoUpload=false)
  final Function(CyberFilePickerResult? result)? onUploaded;

  const CyberButtonUpload({
    super.key,
    // Label
    this.label = 'Tải lên',
    this.isIcon = false,
    this.iconSize,
    this.labelStyle,
    this.iconColor,
    // Text binding
    this.text,
    this.showText = true,
    this.textFormat,
    this.onTextTap,
    // Styling
    this.backgroundColor = const Color(0xFF00D287),
    this.textColor = Colors.white,
    this.borderRadius = 30.0,
    this.paddingVertical = 12.0,
    this.paddingHorizontal = 10.0,
    this.fullWidth = true,
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
  bool _isUploading = false;

  // ── Text binding ──────────────────────────────────────────────
  CyberDataRow? _textBoundRow;
  String? _textBoundField;

  // ── Label binding ─────────────────────────────────────────────
  CyberDataRow? _labelBoundRow;
  String? _labelBoundField;

  @override
  void initState() {
    super.initState();
    _resolveBindings();
  }

  @override
  void didUpdateWidget(covariant CyberButtonUpload oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.label != widget.label) {
      _resolveBindings();
    }
  }

  void _resolveBindings() {
    // Resolve text binding
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _textBoundRow = expr.row;
      _textBoundField = expr.fieldName;
    } else {
      _textBoundRow = null;
      _textBoundField = null;
    }

    // Resolve label binding
    if (widget.label is CyberBindingExpression) {
      final expr = widget.label as CyberBindingExpression;
      _labelBoundRow = expr.row;
      _labelBoundField = expr.fieldName;
    } else {
      _labelBoundRow = null;
      _labelBoundField = null;
    }
  }

  // ── Default picker config ─────────────────────────────────────
  static const _defaultActions = ['Chọn ảnh', 'Chụp ảnh', 'Chọn file'];
  static const _defaultTypes = [
    FilePickerType.image,
    FilePickerType.camera,
    FilePickerType.file,
  ];

  // ── Upload handler ────────────────────────────────────────────
  Future<void> _handleUpload() async {
    if (_isUploading || widget.isReadOnly) return;

    setState(() => _isUploading = true);

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
        // Ghi kết quả vào bound field
        if (_textBoundRow != null && _textBoundField != null) {
          final value = widget.autoUpload
              ? (result.urlFile ?? result.strBase64 ?? '')
              : (result.strBase64 ?? '');
          _textBoundRow!.setValue(_textBoundField!, value);
        }
        widget.onUploaded?.call(result);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Build label content bên trong button ─────────────────────
  Widget _buildLabelContent() {
    // Loading state
    if (_isUploading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.textColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            setText('Đang tải lên...', 'Uploading...'),
            style: TextStyle(
              color: widget.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    // Lấy giá trị label (có thể từ binding)
    dynamic labelValue;
    if (_labelBoundRow != null && _labelBoundField != null) {
      labelValue = _labelBoundRow![_labelBoundField!];
    } else {
      labelValue = widget.label;
    }

    // Icon mode
    if (widget.isIcon) {
      final valueStr = labelValue?.toString() ?? '';
      final iconData = v_parseIcon(valueStr);

      if (iconData != null) {
        return Icon(
          iconData,
          size: widget.iconSize ?? (widget.labelStyle?.fontSize ?? 24),
          color: widget.iconColor ?? widget.textColor,
        );
      }
      // Fallback to text nếu không parse được icon
    }

    // Text mode
    return Text(
      labelValue?.toString() ?? '',
      style:
          widget.labelStyle?.copyWith(color: widget.textColor) ??
          TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
    );
  }

  // ── Build button ──────────────────────────────────────────────
  Widget _buildButton() {
    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: (widget.isReadOnly || _isUploading) ? null : _handleUpload,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.textColor,
          disabledBackgroundColor: widget.backgroundColor.withValues(
            alpha: 0.5,
          ),
          padding: EdgeInsets.symmetric(
            vertical: widget.paddingVertical,
            horizontal: widget.paddingHorizontal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
        child: _buildLabelContent(),
      ),
    );
  }

  // ── Build text display (file URL/name) ────────────────────────
  Widget _buildTextDisplay() {
    if (!widget.showText) return const SizedBox.shrink();

    // Lấy giá trị URL
    dynamic rawValue;
    if (_textBoundRow != null && _textBoundField != null) {
      rawValue = _textBoundRow![_textBoundField!];
    } else if (widget.text is String) {
      rawValue = widget.text as String;
    } else {
      rawValue = null;
    }

    final urlStr = rawValue?.toString() ?? '';
    if (urlStr.isEmpty) return const SizedBox.shrink();

    // Format hiển thị
    String displayText;
    if (widget.textFormat != null && widget.textFormat!.isNotEmpty) {
      displayText = widget.textFormat!.format([urlStr]);
    } else {
      // Chỉ hiện tên file (phần cuối của URL/path)
      displayText = urlStr.contains('/')
          ? urlStr.split('/').last
          : urlStr.contains('\\')
          ? urlStr.split('\\').last
          : urlStr;

      // Nếu là base64 thì hiện "[Dữ liệu file]"
      if (urlStr.length > 200 && !urlStr.startsWith('http')) {
        displayText = setText('[Dữ liệu file]', '[File data]');
      }
    }

    final bool hasTapAction = widget.onTextTap != null;

    Widget textRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.attach_file,
          size: 14,
          color: hasTapAction ? Colors.blue[600] : Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 13,
              color: hasTapAction ? Colors.blue[600] : Colors.grey[700],
              decoration: hasTapAction
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasTapAction) ...[
          const SizedBox(width: 4),
          Icon(Icons.open_in_new, size: 12, color: Colors.blue[600]),
        ],
      ],
    );

    if (hasTapAction) {
      textRow = GestureDetector(
        onTap: () => widget.onTextTap!(rawValue),
        child: textRow,
      );
    }

    return Padding(padding: const EdgeInsets.only(top: 6), child: textRow);
  }

  // ── Main build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Xác định các row cần listen
    final Set<CyberDataRow> listenRows = {};
    if (_textBoundRow != null) listenRows.add(_textBoundRow!);
    if (_labelBoundRow != null) listenRows.add(_labelBoundRow!);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [_buildButton(), _buildTextDisplay()],
    );

    // Wrap với ListenableBuilder nếu có binding
    if (listenRows.isNotEmpty) {
      final listenable = listenRows.length == 1
          ? listenRows.first as Listenable
          : Listenable.merge(listenRows.toList());

      return ListenableBuilder(
        listenable: listenable,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [_buildButton(), _buildTextDisplay()],
        ),
      );
    }

    return content;
  }
}

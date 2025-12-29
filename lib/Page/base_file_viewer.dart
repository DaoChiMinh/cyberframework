import 'package:cyberframework/cyberframework.dart';
import 'package:http/http.dart' as http;

enum FileSourceType { base64, path, url }

abstract class BaseFileViewer extends CyberForm {
  String text = ""; // Chứa base64, path, hoặc URL
  FileSourceType? _sourceType;
  String? _localFilePath;
  Uint8List? _fileBytes;
  bool _isLoading = true;
  String? _errorMessage;

  bool showToolbar = true;
  String fileExtension = "";

  @override
  Future<void> onLoadData() async {
    try {
      _isLoading = true;
      rebuild();

      // Detect source type
      _sourceType = _detectSourceType(text);

      // Load file based on source type
      switch (_sourceType) {
        case FileSourceType.base64:
          await _loadFromBase64();
          break;
        case FileSourceType.path:
          await _loadFromPath();
          break;
        case FileSourceType.url:
          await _loadFromUrl();
          break;
        default:
          throw Exception(setText('Định dạng không hợp lệ', 'Invalid format'));
      }

      _isLoading = false;
      _errorMessage = null;
      rebuild();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      rebuild();
    }
  }

  FileSourceType _detectSourceType(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return FileSourceType.url;
    } else if (input.startsWith('data:') || _isBase64(input)) {
      return FileSourceType.base64;
    } else {
      return FileSourceType.path;
    }
  }

  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadFromBase64() async {
    try {
      // Remove data URI prefix if exists
      String base64String = text;
      if (base64String.contains(',')) {
        base64String = base64String.split(',')[1];
      }

      _fileBytes = base64Decode(base64String);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'temp_file_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(_fileBytes!);
      _localFilePath = file.path;
    } catch (e) {
      throw Exception(setText('Lỗi giải mã base64', 'Base64 decode error'));
    }
  }

  Future<void> _loadFromPath() async {
    final file = File(text);
    if (!await file.exists()) {
      throw Exception(setText('File không tồn tại', 'File does not exist'));
    }
    _localFilePath = text;
    _fileBytes = await file.readAsBytes();
  }

  Future<void> _loadFromUrl() async {
    try {
      final response = await http.get(Uri.parse(text));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      _fileBytes = response.bodyBytes;

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'temp_download_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(_fileBytes!);
      _localFilePath = file.path;
    } catch (e) {
      throw Exception(setText('Lỗi tải file', 'Download error: $e'));
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(setText('Đang tải...', 'Loading...')),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onLoadData(),
              child: Text(setText('Thử lại', 'Retry')),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (showToolbar) _buildToolbar(),
        Expanded(child: buildViewer()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Print
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: setText('In', 'Print'),
            onPressed: canPrint() ? _handlePrint : null,
          ),

          // Share
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: setText('Chia sẻ', 'Share'),
            onPressed: _handleShare,
          ),

          // Download
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: setText('Tải xuống', 'Download'),
            onPressed: _handleDownload,
          ),

          const Spacer(),

          // Additional toolbar buttons (override in child)
          ...buildAdditionalToolbarButtons(),
        ],
      ),
    );
  }

  // Override in child classes
  Widget buildViewer();

  List<Widget> buildAdditionalToolbarButtons() => [];

  bool canPrint() => false;

  Future<void> _handlePrint() async {
    try {
      await onPrint();
    } catch (e) {
      if (context.mounted) {
        setText(
          'Lỗi in: $e',
          'Print error: $e',
        ).V_MsgBox(context, type: CyberMsgBoxType.error);
      }
    }
  }

  Future<void> _handleShare() async {
    try {
      if (_localFilePath != null) {
        final params = ShareParams(
          text: title ?? setText('Chia sẻ file', 'Share file'),
          files: [XFile(_localFilePath!)],
        );

        await SharePlus.instance.share(params);

        // await Share.shareXFiles([
        //   XFile(_localFilePath!),
        // ], text: title ?? setText('Chia sẻ file', 'Share file'));
      }
    } catch (e) {
      if (context.mounted) {
        setText(
          'Lỗi chia sẻ: $e',
          'Share error: $e',
        ).V_MsgBox(context, type: CyberMsgBoxType.error);
      }
    }
  }

  Future<void> _handleDownload() async {
    try {
      if (_fileBytes == null) return;

      final downloadsDir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final fileName =
          'download_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final savePath = '${downloadsDir.path}/$fileName';
      final file = File(savePath);
      await file.writeAsBytes(_fileBytes!);

      if (context.mounted) {
        setText(
          'Đã lưu: $savePath',
          'Saved: $savePath',
        ).V_MsgBox(context, type: CyberMsgBoxType.defaultType);
      }
    } catch (e) {
      if (context.mounted) {
        setText(
          'Lỗi tải xuống: $e',
          'Download error: $e',
        ).V_MsgBox(context, type: CyberMsgBoxType.error);
      }
    }
  }

  // Override in child classes if printable
  Future<void> onPrint() async {}

  // Getters
  Uint8List? get fileBytes => _fileBytes;
  String? get localFilePath => _localFilePath;
  FileSourceType? get sourceType => _sourceType;
}

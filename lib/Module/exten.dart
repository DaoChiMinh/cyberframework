// lib/Module/exten.dart

import 'package:crypto/crypto.dart';
import 'package:cyberframework/cyberframework.dart';

/// Parse icon from code point string
IconData? v_parseIcon(String codePointStr) {
  try {
    codePointStr = codePointStr.trim();

    if (codePointStr.isEmpty) return null;

    int codePoint;

    if (codePointStr.toLowerCase().startsWith('0x')) {
      codePoint = int.parse(codePointStr.substring(2), radix: 16);
    } else if (RegExp(r'^[a-fA-F0-9]+$').hasMatch(codePointStr)) {
      codePoint = int.parse(codePointStr, radix: 16);
    } else {
      codePoint = int.parse(codePointStr);
    }

    return IconData(codePoint, fontFamily: 'MaterialIconsOutlined');
  } catch (e) {
    return null;
  }
}

/// ✅ IMPROVED: Compress and encode data
String V_MaHoa(String data) {
  try {
    if (data.isEmpty) return '';

    final inputBytes = utf8.encode(data);
    final compressedBytes = ZLibEncoder(raw: true).convert(inputBytes);
    final base64Encoded = base64.encode(compressedBytes);

    return base64Encoded;
  } catch (e) {
    debugPrint('❌ V_MaHoa error: $e');
    return '';
  }
}

/// ✅ IMPROVED: Decode and decompress data
// ignore: non_constant_identifier_names
String V_GiaiMa(String encryptedData) {
  try {
    if (encryptedData.isEmpty) return '';

    final normalized = _normalizeBase64(encryptedData);
    final compressedBytes = base64.decode(normalized);
    final decompressedBytes = ZLibDecoder(raw: true).convert(compressedBytes);

    return utf8.decode(decompressedBytes);
  } catch (e) {
    debugPrint('❌ V_GiaiMa error: $e');
    return encryptedData;
  }
}

/// ✅ Normalize base64 string
String _normalizeBase64(String input) {
  input = input.replaceAll(RegExp(r'\s+'), '');
  final mod = input.length % 4;
  if (mod > 0) {
    input += '=' * (4 - mod);
  }
  return input;
}

/// ✅ Parse API response
ReturnData parseResponse(String responseStr) {
  try {
    if (responseStr.isEmpty) {
      return ReturnData(
        status: false,
        message: 'Empty response',
        isConnect: true,
      );
    }

    final decrypted = V_GiaiMa(responseStr);
    final json = jsonDecode(decrypted) as Map<String, dynamic>;

    return ReturnData.fromJson(json);
  } catch (e) {
    debugPrint('❌ Parse response error: $e');
    return ReturnData(
      status: false,
      message: 'Parse error: $e',
      isConnect: true,
    );
  }
}

/// ✅ IMPROVED: MD5 hash with null safety
// ignore: non_constant_identifier_names
String MD5(String? input) {
  if (input == null || input.isEmpty) return '';

  try {
    return md5.convert(utf8.encode(input)).toString();
  } catch (e) {
    debugPrint('❌ MD5 error: $e');
    return '';
  }
}

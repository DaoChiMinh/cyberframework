import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cyberframework/Module/CallData/ReturnData.dart';
import 'package:flutter/material.dart';

IconData? v_parseIcon(String codePointStr) {
  try {
    codePointStr = codePointStr.trim();

    int codePoint;

    // Format: 0xe047 hoặc 0xE047
    if (codePointStr.toLowerCase().startsWith('0x')) {
      codePoint = int.parse(codePointStr.substring(2), radix: 16);
    }
    // Format: e047 (hex không prefix)
    else if (RegExp(r'^[a-fA-F0-9]+$').hasMatch(codePointStr)) {
      codePoint = int.parse(codePointStr, radix: 16);
    }
    // Format: 57415 (decimal)
    else {
      codePoint = int.parse(codePointStr);
    }

    return IconData(codePoint, fontFamily: 'MaterialIcons');
  } catch (e) {
    debugPrint('Error parsing icon code point "$codePointStr": $e');
    return null;
  }
}

String V_MaHoa(String data) {
  try {
    List<int> inputBytes = utf8.encode(data);
    List<int> compressedBytes = ZLibEncoder(raw: true).convert(inputBytes);
    String base64Encoded = base64.encode(compressedBytes);

    base64Encoded = base64Encoded;
    return base64Encoded;
  } catch (e) {
    return '';
  }
}

String V_GiaiMa(String encryptedData) {
  try {
    String normalized = _normalizeBase64(encryptedData);
    Uint8List compressedBytes = base64.decode(normalized);
    List<int> decompressedBytes = ZLibDecoder(
      raw: true,
    ).convert(compressedBytes);
    return utf8.decode(decompressedBytes);
  } catch (e) {
    debugPrint('Decrypt error: $e');
    return encryptedData;
  }
}

String _normalizeBase64(String input) {
  input = input.replaceAll(RegExp(r'\s+'), '');
  int mod = input.length % 4;
  if (mod > 0) {
    input += '=' * (4 - mod);
  }
  return input;
}

ReturnData parseResponse(String responseStr) {
  try {
    final decrypted = V_GiaiMa(responseStr);
    final json = jsonDecode(decrypted) as Map<String, dynamic>;

    return ReturnData.fromJson(json);
  } catch (e) {
    debugPrint('Parse response error: $e');
    return ReturnData(
      status: false,
      message: 'Lỗi parse response: $e',
      isConnect: true,
    );
  }
}

String MD5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

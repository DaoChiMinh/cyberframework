// lib/Module/exten.dart

import 'package:crypto/crypto.dart';
import 'package:cyberframework/cyberframework.dart';

// Color parseColor({Color defaultColor = Colors.white}) {
//     if (isEmpty) return defaultColor;

//     try {
//       String hex = replaceAll('#', '');
//       if (hex.length == 6) {
//         hex = 'FF$hex';
//       }
//       return Color(int.parse(hex, radix: 16));
//     } catch (e) {
//       return defaultColor;
//     }
//   }
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

// ============================================================================
// ✅ EXTENSION METHODS - ToString with Format
// ============================================================================

/// Extension for Object? - Universal toString2
extension ObjectFormatExtension on Object? {
  String toString2(String format) {
    try {
      final value = this;

      if (value == null) return '';

      if (value is DateTime) {
        return _formatDateTime(value, format);
      }

      if (value is num) {
        return _formatNumber(value, format);
      }

      if (value is String) {
        if (format.isEmpty) return value;

        final numValue = num.tryParse(value);
        if (numValue != null) {
          return _formatNumber(numValue, format);
        }

        final dateValue = DateTime.tryParse(value);
        if (dateValue != null) {
          return _formatDateTime(dateValue, format);
        }

        return value;
      }

      return value.toString();
    } catch (e) {
      debugPrint('❌ Object format error: $e');
      return this?.toString() ?? '';
    }
  }
}

/// Extension for int
extension IntFormatExtension on int {
  String toString2(String format) {
    return _formatNumber(this, format);
  }
}

/// Extension for double
extension DoubleFormatExtension on double {
  String toString2(String format) {
    return _formatNumber(this, format);
  }
}

/// Extension for DateTime
extension DateTimeFormatExtension on DateTime {
  String toString2(String format) {
    return _formatDateTime(this, format);
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

String _formatNumber(num value, String format) {
  try {
    if (format.isEmpty) return value.toString();

    final formatUpper = format.toUpperCase();
    final formatType = formatUpper[0];
    final precision = format.length > 1
        ? int.tryParse(format.substring(1))
        : null;

    switch (formatType) {
      case 'N':
        return _formatNumberWithSeparator(value, precision ?? 2, ',', '.');

      case 'C':
        final formatted = _formatNumberWithSeparator(
          value,
          precision ?? 0,
          ',',
          '.',
        );
        return '₫$formatted';

      case 'P':
        final percentValue = value * 100;
        final formatted = _formatNumberWithSeparator(
          percentValue,
          precision ?? 2,
          ',',
          '.',
          grouping: false,
        );
        return '$formatted%';

      case 'F':
        return value.toStringAsFixed(precision ?? 2);

      case 'D':
        if (value is! int) return value.toString();
        final width = precision ?? 0;
        return value.toString().padLeft(width, '0');

      case 'E':
        return value.toStringAsExponential(precision ?? 6).toUpperCase();

      case 'X':
        if (value is! int) return value.toString();
        final hex = value.toRadixString(16).toUpperCase();
        final width = precision ?? 0;
        return hex.padLeft(width, '0');

      case '#':
        return _formatCustomPattern(value, format);

      default:
        return value.toString();
    }
  } catch (e) {
    debugPrint('❌ Number format error: $e');
    return value.toString();
  }
}

String _formatDateTime(DateTime date, String format) {
  try {
    if (format.isEmpty) return date.toString();

    switch (format) {
      case 'd':
        return _formatDatePattern(date, 'dd/MM/yyyy');
      case 't':
        return _formatDatePattern(date, 'HH:mm');
      case 'T':
        return _formatDatePattern(date, 'HH:mm:ss');
      case 'g':
        return _formatDatePattern(date, 'dd/MM/yyyy HH:mm');
      case 'G':
        return _formatDatePattern(date, 'dd/MM/yyyy HH:mm:ss');
      case 's':
        return _formatDatePattern(date, "yyyy-MM-dd'T'HH:mm:ss");
      case 'u':
        return _formatDatePattern(date.toUtc(), "yyyy-MM-dd HH:mm:ss'Z'");
      default:
        return _formatDatePattern(date, format);
    }
  } catch (e) {
    debugPrint('❌ DateTime format error: $e');
    return date.toString();
  }
}

String _formatNumberWithSeparator(
  num value,
  int decimals,
  String groupSeparator,
  String decimalSeparator, {
  bool grouping = true,
}) {
  final fixed = value.toStringAsFixed(decimals);
  final parts = fixed.split('.');

  if (grouping && parts[0].length > 3) {
    final intPart = parts[0];
    final buffer = StringBuffer();
    final length = intPart.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(groupSeparator);
      }
      buffer.write(intPart[i]);
    }

    parts[0] = buffer.toString();
  }

  return parts.join(decimalSeparator);
}

String _formatCustomPattern(num value, String pattern) {
  try {
    String groupSeparator = ',';
    if (pattern.contains(' ')) {
      groupSeparator = ' ';
    } else if (pattern.contains(',')) {
      groupSeparator = ',';
    }

    final parts = pattern.split('.');
    final intPattern = parts[0];
    final decPattern = parts.length > 1 ? parts[1] : '';

    int decimals = 0;
    if (decPattern.isNotEmpty) {
      decimals = decPattern.replaceAll(RegExp(r'[^0#]'), '').length;
    }

    final hasGrouping = intPattern.contains(groupSeparator);

    final fixed = value.toStringAsFixed(decimals);
    final numParts = fixed.split('.');

    if (hasGrouping && numParts[0].isNotEmpty) {
      final intPart = numParts[0];
      final buffer = StringBuffer();
      final length = intPart.length;

      for (int i = 0; i < length; i++) {
        if (i > 0 && (length - i) % 3 == 0) {
          buffer.write(groupSeparator);
        }
        buffer.write(intPart[i]);
      }

      numParts[0] = buffer.toString();
    }

    return numParts.join('.');
  } catch (e) {
    debugPrint('❌ Custom pattern error: $e');
    return value.toString();
  }
}

String _formatDatePattern(DateTime date, String pattern) {
  String result = pattern;

  result = result.replaceAll('yyyy', date.year.toString());
  result = result.replaceAll(
    'yy',
    (date.year % 100).toString().padLeft(2, '0'),
  );
  result = result.replaceAll('MM', date.month.toString().padLeft(2, '0'));
  result = result.replaceAll('M', date.month.toString());
  result = result.replaceAll('dd', date.day.toString().padLeft(2, '0'));
  result = result.replaceAll('d', date.day.toString());
  result = result.replaceAll('HH', date.hour.toString().padLeft(2, '0'));
  result = result.replaceAll('H', date.hour.toString());

  final hour12 = date.hour > 12
      ? date.hour - 12
      : (date.hour == 0 ? 12 : date.hour);
  result = result.replaceAll('hh', hour12.toString().padLeft(2, '0'));
  result = result.replaceAll('h', hour12.toString());

  result = result.replaceAll('mm', date.minute.toString().padLeft(2, '0'));
  result = result.replaceAll('m', date.minute.toString());
  result = result.replaceAll('ss', date.second.toString().padLeft(2, '0'));
  result = result.replaceAll('s', date.second.toString());
  result = result.replaceAll(
    'fff',
    date.millisecond.toString().padLeft(3, '0'),
  );
  result = result.replaceAll(
    'ff',
    (date.millisecond ~/ 10).toString().padLeft(2, '0'),
  );
  result = result.replaceAll('f', (date.millisecond ~/ 100).toString());
  result = result.replaceAll('tt', date.hour >= 12 ? 'PM' : 'AM');
  result = result.replaceAll('t', date.hour >= 12 ? 'P' : 'A');
  result = result.replaceAll("'", '');

  return result;
}

String ToXml(
  List<CyberDataTable> tables,
  List<String> tableNames, {
  Map<String, List<String>>? tableIncludeColumns,
  Map<String, List<String>>? tableExcludeColumns,
}) {
  // Validate input
  if (tables.isEmpty) {
    return '';
  }

  if (tables.length != tableNames.length) {
    throw ArgumentError(
      'Tables and tableNames must have the same length. '
      'Got ${tables.length} tables and ${tableNames.length} names.',
    );
  }

  final StringBuffer xml = StringBuffer();

  // Process each table
  for (int i = 0; i < tables.length; i++) {
    final table = tables[i];
    final tableName = tableNames[i];

    // Get include/exclude columns for this table
    List<String>? includeColumns = tableIncludeColumns?[tableName];
    List<String>? excludeColumns = tableExcludeColumns?[tableName];

    // Generate XML for this table with custom name
    xml.write(
      table.toXml(
        tableNameOverride: tableName,
        includeColumns: includeColumns,
        excludeColumns: excludeColumns,
      ),
    );
  }

  return xml.toString();
}

/// ✅ ALIAS: Shorter name for convenience
String tablesToXml(
  List<CyberDataTable> tables,
  List<String> tableNames, {
  Map<String, List<String>>? tableIncludeColumns,
  Map<String, List<String>>? tableExcludeColumns,
}) {
  return ToXml(
    tables,
    tableNames,
    tableIncludeColumns: tableIncludeColumns,
    tableExcludeColumns: tableExcludeColumns,
  );
}

/// ✅ EXTENSION: Alternative syntax using extension method
extension CyberDataTableListExtension on List<CyberDataTable> {
  /// Convert list of tables to XML with custom names
  ///
  /// Usage:
  /// ```dart
  /// String xml = [tb1, tb2].toXml(["TB1", "TB2"]);
  /// ```
  String toXml(
    List<String> tableNames, {
    Map<String, List<String>>? tableIncludeColumns,
    Map<String, List<String>>? tableExcludeColumns,
  }) {
    return ToXml(
      this,
      tableNames,
      tableIncludeColumns: tableIncludeColumns,
      tableExcludeColumns: tableExcludeColumns,
    );
  }
}

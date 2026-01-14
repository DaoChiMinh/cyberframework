import 'package:flutter/foundation.dart';

/// Kiểu dữ liệu trong template
enum TemplateFieldType {
  string, // C - String
  number, // N - double
  boolean, // B - bool
  date, // D - DateTime
}

/// Field definition trong template
class TemplateField {
  final String key;
  final TemplateFieldType type;
  final String? pattern; // Optional regex pattern
  final bool required;

  const TemplateField({
    required this.key,
    required this.type,
    this.pattern,
    this.required = true,
  });

  /// Parse type từ string (C, N, B, D)
  static TemplateFieldType parseType(String typeStr) {
    switch (typeStr.toUpperCase()) {
      case 'C':
        return TemplateFieldType.string;
      case 'N':
        return TemplateFieldType.number;
      case 'B':
        return TemplateFieldType.boolean;
      case 'D':
        return TemplateFieldType.date;
      default:
        throw ArgumentError('Unknown type: $typeStr');
    }
  }

  /// Convert value to proper type
  dynamic convertValue(String value) {
    final trimmed = value.trim();

    switch (type) {
      case TemplateFieldType.string:
        return trimmed;

      case TemplateFieldType.number:
        // Remove common separators
        final cleaned = trimmed.replaceAll(',', '').replaceAll('.', '');
        return double.tryParse(cleaned) ?? double.tryParse(trimmed);

      case TemplateFieldType.boolean:
        final lower = trimmed.toLowerCase();
        if (lower == 'true' ||
            lower == 'yes' ||
            lower == '1' ||
            lower == 'có' ||
            lower == 'x') {
          return true;
        }
        if (lower == 'false' ||
            lower == 'no' ||
            lower == '0' ||
            lower == 'không' ||
            lower == '') {
          return false;
        }
        return null;

      case TemplateFieldType.date:
        return _parseDate(trimmed);
    }
  }

  /// Parse date với nhiều formats
  DateTime? _parseDate(String value) {
    // Common date formats
    final formats = [
      RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$'), // DD/MM/YYYY
      RegExp(r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$'), // YYYY-MM-DD
      RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2})$'), // DD/MM/YY
    ];

    for (var format in formats) {
      final match = format.firstMatch(value);
      if (match != null) {
        try {
          int year, month, day;

          if (format == formats[0]) {
            // DD/MM/YYYY
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
          } else if (format == formats[1]) {
            // YYYY-MM-DD
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            // DD/MM/YY
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            final yy = int.parse(match.group(3)!);
            year = yy < 50 ? 2000 + yy : 1900 + yy;
          }

          return DateTime(year, month, day);
        } catch (e) {
          debugPrint('Error parsing date: $e');
        }
      }
    }

    return null;
  }

  @override
  String toString() => 'TemplateField(key: $key, type: $type)';
}

/// Text Template definition
class TextTemplate {
  final String name;
  final String rawTemplate;
  final List<TemplateField> fields;
  final List<String> templateLines;

  TextTemplate({
    required this.name,
    required this.rawTemplate,
    required this.fields,
    required this.templateLines,
  });

  /// Parse template string và extract fields
  factory TextTemplate.fromString(String name, String template) {
    final fields = <TemplateField>[];
    final lines = template.split('\n');

    // Pattern: [<KEY,TYPE>] hoặc [<KEY,TYPE,PATTERN>]
    final fieldPattern = RegExp(r'\[<([^,>]+),([CNBD])(?:,([^>]+))?>]');

    for (var line in lines) {
      final matches = fieldPattern.allMatches(line);
      for (var match in matches) {
        final key = match.group(1)!.trim();
        final typeStr = match.group(2)!;
        final pattern = match.group(3); // Optional

        fields.add(
          TemplateField(
            key: key,
            type: TemplateField.parseType(typeStr),
            pattern: pattern,
          ),
        );
      }
    }

    return TextTemplate(
      name: name,
      rawTemplate: template,
      fields: fields,
      templateLines: lines,
    );
  }

  /// Get field by key
  TemplateField? getField(String key) {
    return fields.where((f) => f.key == key).firstOrNull;
  }

  @override
  String toString() {
    return 'TextTemplate($name, ${fields.length} fields)';
  }
}

/// Parser để extract data từ text theo template
class TextTemplateParser {
  final TextTemplate template;
  final double fuzzyThreshold; // 0.0 - 1.0

  TextTemplateParser(this.template, {this.fuzzyThreshold = 0.7});

  /// Parse recognized text theo template
  Map<String, dynamic> parse(String recognizedText) {
    final result = <String, dynamic>{};
    final textLines = recognizedText.split('\n').map((l) => l.trim()).toList();

    // Group fields by template line
    final fieldsByLine = _groupFieldsByTemplateLine();

    // Parse each template line
    for (var entry in fieldsByLine.entries) {
      final templateLine = entry.key;
      final fields = entry.value;

      // Find matching text line
      final matchedTextLine = _findMatchingTextLine(
        textLines,
        recognizedText,
        templateLine,
        fields,
      );

      if (matchedTextLine != null) {
        // Extract all fields from this line
        _extractFieldsFromLine(matchedTextLine, templateLine, fields, result);
      }
    }

    return result;
  }

  /// Group fields by their template line
  Map<String, List<TemplateField>> _groupFieldsByTemplateLine() {
    final fieldsByLine = <String, List<TemplateField>>{};

    for (var templateLine in template.templateLines) {
      if (templateLine.trim().isEmpty) continue;

      final fieldsInLine = <TemplateField>[];

      for (var field in template.fields) {
        if (templateLine.contains('[<${field.key},')) {
          fieldsInLine.add(field);
        }
      }

      if (fieldsInLine.isNotEmpty) {
        fieldsByLine[templateLine] = fieldsInLine;
      }
    }

    return fieldsByLine;
  }

  /// Find matching text line for template line
  String? _findMatchingTextLine(
    List<String> textLines,
    String fullText,
    String templateLine,
    List<TemplateField> fields,
  ) {
    // Extract labels from template
    final labels = _extractLabelsFromTemplate(templateLine, fields);

    if (labels.isEmpty) return null;

    // Try to find in text lines
    for (var textLine in textLines) {
      if (_lineMatchesLabels(textLine, labels)) {
        return textLine;
      }
    }

    // Try in full text (split by various delimiters)
    final allLines = fullText.split(RegExp(r'\n|\.|\|'));
    for (var line in allLines) {
      if (_lineMatchesLabels(line.trim(), labels)) {
        return line.trim();
      }
    }

    return null;
  }

  /// Extract labels from template line
  List<String> _extractLabelsFromTemplate(
    String templateLine,
    List<TemplateField> fields,
  ) {
    final labels = <String>[];
    var workingLine = templateLine;

    // Sort fields by position in template line
    final sortedFields = List<TemplateField>.from(fields);
    sortedFields.sort((a, b) {
      final aIndex = templateLine.indexOf('[<${a.key},');
      final bIndex = templateLine.indexOf('[<${b.key},');
      return aIndex.compareTo(bIndex);
    });

    for (var field in sortedFields) {
      final fieldPattern = '[<${field.key},';
      final index = workingLine.indexOf(fieldPattern);

      if (index > 0) {
        // Text before field is the label
        var label = workingLine.substring(0, index).trim();

        // Remove previous field placeholders
        label = label.replaceAll(RegExp(r'\[<[^>]+>\]'), '').trim();

        if (label.isNotEmpty) {
          labels.add(label);
        }

        workingLine = workingLine.substring(index);
      }
    }

    return labels;
  }

  /// Check if text line matches labels
  bool _lineMatchesLabels(String textLine, List<String> labels) {
    if (labels.isEmpty) return false;

    int matchCount = 0;
    for (var label in labels) {
      if (_fuzzyMatch(textLine, label)) {
        matchCount++;
      }
    }

    // Need at least 60% of labels to match
    return matchCount >= (labels.length * 0.6);
  }

  /// Extract all fields from a text line using template line as pattern
  void _extractFieldsFromLine(
    String textLine,
    String templateLine,
    List<TemplateField> fields,
    Map<String, dynamic> result,
  ) {
    // Build regex pattern from template line
    var pattern = _buildRegexPattern(templateLine, fields);

    if (pattern == null) {
      // Fallback to individual extraction
      _extractFieldsIndividually(textLine, templateLine, fields, result);
      return;
    }

    // Try to match with regex
    final regex = RegExp(pattern, caseSensitive: false);
    final normalizedText = _normalize(textLine);
    final match = regex.firstMatch(normalizedText);

    if (match != null && match.groupCount >= fields.length) {
      // Extract matched groups
      for (int i = 0; i < fields.length; i++) {
        final field = fields[i];
        final value = match.group(i + 1);

        if (value != null && value.isNotEmpty) {
          final converted = _processFieldValue(field, value);
          if (converted != null) {
            result[field.key] = converted;
          }
        }
      }
    } else {
      // Fallback to individual extraction
      _extractFieldsIndividually(textLine, templateLine, fields, result);
    }
  }

  /// Build regex pattern from template line
  String? _buildRegexPattern(String templateLine, List<TemplateField> fields) {
    try {
      var pattern = templateLine;

      // Sort fields by position
      final sortedFields = List<TemplateField>.from(fields);
      sortedFields.sort((a, b) {
        final aIndex = pattern.indexOf('[<${a.key},');
        final bIndex = pattern.indexOf('[<${b.key},');
        return aIndex.compareTo(bIndex);
      });

      // Replace each field with capture group
      for (var field in sortedFields) {
        final placeholder = RegExp(
          r'\[<' + RegExp.escape(field.key) + r',[^\]]+\]',
        );

        // Capture group based on field type
        String capturePattern;
        if (field.pattern != null) {
          // Use custom pattern if provided
          capturePattern = '(${field.pattern})';
        } else {
          // Default patterns based on type
          switch (field.type) {
            case TemplateFieldType.number:
              capturePattern = r'([0-9.,\s]+)';
              break;
            case TemplateFieldType.date:
              capturePattern = r'([\d/\-\s]+)';
              break;
            case TemplateFieldType.boolean:
              capturePattern = r'(\w+)';
              break;
            default:
              capturePattern = r'(.+?)';
          }
        }

        pattern = pattern.replaceFirst(placeholder, capturePattern);
      }

      // Escape special regex characters in labels
      pattern = pattern.replaceAllMapped(
        RegExp(r'[.+*?^$()[\]{}|\\]'),
        (match) => '\\${match.group(0)}',
      );

      // Make whitespace flexible
      pattern = pattern.replaceAll(RegExp(r'\s+'), r'\\s*');

      // Normalize for matching
      pattern = _normalize(pattern);

      return pattern;
    } catch (e) {
      debugPrint('Error building regex pattern: $e');
      return null;
    }
  }

  /// Extract fields individually (fallback method)
  void _extractFieldsIndividually(
    String textLine,
    String templateLine,
    List<TemplateField> fields,
    Map<String, dynamic> result,
  ) {
    // Sort fields by position in template
    final sortedFields = List<TemplateField>.from(fields);
    sortedFields.sort((a, b) {
      final aIndex = templateLine.indexOf('[<${a.key},');
      final bIndex = templateLine.indexOf('[<${b.key},');
      return aIndex.compareTo(bIndex);
    });

    for (int i = 0; i < sortedFields.length; i++) {
      final field = sortedFields[i];

      // Get label for this field
      final label = _getLabelForField(templateLine, field);
      if (label.isEmpty) continue;

      // Find label in text
      final labelIndex = _findLabelIndex(textLine, label);
      if (labelIndex == -1) continue;

      // Extract value after label
      var valueStart = labelIndex + label.length;

      // Skip separators (:, space)
      while (valueStart < textLine.length &&
          (textLine[valueStart] == ':' ||
              textLine[valueStart] == ' ' ||
              textLine[valueStart] == '：')) {
        valueStart++;
      }

      if (valueStart >= textLine.length) continue;

      // Find value end
      int valueEnd = textLine.length;

      // If not last field, find next field's label
      if (i < sortedFields.length - 1) {
        final nextField = sortedFields[i + 1];
        final nextLabel = _getLabelForField(templateLine, nextField);

        if (nextLabel.isNotEmpty) {
          final nextLabelIndex = _findLabelIndex(
            textLine.substring(valueStart),
            nextLabel,
          );

          if (nextLabelIndex != -1) {
            valueEnd = valueStart + nextLabelIndex;
          }
        }
      }

      final valueStr = textLine.substring(valueStart, valueEnd).trim();

      if (valueStr.isNotEmpty) {
        final converted = _processFieldValue(field, valueStr);
        if (converted != null) {
          result[field.key] = converted;
        }
      }
    }
  }

  /// Get label for a field from template line
  String _getLabelForField(String templateLine, TemplateField field) {
    final fieldPattern = '[<${field.key},';
    final index = templateLine.indexOf(fieldPattern);

    if (index <= 0) return '';

    var label = templateLine.substring(0, index).trim();

    // Remove previous field placeholders
    label = label.replaceAll(RegExp(r'\[<[^>]+>\]'), '').trim();

    return label;
  }

  /// Find label index in text (fuzzy)
  int _findLabelIndex(String text, String label) {
    final normalizedText = _normalize(text);
    final normalizedLabel = _normalize(label);

    // Try exact match first
    int index = normalizedText.indexOf(normalizedLabel);
    if (index != -1) return index;

    // Try fuzzy match
    final words = normalizedLabel.split(RegExp(r'\s+'));

    for (int i = 0; i < normalizedText.length; i++) {
      final substring = normalizedText.substring(i);
      int matchCount = 0;
      int lastMatchPos = 0;

      for (var word in words) {
        final wordIndex = substring.indexOf(word, lastMatchPos);
        if (wordIndex != -1) {
          matchCount++;
          lastMatchPos = wordIndex + word.length;
        }
      }

      if (matchCount >= words.length * 0.7) {
        return i;
      }
    }

    return -1;
  }

  /// Process field value (apply pattern and convert type)
  dynamic _processFieldValue(TemplateField field, String value) {
    var processedValue = value.trim();

    // Apply pattern if exists
    if (field.pattern != null) {
      final pattern = RegExp(field.pattern!);
      final match = pattern.firstMatch(processedValue);
      if (match != null) {
        processedValue = match.group(0) ?? processedValue;
      }
    }

    // Convert to proper type
    return field.convertValue(processedValue);
  }

  /// Fuzzy match giữa 2 strings
  bool _fuzzyMatch(String text, String pattern) {
    final textNorm = _normalize(text);
    final patternNorm = _normalize(pattern);

    // Exact match
    if (textNorm.contains(patternNorm)) return true;

    // Levenshtein distance
    final similarity = _calculateSimilarity(textNorm, patternNorm);
    return similarity >= fuzzyThreshold;
  }

  /// Calculate similarity (0.0 - 1.0)
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLength);
  }

  /// Levenshtein distance
  int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;

        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Normalize text (lowercase, remove accents, trim)
  String _normalize(String text) {
    var result = text.toLowerCase().trim();

    // Remove Vietnamese accents (optional)
    const accents = {
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'đ': 'd',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
    };

    for (var entry in accents.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }

  /// Validate parsed result
  bool validate(Map<String, dynamic> result) {
    for (var field in template.fields) {
      if (field.required && !result.containsKey(field.key)) {
        debugPrint('Missing required field: ${field.key}');
        return false;
      }

      if (result.containsKey(field.key)) {
        final value = result[field.key];
        if (value == null) {
          debugPrint('Null value for field: ${field.key}');
          return false;
        }

        // Type validation
        switch (field.type) {
          case TemplateFieldType.string:
            if (value is! String) return false;
            break;
          case TemplateFieldType.number:
            if (value is! double && value is! int) return false;
            break;
          case TemplateFieldType.boolean:
            if (value is! bool) return false;
            break;
          case TemplateFieldType.date:
            if (value is! DateTime) return false;
            break;
        }
      }
    }

    return true;
  }

  /// Debug: Show matching details
  void debugParse(String recognizedText) {
    debugPrint('╔═══════════════════════════════════════╗');
    debugPrint('║ Template: ${template.name}');
    debugPrint('╠═══════════════════════════════════════╣');

    final result = parse(recognizedText);

    for (var field in template.fields) {
      final value = result[field.key];
      debugPrint('║ ${field.key} (${field.type}):');
      debugPrint('║   Value: $value');
      debugPrint('║   Type: ${value?.runtimeType}');
    }

    debugPrint('╠═══════════════════════════════════════╣');
    debugPrint('║ Valid: ${validate(result)}');
    debugPrint('╚═══════════════════════════════════════╝');
  }
}

/// Extension để dùng template với CyberCameraRecognitionText
extension RecognizedTextResultTemplateExtension on dynamic {
  /// Parse result với template
  Map<String, dynamic>? parseWithTemplate(TextTemplate template) {
    // Assuming this is RecognizedTextResult
    if (this == null) return null;

    try {
      final fullText = (this as dynamic).fullText as String;
      final parser = TextTemplateParser(template);
      return parser.parse(fullText);
    } catch (e) {
      debugPrint('Error parsing with template: $e');
      return null;
    }
  }
}

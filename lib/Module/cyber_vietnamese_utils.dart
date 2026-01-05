// lib/Module/Utilities/cyber_vietnamese_utils.dart

class CyberVietnameseUtils {
  static final CyberVietnameseUtils _instance =
      CyberVietnameseUtils._internal();
  factory CyberVietnameseUtils() => _instance;
  CyberVietnameseUtils._internal();

  // ============================================================================
  // BỎ DẤU TIẾNG VIỆT
  // ============================================================================

  /// Bỏ dấu tiếng Việt (giữ nguyên chữ hoa/thường)
  static String removeDiacritics(String text) {
    if (text.isEmpty) return text;

    String result = text;

    // Bỏ dấu các ký tự chữ thường
    for (var entry in _diacriticsMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Bỏ dấu các ký tự chữ HOA
    for (var entry in _diacriticsMapUpper.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }

  /// Bỏ dấu và chuyển thành chữ thường
  static String removeDiacriticsLowerCase(String text) {
    return removeDiacritics(text).toLowerCase();
  }

  /// Bỏ dấu và chuyển thành chữ HOA
  static String removeDiacriticsUpperCase(String text) {
    return removeDiacritics(text).toUpperCase();
  }

  // ============================================================================
  // SLUG (URL FRIENDLY)
  // ============================================================================

  /// Chuyển thành slug (url-friendly)
  /// VD: "Xin chào Việt Nam!" -> "xin-chao-viet-nam"
  static String toSlug(String text, {String separator = '-'}) {
    if (text.isEmpty) return text;

    String result = removeDiacriticsLowerCase(text);

    // Thay thế khoảng trắng và ký tự đặc biệt bằng separator
    result = result.replaceAll(RegExp(r'[^\w\s-]'), '');
    result = result.replaceAll(RegExp(r'[\s_]+'), separator);
    result = result.replaceAll(RegExp('$separator+'), separator);

    // Xóa separator ở đầu và cuối
    result = result.replaceAll(RegExp('^$separator+|$separator+\$'), '');

    return result;
  }

  // ============================================================================
  // SO SÁNH VÀ TÌM KIẾM
  // ============================================================================

  /// So sánh 2 chuỗi không phân biệt dấu và hoa thường
  static bool equalsIgnoreDiacritics(String text1, String text2) {
    return removeDiacriticsLowerCase(text1) == removeDiacriticsLowerCase(text2);
  }

  /// Kiểm tra text có chứa keyword không (không phân biệt dấu)
  static bool containsIgnoreDiacritics(String text, String keyword) {
    return removeDiacriticsLowerCase(
      text,
    ).contains(removeDiacriticsLowerCase(keyword));
  }

  /// Kiểm tra text có bắt đầu bằng keyword không (không phân biệt dấu)
  static bool startsWithIgnoreDiacritics(String text, String keyword) {
    return removeDiacriticsLowerCase(
      text,
    ).startsWith(removeDiacriticsLowerCase(keyword));
  }

  /// Kiểm tra text có kết thúc bằng keyword không (không phân biệt dấu)
  static bool endsWithIgnoreDiacritics(String text, String keyword) {
    return removeDiacriticsLowerCase(
      text,
    ).endsWith(removeDiacriticsLowerCase(keyword));
  }

  // ============================================================================
  // FILTER / SEARCH
  // ============================================================================

  /// Filter danh sách theo keyword (không phân biệt dấu)
  static List<T> filterList<T>(
    List<T> list,
    String keyword,
    String Function(T) getText,
  ) {
    if (keyword.isEmpty) return list;

    final normalizedKeyword = removeDiacriticsLowerCase(keyword);

    return list.where((item) {
      final text = getText(item);
      return removeDiacriticsLowerCase(text).contains(normalizedKeyword);
    }).toList();
  }

  /// Highlight text trong search result (trả về indices của từ khóa)
  static List<int> findKeywordIndices(String text, String keyword) {
    if (keyword.isEmpty) return [];

    final normalizedText = removeDiacriticsLowerCase(text);
    final normalizedKeyword = removeDiacriticsLowerCase(keyword);

    final indices = <int>[];
    int index = normalizedText.indexOf(normalizedKeyword);

    while (index != -1) {
      indices.add(index);
      index = normalizedText.indexOf(normalizedKeyword, index + 1);
    }

    return indices;
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Kiểm tra có phải tiếng Việt không (có dấu)
  static bool hasVietnameseDiacritics(String text) {
    return _diacriticsMap.keys.any((char) => text.contains(char)) ||
        _diacriticsMapUpper.keys.any((char) => text.contains(char));
  }

  /// Kiểm tra có phải tiếng Việt không dấu
  static bool isVietnameseWithoutDiacritics(String text) {
    // Chứa chữ cái nhưng không có dấu
    return text.contains(RegExp(r'[a-zA-Z]')) && !hasVietnameseDiacritics(text);
  }

  // ============================================================================
  // DIACRITICS MAP
  // ============================================================================

  static const Map<String, String> _diacriticsMap = {
    // a
    'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',

    // e
    'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',

    // i
    'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',

    // o
    'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',

    // u
    'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',

    // y
    'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',

    // d
    'đ': 'd',
  };

  static const Map<String, String> _diacriticsMapUpper = {
    // A
    'Á': 'A', 'À': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
    'Ă': 'A', 'Ắ': 'A', 'Ằ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
    'Â': 'A', 'Ấ': 'A', 'Ầ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A',

    // E
    'É': 'E', 'È': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
    'Ê': 'E', 'Ế': 'E', 'Ề': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',

    // I
    'Í': 'I', 'Ì': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',

    // O
    'Ó': 'O', 'Ò': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
    'Ô': 'O', 'Ố': 'O', 'Ồ': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O',
    'Ơ': 'O', 'Ớ': 'O', 'Ờ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',

    // U
    'Ú': 'U', 'Ù': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
    'Ư': 'U', 'Ứ': 'U', 'Ừ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',

    // Y
    'Ý': 'Y', 'Ỳ': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',

    // D
    'Đ': 'D',
  };
}

// ============================================================================
// EXTENSION METHODS
// ============================================================================

extension VietnameseStringExtension on String {
  /// Bỏ dấu tiếng Việt
  String get removeDiacritics => CyberVietnameseUtils.removeDiacritics(this);

  /// Bỏ dấu và chuyển thành chữ thường
  String get removeDiacriticsLower =>
      CyberVietnameseUtils.removeDiacriticsLowerCase(this);

  /// Bỏ dấu và chuyển thành chữ HOA
  String get removeDiacriticsUpper =>
      CyberVietnameseUtils.removeDiacriticsUpperCase(this);

  /// Chuyển thành slug
  String toSlug({String separator = '-'}) =>
      CyberVietnameseUtils.toSlug(this, separator: separator);

  /// So sánh không phân biệt dấu
  bool equalsIgnoreDiacritics(String other) =>
      CyberVietnameseUtils.equalsIgnoreDiacritics(this, other);

  /// Kiểm tra có chứa keyword không (không phân biệt dấu)
  bool containsIgnoreDiacritics(String keyword) =>
      CyberVietnameseUtils.containsIgnoreDiacritics(this, keyword);

  /// Kiểm tra có bắt đầu bằng keyword không (không phân biệt dấu)
  bool startsWithIgnoreDiacritics(String keyword) =>
      CyberVietnameseUtils.startsWithIgnoreDiacritics(this, keyword);

  /// Kiểm tra có kết thúc bằng keyword không (không phân biệt dấu)
  bool endsWithIgnoreDiacritics(String keyword) =>
      CyberVietnameseUtils.endsWithIgnoreDiacritics(this, keyword);

  /// Kiểm tra có dấu tiếng Việt không
  bool get hasVietnameseDiacritics =>
      CyberVietnameseUtils.hasVietnameseDiacritics(this);
}

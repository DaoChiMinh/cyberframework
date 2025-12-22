import 'package:cyberframework/cyberframework.dart';

/// Extension để CyberDataRow hỗ trợ method bind()
/// Dùng thay vì indexer để tạo binding expression rõ ràng
extension CyberDataRowBinding on CyberDataRow {
  /// Tạo binding expression cho field
  /// Usage: drEdit.bind('name') thay vì drEdit['name']
  CyberBindingExpression bind(String fieldName) {
    return CyberBindingExpression(this, fieldName);
  }

  /// Alias cho bind (ngắn gọn hơn)
  CyberBindingExpression $(String fieldName) {
    return CyberBindingExpression(this, fieldName);
  }
}

/// Helper function để tạo binding expression
/// Usage: bind(drEdit, 'name')
CyberBindingExpression bind(CyberDataRow row, String fieldName) {
  return CyberBindingExpression(row, fieldName);
}

/// Operator overload cho CyberDataRow (nếu Dart hỗ trợ)
/// KHÔNG THỂ DÙNG vì Dart không cho override [] trả về type khác
/// CHỈ GHI CHÚ Ý TƯỞNG

// ============================================================================
// WORKAROUND: Vì không thể override indexer, ta có 3 cách:
// ============================================================================

// CÁCH 1: Dùng method bind()
// CyberTextField(
//   text: drEdit.bind('name'),  // ← Rõ ràng
//   label: 'Họ tên',
// )

// CÁCH 2: Dùng helper function
// CyberTextField(
//   text: bind(drEdit, 'name'),
//   label: 'Họ tên',
// )

// CÁCH 3: Dùng shorthand $
// CyberTextField(
//   text: drEdit.$('name'),  // ← Ngắn gọn
//   label: 'Họ tên',
// )

/// Class hỗ trợ binding với syntax đơn giản
class $ {
  /// Tạo binding expression
  /// Usage: $Bind(drEdit, 'name')
  static CyberBindingExpression bind(CyberDataRow row, String fieldName) {
    return CyberBindingExpression(row, fieldName);
  }

  /// Alias ngắn
  /// Usage: $(drEdit, 'name')
  static CyberBindingExpression call(CyberDataRow row, String fieldName) {
    return CyberBindingExpression(row, fieldName);
  }
}

/// Global function để binding (alternative syntax)
CyberBindingExpression $bind(CyberDataRow row, String fieldName) {
  return CyberBindingExpression(row, fieldName);
}

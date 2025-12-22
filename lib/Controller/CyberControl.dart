import 'package:cyberframework/cyberframework.dart';

enum CyberControlType {
  label, //LB
  text, //C
  numeric, // N
  date, //D
  lookup, //L
  comboBox, // CB
  checkbox, //B
}

class CyberControl extends StatelessWidget {
  // ==================== COMMON PROPERTIES ====================
  final String type; // "T", "N", "D", "L", "C"
  final dynamic text;
  final String? label;
  final String? hint;
  final String? format;
  final IconData? icon;
  final bool enabled;
  final dynamic isVisable;

  final TextStyle? style;
  final InputDecoration? decoration;
  final bool isShowLabel;
  final Color? backgroundColor;
  final Color? focusColor;
  final Function(dynamic)? onLeaver;
  // ==================== TEXT PROPERTIES ====================
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool showFormatInField;
  final bool isPassword;

  // ==================== NUMERIC PROPERTIES ====================
  final dynamic min;
  final dynamic max;

  // ==================== LOOKUP PROPERTIES ====================
  final dynamic tbName;
  final dynamic strFilter;
  final dynamic displayBinding;
  // ==================== COMBOBOX PROPERTIES ====================
  final dynamic displayMember;
  final dynamic valueMember;
  final CyberDataTable? dataSource;

  const CyberControl({
    super.key,
    required this.type,
    // Common
    this.text,
    this.label,
    this.hint,
    this.format,
    this.icon,
    this.enabled = true,
    this.isVisable = true,
    this.style,
    this.decoration,
    this.isShowLabel = true,
    this.backgroundColor,
    this.focusColor,
    this.onLeaver,
    // Text
    this.keyboardType,
    this.inputFormatters,
    this.maxLines,
    this.maxLength,
    this.showFormatInField = false,
    this.isPassword = false,

    // Numeric // Date
    this.min,
    this.max,

    // Lookup
    this.tbName,
    this.strFilter,
    this.displayBinding,
    // ComboBox
    this.displayMember,
    this.valueMember,
    this.dataSource,
  });

  factory CyberControl.label({
    dynamic text,
    String? label,
    String? hint,

    dynamic isVisable = true,
    TextStyle? style,
    Function(dynamic)? onLeaver,
  }) {
    return CyberControl(
      type: "LB",
      text: text,
      label: label,
      hint: hint,
      style: style,
      isVisable: isVisable,
      onLeaver: onLeaver,
    );
  }

  factory CyberControl.text({
    dynamic text,
    String? label,
    String? hint,
    String? format,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLines,
    int? maxLength,
    bool enabled = true,
    bool isVisable = true,
    TextStyle? style,
    InputDecoration? decoration,
    ValueChanged<String>? onChanged,
    Function(dynamic)? onLeaver,
    bool showFormatInField = false,
    bool isPassword = false,
    bool isShowLabel = true,
    Color? backgroundColor,
    Color? focusColor,
  }) {
    return CyberControl(
      type: "C",
      text: text,
      label: label,
      hint: hint,
      format: format,
      icon: icon,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      isVisable: isVisable,
      style: style,
      decoration: decoration,
      onLeaver: onLeaver,
      showFormatInField: showFormatInField,
      isPassword: isPassword,
      isShowLabel: isShowLabel,
      backgroundColor: backgroundColor,
      focusColor: focusColor,
    );
  }

  factory CyberControl.numeric({
    dynamic text,
    String? label,
    String? hint,
    String? format,
    IconData? icon,
    bool enabled = true,
    dynamic isVisable = true,
    TextStyle? style,
    InputDecoration? decoration,
    Function(dynamic)? onLeaver,
    int decimalPlaces = 0,
    bool showThousandsSeparator = true,
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
    double? min,
    double? max,
    String? prefix,
    String? suffix,
    bool showFormatInField = false,
    bool isShowLabel = true,
    Color? backgroundColor,
    Color? focusColor,
  }) {
    return CyberControl(
      type: "N",
      text: text,
      label: label,
      hint: hint,
      format: format,
      icon: icon,
      enabled: enabled,
      isVisable: isVisable,
      style: style,
      decoration: decoration,

      onLeaver: onLeaver,
      min: min,
      max: max,
      showFormatInField: showFormatInField,
      isShowLabel: isShowLabel,
      backgroundColor: backgroundColor,
      focusColor: focusColor,
    );
  }

  factory CyberControl.date({
    dynamic text,
    String? label,
    String? hint,
    IconData? icon,
    bool enabled = true,
    dynamic isVisable = true,
    TextStyle? style,
    InputDecoration? decoration,
    ValueChanged<DateTime>? onChanged,
    Function(dynamic)? onLeaver,
    DateTime? minDate,
    DateTime? maxDate,
    String dateFormat = "dd/MM/yyyy",
    bool isShowLabel = true,
    Color? backgroundColor,
    Color? focusColor,
  }) {
    return CyberControl(
      type: "D",
      text: text,
      label: label,
      hint: hint,
      icon: icon,
      enabled: enabled,
      style: style,
      decoration: decoration,
      isVisable: isVisable,
      onLeaver: onLeaver,
      isShowLabel: isShowLabel,
      backgroundColor: backgroundColor,
      focusColor: focusColor,
    );
  }

  factory CyberControl.lookup({
    dynamic text,
    String? label,
    String? hint,
    IconData? icon,
    bool enabled = true,
    dynamic isVisable = true,
    TextStyle? style,
    InputDecoration? decoration,
    ValueChanged? onChanged,
    Function(dynamic)? onLeaver,
    required dynamic tbName,
    required dynamic strFilter,
    required dynamic displayField,
    required dynamic displayValue,
    required dynamic displayBinding,
    bool allowClear = true,
    bool multiSelect = false,
    bool isShowLabel = true,
    Color? backgroundColor,
    Color? focusColor,
  }) {
    return CyberControl(
      type: "L",
      text: text,
      label: label,
      hint: hint,
      icon: icon,
      enabled: enabled,
      isVisable: isVisable,
      style: style,
      decoration: decoration,
      onLeaver: onLeaver,
      tbName: tbName,

      strFilter: strFilter,
      displayMember: displayField,
      valueMember: displayValue,
      displayBinding: displayField,
      isShowLabel: isShowLabel,
      backgroundColor: backgroundColor,
      focusColor: focusColor,
    );
  }

  factory CyberControl.comboBox({
    dynamic text,
    String? label,
    String? hint,
    IconData? icon,
    bool enabled = true,
    dynamic isVisable = true,
    ValueChanged<dynamic>? onChanged,
    Function(dynamic)? onLeaver,
    required dynamic displayMember,
    required dynamic valueMember,
    required CyberDataTable? dataSource,
    TextStyle? labelStyle,
    TextStyle? textStyle,
    Color? iconColor,
    Color? backgroundColor,
    Color? borderColor,
    bool isShowLabel = true,
    Color? focusColor,
  }) {
    return CyberControl(
      type: "CB",
      text: text,
      label: label,
      hint: hint,
      icon: icon,
      enabled: enabled,
      isVisable: isVisable,
      onLeaver: onLeaver,
      displayMember: displayMember,
      valueMember: valueMember,
      dataSource: dataSource,

      backgroundColor: backgroundColor,

      isShowLabel: isShowLabel,
      focusColor: focusColor,
    );
  }
  factory CyberControl.checkbox({
    dynamic text,
    String? label,

    bool enabled = true,
    dynamic isVisable = true,

    Function(dynamic)? onLeaver,
  }) {
    return CyberControl(
      type: "B",
      text: text,
      label: label,

      enabled: enabled,
      isVisable: isVisable,
      onLeaver: onLeaver,
    );
  }
  CyberControlType _getControlType() {
    switch (type.toUpperCase()) {
      case 'C':
        return CyberControlType.text;
      case 'N':
        return CyberControlType.numeric;
      case 'D':
        return CyberControlType.date;
      case 'L':
        return CyberControlType.lookup;
      case 'CB':
        return CyberControlType.comboBox;
      case 'B':
        return CyberControlType.checkbox;
      default:
        return CyberControlType.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlType = _getControlType();

    switch (controlType) {
      case CyberControlType.text:
        return CyberText(
          text: text,
          label: label,
          hint: hint,
          format: format,
          icon: icon,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          isVisible: isVisable,
          style: style,
          decoration: decoration,
          onLeaver: onLeaver,
          showFormatInField: showFormatInField,
          isPassword: isPassword,
          isShowLabel: isShowLabel,
          backgroundColor: backgroundColor,
          focusColor: focusColor,
        );

      case CyberControlType.numeric:
        return CyberNumeric(
          text: text,
          label: label,
          hint: hint,
          format: format,
          icon: icon,
          enabled: enabled,
          isVisible: isVisable,
          style: style,
          decoration: decoration,
          onLeaver: onLeaver,
          min: min,
          max: max,
          isShowLabel: isShowLabel,
          backgroundColor: backgroundColor,
          focusColor: focusColor,
        );

      case CyberControlType.date:
        return CyberDate(
          text: text,
          label: label,
          hint: hint,
          icon: icon,
          enabled: enabled,
          isVisible: isVisable,
          style: style,
          decoration: decoration,
          onLeaver: onLeaver,
          minDate: min,
          maxDate: max,
          format: format ?? "dd/MM/yyyy",
          isShowLabel: isShowLabel,
          backgroundColor: backgroundColor,
          focusColor: focusColor,
        );

      case CyberControlType.lookup:
        return CyberLookup(
          text: text,
          display: displayBinding,
          label: label,
          hint: hint,
          icon: icon,
          enabled: enabled,
          isVisible: isVisable,
          onLeaver: onLeaver,
          tbName: tbName,
          strFilter: strFilter,
          displayField: displayMember,
          displayValue: valueMember,

          isShowLabel: isShowLabel,
          backgroundColor: backgroundColor,
        );

      case CyberControlType.comboBox:
        return CyberComboBox(
          text: text,
          displayMember: displayMember,
          valueMember: valueMember,
          dataSource: dataSource,
          label: label,
          hint: hint,

          icon: icon,
          enabled: enabled,
          isVisible: isVisable,
          onLeaver: onLeaver,

          backgroundColor: backgroundColor,

          isShowLabel: isShowLabel,
        );
      case CyberControlType.label:
        return CyberLabel(
          text: text,
          isVisible: isVisable,
          format: format,
          onLeaver: onLeaver,
        );
      case CyberControlType.checkbox:
        return CyberCheckbox(
          text: text,
          label: label,
          enabled: enabled,
          isVisible: isVisable,
          onLeaver: onLeaver,
        );
    }
  }
}

import 'package:flutter/material.dart';

class CyberButton extends StatelessWidget {
  final String label;
  final VoidCallback? onClick;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double paddingVertical;
  final double paddingHorizontal;
  final bool isReadOnly;

  const CyberButton({
    super.key,
    required this.label,
    this.onClick,
    this.backgroundColor = const Color(0xFF0F3D34),
    this.textColor = Colors.white,
    this.borderRadius = 30.0,
    this.paddingVertical = 12.0,
    this.paddingHorizontal = 10.0,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // chiếm toàn bộ chiều ngang
      child: ElevatedButton(
        onPressed: isReadOnly ? null : onClick,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: EdgeInsets.symmetric(
            vertical: paddingVertical,
            horizontal: paddingHorizontal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

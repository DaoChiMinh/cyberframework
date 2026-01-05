// ignore: file_names
import 'package:flutter/material.dart';

void showLoadingOverlay(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) => const PopScope(
      canPop: false, // Không cho back
      child: Center(child: LoadingOverlay()),
    ),
  );
}

class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        // ✅ Bỏ background color trắng
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Loading indicator màu trắng
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
        ],
      ),
    );
  }
}

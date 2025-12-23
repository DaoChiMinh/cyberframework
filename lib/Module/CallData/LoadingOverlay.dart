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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(height: 16),
            //const Text('Đang xử lý...', style: TextStyle(fontSize: 16)),
          ],
        ],
      ),
    );
  }
}

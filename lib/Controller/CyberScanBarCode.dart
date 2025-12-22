import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Cyberscanbarcode extends StatefulWidget {
  final Function(String)? onCapture;
  final double? height;
  final double? borderRadius;
  const Cyberscanbarcode({
    super.key,
    this.onCapture,
    this.height,
    this.borderRadius = 12.0,
  });

  @override
  State<StatefulWidget> createState() => _CyberCameraScreenState();
}

class _CyberCameraScreenState extends State<Cyberscanbarcode>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 350,
    formats: [BarcodeFormat.all],
    torchEnabled: true,
    autoZoom: true,
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        unawaited(controller.start());
      case AppLifecycleState.inactive:
        unawaited(controller.stop());
    }
  }

  @override
  void initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);
    unawaited(controller.start());
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    await controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.borderRadius!),
      ),
      child: ClipRRect(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MobileScanner(
              controller: controller,
              onDetect: (data) {
                // ignore: no_leading_underscores_for_local_identifiers
                var _barcode = data.barcodes.firstOrNull;
                if (_barcode != null) {
                  if (_barcode.rawValue != null) {
                    widget.onCapture?.call(_barcode.rawValue!);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

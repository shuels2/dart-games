import 'package:flutter/material.dart';

// Stub implementation for non-web platforms
class WebCameraWidget extends StatelessWidget {
  final Function(String imageDataUrl) onCapture;

  const WebCameraWidget({
    super.key,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Camera widget is only available on web platform'),
    );
  }
}

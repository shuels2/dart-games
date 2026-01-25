import 'package:flutter/material.dart';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:async';

class WebCameraWidget extends StatefulWidget {
  final Function(String imageDataUrl) onCapture;

  const WebCameraWidget({
    super.key,
    required this.onCapture,
  });

  @override
  State<WebCameraWidget> createState() => _WebCameraWidgetState();
}

class _WebCameraWidgetState extends State<WebCameraWidget> {
  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  final String _viewId = 'camera-view-${DateTime.now().millisecondsSinceEpoch}';
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Create video element
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      // Register the video element with the platform view registry
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _videoElement!,
      );

      // Request camera access
      final constraints = {
        'video': {
          'facingMode': 'user', // Front camera
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
        'audio': false,
      };

      _stream = await html.window.navigator.mediaDevices!
          .getUserMedia(constraints);

      _videoElement!.srcObject = _stream;

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to access camera: $e';
        _isInitialized = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_videoElement == null || !_isInitialized) return;

    try {
      // Create a canvas to capture the current video frame
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );

      final context = canvas.context2D;
      context.drawImage(_videoElement!, 0, 0);

      // Convert to data URL
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);

      // Stop the camera
      _stopCamera();

      // Return the captured image
      widget.onCapture(dataUrl);
    } catch (e) {
      setState(() {
        _error = 'Failed to capture photo: $e';
      });
    }
  }

  void _stopCamera() {
    if (_stream != null) {
      _stream!.getTracks().forEach((track) => track.stop());
      _stream = null;
    }
    _videoElement?.srcObject = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: HtmlElementView(viewType: _viewId),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _stopCamera();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _capturePhoto,
                icon: const Icon(Icons.camera),
                label: const Text('Capture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

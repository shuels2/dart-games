import 'package:flutter/foundation.dart';

class DartboardEmulatorController extends ChangeNotifier {
  bool _isVisible = true;
  bool _isAutoPlaying = false;

  bool get isVisible => _isVisible;
  bool get isAutoPlaying => _isAutoPlaying;

  void show() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
  }

  void toggle() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  void setAutoPlaying(bool value) {
    if (_isAutoPlaying != value) {
      _isAutoPlaying = value;
      notifyListeners();
    }
  }
}

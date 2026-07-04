import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Tracks whether the user is driving the app with touch or with a mouse.
///
/// The on-screen keyboard uses this to auto-show when the user is on a
/// touchscreen (e.g. the Windows all-in-one kiosk) and stay hidden when
/// a physical keyboard + mouse are in use.
///
/// The mode flips on the FIRST pointer event of a new kind and then
/// stays until another kind is seen — so a stray mouse jiggle doesn't
/// permanently mode-switch a mid-touch user.
enum InputMode { mouse, touch }

class InputModeService extends ChangeNotifier {
  static final InputModeService instance = InputModeService._();
  InputModeService._();

  InputMode _mode = InputMode.mouse;
  InputMode get mode => _mode;
  bool get isTouch => _mode == InputMode.touch;

  void observePointer(PointerEvent event) {
    final next = switch (event.kind) {
      PointerDeviceKind.touch => InputMode.touch,
      PointerDeviceKind.stylus => InputMode.touch,
      PointerDeviceKind.mouse => InputMode.mouse,
      _ => _mode,
    };
    if (next != _mode) {
      _mode = next;
      notifyListeners();
    }
  }

  /// Test-only hook so the shared singleton can be returned to a known
  /// baseline between tests. Production code never calls this.
  @visibleForTesting
  void resetForTest() {
    _mode = InputMode.mouse;
  }
}

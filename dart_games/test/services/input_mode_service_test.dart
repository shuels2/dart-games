import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/input_mode_service.dart';

PointerDownEvent _pointer(PointerDeviceKind kind) {
  return PointerDownEvent(
    kind: kind,
    position: const Offset(10, 10),
  );
}

void main() {
  late InputModeService svc;

  setUp(() {
    svc = InputModeService.instance;
    svc.resetForTest();
  });

  group('InputModeService', () {
    test('starts in mouse mode', () {
      expect(svc.mode, InputMode.mouse);
      expect(svc.isTouch, isFalse);
    });

    test('touch pointer flips mode to touch', () {
      svc.observePointer(_pointer(PointerDeviceKind.touch));
      expect(svc.mode, InputMode.touch);
      expect(svc.isTouch, isTrue);
    });

    test('stylus pointer flips mode to touch', () {
      svc.observePointer(_pointer(PointerDeviceKind.stylus));
      expect(svc.mode, InputMode.touch);
    });

    test('mouse pointer flips mode back to mouse', () {
      svc.observePointer(_pointer(PointerDeviceKind.touch));
      svc.observePointer(_pointer(PointerDeviceKind.mouse));
      expect(svc.mode, InputMode.mouse);
      expect(svc.isTouch, isFalse);
    });

    test('unknown pointer kinds leave mode alone', () {
      svc.observePointer(_pointer(PointerDeviceKind.touch));
      svc.observePointer(_pointer(PointerDeviceKind.unknown));
      expect(svc.mode, InputMode.touch);
    });

    test('notifyListeners fires only on actual mode change', () {
      var notifications = 0;
      void listener() => notifications++;
      svc.addListener(listener);
      try {
        // Same-mode events do NOT notify.
        svc.observePointer(_pointer(PointerDeviceKind.mouse));
        expect(notifications, 0);

        // First transition mouse→touch notifies once.
        svc.observePointer(_pointer(PointerDeviceKind.touch));
        expect(notifications, 1);

        // Repeat touch events do NOT re-notify.
        svc.observePointer(_pointer(PointerDeviceKind.touch));
        svc.observePointer(_pointer(PointerDeviceKind.stylus));
        expect(notifications, 1);

        // Transition back to mouse notifies.
        svc.observePointer(_pointer(PointerDeviceKind.mouse));
        expect(notifications, 2);
      } finally {
        svc.removeListener(listener);
      }
    });
  });
}

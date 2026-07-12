import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/input_mode_service.dart';
import 'package:dart_games/widgets/virtual_keyboard/virtual_keyboard.dart';
import 'package:dart_games/widgets/virtual_keyboard/virtual_keyboard_scaffold.dart';

/// Push a synthetic pointer down through the scaffold so its Listener
/// updates [InputModeService]. Mirrors what a real touchscreen tap does.
Future<void> _dispatchPointer(
  WidgetTester tester,
  PointerDeviceKind kind, {
  Offset at = const Offset(200, 200),
}) async {
  final gesture =
      await tester.createGesture(kind: kind, pointer: kind == PointerDeviceKind.touch ? 1 : 2);
  await gesture.down(at);
  await gesture.up();
  await tester.pump();
}

Future<TextEditingController> _pumpApp(WidgetTester tester) async {
  final controller = TextEditingController();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          VirtualKeyboardScaffold(child: child ?? const SizedBox.shrink()),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: TextField(controller: controller),
          ),
        ),
      ),
    ),
  );
  return controller;
}

void main() {
  setUp(() => InputModeService.instance.resetForTest());

  group('VirtualKeyboardScaffold', () {
    testWidgets('keyboard hidden by default (no focus, mouse mode)',
        (tester) async {
      await _pumpApp(tester);
      expect(find.byType(VirtualKeyboard), findsNothing);
    });

    testWidgets('keyboard hidden when focusing TextField in mouse mode',
        (tester) async {
      await _pumpApp(tester);
      // Drive a mouse pointer through the scaffold's Listener so mode
      // resolves to mouse (not the default touch used by `tester.tap`).
      final tapCenter = tester.getCenter(find.byType(TextField));
      await _dispatchPointer(tester, PointerDeviceKind.mouse, at: tapCenter);
      await tester.pump();
      expect(InputModeService.instance.mode, InputMode.mouse);
      expect(find.byType(VirtualKeyboard), findsNothing);
    });

    testWidgets('keyboard shows when focusing TextField after a touch tap',
        (tester) async {
      await _pumpApp(tester);
      // Touch pointer at the TextField — the scaffold's Listener observes
      // it and flips InputModeService to touch, and the tap grabs focus.
      final tapCenter = tester.getCenter(find.byType(TextField));
      await _dispatchPointer(tester, PointerDeviceKind.touch, at: tapCenter);
      await tester.pump();
      expect(InputModeService.instance.isTouch, isTrue);
      expect(find.byType(VirtualKeyboard), findsOneWidget);
    });

    testWidgets(
        'Hide button dismisses the keyboard even while TextField is focused',
        (tester) async {
      await _pumpApp(tester);
      final tapCenter = tester.getCenter(find.byType(TextField));
      await _dispatchPointer(tester, PointerDeviceKind.touch, at: tapCenter);
      await tester.pump();
      expect(find.byType(VirtualKeyboard), findsOneWidget);

      await tester.tap(find.text('Hide'));
      await tester.pump();
      expect(find.byType(VirtualKeyboard), findsNothing);
    });
  });
}

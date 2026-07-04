import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/virtual_keyboard/virtual_keyboard.dart';

/// Mount a TextField and the VirtualKeyboard together so key taps route
/// to the currently-focused controller (which is what the widget does at
/// runtime via `FocusManager.primaryFocus`).
Future<TextEditingController> _pumpHarness(
  WidgetTester tester, {
  required VoidCallback onDismiss,
}) async {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextField(controller: controller, focusNode: focusNode),
            Expanded(child: VirtualKeyboard(onDismiss: onDismiss)),
          ],
        ),
      ),
    ),
  );
  focusNode.requestFocus();
  await tester.pump();
  return controller;
}

Future<void> _tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await tester.pump();
}

void main() {
  group('VirtualKeyboard', () {
    testWidgets('typing a letter appends to the focused controller (shift on start)',
        (tester) async {
      final controller = await _pumpHarness(tester, onDismiss: () {});
      // Shift starts on → first tap should insert uppercase.
      await _tapKey(tester, 'Q');
      expect(controller.text, 'Q');
    });

    testWidgets('shift auto-releases after typing one character', (tester) async {
      final controller = await _pumpHarness(tester, onDismiss: () {});
      await _tapKey(tester, 'Q'); // shift on → uppercase
      // After one char, shift released. Next taps show/insert lowercase.
      await _tapKey(tester, 'w');
      await _tapKey(tester, 'e');
      expect(controller.text, 'Qwe');
    });

    testWidgets('digit keys insert plain digits', (tester) async {
      final controller = await _pumpHarness(tester, onDismiss: () {});
      await _tapKey(tester, '1');
      await _tapKey(tester, '2');
      await _tapKey(tester, '3');
      expect(controller.text, '123');
    });

    testWidgets('backspace removes the character before the cursor',
        (tester) async {
      final controller = await _pumpHarness(tester, onDismiss: () {});
      await _tapKey(tester, 'Q');
      await _tapKey(tester, 'w');
      await _tapKey(tester, 'e');
      // Backspace is icon-only (⌫ label); find by icon.
      await tester.tap(find.byIcon(Icons.backspace));
      await tester.pump();
      expect(controller.text, 'Qw');
    });

    testWidgets('space key inserts a space', (tester) async {
      final controller = await _pumpHarness(tester, onDismiss: () {});
      await _tapKey(tester, 'Q');
      await _tapKey(tester, 'space');
      await _tapKey(tester, 'w');
      expect(controller.text, 'Q w');
    });

    testWidgets('Hide button invokes onDismiss', (tester) async {
      var dismissed = 0;
      await _pumpHarness(tester, onDismiss: () => dismissed++);
      await _tapKey(tester, 'Hide');
      expect(dismissed, 1);
    });

    testWidgets('Done button clears focus (dismisses keyboard indirectly)',
        (tester) async {
      await _pumpHarness(tester, onDismiss: () {});
      // Ensure something is focused before Done.
      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorStateOfType<EditableTextState>() !=
            null,
        isTrue,
      );
      await _tapKey(tester, 'Done');
      await tester.pump();
      // Primary focus is no longer an EditableText.
      final stillEditable = FocusManager.instance.primaryFocus?.context
              ?.findAncestorStateOfType<EditableTextState>() !=
          null;
      expect(stillEditable, isFalse);
    });
  });
}

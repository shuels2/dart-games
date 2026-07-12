/// Widget tests for the AddPlayerDialog progress overlay — verifies
/// the shared modal shows an in-dialog status row while an async
/// `onSubmit` callback is running, disables the action buttons during
/// that window, and surfaces an error message if the callback throws.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/widgets/add_player/add_player_dialog.dart';
import 'package:dart_games/widgets/add_player/add_player_dialog_config.dart';

void main() {
  Widget _harness({required VoidCallback onOpen}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: onOpen,
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  group('AddPlayerDialog progress overlay', () {
    testWidgets(
        'without onSubmit — old behavior, Add Player pops immediately '
        'and no progress row renders', (tester) async {
      Player? returned;
      late BuildContext ctx;
      await tester.pumpWidget(_harness(onOpen: () async {}));
      // Rebuild with a real onPressed once we have context.
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          ctx = context;
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  returned = await showAddPlayerDialog(
                    context: ctx,
                    config: AddPlayerDialogConfig.optionsScreen(ctx),
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        }),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();

      await tester.enterText(
          find.byKey(AddPlayerDialogKeys.nameTextField), 'Alex');
      await tester.tap(find.byKey(AddPlayerDialogKeys.addButton));
      await tester.pump();

      expect(returned, isNotNull);
      expect(returned!.name, 'Alex');
      // No progress overlay renders on this path.
      expect(find.byKey(AddPlayerDialogKeys.progressOverlay), findsNothing);
    });

    testWidgets(
        'with onSubmit — the status row renders while the future is '
        'in flight; Add / Cancel are disabled; dialog pops on success',
        (tester) async {
      final completer = Completer<void>();
      Player? submittedPlayer;
      Player? returnedPlayer;
      late BuildContext ctx;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          ctx = context;
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  returnedPlayer = await showAddPlayerDialog(
                    context: ctx,
                    config: AddPlayerDialogConfig.optionsScreen(ctx),
                    onSubmit: (p) async {
                      submittedPlayer = p;
                      await completer.future;
                    },
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        }),
      ));

      await tester.tap(find.text('open'));
      await tester.pump();

      await tester.enterText(
          find.byKey(AddPlayerDialogKeys.nameTextField), 'Alex');
      await tester.tap(find.byKey(AddPlayerDialogKeys.addButton));
      // Rebuild → progress overlay appears; onSubmit is now awaiting completer.
      await tester.pump();

      expect(find.byKey(AddPlayerDialogKeys.progressOverlay), findsOneWidget,
          reason: 'progress overlay should appear while onSubmit is in flight');
      expect(find.byKey(AddPlayerDialogKeys.progressLabel), findsOneWidget);
      expect(submittedPlayer, isNotNull,
          reason: 'onSubmit was called with the player');
      expect(submittedPlayer!.name, 'Alex');

      // Buttons disabled while busy.
      final addBtn = tester
          .widget<ElevatedButton>(find.byKey(AddPlayerDialogKeys.addButton));
      expect(addBtn.onPressed, isNull,
          reason: 'Add button should be disabled while onSubmit is in flight');
      final cancelBtn = tester
          .widget<ElevatedButton>(find.byKey(AddPlayerDialogKeys.cancelButton));
      expect(cancelBtn.onPressed, isNull,
          reason: 'Cancel button should be disabled while onSubmit is in flight');

      // Complete the future → dialog should close and return the Player.
      completer.complete();
      // Pump a couple of frames to let the microtask run and Navigator.pop
      // finish. We can't use pumpAndSettle because the indeterminate
      // LinearProgressIndicator would never settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(returnedPlayer, isNotNull);
      expect(returnedPlayer!.name, 'Alex');
      // The dialog is gone, so the overlay is gone too.
      expect(find.byKey(AddPlayerDialogKeys.progressOverlay), findsNothing);
    });

    testWidgets(
        'with onSubmit that throws — status row switches to the error '
        'message; buttons re-enable so the user can retry or cancel',
        (tester) async {
      Player? returnedPlayer;
      late BuildContext ctx;
      var attempts = 0;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          ctx = context;
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  returnedPlayer = await showAddPlayerDialog(
                    context: ctx,
                    config: AddPlayerDialogConfig.optionsScreen(ctx),
                    onSubmit: (p) async {
                      attempts++;
                      throw Exception('boom-network-503');
                    },
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        }),
      ));

      await tester.tap(find.text('open'));
      await tester.pump();

      await tester.enterText(
          find.byKey(AddPlayerDialogKeys.nameTextField), 'Alex');
      await tester.tap(find.byKey(AddPlayerDialogKeys.addButton));
      // Give the async onSubmit a microtask + a frame to throw and update state.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      // The overlay is still visible — but now showing the error.
      expect(find.byKey(AddPlayerDialogKeys.progressOverlay), findsOneWidget);
      expect(find.textContaining('boom-network-503'), findsOneWidget);
      expect(attempts, 1);

      // Buttons are re-enabled so the user can retry.
      final addBtn = tester
          .widget<ElevatedButton>(find.byKey(AddPlayerDialogKeys.addButton));
      expect(addBtn.onPressed, isNotNull,
          reason: 'Add button re-enables after onSubmit throws');
      final cancelBtn = tester
          .widget<ElevatedButton>(find.byKey(AddPlayerDialogKeys.cancelButton));
      expect(cancelBtn.onPressed, isNotNull,
          reason: 'Cancel button re-enables after onSubmit throws');

      // Dialog has NOT closed yet.
      expect(returnedPlayer, isNull,
          reason: 'dialog stays open so the user can retry or cancel');

      // Cancel closes the dialog with null.
      await tester.tap(find.byKey(AddPlayerDialogKeys.cancelButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(returnedPlayer, isNull);
    });

    testWidgets(
        'status row inherits config colors — spinner uses addButtonColor, '
        'label uses textColor', (tester) async {
      const kAddBtnColor = Color(0xFF00AA88);
      const kTextColor = Color(0xFFCCEEEE);
      final config = AddPlayerDialogConfig(
        backgroundColor: Colors.black,
        textColor: kTextColor,
        titleStyle: const TextStyle(),
        inputLabelStyle: const TextStyle(),
        inputBorderColor: Colors.grey,
        inputFocusedBorderColor: Colors.grey,
        inputErrorBorderColor: Colors.red,
        photoLabelStyle: const TextStyle(),
        photoButtonColor: Colors.grey,
        photoButtonForegroundColor: Colors.white,
        photoButtonBorderColor: Colors.grey,
        photoButtonTextStyle: const TextStyle(),
        addButtonColor: kAddBtnColor,
        addButtonForegroundColor: Colors.white,
        addButtonBorderColor: kAddBtnColor,
        addButtonTextStyle: const TextStyle(),
        cancelButtonColor: Colors.grey,
        cancelButtonForegroundColor: Colors.white,
        cancelButtonBorderColor: Colors.grey,
        cancelButtonTextStyle: const TextStyle(),
        errorTextColor: Colors.red,
      );

      final completer = Completer<void>();
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          ctx = context;
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await showAddPlayerDialog(
                    context: ctx,
                    config: config,
                    onSubmit: (_) => completer.future,
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        }),
      ));

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.enterText(
          find.byKey(AddPlayerDialogKeys.nameTextField), 'Alex');
      await tester.tap(find.byKey(AddPlayerDialogKeys.addButton));
      await tester.pump();

      // The spinner is a CircularProgressIndicator whose valueColor is
      // an AlwaysStoppedAnimation<Color> using addButtonColor.
      final spinner = tester.widget<CircularProgressIndicator>(
        find.descendant(
          of: find.byKey(AddPlayerDialogKeys.progressOverlay),
          matching: find.byType(CircularProgressIndicator),
        ),
      );
      expect(spinner.valueColor?.value, kAddBtnColor);

      // The label text uses textColor while busy.
      final label = tester.widget<Text>(
        find.byKey(AddPlayerDialogKeys.progressLabel),
      );
      expect(label.style?.color, kTextColor);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}

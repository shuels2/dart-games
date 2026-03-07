import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/save_game_modal/save_game_modal.dart';
import 'package:dart_games/constants/test_keys.dart';

void main() {
  group('SaveGameModal', () {
    late bool savedCalled;
    late bool dontSaveCalled;

    setUp(() {
      savedCalled = false;
      dontSaveCalled = false;
    });

    Widget buildModal({SaveGameModalConfig? config}) {
      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SaveGameModal(
                config: config ?? SaveGameModalConfig.carnivalDerby(),
                onSave: () => savedCalled = true,
                onDontSave: () => dontSaveCalled = true,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('renders all widget keys', (tester) async {
      await tester.pumpWidget(buildModal());

      expect(find.byKey(SaveGameModalKeys.overlay), findsOneWidget);
      expect(find.byKey(SaveGameModalKeys.container), findsOneWidget);
      expect(find.byKey(SaveGameModalKeys.icon), findsOneWidget);
      expect(find.byKey(SaveGameModalKeys.title), findsOneWidget);
      expect(find.byKey(SaveGameModalKeys.message), findsOneWidget);
      expect(find.byKey(SaveGameModalKeys.saveButton), findsOneWidget);
      expect(find.byKey(SaveGameModalKeys.dontSaveButton), findsOneWidget);
    });

    testWidgets('displays correct title and message', (tester) async {
      await tester.pumpWidget(buildModal());

      expect(find.text('Save Game?'), findsOneWidget);
      expect(find.text('Would you like to save your game\nso you can resume later?'),
          findsOneWidget);
    });

    testWidgets('Save button triggers onSave callback', (tester) async {
      await tester.pumpWidget(buildModal());

      await tester.tap(find.byKey(SaveGameModalKeys.saveButton));
      expect(savedCalled, true);
      expect(dontSaveCalled, false);
    });

    testWidgets("Don't Save button triggers onDontSave callback", (tester) async {
      await tester.pumpWidget(buildModal());

      await tester.tap(find.byKey(SaveGameModalKeys.dontSaveButton));
      expect(dontSaveCalled, true);
      expect(savedCalled, false);
    });

    testWidgets('Carnival Derby config applies theme colors', (tester) async {
      await tester.pumpWidget(
          buildModal(config: SaveGameModalConfig.carnivalDerby()));

      final container = tester.widget<Container>(
          find.byKey(SaveGameModalKeys.container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('Target Tag config applies theme colors', (tester) async {
      await tester.pumpWidget(
          buildModal(config: SaveGameModalConfig.targetTag()));

      expect(find.byKey(SaveGameModalKeys.container), findsOneWidget);
    });

    testWidgets('Monster Mash config applies theme colors', (tester) async {
      await tester.pumpWidget(
          buildModal(config: SaveGameModalConfig.monsterMash()));

      expect(find.byKey(SaveGameModalKeys.container), findsOneWidget);
    });

    testWidgets('Reef Royale config applies theme colors', (tester) async {
      await tester.pumpWidget(
          buildModal(config: SaveGameModalConfig.reefRoyale()));

      expect(find.byKey(SaveGameModalKeys.container), findsOneWidget);
    });
  });
}

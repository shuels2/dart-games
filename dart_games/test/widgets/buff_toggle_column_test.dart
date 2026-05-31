import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/models/monster_mash_game.dart';
import 'package:dart_games/widgets/dartboard_emulator/buff_toggle_column.dart';
import 'package:dart_games/widgets/dartboard_emulator/dartboard_emulator_config.dart';

BuffToggleSpec<Object> _spec(
  BonusBuff buff, {
  required bool isActive,
  required bool isEnabled,
}) {
  return BuffToggleSpec<Object>(
    buff: buff,
    label: MonsterMashGame.getBuffDisplayName(buff),
    isActive: isActive,
    isEnabled: isEnabled,
    buttonKey: DartboardEmulatorKeys.buffToggleButton(buff.name),
    config: BuffToggleButtonConfig.monsterMash(buff),
  );
}

Future<void> _pumpColumn(
  WidgetTester tester, {
  required List<BuffToggleSpec<Object>> specs,
  required void Function(Object buff) onToggle,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BuffToggleColumn<Object>(specs: specs, onToggle: onToggle),
      ),
    ),
  );
}

void main() {
  group('BuffToggleColumn', () {
    testWidgets('renders one button per spec', (tester) async {
      await _pumpColumn(
        tester,
        specs: [
          _spec(BonusBuff.bloodMoon, isActive: false, isEnabled: true),
          _spec(BonusBuff.ancientBandages, isActive: false, isEnabled: true),
        ],
        onToggle: (_) {},
      );

      expect(
        find.byKey(
          DartboardEmulatorKeys.buffToggleButton(BonusBuff.bloodMoon.name),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          DartboardEmulatorKeys.buffToggleButton(
            BonusBuff.ancientBandages.name,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Blood Moon'), findsOneWidget);
      expect(find.text('Ancient Bandages'), findsOneWidget);
    });

    testWidgets('tap fires onToggle with the buff enum', (tester) async {
      Object? tapped;
      await _pumpColumn(
        tester,
        specs: [
          _spec(BonusBuff.bloodMoon, isActive: false, isEnabled: true),
        ],
        onToggle: (b) => tapped = b,
      );
      await tester.tap(
        find.byKey(
          DartboardEmulatorKeys.buffToggleButton(BonusBuff.bloodMoon.name),
        ),
      );
      await tester.pump();
      expect(tapped, equals(BonusBuff.bloodMoon));
    });

    testWidgets('disabled spec swallows taps and dims the button',
        (tester) async {
      int taps = 0;
      await _pumpColumn(
        tester,
        specs: [
          _spec(BonusBuff.bloodMoon, isActive: false, isEnabled: false),
        ],
        onToggle: (_) => taps++,
      );

      await tester.tap(
        find.byKey(
          DartboardEmulatorKeys.buffToggleButton(BonusBuff.bloodMoon.name),
        ),
      );
      await tester.pump();
      expect(taps, equals(0));

      // Disabled state wraps button in an Opacity at 0.4.
      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, closeTo(0.4, 0.001));
    });

    testWidgets('active spec renders with thicker border', (tester) async {
      await _pumpColumn(
        tester,
        specs: [
          _spec(BonusBuff.bloodMoon, isActive: true, isEnabled: true),
          _spec(BonusBuff.ancientBandages, isActive: false, isEnabled: true),
        ],
        onToggle: (_) {},
      );

      // Find all Container with BoxDecoration in the column and inspect
      // their border widths. Active = 2.5, inactive = 1.5.
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .map((c) => (c.decoration as BoxDecoration).border)
          .whereType<Border>()
          .toList();

      final widths = containers.map((b) => b.top.width).toSet();
      expect(widths.contains(2.5), isTrue,
          reason: 'expected at least one button with active border 2.5');
      expect(widths.contains(1.5), isTrue,
          reason: 'expected at least one button with inactive border 1.5');
    });

    testWidgets('empty spec list renders SizedBox.shrink', (tester) async {
      await _pumpColumn(tester, specs: const [], onToggle: (_) {});
      expect(find.byType(InkWell), findsNothing);
    });
  });
}

// WS03 §3.7. Four modals each carried the same chrome stack. These tests pin
// the shared values, because the failure mode of drift is two modals looking
// subtly different on the same screen — which no functional test would catch.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/themed_modal_shell.dart';

Future<void> _pump(WidgetTester tester, ThemedModalShell shell) =>
    tester.pumpWidget(MaterialApp(home: Stack(children: [shell])));

void main() {
  group('ThemedModalShell', () {
    testWidgets('renders the barrier, the panel and the child', (tester) async {
      await _pump(
        tester,
        const ThemedModalShell(
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          child: Text('content'),
        ),
      );
      expect(find.text('content'), findsOneWidget);
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('passes barrier and panel keys through', (tester) async {
      const barrier = Key('barrier');
      const panel = Key('panel');
      await _pump(
        tester,
        const ThemedModalShell(
          barrierKey: barrier,
          panelKey: panel,
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          child: SizedBox.shrink(),
        ),
      );
      // The UI suites match on these; if the shell swallowed them,
      // getSaveGameModalOverlay() would stop finding anything.
      expect(find.byKey(barrier), findsOneWidget);
      expect(find.byKey(panel), findsOneWidget);
    });

    testWidgets('applies the shared barrier opacity', (tester) async {
      const barrier = Key('barrier');
      await _pump(
        tester,
        const ThemedModalShell(
          barrierKey: barrier,
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          child: SizedBox.shrink(),
        ),
      );
      final container = tester.widget<Container>(find.byKey(barrier));
      expect(container.color, Colors.black.withOpacity(0.7));
      expect(ThemedModalShell.defaultBarrierOpacity, 0.7,
          reason: 'all four modals shared this; changing it is a one-place '
              'decision now, not four independent literals');
    });

    testWidgets('applies the shared glow geometry', (tester) async {
      const panel = Key('panel');
      await _pump(
        tester,
        const ThemedModalShell(
          panelKey: panel,
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          boxShadowColor: Color(0xFF7FFF00),
          boxShadowOpacity: 0.3,
          child: SizedBox.shrink(),
        ),
      );
      final decoration = tester
          .widget<Container>(find.byKey(panel))
          .decoration as BoxDecoration;
      final shadow = decoration.boxShadow!.single;
      expect(shadow.blurRadius, ThemedModalShell.shadowBlurRadius);
      expect(shadow.spreadRadius, ThemedModalShell.shadowSpreadRadius);
      expect(shadow.color, const Color(0xFF7FFF00).withOpacity(0.3));
    });

    testWidgets('an infinite maxWidth adds no width cap of its own',
        (tester) async {
      // RemoveDartsModal wants no cap. The ConstrainedBox is simply not
      // inserted — the framework's own are scoped out by looking only at
      // ancestors of the panel.
      const panel = Key('panel');
      await _pump(
        tester,
        const ThemedModalShell(
          panelKey: panel,
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          child: SizedBox.shrink(),
        ),
      );
      final caps = tester
          .widgetList<ConstrainedBox>(find.ancestor(
            of: find.byKey(panel),
            matching: find.byType(ConstrainedBox),
          ))
          .where((c) => c.constraints.maxWidth.isFinite);
      expect(caps, isEmpty);
    });

    testWidgets('a finite maxWidth constrains the panel', (tester) async {
      const panel = Key('panel');
      await _pump(
        tester,
        const ThemedModalShell(
          panelKey: panel,
          maxWidth: 420,
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          child: SizedBox.shrink(),
        ),
      );
      final caps = tester
          .widgetList<ConstrainedBox>(find.ancestor(
            of: find.byKey(panel),
            matching: find.byType(ConstrainedBox),
          ))
          .where((c) => c.constraints.maxWidth == 420);
      expect(caps, hasLength(1));
    });
  });

  group('the two structural options the last two modals needed', () {
    testWidgets('fill: false omits Positioned.fill', (tester) async {
      // RemoveDartsModal is mounted as a bare child of the game shell's outer
      // Stack, in a specific layer (below the emulator so DARTS REMOVED stays
      // reachable), and returned a plain Material. Wrapping it in
      // Positioned.fill would turn a loose Stack child into a filling one.
      await _pump(
        tester,
        const ThemedModalShell(
          fill: false,
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          child: SizedBox.shrink(),
        ),
      );
      expect(
          find.descendant(
              of: find.byType(ThemedModalShell),
              matching: find.byType(Positioned)),
          findsNothing);
    });

    testWidgets('fill: true (default) wraps in Positioned', (tester) async {
      await _pump(
        tester,
        const ThemedModalShell(
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          child: SizedBox.shrink(),
        ),
      );
      expect(
          find.descendant(
              of: find.byType(ThemedModalShell),
              matching: find.byType(Positioned)),
          findsOneWidget);
    });

    testWidgets('maxHeight constrains the panel too', (tester) async {
      // Only ResumeGameModal sets one — its saved-game list must stop growing
      // before it runs off the screen.
      const panel = Key('panel');
      await _pump(
        tester,
        const ThemedModalShell(
          panelKey: panel,
          maxWidth: 500,
          maxHeight: 600,
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          child: SizedBox.shrink(),
        ),
      );
      final caps = tester
          .widgetList<ConstrainedBox>(find.ancestor(
            of: find.byKey(panel),
            matching: find.byType(ConstrainedBox),
          ))
          .where((c) =>
              c.constraints.maxWidth == 500 && c.constraints.maxHeight == 600);
      expect(caps, hasLength(1));
    });

    testWidgets('a height-only cap still inserts the ConstrainedBox',
        (tester) async {
      const panel = Key('panel');
      await _pump(
        tester,
        const ThemedModalShell(
          panelKey: panel,
          maxHeight: 600,
          backgroundColor: Color(0xFF1D3557),
          borderColor: Color(0xFFFFD700),
          child: SizedBox.shrink(),
        ),
      );
      final caps = tester
          .widgetList<ConstrainedBox>(find.ancestor(
            of: find.byKey(panel),
            matching: find.byType(ConstrainedBox),
          ))
          .where((c) => c.constraints.maxHeight == 600);
      expect(caps, hasLength(1));
    });
  });
}

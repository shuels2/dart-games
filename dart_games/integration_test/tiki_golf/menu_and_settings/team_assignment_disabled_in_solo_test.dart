// integration_test/tiki_golf/menu_and_settings/team_assignment_disabled_in_solo_test.dart
//
// Verifies Team Assignment toggle is fully disabled in Solo mode:
//   - Renders at 50% opacity
//   - IgnorePointer wraps it (taps do nothing — MANUAL segment does not activate)
//   - Switching to TEAM re-enables it (taps work)
//   - Switching back to SOLO disables it again
//
// Section 12B File 2 — Test 7 (team_assignment_disabled_in_solo)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Assignment toggle is disabled (50% opacity + IgnorePointer) in Solo mode',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_menu_and_settings_team_assignment_disabled_solo',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // ── Solo mode: verify 50% opacity wrapper ─────────────────────────────
        bool foundHalfOpacity() {
          for (final element in find.byType(Opacity).evaluate()) {
            final w = element.widget as Opacity;
            if (w.opacity == 0.5) return true;
          }
          return false;
        }
        expect(foundHalfOpacity(), isTrue,
            reason:
                '[DIAG team_assign_disabled] Opacity(0.5) wrapper not found in Solo mode');

        // ── Attempt to tap MANUAL segment while in Solo mode ──────────────────
        // The IgnorePointer should swallow the tap — the assignment stays RANDOM.
        // We try tapping and verify Team Count dropdown does NOT appear.
        final manualSegment = ElementFinders.getTikiGolfAssignmentModeManual();
        expect(manualSegment, findsOneWidget,
            reason: '[DIAG team_assign_disabled] MANUAL segment not in tree');

        await tester.tap(manualSegment);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Team Count dropdown must NOT appear (it only appears in Team+Manual)
        final teamCountDropdown =
            ElementFinders.getTikiGolfTeamCountDropdown();
        expect(teamCountDropdown, findsNothing,
            reason:
                '[DIAG team_assign_disabled] Team Count dropdown should NOT appear when tap is ignored in Solo mode');

        // ── Switch to TEAM mode — verify toggle activates ─────────────────────
        await setGameModeTeam(tester);

        expect(foundHalfOpacity(), isFalse,
            reason:
                '[DIAG team_assign_disabled] Opacity(0.5) should be gone in Team mode');

        // Now tapping MANUAL should work
        await setAssignmentManual(tester);

        // Team Count dropdown should appear (Team + Manual mode)
        final teamCountDropdownAfter =
            ElementFinders.getTikiGolfTeamCountDropdown();
        expect(teamCountDropdownAfter, findsOneWidget,
            reason:
                '[DIAG team_assign_disabled] Team Count dropdown should appear in Team+Manual mode');

        // ── Switch back to SOLO — verify disabled again ───────────────────────
        await setGameModeSolo(tester);

        expect(foundHalfOpacity(), isTrue,
            reason:
                '[DIAG team_assign_disabled] Opacity(0.5) should return when back in Solo mode');

        // Team Count dropdown should disappear
        expect(teamCountDropdown, findsNothing,
            reason:
                '[DIAG team_assign_disabled] Team Count dropdown should be gone in Solo mode');
      },
    );
  });
}

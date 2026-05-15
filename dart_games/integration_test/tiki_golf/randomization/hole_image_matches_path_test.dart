// integration_test/tiki_golf/randomization/hole_image_matches_path_test.dart
//
// For hole 1 and hole 2, verify the displayed image path matches
// holeImagePaths[currentHole-1] from the provider.
//
// The holeImage widget is keyed with TikiGolfGameKeys.holeImage. Its source
// path should match what the provider reports in holeImagePaths.
// This confirms the game renders the game-specific shuffled image, not a fixed one.
//
// Section 12B File 3a — Randomization test 2
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Randomization: displayed hole image matches provider holeImagePaths for holes 1 and 2',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_randomization_hole_image_matches_path',
      () async {
        await UITestHelpers.resetServerState();
        await setupAndStartGame(tester);

        // ── Hole 1 image check ────────────────────────────────────────────────
        final providerImageHole1 =
            ProviderHelpers.getTikiGolfHoleImagePath(tester, 1);
        expect(providerImageHole1, isNotNull,
            reason: 'Provider should have a hole image path for hole 1');
        expect(providerImageHole1, isNotEmpty,
            reason: 'Hole 1 image path should not be empty');

        // The holeImage widget should be present
        final holeImageFinder = ElementFinders.getTikiGolfHoleImage();
        expect(holeImageFinder, findsOneWidget,
            reason: 'Hole image widget should be present on game screen');

        // The image widget should use the path from the provider.
        // We inspect the Image widget's image property (AssetImage).
        final imageWidget = tester.widget<Image>(holeImageFinder);
        final assetImage = imageWidget.image as AssetImage;
        expect(assetImage.assetName, equals(providerImageHole1),
            reason:
                'Displayed hole 1 image path should match holeImagePaths[0] from provider. '
                'Provider: $providerImageHole1, Displayed: ${assetImage.assetName}');

        // ── Advance to hole 2 ─────────────────────────────────────────────────
        await completeHoleForAllPlayers(tester);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        final providerImageHole2 =
            ProviderHelpers.getTikiGolfHoleImagePath(tester, 2);
        expect(providerImageHole2, isNotNull,
            reason: 'Provider should have a hole image path for hole 2');
        expect(providerImageHole2, isNotEmpty,
            reason: 'Hole 2 image path should not be empty');

        // Hole 1 and hole 2 should have different images (they're shuffled)
        expect(providerImageHole1 != providerImageHole2, isTrue,
            reason:
                'Holes 1 and 2 should have different image paths (shuffled per game)');

        // Verify hole 2 image is now displayed
        final holeImageFinderH2 = ElementFinders.getTikiGolfHoleImage();
        expect(holeImageFinderH2, findsOneWidget,
            reason: 'Hole image widget should still be present on hole 2');

        final imageWidgetH2 = tester.widget<Image>(holeImageFinderH2);
        final assetImageH2 = imageWidgetH2.image as AssetImage;
        expect(assetImageH2.assetName, equals(providerImageHole2),
            reason:
                'Displayed hole 2 image path should match holeImagePaths[1] from provider. '
                'Provider: $providerImageHole2, Displayed: ${assetImageH2.assetName}');
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/widgets/game_background.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: Stack(children: [child])),
      );

  group('GameBackground', () {
    testWidgets('bounds the decoded raster', (tester) async {
      await tester.pumpWidget(host(const GameBackground(
        asset: 'assets/games/treasure_divide/images/TreasureDivide-Background.png',
        fallbackColor: Colors.black,
      )));

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image;
      expect(provider, isA<ResizeImage>(),
          reason: 'An uncapped provider keeps a full-size bitmap resident for '
              'the whole game');
      final resize = provider as ResizeImage;
      expect(resize.width, 1280);
      expect(resize.height, 512);
      expect(resize.policy, ResizeImagePolicy.fit);
    });

    testWidgets('honours a custom decode cap', (tester) async {
      await tester.pumpWidget(host(const GameBackground(
        asset: 'assets/games/target_tag/images/background.png',
        fallbackColor: Colors.black,
        decodeWidth: 1920,
        decodeHeight: 1080,
      )));

      final resize = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
      expect(resize.width, 1920);
      expect(resize.height, 1080);
    });

    testWidgets('paints no wash when none is asked for', (tester) async {
      await tester.pumpWidget(host(const GameBackground(
        asset: 'a.png',
        fallbackColor: Colors.black,
      )));

      // Only the image layer.
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('paints the wash at the requested opacity', (tester) async {
      await tester.pumpWidget(host(const GameBackground(
        asset: 'a.png',
        fallbackColor: Colors.black,
        overlayColor: Color(0xFF2E8B87),
        overlayOpacity: 0.10,
      )));

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, const Color(0xFF2E8B87).withOpacity(0.10));
    });

    testWidgets('falls back to the game colour when the asset is missing',
        (tester) async {
      await tester.pumpWidget(host(const GameBackground(
        asset: 'assets/does/not/exist.png',
        fallbackColor: Color(0xFF123456),
      )));
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      final fallback = image.errorBuilder!(
          tester.element(find.byType(Image)), 'boom', null) as Container;
      expect(fallback.color, const Color(0xFF123456),
          reason: 'A missing background must not leave a white screen');
    });
  });
}

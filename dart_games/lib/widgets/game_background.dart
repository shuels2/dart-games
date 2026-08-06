import 'package:flutter/material.dart';

/// Full-bleed background art for a game screen, with the decoded raster
/// bounded and an optional brand wash on top.
///
/// Every game paints one of these and each was doing it by hand. Only
/// Treasure Divide capped the decode; the rest handed Flutter a full-size
/// asset, which on a hi-DPI display can keep a bitmap several times larger
/// than the screen resident for the whole game. A 1584×588 source is ~3.7 MB
/// decoded; capped it is ~2.6 MB, once, for a layer nobody looks closely at.
///
/// ```dart
/// GameBackground(
///   asset: 'assets/games/treasure_divide/images/TreasureDivide-Background.png',
///   fallbackColor: _oceanTeal,
///   overlayColor: _oceanTeal,
///   overlayOpacity: 0.10,
/// )
/// ```
class GameBackground extends StatelessWidget {
  const GameBackground({
    super.key,
    required this.asset,
    required this.fallbackColor,
    this.overlayColor,
    this.overlayOpacity = 0.0,
    this.decodeWidth = 1280,
    this.decodeHeight = 512,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.imageColor,
    this.imageBlendMode,
  });

  /// Asset path of the background art.
  final String asset;

  /// Painted instead of the image if the asset fails to load, so a missing
  /// file degrades to the game's colour rather than a white screen.
  final Color fallbackColor;

  /// Optional brand wash painted over the art.
  final Color? overlayColor;

  /// Opacity of [overlayColor]. Ignored when [overlayColor] is null.
  final double overlayOpacity;

  /// Cap on the decoded raster. Defaults suit a landscape tablet; raise only
  /// for art with fine detail that visibly softens.
  final int decodeWidth;
  final int decodeHeight;

  final BoxFit fit;

  /// Which part of the art to keep when [fit] crops it.
  final Alignment alignment;

  /// Tint blended into the image itself (as opposed to [overlayColor], which
  /// is a separate layer painted on top). Used with [imageBlendMode] for the
  /// darken passes some games apply.
  final Color? imageColor;
  final BlendMode? imageBlendMode;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image(
              // The provider is built from const-able pieces so the same
              // entry is reused across rebuilds — game screens rebuild on
              // every dart, and a fresh provider each time would churn the
              // image cache.
              image: ResizeImage(
                AssetImage(asset),
                width: decodeWidth,
                height: decodeHeight,
                policy: ResizeImagePolicy.fit,
              ),
              fit: fit,
              alignment: alignment,
              color: imageColor,
              colorBlendMode: imageBlendMode,
              errorBuilder: (_, __, ___) => Container(color: fallbackColor),
            ),
          ),
          if (overlayColor != null && overlayOpacity > 0)
            Positioned.fill(
              child: Container(
                color: overlayColor!.withOpacity(overlayOpacity),
              ),
            ),
        ],
      ),
    );
  }
}

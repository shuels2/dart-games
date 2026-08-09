import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/player.dart';

class PlayerAvatarWidget extends StatelessWidget {
  final Player player;
  final double size;
  final bool showName;
  final bool isHighlighted;

  const PlayerAvatarWidget({
    super.key,
    required this.player,
    this.size = 30.0,
    this.showName = false,
    this.isHighlighted = false,
  });

  // ─── Photo ImageProvider cache ──────────────────────────────────────────────
  //
  // Memoize the ResizeImage(NetworkImage|FileImage(photoPath)) wrapper by
  // photoPath. Without this, every PlayerAvatarWidget.build() — and the
  // gameplay screens rebuild via setState on every dart throw, touching
  // every visible avatar (up to 8 in Treasure Divide) — allocates fresh
  // NetworkImage + ResizeImage instances. While ImageProvider equality is
  // defined for both classes (so the image cache would still hit on key
  // lookup), repeated provider chain allocation + repeated Image-widget
  // stream-listener registration churn under heavy avatar density was
  // contributing to CanvasKit wasm-heap pressure that surfaces as
  // RuntimeError: Aborted() inside PictureRecorder. Memoization keeps one
  // canonical provider per (platform, photoPath) so Image widgets share
  // the same listener registration across rebuilds.
  static final Map<String, ImageProvider> _photoProviderCache = {};

  static ImageProvider _resolvePhotoProvider(String photoPath) {
    final existing = _photoProviderCache[photoPath];
    if (existing != null) return existing;

    // Evict every other entry for the SAME underlying photo before inserting
    // (WS04 4.8). Keys are cache-busted URLs (`.../avatar.png?v=1699…`), so a
    // player who re-uploads their headshot five times used to leave five
    // ResizeImage providers cached forever — each pinning up to ~1MB of
    // decoded pixels in an unbounded static map. Only the newest URL is ever
    // requested again, so the older ones are pure leak.
    final base = photoPath.split('?').first;
    _photoProviderCache.removeWhere((key, _) => key.split('?').first == base);

    final ImageProvider raw =
        kIsWeb ? NetworkImage(photoPath) : FileImage(File(photoPath));
    final provider = ResizeImage(raw, width: 512, height: 512);
    _photoProviderCache[photoPath] = provider;
    return provider;
  }

  /// Test hook: the cache is a static that otherwise persists across tests.
  @visibleForTesting
  static void clearPhotoProviderCacheForTesting() =>
      _photoProviderCache.clear();

  @visibleForTesting
  static int get photoProviderCacheSizeForTesting =>
      _photoProviderCache.length;

  ImageProvider? _getImageProvider() {
    if (player.photoPath == null) return null;

    // Cap the decoded bitmap dimensions. Without this, an uploaded 2250x1500
    // headshot decodes to ~13MB of pixel data and can exhaust the CanvasKit
    // wasm heap when several avatars render together — the symptom is a
    // RuntimeError: Aborted() inside PictureRecorder on every frame.
    //
    // 512px is ~2x the largest on-screen avatar (Treasure Divide active
    // player is 300px logical) — enough headroom for hi-DPI rendering while
    // keeping a single decoded headshot bounded to ~1MB of pixel data.
    // The previous cap was 256 (sized for an 80px max display) and became
    // smaller than the new 300px Treasure Divide active avatar, which
    // forced upscaling and lost crispness even though it didn't cause the
    // abort by itself.
    return _resolvePhotoProvider(player.photoPath!);
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      decoration: isHighlighted
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.amber,
                width: 3.0,
              ),
            )
          : null,
      child: CircleAvatar(
        radius: size,
        backgroundColor: Colors.grey[300],
        backgroundImage: _getImageProvider(),
        child: player.photoPath == null
            ? Icon(
                Icons.person,
                size: size * 1.2,
                color: Colors.grey[600],
              )
            : null,
      ),
    );

    // When the caller only wants the avatar, skip the Column entirely.
    // Wrapping the avatar in a Column(mainAxisSize.min) inside a strict
    // parent constraint (e.g. PirateAvatarWidget's Positioned.fill →
    // ClipOval → PlayerAvatarWidget) tripped a vertical overflow at
    // large sizes because Column layout + CircleAvatar's minDiameter
    // don't play well together when the child exactly matches the
    // parent height. Removing the Column when there's nothing to
    // stack lets the ClipOval size the avatar directly.
    if (!showName) return avatar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 4),
        Text(
          player.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

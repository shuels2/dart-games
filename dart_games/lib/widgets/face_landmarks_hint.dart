import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';

/// If the last `savePlayer` call left a face-landmarks detection
/// error on [PlayerProvider], show a short non-blocking snackbar so
/// the operator knows detection failed and can retake the photo or
/// hit "Re-detect" later from the player-edit UI.
///
/// Call this after `await playerProvider.savePlayer(player);` on
/// screens/widgets that add or edit a player with a photo. The
/// photo itself is always saved; this only hints that the themed
/// avatar overlay may look off until the landmarks are corrected.
///
/// No-op when there is no error (the field is cleared at the start
/// of every `savePlayer` call).
void showFaceLandmarksHintIfAny(BuildContext context) {
  if (!context.mounted) return;
  final provider = context.read<PlayerProvider>();
  final reason = provider.lastPhotoUploadFaceLandmarksError;
  if (reason == null || reason.isEmpty) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(faceLandmarksHintMessage(reason)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
    ),
  );
}

/// Maps a sidecar `errorReason` string to a short human-readable
/// operator hint. Kept pure so it can be unit-tested independently
/// of a BuildContext or ScaffoldMessenger.
///
/// Buckets:
///   - `no-face-detected` — the photo doesn't show a clear face.
///   - Every other reason (`python-not-found`, `sidecar-not-found`,
///     `sidecar-exit-N`, `timeout`, `unexpected-error`, etc.) — the
///     sidecar itself is unhealthy and the operator can't fix it
///     from the game UI; direct them to the diagnostics screen.
String faceLandmarksHintMessage(String reason) {
  if (reason.startsWith('no-face-detected')) {
    return "Face detection didn't find a clear face in the photo — the "
        'photo was saved, but themed avatars may look off. Try a '
        'clearer, front-facing photo, or use "Re-detect" from the '
        'player-edit screen once detection is happy again.';
  }
  return 'Face detection ran into a problem (${_shortReason(reason)}) — '
      'the photo was saved, but themed avatars may look off. Ask an '
      'admin to check Options → Admin Options → Diagnose face '
      'landmarks.';
}

/// Trim a sidecar reason string to a short parenthetical fit (the
/// full reason can span multiple lines and include stack traces).
String _shortReason(String reason) {
  final firstLine = reason.split('\n').first.trim();
  if (firstLine.length <= 80) return firstLine;
  return '${firstLine.substring(0, 77)}…';
}

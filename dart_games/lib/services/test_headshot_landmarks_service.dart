import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/player.dart';
import 'test_data_service.dart';

/// Loads manual landmark corrections that should be applied on top of
/// mediapipe's detection when "Load Test Data" runs.
///
/// The corrections live in `assets/common/test_headshot_landmarks.json`,
/// keyed by headshot filename (e.g. `headshot-07.png`). The file starts
/// out as `{}` and is populated by the "Export test-data landmark
/// overrides" action in System Settings, which the user then commits to
/// the repo so future builds ship with the corrections baked in.
///
/// Keying by filename (not player name or DB id) keeps the overrides
/// stable across test-data reshuffles and across the per-load random
/// UUIDs that `TestDataService.generateTestPlayers` produces.
class TestHeadshotLandmarksService {
  static const String _assetPath =
      'assets/common/test_headshot_landmarks.json';

  /// Returns the parsed override map (filename → landmarks). Missing /
  /// empty / unreadable file resolves to an empty map — callers fall
  /// through to mediapipe normally.
  static Future<Map<String, Map<String, dynamic>>> loadOverrides() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      if (raw.trim().isEmpty) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final out = <String, Map<String, dynamic>>{};
      decoded.forEach((k, v) {
        if (k is String && v is Map) {
          out[k] = Map<String, dynamic>.from(v);
        }
      });
      return out;
    } catch (_) {
      return const {};
    }
  }

  /// Returns the headshot filename that [TestDataService] pairs with
  /// the i-th generated player. Index `i` is 0-based.
  static String filenameForIndex(int i) {
    return 'headshot-${(i + 1).toString().padLeft(2, '0')}.png';
  }

  /// Walks the canonical test-data player list and returns a JSON map
  /// of `headshot-NN.png → landmarks` for every player that
  ///   (a) currently exists in [allPlayers] (matched by name), and
  ///   (b) has non-null `faceLandmarks`.
  ///
  /// Used by the export action so the user can dump their inspector-
  /// corrected landmarks into a file they can commit to the repo.
  static Map<String, Map<String, dynamic>> buildExportPayload(
    List<Player> allPlayers,
  ) {
    final canonical = TestDataService.generateTestPlayers();
    final byName = <String, Player>{
      for (final p in allPlayers) p.name: p,
    };
    final out = <String, Map<String, dynamic>>{};
    for (int i = 0; i < canonical.length; i++) {
      final match = byName[canonical[i].name];
      if (match?.faceLandmarks == null) continue;
      out[filenameForIndex(i)] = Map<String, dynamic>.from(
        match!.faceLandmarks!,
      );
    }
    return out;
  }
}

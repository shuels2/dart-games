/// One-shot script: re-key the manual landmark corrections in
/// `assets/common/test_headshot_landmarks.json` from each headshot's
/// PRE-canonical pixel space into its NEW post-canonical 512×512 square.
///
/// Reads:
/// - assets/common/test_headshot_landmarks.json
/// - assets/common/test_headshots/_pre_canonical_dimensions.json
///
/// Writes:
/// - assets/common/test_headshot_landmarks.json (transformed in place)
///
/// The math mirrors TestHeadshotLandmarksService.cropToSquare /
/// transformOverrideForCanonicalCrop (which are unit-tested under
/// test/services/). Inlined here because `dart run` can't load this
/// package — the lib/ side pulls in Flutter via rootBundle.
///
/// Run once after re-canonicalizing the test headshots, then delete the
/// _pre_canonical_dimensions.json sidecar:
///
///   dart run tool/transform_test_headshot_landmarks.dart
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

({double x, double y}) _cropToSquare(
  double normX,
  double normY, {
  required int oldW,
  required int oldH,
}) {
  final side = math.min(oldW, oldH);
  final cropX = (oldW - side) / 2.0;
  final cropY = (oldH - side) / 2.0;
  final px = normX * oldW - cropX;
  final py = normY * oldH - cropY;
  return (
    x: (px / side).clamp(0.0, 1.0),
    y: (py / side).clamp(0.0, 1.0),
  );
}

Map<String, dynamic> _transformOverride(
  Map<String, dynamic> override, {
  required int oldW,
  required int oldH,
}) {
  final out = <String, dynamic>{};
  override.forEach((key, value) {
    if (key == 'boundingBox' && value is Map) {
      final ox = (value['x'] as num).toDouble();
      final oy = (value['y'] as num).toDouble();
      final ow = (value['width'] as num).toDouble();
      final oh = (value['height'] as num).toDouble();
      final tl = _cropToSquare(ox, oy, oldW: oldW, oldH: oldH);
      final br = _cropToSquare(ox + ow, oy + oh, oldW: oldW, oldH: oldH);
      out[key] = {
        'x': tl.x,
        'y': tl.y,
        'width': (br.x - tl.x).clamp(0.0, 1.0),
        'height': (br.y - tl.y).clamp(0.0, 1.0),
      };
    } else if (value is Map &&
        value.containsKey('x') &&
        value.containsKey('y')) {
      final ox = (value['x'] as num).toDouble();
      final oy = (value['y'] as num).toDouble();
      final t = _cropToSquare(ox, oy, oldW: oldW, oldH: oldH);
      out[key] = {'x': t.x, 'y': t.y};
    } else {
      out[key] = value;
    }
  });
  return out;
}

void main() {
  const overridesPath = 'assets/common/test_headshot_landmarks.json';
  const dimsPath = 'assets/common/test_headshots/_pre_canonical_dimensions.json';

  final overrides =
      jsonDecode(File(overridesPath).readAsStringSync()) as Map<String, dynamic>;
  final dims =
      jsonDecode(File(dimsPath).readAsStringSync()) as Map<String, dynamic>;

  final out = <String, dynamic>{};
  var migrated = 0;
  for (final entry in overrides.entries) {
    final filename = entry.key;
    final landmarks = entry.value as Map<String, dynamic>;
    final dim = dims[filename] as Map<String, dynamic>?;
    if (dim == null) {
      stderr.writeln('skip $filename — no pre-canonical dimensions on record');
      out[filename] = landmarks;
      continue;
    }
    final oldW = (dim['w'] as num).toInt();
    final oldH = (dim['h'] as num).toInt();
    out[filename] = _transformOverride(landmarks, oldW: oldW, oldH: oldH);
    migrated++;
  }

  final encoder = const JsonEncoder.withIndent('  ');
  File(overridesPath).writeAsStringSync('${encoder.convert(out)}\n');
  stdout.writeln('Migrated $migrated overrides into 512×512 canonical space.');
}

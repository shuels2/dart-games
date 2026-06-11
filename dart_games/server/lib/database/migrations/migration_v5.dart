import 'package:sqlite3/sqlite3.dart' as sqlite3;
import '../migration.dart';

/// Adds the `face_landmarks` column to `players`.
///
/// Stores the MediaPipe face-landmarks JSON blob detected by the Python
/// sidecar on avatar upload. Coordinates are normalized 0..1 relative to
/// the avatar image dimensions so they survive server-side resizing.
///
/// Schema shape:
/// ```json
/// {
///   "boundingBox": {"x": 0.18, "y": 0.12, "width": 0.64, "height": 0.72},
///   "leftEye":     {"x": 0.34, "y": 0.40},
///   "rightEye":    {"x": 0.66, "y": 0.40},
///   "noseTip":     {"x": 0.50, "y": 0.55},
///   "mouthCenter": {"x": 0.50, "y": 0.72},
///   "confidence":  0.97
/// }
/// ```
///
/// The column is nullable — null means either no custom avatar has been
/// uploaded yet, or face detection failed / was skipped. The Flutter
/// [PirateAvatarWidget] falls back to heuristic placement when null.
class MigrationV5PlayerFaceLandmarks extends Migration {
  @override
  int get version => 5;

  @override
  String get description => 'Add face_landmarks column to players';

  @override
  void migrate(sqlite3.Database db) {
    db.execute(
      'ALTER TABLE players ADD COLUMN face_landmarks TEXT;',
    );
  }
}

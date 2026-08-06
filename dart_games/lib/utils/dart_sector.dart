/// Where a dart landed, parsed once from the board's sector notation.
///
/// The Scolia board's grammar is
/// `([SsDT])(20|1[0-9]|[1-9]) | 25 | Bull | None` — see
/// `MockScoliaApiService._convertToScoliaFormat`, which is the app's own
/// encoder for it. In that grammar:
///
/// - **`Bull` is the bullseye and scores 50.**
/// - **`25` is the ring around it and scores 25.**
/// - **There is no double bull.** `DBull` / `SBull` are not sectors the board
///   can report; any code branching on them is dead.
///
/// Until this type existed every game parsed the grammar itself. Nine private
/// `_parseSector` copies had drifted into four return shapes and — worse — two
/// of them scored `Bull` as 25, so a bullseye was worth half of what it should
/// have been in those games.
enum DartRing {
  miss,
  single,
  double,
  triple,

  /// The 25 ring. Scores 25.
  ring25,

  /// The bullseye. Scores 50.
  bull,
}

class DartSector {
  const DartSector._({
    required this.raw,
    required this.ring,
    required this.face,
  });

  /// The string the board reported, unchanged.
  final String raw;

  final DartRing ring;

  /// The segment number: 1-20 for the numbered ring, 25 for the 25 ring and
  /// the bullseye, 0 for a miss.
  final int face;

  static const DartSector _miss =
      DartSector._(raw: 'Miss', ring: DartRing.miss, face: 0);

  static final RegExp _segment = RegExp(r'^([SDTsdt])(\d+)$');

  /// Parses [sector]. Never throws and never returns null — anything
  /// unrecognised is a miss, which is what every caller did with a parse
  /// failure anyway.
  factory DartSector.parse(String? sector) {
    final raw = sector?.trim() ?? '';
    if (raw.isEmpty || raw == 'None' || raw == 'Miss' || raw == 'miss') {
      return _miss;
    }

    final lower = raw.toLowerCase();
    if (lower == 'bull') {
      return DartSector._(raw: raw, ring: DartRing.bull, face: 25);
    }
    if (raw == '25' || lower == 'outer bull') {
      return DartSector._(raw: raw, ring: DartRing.ring25, face: 25);
    }

    final match = _segment.firstMatch(raw);
    if (match == null) {
      return DartSector._(raw: raw, ring: DartRing.miss, face: 0);
    }

    final face = int.tryParse(match.group(2)!);
    if (face == null || face < 1 || face > 20) {
      return DartSector._(raw: raw, ring: DartRing.miss, face: 0);
    }

    switch (match.group(1)!.toUpperCase()) {
      case 'D':
        return DartSector._(raw: raw, ring: DartRing.double, face: face);
      case 'T':
        return DartSector._(raw: raw, ring: DartRing.triple, face: face);
      default:
        return DartSector._(raw: raw, ring: DartRing.single, face: face);
    }
  }

  bool get isMiss => ring == DartRing.miss;

  /// The bullseye (50).
  bool get isBullseye => ring == DartRing.bull;

  /// The 25 ring.
  bool get isRing25 => ring == DartRing.ring25;

  /// Either bull ring.
  bool get isBull => isBullseye || isRing25;

  bool get isDouble => ring == DartRing.double;
  bool get isTriple => ring == DartRing.triple;

  /// Points scored.
  ///
  /// Not `face * factor`: the bullseye is a single landing worth 50, not a
  /// double of anything.
  int get score {
    switch (ring) {
      case DartRing.miss:
        return 0;
      case DartRing.single:
        return face;
      case DartRing.double:
        return face * 2;
      case DartRing.triple:
        return face * 3;
      case DartRing.ring25:
        return 25;
      case DartRing.bull:
        return 50;
    }
  }

  /// 0 for a miss, 2 for a double, 3 for a triple, otherwise 1.
  ///
  /// Both bull rings report 1 — neither is a double. Use [score] for points.
  int get factor {
    switch (ring) {
      case DartRing.miss:
        return 0;
      case DartRing.double:
        return 2;
      case DartRing.triple:
        return 3;
      case DartRing.single:
      case DartRing.ring25:
      case DartRing.bull:
        return 1;
    }
  }

  /// `single` / `double` / `triple` / `miss`.
  ///
  /// Both bull rings report `single`. Games that treat the bullseye specially
  /// should check [isBullseye] rather than reading this.
  String get multiplierName {
    switch (ring) {
      case DartRing.miss:
        return 'miss';
      case DartRing.double:
        return 'double';
      case DartRing.triple:
        return 'triple';
      case DartRing.single:
      case DartRing.ring25:
      case DartRing.bull:
        return 'single';
    }
  }

  /// The number games historically stored: 50 for the bullseye, 25 for the
  /// 25 ring, otherwise the face value.
  int get legacyNumber => isBullseye ? 50 : face;

  /// Canonical display string: `S20`, `D16`, `T19`, `Bull`, `25`, `Miss`.
  String get label {
    switch (ring) {
      case DartRing.miss:
        return 'Miss';
      case DartRing.bull:
        return 'Bull';
      case DartRing.ring25:
        return '25';
      case DartRing.single:
        return 'S$face';
      case DartRing.double:
        return 'D$face';
      case DartRing.triple:
        return 'T$face';
    }
  }

  @override
  String toString() => 'DartSector($label)';

  @override
  bool operator ==(Object other) =>
      other is DartSector && other.ring == ring && other.face == face;

  @override
  int get hashCode => Object.hash(ring, face);
}

/// Where a dart landed, parsed once from the board's sector notation.
///
/// The Scolia board reports throws as short strings — `S20`, `D16`, `T19`,
/// `Bull`, `25`, `None` — and until this existed every game parsed them
/// itself. Nine private `_parseSector` copies had drifted into four different
/// return shapes (`number` vs `score`, `String` vs `int` multiplier, bull as
/// 50 vs 25), and small differences in what counted as a miss. This is the
/// single grammar; games adapt its fields to whatever shape they need.
///
/// Grammar accepted:
/// - `S<n>` / `D<n>` / `T<n>` (case-insensitive) — single, double, triple
/// - `Bull` / `SBull` — inner bull (50)
/// - `DBull` — the double ring of the bull, reported by some boards (50)
/// - `25` / `Outer Bull` — outer bull (25)
/// - `Miss`, `None`, empty, or anything unrecognised — a miss
enum DartRing { miss, single, double, triple, outerBull, innerBull }

class DartSector {
  const DartSector._({
    required this.raw,
    required this.ring,
    required this.face,
  });

  /// The string the board reported, unchanged.
  final String raw;

  final DartRing ring;

  /// The segment number: 1-20 for the numbered ring, 25 for either bull,
  /// 0 for a miss.
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
    if (lower == 'bull' || lower == 'sbull' || lower == 'dbull') {
      // Boards differ on whether the inner bull is reported as a double of
      // the 25 ring; both mean the same 50 points.
      return DartSector._(raw: raw, ring: DartRing.innerBull, face: 25);
    }
    if (raw == '25' || lower == 'outer bull') {
      return DartSector._(raw: raw, ring: DartRing.outerBull, face: 25);
    }

    final match = _segment.firstMatch(raw);
    if (match == null) return DartSector._(raw: raw, ring: DartRing.miss, face: 0);

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
  bool get isInnerBull => ring == DartRing.innerBull;
  bool get isOuterBull => ring == DartRing.outerBull;
  bool get isBull => isInnerBull || isOuterBull;
  bool get isDouble => ring == DartRing.double;
  bool get isTriple => ring == DartRing.triple;

  /// 0 for a miss, 1 single/outer bull, 2 double/inner bull, 3 triple.
  ///
  /// The inner bull counts as 2 because it is the double of the 25 ring —
  /// which is how "any double" rounds treat it.
  int get factor {
    switch (ring) {
      case DartRing.miss:
        return 0;
      case DartRing.single:
      case DartRing.outerBull:
        return 1;
      case DartRing.double:
      case DartRing.innerBull:
        return 2;
      case DartRing.triple:
        return 3;
    }
  }

  /// Points scored: face × factor, so 50 for the inner bull and 25 for outer.
  int get score => face * factor;

  /// `single` / `double` / `triple` / `miss`.
  ///
  /// Both bulls report `single`, matching how most games treat them when they
  /// only care about the score. Games that distinguish the bull should check
  /// [isBull] rather than this.
  String get multiplierName {
    switch (ring) {
      case DartRing.miss:
        return 'miss';
      case DartRing.double:
        return 'double';
      case DartRing.triple:
        return 'triple';
      case DartRing.single:
      case DartRing.outerBull:
      case DartRing.innerBull:
        return 'single';
    }
  }

  /// The number games historically stored: 50 for the inner bull, 25 for the
  /// outer, otherwise the face value.
  int get legacyNumber => isInnerBull ? 50 : face;

  /// Canonical display string: `S20`, `D16`, `T19`, `Bull`, `25`, `Miss`.
  String get label {
    switch (ring) {
      case DartRing.miss:
        return 'Miss';
      case DartRing.innerBull:
        return 'Bull';
      case DartRing.outerBull:
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

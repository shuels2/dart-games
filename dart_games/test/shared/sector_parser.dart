/// Shared sector parsing logic for dart notation
///
/// Parses dart sector strings like "S20", "D20", "T20", "Bull", "Miss"
/// Returns unified format: {'number': int, 'multiplier': String}
class SectorParser {
  /// Parse a sector string into number and multiplier
  ///
  /// Examples:
  /// - "S20" → {'number': 20, 'multiplier': 'single'}
  /// - "D20" → {'number': 20, 'multiplier': 'double'}
  /// - "T20" → {'number': 20, 'multiplier': 'triple'}
  /// - "Bull" → {'number': 50, 'multiplier': 'single'}
  /// - "25" → {'number': 25, 'multiplier': 'single'}
  /// - "Miss" → {'number': 0, 'multiplier': 'miss'}
  /// - "None" → null (treated as miss)
  static Map<String, dynamic>? parse(String sector) {
    // Handle bulls
    if (sector == 'Bull') {
      return {'number': 50, 'multiplier': 'single'};
    }
    if (sector == '25' || sector == 'Outer Bull') {
      return {'number': 25, 'multiplier': 'single'};
    }

    // Handle miss
    if (sector == 'Miss' || sector == 'None' || sector.isEmpty) {
      return {'number': 0, 'multiplier': 'miss'};
    }

    // Parse regular sectors (S20, D20, T20, etc.)
    final match = RegExp(r'^([SDTsdt])(\d+)$').firstMatch(sector);
    if (match == null) return null;

    final multiplierChar = match.group(1)!.toUpperCase();
    final number = int.parse(match.group(2)!);

    String multiplier;
    switch (multiplierChar) {
      case 'S':
        multiplier = 'single';
        break;
      case 'D':
        multiplier = 'double';
        break;
      case 'T':
        multiplier = 'triple';
        break;
      default:
        return null;
    }

    return {'number': number, 'multiplier': multiplier};
  }

  /// Get score value from sector string
  ///
  /// Examples:
  /// - "S20" → 20
  /// - "D20" → 40
  /// - "T20" → 60
  /// - "Bull" → 50
  /// - "Miss" → 0
  static int getScore(String sector) {
    final parsed = parse(sector);
    if (parsed == null) return 0;

    final number = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as String;

    switch (multiplier) {
      case 'single':
      case 'miss':
        return number;
      case 'double':
        return number * 2;
      case 'triple':
        return number * 3;
      default:
        return 0;
    }
  }

  /// Convert to Carnival Derby format
  ///
  /// Carnival Derby uses: {'score': int, 'multiplier': String}
  /// Special handling for bullseye
  static Map<String, dynamic>? toCarnivalDerbyFormat(String sector) {
    final parsed = parse(sector);
    if (parsed == null) return null;

    final number = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as String;

    // Special case: bullseye
    if (number == 50 && multiplier == 'single') {
      return {'score': 50, 'multiplier': 'bullseye'};
    }

    // Regular scoring
    return {'score': getScore(sector), 'multiplier': multiplier};
  }
}

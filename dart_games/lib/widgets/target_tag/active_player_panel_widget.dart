import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/test_keys.dart';
import '../../models/player.dart';

class ActivePlayerPanelWidget extends StatelessWidget {
  final Player player;
  final int currentShields;
  final int shieldMax;
  final int targetNumber;
  final int? soloHeroBuffNumber;
  final String? soloHeroBuffMultiplier; // "double" or "triple"
  final bool isTaggedIn;
  final List<String> dartSegments; // D1, D2, D3
  final List<bool> dartTaggedInStatus; // Was tagged in when each dart was thrown
  final List<bool> dartHeroBonusHit; // Did each dart hit the hero bonus
  final List<bool> dartReachedMax; // Did each dart cause shields to reach max
  final List<bool> dartCausedElimination; // Did each dart cause an elimination
  final List<bool> dartHitOpponentTarget; // Did each dart hit an opponent's target (at time of throw)
  final List<int> opponentTargetNumbers; // Other players' target numbers
  final VoidCallback? onSkipTurn; // Callback for skipping turn

  const ActivePlayerPanelWidget({
    super.key,
    required this.player,
    required this.currentShields,
    required this.shieldMax,
    required this.targetNumber,
    this.soloHeroBuffNumber,
    this.soloHeroBuffMultiplier,
    required this.isTaggedIn,
    required this.dartSegments,
    this.dartTaggedInStatus = const [],
    this.dartHeroBonusHit = const [],
    this.dartReachedMax = const [],
    this.dartCausedElimination = const [],
    this.dartHitOpponentTarget = const [],
    this.opponentTargetNumbers = const [],
    this.onSkipTurn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E).withOpacity(0.85), // Slightly lighter than background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF007A), // Pink border
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar (larger, spans multiple rows)
          if (player.photoPath != null)
            CircleAvatar(
              radius: 50,
              backgroundImage: player.photoPath!.startsWith('data:')
                  ? MemoryImage(Uri.parse(player.photoPath!).data!.contentAsBytes())
                  : NetworkImage(player.photoPath!) as ImageProvider,
            )
          else
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFFF007A),
              child: Text(
                player.name[0].toUpperCase(),
                style: GoogleFonts.fredoka(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(width: 16),

          // Name, shields, and Skip Turn button
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                player.name,
                key: TargetTagGameKeys.activePlayerName,
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Shields: $currentShields/$shieldMax',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  color: const Color(0xFFFFD700), // Arcade gold
                ),
              ),
              // Skip Turn Button
              if (onSkipTurn != null) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  key: TargetTagGameKeys.skipTurnButton,
                  onPressed: onSkipTurn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF007A).withOpacity(0.85),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Skip turn',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          // Target number(s) and Tagged In indicator - centered
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    isTaggedIn ? 'Opponent targets: ' : 'Target number: ',
                    key: isTaggedIn
                        ? TargetTagGameKeys.activePlayerOpponentTargetsLabel
                        : TargetTagGameKeys.activePlayerTargetLabel,
                    style: GoogleFonts.fredoka(
                      fontSize: 26, // Increased from 24
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8), // Padding between label and number
                  Transform.translate(
                    offset: const Offset(0, 5), // Move down 5px
                    child: Text(
                      isTaggedIn
                          ? opponentTargetNumbers.join(', ')
                          : '$targetNumber',
                      key: isTaggedIn
                          ? TargetTagGameKeys.activePlayerOpponentTargetsValue
                          : TargetTagGameKeys.activePlayerTargetValue,
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 32, // Increased from 30
                        color: const Color(0xFFFF007A), // Pink
                      ),
                    ),
                  ),
                  if (soloHeroBuffNumber != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      '|',
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Buff: ',
                      key: TargetTagGameKeys.activePlayerBuffLabel,
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8), // Padding between label and number
                    Transform.translate(
                      offset: const Offset(0, 5), // Move down 5px
                      child: Text(
                        _formatBuffNumber(soloHeroBuffNumber!, soloHeroBuffMultiplier),
                        key: TargetTagGameKeys.activePlayerBuffValue,
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 30, // Increased from 28
                          color: const Color(0xFFFFD700), // Arcade gold for buff
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isTaggedIn) ...[
                const SizedBox(height: 8),
                Container(
                  key: TargetTagGameKeys.activePlayerTaggedInBadge,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700), // Arcade gold for tagged in
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'TAGGED IN',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          // Dart throws (D1, D2, D3) - on the right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDartDisplay('D1', 0),
              const SizedBox(width: 16), // Increased spacing
              _buildDartDisplay('D2', 1),
              const SizedBox(width: 16), // Increased spacing
              _buildDartDisplay('D3', 2),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBuffNumber(int number, String? multiplier) {
    if (multiplier == null) return '$number';
    final prefix = multiplier == 'double' ? 'D' : 'T';
    return '$prefix$number';
  }

  int? _parseSegmentNumber(String segment) {
    if (segment.isEmpty || segment == 'Miss') return null;

    // Remove multiplier prefix (S, D, T) - case insensitive
    final numberStr = segment.replaceAll(RegExp(r'[SDTsdt]'), '');
    return int.tryParse(numberStr);
  }

  Color _getDartBoxColor(int dartIndex) {
    // If no dart thrown yet, show empty state
    if (dartIndex >= dartSegments.length) return Colors.white24;

    final segment = dartSegments[dartIndex];
    if (segment.isEmpty) return Colors.white24;

    // Check for hero bonus hit (highest priority - gold pulse)
    if (dartIndex < dartHeroBonusHit.length && dartHeroBonusHit[dartIndex]) {
      return const Color(0xFFFFD700); // Arcade gold for hero bonus
    }

    // Check if this dart reached max shields (green border)
    if (dartIndex < dartReachedMax.length && dartReachedMax[dartIndex]) {
      return const Color(0xFF00FFA3); // Green for reaching max shields
    }

    // Check if this dart caused an elimination (gold border, persists)
    if (dartIndex < dartCausedElimination.length && dartCausedElimination[dartIndex]) {
      return const Color(0xFFFFD700); // Gold for elimination
    }

    final hitNumber = _parseSegmentNumber(segment);
    if (hitNumber == null) return const Color(0xFFFF007A); // Pink for miss

    // Get tagged-in status at the time this dart was thrown
    final wasTaggedIn = dartIndex < dartTaggedInStatus.length ? dartTaggedInStatus[dartIndex] : false;

    // Use the tagged-in status AT THE TIME the dart was thrown
    if (!wasTaggedIn) {
      // NOT tagged in when thrown: Hitting own target = GREEN (building shields)
      if (hitNumber == targetNumber) {
        return const Color(0xFF00FFA3);
      }
      // Hitting opponent number = PINK (can't attack yet)
      return const Color(0xFFFF007A);
    }

    // Was tagged in when thrown:
    // Hitting own target = PINK (no benefit)
    if (hitNumber == targetNumber) {
      return const Color(0xFFFF007A);
    }

    // Check if this dart hit an opponent's target at the time it was thrown (persists even if opponent eliminated)
    if (dartIndex < dartHitOpponentTarget.length && dartHitOpponentTarget[dartIndex]) {
      return const Color(0xFFFFD700); // Gold for attacking opponent (persists after elimination)
    }

    return const Color(0xFFFF007A); // Pink for miss (includes opponent's hero buffs)
  }

  Widget _buildDartDisplay(String label, int dartIndex) {
    final segment = dartIndex < dartSegments.length ? dartSegments[dartIndex] : '';
    final isHeroBonusHit = dartIndex < dartHeroBonusHit.length && dartHeroBonusHit[dartIndex];
    final borderColor = _getDartBoxColor(dartIndex);

    // Map label to key (D1 -> d1_indicator, D2 -> d2_indicator, D3 -> d3_indicator)
    final indicatorKey = label == 'D1'
        ? TargetTagGameKeys.activePlayerD1Indicator
        : label == 'D2'
            ? TargetTagGameKeys.activePlayerD2Indicator
            : TargetTagGameKeys.activePlayerD3Indicator;

    Widget dartBox = Container(
      key: indicatorKey,
      width: 70,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E), // Dark background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          segment.isEmpty ? '-' : (segment == 'Miss' ? 'Miss' : segment),
          style: GoogleFonts.fredoka(
            fontSize: 18, // Increased from 14
            fontWeight: FontWeight.bold,
            color: segment.isEmpty ? Colors.white38 : Colors.white,
          ),
        ),
      ),
    );

    // Add pulse animation for hero bonus hits
    if (isHeroBonusHit) {
      dartBox = _PulsingGoldBorder(child: dartBox);
    }

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 16, // Increased from 12
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        dartBox,
      ],
    );
  }
}

// Pulsing gold border animation for hero bonus hits
class _PulsingGoldBorder extends StatefulWidget {
  final Widget child;

  const _PulsingGoldBorder({required this.child});

  @override
  State<_PulsingGoldBorder> createState() => _PulsingGoldBorderState();
}

class _PulsingGoldBorderState extends State<_PulsingGoldBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.8 * _animation.value),
                blurRadius: 15 * _animation.value,
                spreadRadius: 4 * _animation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

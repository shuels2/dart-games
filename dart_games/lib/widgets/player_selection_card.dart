import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/player.dart';
import 'player_avatar_widget.dart';

class PlayerSelectionCard extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool compact;
  final Color? selectedColor;
  final Color? selectedBorderColor;
  final Key? removeButtonKey;
  final TextStyle? nameStyle;
  final double? nameStatsSpacing;
  final Color? unselectedBackgroundColor;
  final Color? unselectedBorderColor;
  final TextStyle? statsStyle;
  final Color? checkIconColor;
  final Color? removeIconColor;
  final Widget? trailing;

  const PlayerSelectionCard({
    super.key,
    required this.player,
    required this.isSelected,
    required this.onTap,
    this.onRemove,
    this.compact = false,
    this.selectedColor,
    this.selectedBorderColor,
    this.removeButtonKey,
    this.nameStyle,
    this.nameStatsSpacing,
    this.unselectedBackgroundColor,
    this.unselectedBorderColor,
    this.statsStyle,
    this.checkIconColor,
    this.removeIconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final defaultSelectedColor = selectedColor ?? const Color(0xFFFFD700); // Canary Yellow
    final defaultSelectedBorderColor = selectedBorderColor ?? const Color(0xFFFFD700); // Canary Yellow

    if (compact) {
      return _buildCompactCard();
    }

    final defaultUnselectedBg = unselectedBackgroundColor ?? const Color(0xFF1D3557);
    final defaultUnselectedBorder = unselectedBorderColor ?? const Color(0xFF48CAE4);
    final defaultStatsStyle = statsStyle ?? GoogleFonts.montserrat(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFF1FAEE).withOpacity(0.8),
    );
    final defaultCheckColor = checkIconColor ?? const Color(0xFF48CAE4);
    final defaultRemoveColor = removeIconColor ?? const Color(0xFFE63946);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected
            ? defaultSelectedColor.withOpacity(0.2)  // Selected tint
            : defaultUnselectedBg.withOpacity(0.6),
        border: Border.all(
          color: isSelected
              ? defaultSelectedBorderColor  // Selected border
              : defaultUnselectedBorder,
          width: isSelected ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                PlayerAvatarWidget(
                  player: player,
                  size: 22.0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: nameStyle ?? GoogleFonts.montserrat(
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFFF1FAEE), // Cloud Dancer
                        ),
                      ),
                      SizedBox(height: nameStatsSpacing ?? 2),
                      Text(
                        'Games: ${player.gamesPlayed} | Wins: ${player.gamesWon}',
                        style: defaultStatsStyle,
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (isSelected && onRemove != null)
                  IconButton(
                    key: removeButtonKey,
                    icon: Icon(Icons.remove_circle, color: defaultRemoveColor),
                    iconSize: 24,
                    onPressed: onRemove,
                  )
                else if (isSelected)
                  Icon(Icons.check_circle, color: defaultCheckColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    final defaultSelectedColor = selectedColor ?? const Color(0xFFFFD700); // Canary Yellow
    final defaultSelectedBorderColor = selectedBorderColor ?? const Color(0xFFFFD700); // Canary Yellow
    final defaultRemoveColor = removeIconColor ?? const Color(0xFFE63946);
    final defaultCompactStatsStyle = statsStyle ?? GoogleFonts.montserrat(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFF1FAEE).withOpacity(0.8),
    );

    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: defaultSelectedColor.withOpacity(0.2), // Selected tint
        border: Border.all(
          color: defaultSelectedBorderColor, // Selected border
          width: 3,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: PlayerAvatarWidget(
                        player: player,
                        size: 16.0,
                      ),
                    ),
                    if (onRemove != null)
                      GestureDetector(
                        onTap: onRemove,
                        child: Icon(
                          Icons.remove_circle,
                          color: defaultRemoveColor,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  player.name,
                  style: nameStyle ?? GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: const Color(0xFFF1FAEE), // Cloud Dancer
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: nameStatsSpacing ?? 2),
                Text(
                  'G: ${player.gamesPlayed}',
                  style: defaultCompactStatsStyle,
                ),
                Text(
                  'W: ${player.gamesWon}',
                  style: defaultCompactStatsStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

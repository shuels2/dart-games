import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// A CSS-inspired concentric circle "target" background for carnival game logo.
///
/// Features:
/// - Radial gradient with hard stops for crisp rings
/// - Color palette: Red center, Off-White, Teal, Navy outer
/// - 3D painted wood effect with shadows
/// - Vintage carnival aesthetic with subtle texture
class CarnivalTargetLogo extends StatelessWidget {
  final double size;

  const CarnivalTargetLogo({
    super.key,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Perfect circle
        shape: BoxShape.circle,

        // Radial gradient with hard stops (no blending)
        // 7 rings total with HIGHLY varying widths (minimum 16px)
        // Pattern: Red, White, Light Blue, Red, White, Light Blue, Navy
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.5,
          colors: [
            Color(0xFFE63946), // Ring 1: Red (center) - wide
            Color(0xFFE63946), // Hard stop
            Color(0xFFF1FAEE), // Ring 2: White - narrow
            Color(0xFFF1FAEE), // Hard stop
            Color(0xFF457B9D), // Ring 3: Light Blue - extra wide
            Color(0xFF457B9D), // Hard stop
            Color(0xFFE63946), // Ring 4: Red - medium
            Color(0xFFE63946), // Hard stop
            Color(0xFFF1FAEE), // Ring 5: White - narrow
            Color(0xFFF1FAEE), // Hard stop
            Color(0xFF457B9D), // Ring 6: Light Blue - wide
            Color(0xFF457B9D), // Hard stop
            Color(0xFF1D3557), // Ring 7: Navy (outer) - medium
            Color(0xFF1D3557), // Hard stop
          ],
          stops: [
            0.0,    // Red center start
            0.28,   // Red end (98px - extra wide)
            0.28,   // White start (hard stop)
            0.33,   // White end (17.5px - narrow)
            0.33,   // Light Blue start (hard stop)
            0.53,   // Light Blue end (70px - extra wide)
            0.53,   // Red start (hard stop)
            0.66,   // Red end (45.5px - medium)
            0.66,   // White start (hard stop)
            0.71,   // White end (17.5px - narrow)
            0.71,   // Light Blue start (hard stop)
            0.87,   // Light Blue end (56px - wide)
            0.87,   // Navy start (hard stop)
            1.0,    // Navy end (45.5px - medium)
          ],
        ),

        // Heavy frame border
        border: Border.all(
          color: const Color(0xFF1D3557), // Navy
          width: 8.0,
        ),

        // 3D "painted wood" depth with shadows
        boxShadow: [
          // Thick dark navy outer shadow
          BoxShadow(
            color: const Color(0xFF1D3557).withOpacity(0.8),
            blurRadius: 10,
            spreadRadius: 5,
            offset: const Offset(0, 4),
          ),
          // Subtle outer glow for depth
          BoxShadow(
            color: const Color(0xFF1D3557).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Noise/grain overlay for vintage carnival wood texture
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
          child: Container(
            decoration: BoxDecoration(
              // Subtle noise pattern overlay
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.0,
                colors: [
                  Colors.white.withOpacity(0.03),
                  Colors.black.withOpacity(0.03),
                  Colors.white.withOpacity(0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
            // Inset shadow for painted wood depth
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  // Subtle inset shadow effect
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

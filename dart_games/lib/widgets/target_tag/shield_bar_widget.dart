import 'package:flutter/material.dart';

class ShieldBarWidget extends StatelessWidget {
  final int currentShields;
  final int shieldMax;
  final Color filledColor;
  final Color emptyColor;
  final double height;

  const ShieldBarWidget({
    super.key,
    required this.currentShields,
    required this.shieldMax,
    this.filledColor = const Color(0xFFFFD700), // Arcade gold
    this.emptyColor = const Color(0xFF4A4A4A), // Dark gray
    this.height = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    // Create segments based on shieldMax
    return Row(
      children: List.generate(
        shieldMax,
        (index) => Expanded(
          child: Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: index < currentShields ? filledColor : emptyColor,
              border: Border.all(
                color: Colors.black,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

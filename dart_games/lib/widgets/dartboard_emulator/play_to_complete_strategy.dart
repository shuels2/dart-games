import 'package:flutter/widgets.dart';

class SimulatedThrow {
  final int score;
  final String multiplier;
  final int baseScore;

  const SimulatedThrow({
    required this.score,
    required this.multiplier,
    required this.baseScore,
  });

  @override
  String toString() => 'SimulatedThrow($multiplier $baseScore = $score)';
}

abstract class PlayToCompleteStrategy {
  SimulatedThrow? getNextThrow(BuildContext context);
  bool isGameComplete(BuildContext context);
  bool shouldAutoTakeout(BuildContext context);
}

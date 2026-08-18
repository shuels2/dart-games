import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// The confetti burst every results screen fires on victory.
///
/// WS03 §3.7. Five results screens each carried the same scaffolding: a
/// `ConfettiController` field, its construction with a duration, `play()` on a
/// delay, `dispose()`, and then THREE `ConfettiWidget`s — top-left, top-centre
/// and top-right — whose emission frequency, particle count, gravity and full
/// colour list were written out once per emitter. Nine copies of the same
/// parameter block per screen, forty-five across the app.
///
/// The colours are the one thing that genuinely differs per game, so they are
/// the required argument. Everything else has the shared default and can be
/// overridden where a game means to differ.
class VictoryCelebrationOverlay extends StatelessWidget {
  const VictoryCelebrationOverlay({
    super.key,
    required this.controller,
    required this.colors,
    this.emissionFrequency = 0.05,
    this.numberOfParticles = 30,
    this.numberOfParticlesFor,
    this.gravity = 0.1,
    this.alignments = defaultAlignments,
  });

  final ConfettiController controller;

  /// This game's confetti palette.
  final List<Color> colors;

  final double emissionFrequency;
  final int numberOfParticles;

  /// Per-emitter particle count, when a game's emitters differ.
  ///
  /// Carnival Derby fires 30 particles from the centre and 20 from each
  /// corner — a heavier central burst. That is a real difference in what the
  /// screen looks like, so it is expressible rather than averaged away.
  /// Null means every emitter uses [numberOfParticles].
  final int Function(Alignment alignment)? numberOfParticlesFor;

  final double gravity;

  /// Where the emitters sit. Each blasts inward-and-down from its corner.
  final List<Alignment> alignments;

  /// Top-left, top-centre, top-right — the arrangement all five screens used.
  static const List<Alignment> defaultAlignments = [
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
  ];

  /// Blast direction for an emitter, in radians.
  ///
  /// The screens hard-coded `pi / 4`, `pi / 2`, `3 * pi / 4` alongside their
  /// alignments — two lists that had to stay in step by hand. Deriving the
  /// angle from the alignment keeps them in step by construction.
  static double blastDirectionFor(Alignment alignment) {
    if (alignment.x < 0) return pi / 4; // from the left, aimed down-right
    if (alignment.x > 0) return 3 * pi / 4; // from the right, aimed down-left
    return pi / 2; // straight down
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final alignment in alignments)
          Align(
            alignment: alignment,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirection: blastDirectionFor(alignment),
              emissionFrequency: emissionFrequency,
              numberOfParticles:
                  numberOfParticlesFor?.call(alignment) ?? numberOfParticles,
              gravity: gravity,
              colors: colors,
            ),
          ),
      ],
    );
  }
}

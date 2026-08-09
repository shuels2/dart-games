import 'package:flutter/material.dart';

/// The chrome every full-screen game modal sits inside.
///
/// WS03 §3.7. DartboardPausedModal, SaveGameModal, ResumeGameModal and
/// RemoveDartsModal each open with the same stack:
///
///   Positioned.fill > Material(transparency) > 0.7-black barrier > Center
///     > ConstrainedBox(maxWidth) > Container(margin, padding, decoration)
///
/// Four copies of the same barrier opacity, blur radius and spread. Divergence
/// there is the kind nobody notices until two modals look subtly different on
/// the same screen.
///
/// Only the chrome is shared. The contents stay entirely each modal's own —
/// these differ far too much to template.
class ThemedModalShell extends StatelessWidget {
  const ThemedModalShell({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.backgroundOpacity = 1.0,
    this.borderWidth = 4.0,
    this.borderRadius = 12.0,
    this.boxShadowColor = Colors.black,
    this.boxShadowOpacity = 0.5,
    this.maxWidth = double.infinity,
    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.all(32),
    this.barrierOpacity = defaultBarrierOpacity,
    this.barrierKey,
    this.panelKey,
  });

  /// The modal's own content, below the chrome.
  final Widget child;

  final Color backgroundColor;
  final double backgroundOpacity;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Color boxShadowColor;
  final double boxShadowOpacity;

  /// `double.infinity` means "no width cap" — RemoveDartsModal uses that, and
  /// the ConstrainedBox is skipped entirely rather than being given an
  /// infinite constraint.
  final double maxWidth;

  final EdgeInsets margin;
  final EdgeInsets padding;

  /// How dark the scrim behind the modal is.
  final double barrierOpacity;

  /// Keys the UI suites match on. They sit on the barrier and the panel
  /// respectively, so they must be passed through rather than living on the
  /// shell itself — `getSaveGameModalOverlay()` looks for the barrier.
  final Key? barrierKey;
  final Key? panelKey;

  /// Shared across all four modals. Named so a change is a deliberate,
  /// one-place decision rather than four independent literals drifting.
  static const double defaultBarrierOpacity = 0.7;

  /// Shared glow geometry, likewise previously restated per modal.
  static const double shadowBlurRadius = 20;
  static const double shadowSpreadRadius = 5;

  @override
  Widget build(BuildContext context) {
    Widget panel = Container(
      key: panelKey,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(backgroundOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: boxShadowColor.withOpacity(boxShadowOpacity),
            blurRadius: shadowBlurRadius,
            spreadRadius: shadowSpreadRadius,
          ),
        ],
      ),
      child: child,
    );

    if (maxWidth != double.infinity) {
      panel = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: panel,
      );
    }

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          key: barrierKey,
          color: Colors.black.withOpacity(barrierOpacity),
          child: Center(child: panel),
        ),
      ),
    );
  }
}

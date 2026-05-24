import 'package:flutter/material.dart';
import 'dartboard_emulator_config.dart';

/// One row of data driving a single buff-toggle button.
///
/// [buff] is the enum value the parent toggles. The parent owns the
/// callback shape, so the spec just carries the enum + display state
/// and the column hands the enum back through [BuffToggleColumn.onToggle]
/// when the user taps.
class BuffToggleSpec<T> {
  final T buff;
  final String label;
  final bool isActive;
  final bool isEnabled;
  final Key? buttonKey;
  final BuffToggleButtonConfig config;

  const BuffToggleSpec({
    required this.buff,
    required this.label,
    required this.isActive,
    required this.isEnabled,
    required this.config,
    this.buttonKey,
  });
}

/// Vertical column of buff-toggle buttons that flanks the dartboard
/// emulator. Each button shows the buff name on two lines; tapping
/// fires [onToggle] with the buff enum value.
///
/// When [BuffToggleSpec.isEnabled] is false the button still renders
/// but is non-tappable and dimmed — this is the state when the game
/// is running but Bonus Buffs is OFF in the options. The user can see
/// the affordance but can't toggle a buff that the active game won't
/// honor anyway.
class BuffToggleColumn<T> extends StatelessWidget {
  final List<BuffToggleSpec<T>> specs;
  final void Function(T buff) onToggle;

  /// Approximate button footprint. Width keeps long names like
  /// "Laboratory Spark" on two lines at fontSize 11.
  static const double buttonWidth = 92;
  static const double buttonHeight = 52;
  static const double verticalGap = 8;

  const BuffToggleColumn({
    super.key,
    required this.specs,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (specs.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < specs.length; i++) ...[
          if (i > 0) const SizedBox(height: verticalGap),
          _BuffToggleButton<T>(spec: specs[i], onToggle: onToggle),
        ],
      ],
    );
  }
}

class _BuffToggleButton<T> extends StatelessWidget {
  final BuffToggleSpec<T> spec;
  final void Function(T buff) onToggle;

  const _BuffToggleButton({required this.spec, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cfg = spec.config;
    final bg = spec.isActive
        ? cfg.activeBackgroundColor
        : cfg.inactiveBackgroundColor;
    final textStyle =
        spec.isActive ? cfg.activeTextStyle : cfg.inactiveTextStyle;

    final button = SizedBox(
      width: BuffToggleColumn.buttonWidth,
      height: BuffToggleColumn.buttonHeight,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: spec.buttonKey,
          borderRadius: BorderRadius.circular(8),
          onTap: spec.isEnabled ? () => onToggle(spec.buff) : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cfg.borderColor,
                width: spec.isActive ? 2.5 : 1.5,
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              spec.label,
              textAlign: TextAlign.center,
              style: textStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    // Disabled state: half opacity so the user can see the affordance
    // exists but understands it's not actionable while bonus buffs is
    // off in the game's options.
    if (!spec.isEnabled) {
      return Opacity(opacity: 0.4, child: button);
    }
    return button;
  }
}

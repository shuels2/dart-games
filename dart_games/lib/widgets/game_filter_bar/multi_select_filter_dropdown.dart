import 'package:flutter/material.dart';

/// A pill-shaped button that opens a menu of checkbox tiles for multi-select.
///
/// Closing the menu (outside-tap or pressing Escape) commits the current
/// selection. Toggling a checkbox does NOT close the menu — the user can
/// pick multiple values per filter in a single open. The internal selection
/// is reflected in real time via [onChanged] so the home screen's filtered
/// game list updates as the user toggles.
///
/// Visual: Material `OutlinedButton` look — neutral border, light fill,
/// label + selected-count indicator on the right. Matches the home-screen
/// theme (default Material 3 colors, no game-specific accent).
class MultiSelectFilterDropdown<T> extends StatefulWidget {
  /// The user-visible label (e.g. "Max Players").
  final String label;

  /// Test key applied to the trigger button so UI tests can locate it.
  final Key? buttonKey;

  /// All available options. Each entry maps a value to its display label.
  final Map<T, String> options;

  /// Currently-selected values (a subset of `options.keys`).
  /// Empty = "no filter applied for this criterion" (treated as "all").
  final Set<T> selected;

  /// Called whenever the selection changes (after a checkbox toggle).
  final ValueChanged<Set<T>> onChanged;

  /// Test key applied to each menu item — caller computes per-value keys.
  final Key Function(T value)? menuItemKey;

  const MultiSelectFilterDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.buttonKey,
    this.menuItemKey,
  });

  @override
  State<MultiSelectFilterDropdown<T>> createState() =>
      _MultiSelectFilterDropdownState<T>();
}

class _MultiSelectFilterDropdownState<T>
    extends State<MultiSelectFilterDropdown<T>> {
  final GlobalKey _buttonKey = GlobalKey();

  Future<void> _open() async {
    final RenderBox button =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context)
        .overlay!
        .context
        .findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomLeft(Offset.zero),
            ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    // Maintain a local copy so toggles don't close the menu — we only
    // commit-via-callback, the menu rebuilds in place via StatefulBuilder.
    final working = Set<T>.from(widget.selected);

    await showMenu<void>(
      context: context,
      position: position,
      items: [
        for (final entry in widget.options.entries)
          PopupMenuItem<void>(
            key: widget.menuItemKey?.call(entry.key),
            // padding=0 so CheckboxListTile fills the item; enabled=false
            // disables the auto-dismiss-on-tap behaviour of PopupMenuItem.
            padding: EdgeInsets.zero,
            // ignore: deprecated_member_use
            enabled: false,
            child: StatefulBuilder(
              builder: (context, setMenuState) {
                final isSelected = working.contains(entry.key);
                return CheckboxListTile(
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: isSelected,
                  title: Text(entry.value),
                  onChanged: (next) {
                    setMenuState(() {
                      if (next == true) {
                        working.add(entry.key);
                      } else {
                        working.remove(entry.key);
                      }
                    });
                    widget.onChanged(Set.unmodifiable(working));
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = widget.selected.length;
    final summary = selectedCount == 0
        ? widget.label
        : '${widget.label} ($selectedCount)';

    return OutlinedButton(
      key: widget.buttonKey ?? _buttonKey,
      onPressed: _open,
      style: OutlinedButton.styleFrom(
        backgroundColor: selectedCount > 0
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(
          color: selectedCount > 0
              ? theme.colorScheme.primary
              : Colors.grey.shade400,
          width: selectedCount > 0 ? 1.5 : 1.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(fontSize: 14),
      ),
      child: Container(
        // Re-uses the GlobalKey so the popup positioning anchors here.
        key: _buttonKey,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(summary),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

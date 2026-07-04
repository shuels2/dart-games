import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// QWERTY on-screen keyboard rendered at the bottom of the screen.
///
/// Drives the currently focused [EditableText] by mutating its
/// [TextEditingController.value]. No platform channel needed, so it
/// works identically on web, Windows, and mobile web builds.
class VirtualKeyboard extends StatefulWidget {
  final VoidCallback onDismiss;

  const VirtualKeyboard({super.key, required this.onDismiss});

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  bool _shift = true; // start capitalized for names

  static const _row1 = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
  static const _row2 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
  static const _row3 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
  static const _row4 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

  TextEditingController? _focusedController() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return null;
    final editable = ctx.findAncestorStateOfType<EditableTextState>();
    return editable?.widget.controller;
  }

  void _type(String char) {
    final controller = _focusedController();
    if (controller == null) return;
    final value = controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final newText = value.text.replaceRange(start, end, char);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + char.length),
    );
    if (_shift) {
      setState(() => _shift = false);
    }
  }

  void _backspace() {
    final controller = _focusedController();
    if (controller == null) return;
    final value = controller.value;
    final selection = value.selection;
    if (!selection.isValid) {
      if (value.text.isEmpty) return;
      controller.value = TextEditingValue(
        text: value.text.substring(0, value.text.length - 1),
        selection:
            TextSelection.collapsed(offset: value.text.length - 1),
      );
      return;
    }
    if (selection.isCollapsed) {
      if (selection.start == 0) return;
      final newText = value.text.replaceRange(
        selection.start - 1,
        selection.start,
        '',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );
    } else {
      final newText =
          value.text.replaceRange(selection.start, selection.end, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
  }

  void _toggleShift() {
    setState(() => _shift = !_shift);
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Material(
      color: const Color(0xFF23272E),
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 8, 6, 8 + safeBottom * 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ctrlKey(
                    icon: Icons.keyboard_hide,
                    label: 'Hide',
                    onTap: widget.onDismiss,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _row(_row1),
              const SizedBox(height: 6),
              _row(_row2),
              const SizedBox(height: 6),
              _row(_row3, sidePadding: 24),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _ctrlKey(
                      icon: _shift
                          ? Icons.keyboard_capslock
                          : Icons.keyboard_arrow_up,
                      label: _shift ? 'SHIFT' : 'shift',
                      onTap: _toggleShift,
                      active: _shift,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ..._row4.map(
                    (c) => Expanded(
                      flex: 2,
                      child: _charKey(c),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _ctrlKey(
                      icon: Icons.backspace,
                      onTap: _backspace,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _ctrlKey(
                      label: ',',
                      onTap: () => _type(','),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 10,
                    child: _charKey(' ', label: 'space'),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _ctrlKey(
                      label: '.',
                      onTap: () => _type('.'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _ctrlKey(
                      icon: Icons.keyboard_return,
                      label: 'Done',
                      onTap: _submit,
                      accent: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<String> chars, {double sidePadding = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      child: Row(
        children: chars
            .expand<Widget>(
              (c) => [
                Expanded(child: _charKey(c)),
                const SizedBox(width: 6),
              ],
            )
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _charKey(String rawChar, {String? label}) {
    final displayChar = _shift ? rawChar.toUpperCase() : rawChar;
    return _KeyTile(
      label: label ?? displayChar,
      onTap: () => _type(displayChar),
    );
  }

  Widget _ctrlKey({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    bool active = false,
    bool accent = false,
  }) {
    return _KeyTile(
      label: label,
      icon: icon,
      onTap: onTap,
      background: accent
          ? const Color(0xFFFF6B35)
          : active
              ? const Color(0xFF3A4048)
              : const Color(0xFF2C313A),
      foreground: accent ? Colors.white : Colors.white70,
    );
  }
}

class _KeyTile extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  const _KeyTile({
    this.label,
    this.icon,
    required this.onTap,
    this.background = const Color(0xFF3A4048),
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // Focus is excluded so tapping a key doesn't steal focus from the
    // TextField that owns the currently editing controller.
    return ExcludeFocus(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: _content(foreground),
        ),
      ),
    );
  }

  Widget _content(Color foreground) {
    final labelStyle = TextStyle(
      color: foreground,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    );
    if (icon != null && label != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 6),
          Text(label!, style: labelStyle.copyWith(fontSize: 16)),
        ],
      );
    }
    if (icon != null) {
      return Icon(icon, color: foreground, size: 22);
    }
    return Text(label ?? '', style: labelStyle);
  }
}

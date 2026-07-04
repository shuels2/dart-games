import 'package:flutter/material.dart';

import '../../services/input_mode_service.dart';
import 'virtual_keyboard.dart';

/// Wraps the whole app so that:
///   * every pointer down event is observed to detect touch vs mouse mode
///   * whenever a [TextField] gains focus AND the user is in touch mode,
///     an in-app QWERTY keyboard slides up from the bottom
///   * the keyboard's height is exposed via [MediaQuery.viewInsets] so
///     dialogs (like AddPlayer) shift up rather than being covered
///
/// The user can also dismiss the keyboard manually via its Hide button;
/// tapping outside a text field to lose focus hides it too.
class VirtualKeyboardScaffold extends StatefulWidget {
  final Widget child;
  final double keyboardHeight;
  final bool enabled;

  const VirtualKeyboardScaffold({
    super.key,
    required this.child,
    this.keyboardHeight = 320,
    this.enabled = true,
  });

  @override
  State<VirtualKeyboardScaffold> createState() =>
      _VirtualKeyboardScaffoldState();
}

class _VirtualKeyboardScaffoldState extends State<VirtualKeyboardScaffold> {
  bool _manualDismiss = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChanged);
    InputModeService.instance.addListener(_onModeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    InputModeService.instance.removeListener(_onModeChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    // A new focus target clears any prior manual-hide preference.
    if (mounted) setState(() => _manualDismiss = false);
  }

  void _onModeChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasEditableFocus {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return false;
    return ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  bool get _shouldShow {
    if (!widget.enabled) return false;
    if (_manualDismiss) return false;
    if (!InputModeService.instance.isTouch) return false;
    return _hasEditableFocus;
  }

  @override
  Widget build(BuildContext context) {
    final show = _shouldShow;
    final media = MediaQuery.of(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: InputModeService.instance.observePointer,
      child: Stack(
        children: [
          MediaQuery(
            data: media.copyWith(
              viewInsets: media.viewInsets.copyWith(
                bottom: show
                    ? widget.keyboardHeight
                    : media.viewInsets.bottom,
              ),
            ),
            child: widget.child,
          ),
          if (show)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: widget.keyboardHeight,
                child: VirtualKeyboard(
                  onDismiss: () => setState(() => _manualDismiss = true),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

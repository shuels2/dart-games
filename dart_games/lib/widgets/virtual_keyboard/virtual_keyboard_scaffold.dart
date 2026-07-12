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

  // Cached MediaQuery captured on inherited-widget changes so build()
  // never has to call MediaQuery.of(context) directly. The
  // FocusManager / InputModeService listeners can fire a setState()
  // right before this widget is unmounted (e.g. during a route pop
  // that also clears the focus), and the framework may still process
  // the rebuild against the now-deactivated element. Reading
  // MediaQuery via .of() on a deactivated context throws
  // "Looking up a deactivated widget's ancestor is unsafe" —
  // caching here avoids that entirely.
  MediaQueryData? _media;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChanged);
    InputModeService.instance.addListener(_onModeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Guarded because MaterialApp.builder recreates this scaffold on
    // every navigation and its FocusManager / InputModeService
    // listeners can schedule a rebuild during the tear-down window,
    // triggering the framework's "Looking up a deactivated widget's
    // ancestor is unsafe" error even here. Keeping the last-known
    // cached value on failure is safe — build() will fall back to
    // pass-through if the cache is null anyway.
    try {
      _media = MediaQuery.maybeOf(context);
    } catch (_) {
      // Context is deactivated; keep whatever we cached last time.
    }
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
    // Prefer the cached MediaQuery so we don't touch inherited widgets
    // via the (possibly deactivated) context. If the cache is empty
    // AND MediaQuery.of() fails on the ancestor lookup, the scaffold
    // is being torn down mid-rebuild by MaterialApp.builder — just
    // pass the child through unwrapped so the framework can finish
    // its unmount cleanly. Steady-state (production) never hits the
    // catch path because the widget isn't deactivated during rebuild.
    MediaQueryData? media = _media;
    if (media == null) {
      try {
        media = MediaQuery.of(context);
      } catch (_) {
        return widget.child;
      }
    }
    final show = _shouldShow;
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

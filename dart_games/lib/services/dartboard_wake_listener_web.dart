import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web-only implementation of the page-visibility wake listener.
///
/// Subscribes to `document.onVisibilityChange`. When the tab becomes
/// visible again after a hidden period (typically because the OS slept
/// and woke, or the user re-focused a backgrounded tab), the provided
/// callback fires. The provider uses this to kick off an immediate
/// reconnect attempt instead of waiting for the next backoff tick.
class DartboardWakeListener {
  StreamSubscription<web.Event>? _sub;

  void start(VoidCallback onVisible) {
    _sub?.cancel();
    _sub = web.document.onVisibilityChange.listen((_) {
      // visibilityState is "visible" once the tab regains focus.
      if (web.document.visibilityState == 'visible') {
        onVisible();
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}

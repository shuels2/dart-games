import 'package:flutter/foundation.dart';

/// No-op implementation of the page-visibility wake listener used on
/// every non-web platform. Native dart-games installs don't suspend
/// the way a browser tab does, so this isn't needed.
class DartboardWakeListener {
  void start(VoidCallback onVisible) {}
  void stop() {}
}

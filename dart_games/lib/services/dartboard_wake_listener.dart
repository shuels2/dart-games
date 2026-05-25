// Conditional-import dispatcher for the page-visibility wake listener.
// Web compiles get the package:web implementation; everything else
// (native + tests under flutter_test) gets the no-op stub.
//
// `dart.library.html` is the canonical web-only guard — it's only
// defined when compiling to JS/wasm. (Don't use dart.library.js_interop
// here; that one is portable across all platforms in modern Dart.)
export 'dartboard_wake_listener_stub.dart'
    if (dart.library.html) 'dartboard_wake_listener_web.dart';

// Conditional-import dispatcher for the ResponsiveVoice browser library.
// Web compiles get the dart:js_interop implementation; everything else
// (native + tests under flutter_test) gets the no-op stub.
//
// The web implementation must NOT be imported directly. `dart:js_interop` is
// unavailable off-web, and importing it unconditionally makes every library
// that transitively reaches DartAnnouncerService fail to compile in the VM
// test runner — which is why the announcement services previously had no
// unit tests.
export 'responsive_voice_service_stub.dart'
    if (dart.library.js_interop) 'responsive_voice_service_web.dart';

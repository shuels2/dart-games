import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;
import 'responsive_voice_service.dart';

/// Voice engine type
enum VoiceEngine {
  browser('Browser Voices', 'Use browser built-in voices'),
  responsiveVoice('ResponsiveVoice', 'Natural voices powered by ResponsiveVoice');

  final String displayName;
  final String description;

  const VoiceEngine(this.displayName, this.description);
}

/// Voice profiles for the dartboard announcer
enum AnnouncerVoice {
  professional('Professional', 'Standard professional announcer'),
  excited('Excited', 'High-energy enthusiastic caller'),
  calm('Calm', 'Soothing and relaxed announcer'),
  funny('Funny', 'Comedic and entertaining caller'),
  drill('Drill Sergeant', 'Military-style motivational caller');

  final String displayName;
  final String description;

  const AnnouncerVoice(this.displayName, this.description);
}

/// Service for announcing dart throws with different voices and phrases
class DartAnnouncerService {
  /// App-wide shared instance. Created on first access, kept alive for
  /// the lifetime of the app.
  ///
  /// Why a singleton: `FlutterTts()` on web wraps `SpeechSynthesisUtterance`,
  /// and Chrome's `speechSynthesis.getVoices()` returns `[]` until the
  /// browser fires `voiceschanged` (which can happen well after page
  /// load). A `DartAnnouncerService` constructed mid-game (each game
  /// screen used to create its own via `GameAnnouncementQueueService`)
  /// therefore hits `_initializeTts()` before voices have loaded and
  /// falls back to the OS-default voice — which on a de-DE Windows
  /// kiosk is a German voice, so games spoke German even though the
  /// Options screen (which used the home-screen's much-older instance)
  /// correctly used the saved English voice.
  ///
  /// Sharing a single instance means voices only need to load once, and
  /// whatever the Options screen configures via `setSystemVoice` /
  /// `useResponsiveVoice` is the exact same state that games speak with.
  ///
  /// [dispose] is a no-op on the shared instance — see the note there.
  static DartAnnouncerService? _shared;
  static DartAnnouncerService get shared =>
      _shared ??= DartAnnouncerService();

  final FlutterTts _tts = FlutterTts();
  final ResponsiveVoiceService _responsiveVoice;
  VoiceEngine _engine = VoiceEngine.browser;
  AnnouncerVoice _currentVoice = AnnouncerVoice.professional;
  bool _enabled = true;
  final math.Random _random = math.Random();
  List<dynamic> _availableVoices = [];
  String? _selectedVoiceName;
  String _responsiveVoiceName = 'US English Female'; // Default ResponsiveVoice

  // User-configurable playback rate multiplier. 1.0 = normal. Applied on
  // top of per-personality rates in announceDart() and as the rate for
  // the generic speak() path. See AppSettings.getVoicePlaybackRate.
  double _playbackRate = 1.0;

  // Browser-TTS completion: flutter_tts supports a one-shot completion
  // handler. We park a Completer here for the current utterance and
  // resolve it from setCompletionHandler so speak() can be awaited
  // event-driven instead of estimated.
  Completer<void>? _ttsCompleter;

  // Tail of the serialized speech chain. Every speak() links onto this so two
  // queues sharing this singleton cannot talk over each other.
  Future<void> _speakChain = Future<void>.value();

  // Upper bound on how long one link of that chain may stay pending. See
  // _defaultChainWatchdog.
  final Duration Function(String text) _chainWatchdogFor;

  // Future completed when _initializeTts() finishes populating
  // _availableVoices. Callers that need to set a specific system voice
  // must `await ready` first; otherwise setSystemVoice() runs against an
  // empty _availableVoices list, silently fails to call _tts.setVoice,
  // and the browser falls back to the OS default (which on non-English
  // Windows locales is not an English voice).
  late final Future<void> _initFuture;

  /// Resolves when the async init started in the constructor is done —
  /// specifically once [_availableVoices] has been populated from
  /// `flutter_tts.getVoices`. Await this before calling [setSystemVoice]
  /// on a freshly-constructed instance.
  Future<void> get ready => _initFuture;

  /// [responsiveVoice] exists only so tests can supply an engine that behaves
  /// like the real browser one — in particular one whose utterance never
  /// reports completion. Off the web the production value is a stub that
  /// reports "not ready", so the ResponsiveVoice path (the DEFAULT engine in
  /// `loadSettings`) was unreachable in tests and its deadlock went unseen.
  ///
  /// [chainWatchdog] likewise exists for tests: the production budget is
  /// seconds long by design, which no unit test should sit through.
  DartAnnouncerService({
    @visibleForTesting ResponsiveVoiceService? responsiveVoice,
    @visibleForTesting Duration Function(String text)? chainWatchdog,
  })  : _responsiveVoice = responsiveVoice ?? ResponsiveVoiceService(),
        _chainWatchdogFor = chainWatchdog ?? _defaultChainWatchdog {
    _initFuture = _initializeTts();
  }

  /// Set the user-configurable playback rate. 1.0 = normal speed.
  /// Range typically 0.7-1.5 (clamped by the settings UI).
  void setPlaybackRate(double rate) {
    _playbackRate = rate;
  }

  double get playbackRate => _playbackRate;

  Future<void> _initializeTts() async {
    // Configure TTS for web
    await _tts.setLanguage('en-AU');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Event-driven completion for the browser-TTS path. The queue
    // service awaits speak() and relies on this callback to know
    // exactly when an utterance finished, eliminating the wordCount-
    // based wait estimate that used to gate the next announcement.
    _tts.setCompletionHandler(() {
      final c = _ttsCompleter;
      _ttsCompleter = null;
      if (c != null && !c.isCompleted) c.complete();
    });
    _tts.setErrorHandler((_) {
      final c = _ttsCompleter;
      _ttsCompleter = null;
      if (c != null && !c.isCompleted) c.complete();
    });
    _tts.setCancelHandler(() {
      final c = _ttsCompleter;
      _ttsCompleter = null;
      if (c != null && !c.isCompleted) c.complete();
    });

    // Get available voices. Chrome's speechSynthesis.getVoices() returns
    // [] until the browser fires its `voiceschanged` event, and the
    // flutter_tts_web wrapper does NOT wait for that event — it calls
    // synth.getVoices() synchronously and returns whatever it sees.
    // A DartAnnouncerService constructed shortly after page load (as
    // each game screen does) therefore gets an empty list, no voice
    // is ever set on the underlying SpeechSynthesisUtterance, and
    // Chrome falls back to the OS default (German on a de-DE Windows
    // kiosk). Poll a handful of times to give the browser a chance
    // to populate voices before we bail.
    for (var attempt = 0; attempt < 20; attempt++) {
      final voices = await _tts.getVoices ?? [];
      if (voices.isNotEmpty) {
        _availableVoices = voices;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Try to select Australian voice as default
    if (_availableVoices.isNotEmpty) {
      // First try to find Australian voices
      final australianVoice = _availableVoices.firstWhere(
        (voice) {
          final name = (voice['name'] ?? '').toString().toLowerCase();
          final locale = (voice['locale'] ?? '').toString().toLowerCase();
          return locale.contains('en-au') ||
                 name.contains('australian') ||
                 name.contains('australia');
        },
        orElse: () => null,
      );

      if (australianVoice != null) {
        _selectedVoiceName = australianVoice['name']?.toString();
        await _tts.setVoice({
          'name': _selectedVoiceName!,
          'locale': australianVoice['locale']?.toString() ?? 'en-AU'
        });
      } else {
        // Fallback to any quality English voice
        final preferredVoice = _availableVoices.firstWhere(
          (voice) {
            final name = (voice['name'] ?? '').toString().toLowerCase();
            return name.contains('google') ||
                   name.contains('enhanced') ||
                   name.contains('premium') ||
                   name.contains('natural');
          },
          orElse: () => _availableVoices.firstWhere(
            (voice) => (voice['locale'] ?? '').toString().startsWith('en'),
            orElse: () => _availableVoices[0],
          ),
        );
        _selectedVoiceName = preferredVoice['name']?.toString();
        if (_selectedVoiceName != null) {
          await _tts.setVoice({'name': _selectedVoiceName!, 'locale': preferredVoice['locale']?.toString() ?? 'en-US'});
        }
      }
    }
  }

  /// Get list of available voices
  List<dynamic> get availableVoices => _availableVoices;

  /// Get list of ResponsiveVoice voices
  List<Map<String, String>> get responsiveVoices => ResponsiveVoiceService.defaultVoices;

  /// Get current engine
  VoiceEngine get currentEngine => _engine;

  /// Check if ResponsiveVoice is ready
  bool isResponsiveVoiceReady() {
    return _responsiveVoice.isReady();
  }

  /// Switch to browser voice engine
  void useBrowserVoices() {
    _engine = VoiceEngine.browser;
  }

  /// Switch to ResponsiveVoice engine
  void useResponsiveVoice() {
    _engine = VoiceEngine.responsiveVoice;
  }

  /// Set ResponsiveVoice voice
  void setResponsiveVoice(String voiceName) {
    _responsiveVoiceName = voiceName;
  }

  /// Set a specific system voice by name
  Future<void> setSystemVoice(String voiceName) async {
    _selectedVoiceName = voiceName;
    try {
      final voice = _availableVoices.firstWhere(
        (v) => v['name'] == voiceName,
      );
      await _tts.setVoice({
        'name': voice['name']?.toString() ?? voiceName,
        'locale': voice['locale']?.toString() ?? 'en-US'
      });
    } catch (e) {
      // Voice not found, ignore
    }
  }

  /// Set the current announcer voice
  void setVoice(AnnouncerVoice voice) {
    _currentVoice = voice;
    _updateVoiceSettings();
  }

  /// Whether announcements are enabled
  bool get enabled => _enabled;

  /// Enable or disable announcements
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Personality base rate for browser TTS. The values are tuned for
  /// `SpeechSynthesisUtterance.rate` where 0.5 is a slow announcer
  /// cadence and 1.0 is natural conversation speed. Multiplied by the
  /// user's [_playbackRate] to produce the effective rate.
  double _browserBaseRate() {
    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        return 0.5;
      case AnnouncerVoice.excited:
        return 0.6;
      case AnnouncerVoice.calm:
        return 0.4;
      case AnnouncerVoice.funny:
        return 0.55;
      case AnnouncerVoice.drill:
        return 0.65;
    }
  }

  /// Personality pitch for browser TTS.
  double _browserPitch() {
    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        return 1.0;
      case AnnouncerVoice.excited:
        return 1.3;
      case AnnouncerVoice.calm:
        return 0.8;
      case AnnouncerVoice.funny:
        return 1.1;
      case AnnouncerVoice.drill:
        return 0.9;
    }
  }

  /// Personality base rate for ResponsiveVoice.
  ///
  /// A DIFFERENT SCALE from [_browserBaseRate]. ResponsiveVoice treats 1.0 as
  /// normal speed, while `SpeechSynthesisUtterance.rate` (what flutter_tts
  /// drives on web) wants ~0.5 for an announcer cadence. Collapsing the two
  /// tables would make one of the engines unlistenable, so they stay separate.
  ///
  /// These are the values `announceDart` has always used; they are lifted here
  /// so every utterance gets them, not just that one method.
  double _responsiveVoiceBaseRate() {
    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        return 0.95;
      case AnnouncerVoice.excited:
        return 1.15;
      case AnnouncerVoice.calm:
        return 0.85;
      case AnnouncerVoice.funny:
        return 1.05;
      case AnnouncerVoice.drill:
        return 1.2;
    }
  }

  /// Personality pitch for ResponsiveVoice.
  ///
  /// Whether ResponsiveVoice actually applies this is voice-dependent — it
  /// proxies to the browser's SpeechSynthesis for some voices (where pitch
  /// works) and streams its own audio for others (where it may be ignored).
  /// Passing it is safe regardless: the options object is a plain JS literal,
  /// and a property the library does not read is inert rather than an error.
  /// No automated test can confirm the audible result; that is a listening
  /// check on the device.
  double _responsiveVoicePitch() {
    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        return 1.0;
      case AnnouncerVoice.excited:
        return 1.3;
      case AnnouncerVoice.calm:
        return 0.9;
      case AnnouncerVoice.funny:
        return 1.1;
      case AnnouncerVoice.drill:
        return 0.95;
    }
  }

  /// Effective ResponsiveVoice rate: `personality base × user slider`, clamped.
  ///
  /// The clamp is the counterpart of the one in [_setBrowserSpeechRate], which
  /// the ResponsiveVoice path never had. Drill (1.2) at the slider's maximum
  /// (1.5) asks for 1.8, which is past what speech engines render cleanly.
  double _effectiveResponsiveVoiceRate() =>
      (_responsiveVoiceBaseRate() * _playbackRate).clamp(0.1, 1.5);

  /// Update TTS settings based on selected voice. Pitch stays fixed
  /// per personality; the effective SPEECH rate is set right before
  /// each speak call in [_setBrowserSpeechRate] so the user's live
  /// [_playbackRate] is always folded in as a multiplier.
  Future<void> _updateVoiceSettings() async {
    await _setBrowserSpeechRate();
    await _tts.setPitch(_browserPitch());
  }

  /// Compute and apply the effective browser-TTS speech rate:
  /// `personality-base-rate * playbackRate`, clamped to a safe range.
  /// Called before every browser-TTS speak so the slider is honored.
  Future<void> _setBrowserSpeechRate() async {
    final effective = _browserBaseRate() * _playbackRate;
    // SpeechSynthesisUtterance.rate accepts 0.1 - 10, but past ~1.5
    // most engines sound clipped and past 2.0 they refuse to speak.
    await _tts.setSpeechRate(effective.clamp(0.1, 2.0));
  }

  /// Announce a dart throw
  /// Announce a dart throw.
  ///
  /// The per-personality rate/pitch switch that used to live here now lives in
  /// [_responsiveVoiceBaseRate] / [_responsiveVoicePitch] and applies to every
  /// utterance, so this is just a phrase plus the shared speech path. The
  /// returned future now resolves when the line has actually been spoken; on
  /// the ResponsiveVoice path it used to resolve immediately.
  Future<void> announceDart(int score, String multiplier) =>
      _enqueueSpeak(_getPhrase(score, multiplier));

  /// Get announcement phrase based on score, multiplier, and voice
  String _getPhrase(int score, String multiplier) {
    // Special cases first
    if (multiplier == 'bullseye') {
      return _getBullseyePhrase();
    }

    if (multiplier == 'outer_bull') {
      return _getOuterBullPhrase();
    }

    if (multiplier == 'miss') {
      return _getMissPhrase();
    }

    // Regular scoring announcements
    final baseScore = _getBaseScore(score, multiplier);
    final multiplierText = _getMultiplierText(multiplier);

    return _getScoringPhrase(score, baseScore, multiplierText, multiplier);
  }

  int _getBaseScore(int score, String multiplier) {
    if (multiplier == 'double') return score ~/ 2;
    if (multiplier == 'triple') return score ~/ 3;
    return score;
  }

  String _getMultiplierText(String multiplier) {
    switch (multiplier) {
      case 'double':
        return 'double';
      case 'triple':
        return 'triple';
      default:
        return '';
    }
  }

  String _getBullseyePhrase() {
    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        return 'Bullseye! 50 points!';
      case AnnouncerVoice.excited:
        final phrases = [
          'BULLSEYE! Fifty points! What a shot!',
          'Oh my! Bullseye for 50!',
          'Right in the middle! Bullseye! 50!',
        ];
        return phrases[_random.nextInt(phrases.length)];
      case AnnouncerVoice.calm:
        return 'Perfect center. Bullseye. Fifty points.';
      case AnnouncerVoice.funny:
        final phrases = [
          'Boom! Right in the eye! Bullseye! 50!',
          'Nailed it! Bullseye baby! That\'s 50 big ones!',
          'Bulls-eye! The bull is not happy! 50 points!',
        ];
        return phrases[_random.nextInt(phrases.length)];
      case AnnouncerVoice.drill:
        final phrases = [
          'BULLSEYE! FIFTY! Outstanding shot, soldier!',
          'CENTER MASS! Bullseye! 50 points! Hooah!',
          'DIRECT HIT! Bullseye for 50! Move out!',
        ];
        return phrases[_random.nextInt(phrases.length)];
    }
  }

  String _getOuterBullPhrase() {
    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        return '25. Outer bull.';
      case AnnouncerVoice.excited:
        return 'Nice shot! 25 on the outer bull!';
      case AnnouncerVoice.calm:
        return 'Twenty five. Outer bull.';
      case AnnouncerVoice.funny:
        return 'Almost had the bullseye! 25 on the green!';
      case AnnouncerVoice.drill:
        return 'TWENTY FIVE! Outer bull! Keep pushing!';
    }
  }

  String _getMissPhrase() {
    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        return 'Miss. No score.';
      case AnnouncerVoice.excited:
        final phrases = [
          'Ooh! Just missed the board!',
          'Off target! No score!',
        ];
        return phrases[_random.nextInt(phrases.length)];
      case AnnouncerVoice.calm:
        return 'Off the board. No score.';
      case AnnouncerVoice.funny:
        final phrases = [
          'Whoops! Missed the boat! Zero points!',
          'Air ball! Better luck next time!',
          'And... it\'s gone! Zero!',
        ];
        return phrases[_random.nextInt(phrases.length)];
      case AnnouncerVoice.drill:
        final phrases = [
          'MISS! Get back in the fight!',
          'OFF TARGET! Zero! Focus up!',
          'NEGATIVE! Missed the board! Try again!',
        ];
        return phrases[_random.nextInt(phrases.length)];
    }
  }

  String _getScoringPhrase(int score, int baseScore, String multiplierText, String multiplier) {
    // Check for high scores (triple 20, triple 19, triple 18, etc.)
    final isHighScore = score >= 50 && multiplier == 'triple';

    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        if (multiplierText.isEmpty) {
          return '$score';
        }
        return '$multiplierText $baseScore for $score';

      case AnnouncerVoice.excited:
        if (isHighScore) {
          final phrases = [
            'Wow! $multiplierText $baseScore! That\'s $score points!',
            'What a throw! $multiplierText $baseScore for $score!',
            'Incredible! $multiplierText $baseScore! $score!',
          ];
          return phrases[_random.nextInt(phrases.length)];
        }
        if (multiplierText.isEmpty) {
          return '$score!';
        }
        return '$multiplierText $baseScore for $score!';

      case AnnouncerVoice.calm:
        if (multiplierText.isEmpty) {
          return '$score';
        }
        return '$multiplierText $baseScore. $score points.';

      case AnnouncerVoice.funny:
        if (score == 69) {
          return 'Nice! $score!';
        }
        if (isHighScore) {
          final phrases = [
            'Oh baby! $multiplierText $baseScore! $score points of pure awesome!',
            'Crushed it! $multiplierText $baseScore for $score!',
            'Boom! $multiplierText $baseScore! That\'s $score points baby!',
          ];
          return phrases[_random.nextInt(phrases.length)];
        }
        if (multiplierText.isEmpty) {
          return '$score points!';
        }
        return '$multiplierText $baseScore! That\'s $score!';

      case AnnouncerVoice.drill:
        if (isHighScore) {
          final phrases = [
            'OUTSTANDING! $multiplierText $baseScore! $score points! Hooah!',
            'EXCELLENT SHOT! $multiplierText $baseScore for $score!',
            'THAT\'S HOW IT\'S DONE! $multiplierText $baseScore! $score!',
          ];
          return phrases[_random.nextInt(phrases.length)];
        }
        if (multiplierText.isEmpty) {
          return '$score! Keep it up!';
        }
        return '$multiplierText $baseScore! $score points! Move move move!';
    }
  }

  // DELETED: announceGameStart().
  //
  // It spoke a per-personality "Game on" line and had no callers. All ten
  // games announce their own start through their helper's announceGameStart,
  // which calls queue.announce() with game-specific wording and a sound
  // effect — nine helpers define a method of that exact name. That collision
  // is why the service's copy looked used: grepping the name returns eighty
  // hits, every one of them a helper or a mock.
  //
  // It is recorded here rather than silently removed because it was also one
  // of the three methods that spoke to the engines directly, bypassing
  // _speakChain. If a future "announcer says the game is starting" feature
  // wants this, it belongs in a game helper going through queue.announce(),
  // not as a second speech path on the service.

  /// Speak a custom phrase using current engine and voice settings.
  ///
  /// Returns a `Future<void>` that resolves when the speech engine has
  /// actually finished speaking (via ResponsiveVoice's `onend` callback
  /// or flutter_tts's `setCompletionHandler`), NOT when the speak call
  /// is dispatched. The queue service awaits this so it knows when to
  /// start the next utterance — no wordCount-based estimate required.
  ///
  /// The user-configurable [playbackRate] is applied to both engines.
  Future<void> speak(String text) => _enqueueSpeak(text);

  /// Links one utterance onto [_speakChain] and returns a future that resolves
  /// when it has been spoken.
  ///
  /// EVERY utterance must go through here. Three methods used to call the
  /// engines directly instead — `announceDart`, the old body of this method,
  /// and `announceGameStart` (since deleted as dead code) — which meant they
  /// could talk over whatever the chain was speaking, and on the browser path
  /// their utterance's completion resolved somebody else's `_ttsCompleter`
  /// (the handler is global), quietly advancing a game's queue mid-sentence.
  /// `test/meta/speech_engine_completion_lint_test.dart` now enforces that the
  /// engines are only ever touched from [_speakNow].
  Future<void> _enqueueSpeak(String text) {
    if (!_enabled) return Future.value();

    // Serialize every caller through one chain. There is always more than
    // one queue alive — each game screen has one and GlobalConnectionAnnouncer
    // keeps an app-lifetime one — and they share this singleton. Concurrent
    // speak() calls used to overwrite _ttsCompleter, so the first caller's
    // await hung until its queue's timeout while the first utterance's
    // completion resolved the SECOND caller's completer, advancing that queue
    // mid-speech.
    final previous = _speakChain;
    final done = Completer<void>();
    _speakChain = done.future;

    final spoken = previous.then((_) => _speakNow(text));

    // Bound the link. `whenComplete` alone is not enough: if the engine never
    // reports completion, `spoken` stays pending, `done` is never completed,
    // and EVERY later speak() waits on it forever — speech dies for the rest
    // of the session while the queue keeps draining on its own timeout and
    // sound effects keep playing. That is the failure seen on a real
    // dartboard (game start and the first player announced, then silence).
    //
    // The queue applies its own tighter timeout to the future returned below,
    // so this only fires when that path failed to unwedge things too. It is a
    // deadlock breaker, not a pacing mechanism — hence the generous budget.
    unawaited(spoken
        .timeout(_chainWatchdogFor(text), onTimeout: () {})
        // A link that threw must not poison the chain either.
        .catchError((Object _) {})
        .whenComplete(() {
      if (!done.isCompleted) done.complete();
    }));

    return spoken;
  }

  /// How long one link of [_speakChain] may stay pending before it is treated
  /// as wedged. Scales with utterance length so a long line is not cut loose
  /// early, with generous headroom over the queue's own
  /// `wordCount * 1000 + 1500` timeout so this stays the last resort.
  static Duration _defaultChainWatchdog(String text) =>
      Duration(milliseconds: text.split(' ').length * 1000 + 5000);

  Future<void> _speakNow(String text) async {
    if (!_enabled) return;

    if (_engine == VoiceEngine.responsiveVoice && _responsiveVoice.isReady()) {
      // Personality rate AND pitch, not just the slider. This path used to
      // pass bare _playbackRate and no pitch, so on the DEFAULT engine the
      // announcer style was inaudible in every game — "excited" and "calm"
      // sounded identical. Only announceDart honoured the personality, and
      // nothing but the Test Dartboard screen called it.
      await _responsiveVoice.speak(
        text,
        voiceName: _responsiveVoiceName,
        rate: _effectiveResponsiveVoiceRate(),
        pitch: _responsiveVoicePitch(),
      );
    } else {
      // flutter_tts: the completion callback resolves _ttsCompleter
      // (wired in _initializeTts). _tts.speak typically returns when
      // the utterance STARTS, so we use the completer as the actual
      // "speech finished" signal.
      final completer = Completer<void>();
      _ttsCompleter = completer;
      // Effective rate = personality base rate × user slider. Slider
      // at 1.0 keeps the personality's intended announcer cadence;
      // 0.7 slows it 30%, 1.5 speeds it 50%. See _setBrowserSpeechRate.
      await _setBrowserSpeechRate();
      await _tts.speak(text);
      await completer.future;
    }
  }

  /// Stops whatever is currently being spoken.
  ///
  /// Needed by the queue's watchdog: `Future.timeout` abandons the await but
  /// leaves the utterance playing (and queued inside the browser's speech
  /// engine), so without this the next announcement talks over it.
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Engine may not be initialized yet; nothing to stop.
    }
    _responsiveVoice.cancel();
    final c = _ttsCompleter;
    _ttsCompleter = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Dispose of TTS resources.
  ///
  /// No-op on the shared singleton — the app-wide instance is kept alive
  /// intentionally so voice-list state, saved voice selection, and the
  /// browser-TTS `SpeechSynthesisUtterance.voice` binding survive across
  /// screen transitions (see the doc on [shared]). Only stops speech
  /// and cancels ResponsiveVoice for non-shared instances, which today
  /// means nothing — every consumer routes through [shared].
  void dispose() {
    if (identical(this, _shared)) return;
    _tts.stop();
    _responsiveVoice.cancel();
  }
}

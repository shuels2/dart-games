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
  final FlutterTts _tts = FlutterTts();
  final ResponsiveVoiceService _responsiveVoice = ResponsiveVoiceService();
  VoiceEngine _engine = VoiceEngine.browser;
  AnnouncerVoice _currentVoice = AnnouncerVoice.professional;
  bool _enabled = true;
  final math.Random _random = math.Random();
  List<dynamic> _availableVoices = [];
  String? _selectedVoiceName;
  String _responsiveVoiceName = 'US English Female'; // Default ResponsiveVoice

  DartAnnouncerService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    // Configure TTS for web
    await _tts.setLanguage('en-AU');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Get available voices
    _availableVoices = await _tts.getVoices ?? [];

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

  /// Enable or disable announcements
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Update TTS settings based on selected voice
  Future<void> _updateVoiceSettings() async {
    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        await _tts.setSpeechRate(0.5);
        await _tts.setPitch(1.0);
        break;
      case AnnouncerVoice.excited:
        await _tts.setSpeechRate(0.6);
        await _tts.setPitch(1.3);
        break;
      case AnnouncerVoice.calm:
        await _tts.setSpeechRate(0.4);
        await _tts.setPitch(0.8);
        break;
      case AnnouncerVoice.funny:
        await _tts.setSpeechRate(0.55);
        await _tts.setPitch(1.1);
        break;
      case AnnouncerVoice.drill:
        await _tts.setSpeechRate(0.65);
        await _tts.setPitch(0.9);
        break;
    }
  }

  /// Announce a dart throw
  Future<void> announceDart(int score, String multiplier) async {
    if (!_enabled) return;

    final phrase = _getPhrase(score, multiplier);

    // Use appropriate engine
    if (_engine == VoiceEngine.responsiveVoice && _responsiveVoice.isReady()) {
      // Get speech rate and pitch based on personality
      double rate = 1.0;
      double pitch = 1.0;

      switch (_currentVoice) {
        case AnnouncerVoice.professional:
          rate = 0.95;
          pitch = 1.0;
          break;
        case AnnouncerVoice.excited:
          rate = 1.15;
          pitch = 1.3;
          break;
        case AnnouncerVoice.calm:
          rate = 0.85;
          pitch = 0.9;
          break;
        case AnnouncerVoice.funny:
          rate = 1.05;
          pitch = 1.1;
          break;
        case AnnouncerVoice.drill:
          rate = 1.2;
          pitch = 0.95;
          break;
      }

      _responsiveVoice.speak(
        phrase,
        voiceName: _responsiveVoiceName,
        rate: rate,
        pitch: pitch,
      );
    } else {
      // Use browser TTS
      await _tts.speak(phrase);
    }
  }

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

  /// Announce game start
  Future<void> announceGameStart() async {
    if (!_enabled) return;

    String phrase;
    switch (_currentVoice) {
      case AnnouncerVoice.professional:
        phrase = 'Game on. Good luck.';
        break;
      case AnnouncerVoice.excited:
        phrase = 'Let\'s gooo! Game on! Show me what you got!';
        break;
      case AnnouncerVoice.calm:
        phrase = 'Game beginning. Take your time.';
        break;
      case AnnouncerVoice.funny:
        phrase = 'Alright folks! Let the dart slinging begin!';
        break;
      case AnnouncerVoice.drill:
        phrase = 'GAME ON! Give me your best shot! Let\'s go!';
        break;
    }

    if (_engine == VoiceEngine.responsiveVoice && _responsiveVoice.isReady()) {
      _responsiveVoice.speak(phrase, voiceName: _responsiveVoiceName);
    } else {
      await _tts.speak(phrase);
    }
  }

  /// Speak a custom phrase using current engine and voice settings
  Future<void> speak(String text) async {
    if (!_enabled) return;

    if (_engine == VoiceEngine.responsiveVoice && _responsiveVoice.isReady()) {
      _responsiveVoice.speak(text, voiceName: _responsiveVoiceName);
    } else {
      await _tts.speak(text);
    }
  }

  /// Dispose of TTS resources
  void dispose() {
    _tts.stop();
    _responsiveVoice.cancel();
  }
}

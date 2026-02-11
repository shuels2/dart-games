import 'game_announcement_queue_service.dart';
import 'target_tag_sound_effects.dart';

/// Target Tag-specific announcement helper
/// Wraps the global GameAnnouncementQueueService with convenience methods
class TargetTagAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  TargetTagAnnouncementHelper(this._queue);

  // Announce dart hit
  void announceHit(int number, String multiplier, {bool isMiss = false}) {
    SoundEffectConfig? sfx;

    if (isMiss) {
      sfx = TargetTagSoundEffects.miss;
      _queue.announce('Miss', AudioPriority.hitConfirm, soundEffect: sfx);
      return;
    }

    String text = '';
    if (number == 50) {
      text = 'Bullseye!';
      sfx = TargetTagSoundEffects.bullseye;
    } else if (number == 25) {
      text = 'Outer bull';
      sfx = TargetTagSoundEffects.outerBull;
    } else {
      final mult = multiplier == 'double' ? 'Double' : (multiplier == 'triple' ? 'Triple' : 'Single');
      text = '$mult $number';

      // Select sound effect based on multiplier
      if (multiplier == 'double') {
        sfx = TargetTagSoundEffects.doubleHit;
      } else if (multiplier == 'triple') {
        sfx = TargetTagSoundEffects.tripleHit;
      } else {
        sfx = TargetTagSoundEffects.singleHit;
      }
    }

    _queue.announce(text, AudioPriority.hitConfirm, soundEffect: sfx);
  }

  // Announce shield gained
  void announceShieldGained(String playerName, int shields, int shieldMax) {
    _queue.announce('$shields shields', AudioPriority.shieldStatus, soundEffect: TargetTagSoundEffects.shieldGained);
  }

  // Announce player(s) reached Tagged In status
  void announceTaggedIn(List<String> playerNames) {
    String names;
    if (playerNames.length == 1) {
      names = '${playerNames[0]} is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]} are';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last} are';
    }
    _queue.announce('JACKPOT! $names TAGGED IN!', AudioPriority.statusChange, soundEffect: TargetTagSoundEffects.taggedIn);
  }

  // Announce player(s) lost Tagged In status
  void announceTaggedOut(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = playerNames[0];
      verb = 'is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}';
      verb = 'are';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}';
      verb = 'are';
    }
    _queue.announce('Shield compromised! $names $verb back on the hunt.', AudioPriority.statusChange, soundEffect: TargetTagSoundEffects.taggedOut);
  }

  // Announce low shields warning
  void announceLowShields(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = '${playerNames[0]}\'s';
      verb = 'are';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}\'s';
      verb = 'are';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}\'s';
      verb = 'are';
    }
    _queue.announce('Warning! $names shields $verb almost gone!', AudioPriority.shieldStatus, soundEffect: TargetTagSoundEffects.lowShields);
  }

  // Announce player(s) vulnerable (at 0 shields)
  void announceVulnerable(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = playerNames[0];
      verb = 'is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}';
      verb = 'are';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}';
      verb = 'are';
    }
    _queue.announce('DANGER! $names $verb vulnerable! One more hit and you\'re out!', AudioPriority.shieldStatus, soundEffect: TargetTagSoundEffects.lowShields);
  }

  // Announce player(s) eliminated
  void announceEliminated(List<String> playerNames) {
    String names;
    if (playerNames.length == 1) {
      names = '${playerNames[0]} is';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]} are';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last} are';
    }
    _queue.announce('$names Tagged Out! Better luck next time!', AudioPriority.statusChange, soundEffect: TargetTagSoundEffects.eliminated);
  }

  // Announce successful tag on opponent
  void announceSuccessfulTag() {
    _queue.announce('Tag! Got \'em!', AudioPriority.hitConfirm, soundEffect: TargetTagSoundEffects.successfulTag);
  }

  // Announce turn change
  void announceTurn(String playerName) {
    _queue.announce('$playerName, your turn', AudioPriority.turnTransition, soundEffect: TargetTagSoundEffects.turnStart);
  }

  // Announce game start
  void announceGameStart() {
    _queue.announce('Welcome to Target Tag! Fill those shields!', AudioPriority.victory, soundEffect: TargetTagSoundEffects.gameStart);
  }

  // Announce winner(s)
  void announceWinner(List<String> playerNames) {
    String names;
    String verb;
    if (playerNames.length == 1) {
      names = playerNames[0];
      verb = 'is the Target Tag Champion';
    } else if (playerNames.length == 2) {
      names = '${playerNames[0]} and ${playerNames[1]}';
      verb = 'are the Target Tag Champions';
    } else {
      // Handle 3+ names with commas and "and"
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}';
      verb = 'are the Target Tag Champions';
    }
    _queue.announce('GAME OVER! $names $verb!', AudioPriority.victory);
  }

  // Announce remove darts
  void announceRemoveDarts() {
    _queue.announce('Remove your darts', AudioPriority.turnTransition, soundEffect: TargetTagSoundEffects.removeDarts);
  }

  // Dispose the underlying queue
  void dispose() {
    _queue.dispose();
  }
}

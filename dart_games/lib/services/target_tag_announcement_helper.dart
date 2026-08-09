import 'game_announcement_helper_base.dart';
import 'game_announcement_queue_service.dart';
import 'target_tag_sound_effects.dart';

/// Target Tag-specific announcement helper
/// Wraps the global GameAnnouncementQueueService with convenience methods
class TargetTagAnnouncementHelper extends GameAnnouncementHelperBase {

  TargetTagAnnouncementHelper(super.queue);

  // Generic per-dart score readout ("Single 20" / "Bullseye!" / "Miss").
  // The game screen calls this only when no secondary effect is present
  // (target_tag_game_screen.dart:270 region).
  void announceHit(int number, String multiplier, {bool isMiss = false}) {
    SoundEffectConfig? sfx;

    if (isMiss) {
      sfx = TargetTagSoundEffects.miss;
      queue.announce('Miss', AudioPriority.hitConfirm, soundEffect: sfx);
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

    queue.announce(text, AudioPriority.hitConfirm, soundEffect: sfx);
  }

  /// Formats a list of names for announcements.
  /// 1-4 names: listed ("Alice", "Alice and Bob", "Alice, Bob, and Charlie")
  /// 5+ names (not all): "all players except {excluded}"
  /// All names: "all players"
  static String formatNames(List<String> names, {List<String>? allPlayerNames}) {
    if (allPlayerNames != null && names.length == allPlayerNames.length && allPlayerNames.length > 1) {
      return 'all players';
    }
    if (allPlayerNames == null || names.length <= 4) {
      if (names.length == 1) return names[0];
      if (names.length == 2) return '${names[0]} and ${names[1]}';
      return '${names.sublist(0, names.length - 1).join(', ')}, and ${names.last}';
    }
    // 5+: use "except" with excluded names
    final excluded = allPlayerNames!.where((n) => !names.contains(n)).toList();
    if (excluded.isEmpty) return 'all players';
    if (excluded.length == 1) return 'all players except ${excluded[0]}';
    if (excluded.length == 2) return 'all players except ${excluded[0]} and ${excluded[1]}';
    return 'all players except ${excluded.sublist(0, excluded.length - 1).join(', ')}, and ${excluded.last}';
  }

  static String verb(List<String> names, {List<String>? allPlayerNames}) {
    if (names.length >= 5) return 'are';
    if (allPlayerNames != null && names.length == allPlayerNames.length && allPlayerNames.length > 1) return 'are';
    return names.length == 1 ? 'is' : 'are';
  }

  // Announce shield gained
  void announceShieldGained(String playerName, int shields, int shieldMax) {
    queue.announce('$shields shields', AudioPriority.shieldStatus, soundEffect: TargetTagSoundEffects.shieldGained);
  }

  void announceTaggedIn(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = formatNames(playerNames, allPlayerNames: allPlayerNames);
    final v = verb(playerNames, allPlayerNames: allPlayerNames);
    queue.announce('JACKPOT! $names ${v} TAGGED IN!', AudioPriority.statusChange, soundEffect: TargetTagSoundEffects.taggedIn);
  }

  void announceTaggedOut(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = formatNames(playerNames, allPlayerNames: allPlayerNames);
    final v = verb(playerNames, allPlayerNames: allPlayerNames);
    queue.announce('Shield compromised! $names ${v} back on the hunt.', AudioPriority.statusChange, soundEffect: TargetTagSoundEffects.taggedOut);
  }

  void announceLowShields(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = formatNames(playerNames, allPlayerNames: allPlayerNames);
    queue.announce('Warning! Shields almost gone for $names!', AudioPriority.shieldStatus, soundEffect: TargetTagSoundEffects.lowShields);
  }

  void announceVulnerable(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = formatNames(playerNames, allPlayerNames: allPlayerNames);
    final v = verb(playerNames, allPlayerNames: allPlayerNames);
    queue.announce('DANGER! $names ${v} vulnerable! One more hit and you\'re out!', AudioPriority.shieldStatus, soundEffect: TargetTagSoundEffects.lowShields);
  }

  void announceEliminated(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = formatNames(playerNames, allPlayerNames: allPlayerNames);
    final v = verb(playerNames, allPlayerNames: allPlayerNames);
    queue.announce('$names ${v} Tagged Out! Better luck next time!', AudioPriority.statusChange, soundEffect: TargetTagSoundEffects.eliminated);
  }

  // Announce successful tag on opponent
  void announceSuccessfulTag() {
    queue.announce('Tag! Got \'em!', AudioPriority.hitConfirm, soundEffect: TargetTagSoundEffects.successfulTag);
  }

  // Announce turn change
  void announceTurn(String playerName) {
    queue.announce('$playerName, your turn', AudioPriority.turnTransition, soundEffect: TargetTagSoundEffects.turnStart);
  }

  // Announce game start
  void announceGameStart() {
    queue.announce('Welcome to Target Tag! Fill those shields!', AudioPriority.victory, soundEffect: TargetTagSoundEffects.gameStart);
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
    queue.announce('GAME OVER! $names $verb!', AudioPriority.victory);
  }

  // Announce remove darts
  void announceRemoveDarts() {
    queue.announce('Remove your darts', AudioPriority.turnTransition);
  }

}

import '../models/monster_mash_game.dart';
import 'game_announcement_helper_base.dart';
import 'game_announcement_queue_service.dart';
import 'monster_mash_sound_effects.dart';

class MonsterMashAnnouncementHelper extends GameAnnouncementHelperBase {

  MonsterMashAnnouncementHelper(super.queue);

  // Announce game start
  void announceGameStart() {
    queue.announce(
      'Welcome to Monster Mash! Let the battle begin!',
      AudioPriority.victory,
      soundEffect: MonsterMashSoundEffects.gameStart,
    );
  }

  // Announce turn transition
  void announceTurn(String playerName) {
    queue.announce(
      '$playerName, your turn',
      AudioPriority.turnTransition,
      soundEffect: MonsterMashSoundEffects.turnStart,
    );
  }

  // Generic per-dart score readout ("Single 20" / "Bullseye!" / "Miss").
  // The game screen calls this only when there is no secondary effect to
  // announce (the !hasSecondary fallback path).
  void announceHit(int number, String multiplier, {bool isMiss = false}) {
    if (isMiss) {
      queue.announce('Miss', AudioPriority.hitConfirm, soundEffect: MonsterMashSoundEffects.dartHit);
      return;
    }

    String text = '';
    if (number == 50) {
      text = 'Bullseye!';
    } else if (number == 25) {
      text = 'Outer bull';
    } else {
      final mult = multiplier == 'double' ? 'Double' : (multiplier == 'triple' ? 'Triple' : 'Single');
      text = '$mult $number';
    }

    queue.announce(text, AudioPriority.hitConfirm, soundEffect: MonsterMashSoundEffects.dartHit);
  }

  // Announce healing
  void announceHealing(String multiplier, int amount, {int? dartNumber}) {
    if (amount <= 0) return;

    String prefix = '';
    if (dartNumber == 50) {
      prefix = 'Bullseye! ';
    } else if (dartNumber == 25) {
      prefix = 'Outer bull! ';
    }

    String text;
    if (amount >= 50) {
      text = '${prefix}Max Health!';
    } else if (amount == 5) {
      text = '${prefix}Plus 5 health!';
    } else {
      text = '${prefix}Plus $amount health!';
    }

    queue.announce(text, AudioPriority.hitConfirm, soundEffect: MonsterMashSoundEffects.healing);
  }

  // Announce attack on opponent
  void announceAttack(String playerName, String multiplier, int damage) {
    String text;
    if (damage <= 0) {
      text = 'The shadows protect $playerName! No damage!';
    } else if (multiplier == 'triple') {
      text = 'Devastating strike! $playerName takes $damage damage!';
    } else if (multiplier == 'double') {
      text = 'Powerful double hit! $playerName feels the pain!';
    } else {
      text = 'A single glancing blow! $playerName feels the sting.';
    }

    queue.announce(text, AudioPriority.hitConfirm, soundEffect: MonsterMashSoundEffects.attack);
  }

  void announceHealthWarning(String playerName, double percentage, {int? damage}) {
    String prefix = damage != null ? '$damage damage! ' : '';
    String text;
    if (percentage <= 0.10) {
      text = '$prefix$playerName is barely clinging to life!';
    } else if (percentage <= 0.30) {
      text = '$prefix$playerName is in critical condition!';
    } else if (percentage <= 0.70) {
      text = '$prefix$playerName is starting to weaken!';
    } else {
      return;
    }

    queue.announce(text, AudioPriority.shieldStatus, soundEffect: MonsterMashSoundEffects.healthWarning);
  }

  // Announce elimination
  void announceElimination(String playerName) {
    queue.announce(
      '$playerName! Back to the shadows!',
      AudioPriority.statusChange,
      soundEffect: MonsterMashSoundEffects.elimination,
    );
  }

  // Announce hat trick (3 darts all hit same opponent)
  void announceHatTrick(String playerName, int damage) {
    queue.announce(
      'MONSTROUS! $damage damage! Triple strike on $playerName!',
      AudioPriority.statusChange,
      soundEffect: MonsterMashSoundEffects.hatTrick,
    );
  }

  void announceHatTrickElimination(String playerName, int damage) {
    queue.announce(
      'MONSTROUS! $damage damage! Triple strike eliminates $playerName!',
      AudioPriority.statusChange,
      soundEffect: MonsterMashSoundEffects.hatTrick,
    );
  }

  // Announce combined elimination (multiple players eliminated at once)
  void announceCombinedElimination(List<String> playerNames) {
    final names = playerNames.join(' and ');
    queue.announce(
      '$names! Back to the shadows!',
      AudioPriority.statusChange,
      soundEffect: MonsterMashSoundEffects.elimination,
    );
  }

  // Announce clutch heal (hit own number while below 10 HP)
  void announceClutchHeal(String playerName) {
    queue.announce(
      '$playerName rises from near death!',
      AudioPriority.statusChange,
      soundEffect: MonsterMashSoundEffects.clutchHeal,
    );
  }

  // Announce buff activation
  void announceBuff(BonusBuff buff) {
    String text;
    switch (buff) {
      case BonusBuff.bloodMoon:
        text = 'Blood Moon rises! Attack damage doubled!';
      case BonusBuff.ancientBandages:
        text = 'Ancient Bandages discovered! Healing boosted to 5!';
      case BonusBuff.shadowWalk:
        text = 'Shadow Walk activated! Attacks deal no damage!';
      case BonusBuff.laboratorySpark:
        text = 'Laboratory Spark! Bullseye zaps all opponents!';
    }

    queue.announce(text, AudioPriority.statusChange, soundEffect: MonsterMashSoundEffects.buffActivation);
  }

  // Announce remove darts
  void announceRemoveDarts() {
    queue.announce(
      'Remove your darts',
      AudioPriority.turnTransition,
    );
  }

  // Announce winner
  void announceWinner(String playerName) {
    queue.announce('GAME OVER! The night belongs to $playerName!', AudioPriority.victory);
  }

  // Announce winners (ties)
  void announceWinners(List<String> playerNames) {
    if (playerNames.length == 1) {
      announceWinner(playerNames.first);
      return;
    }
    final names = playerNames.join(' and ');
    queue.announce('GAME OVER! The night is shared by $names!', AudioPriority.victory);
  }

}

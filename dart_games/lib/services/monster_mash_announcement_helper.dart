import '../models/monster_mash_game.dart';
import 'game_announcement_queue_service.dart';
import 'monster_mash_sound_effects.dart';

class MonsterMashAnnouncementHelper {
  final GameAnnouncementQueueService _queue;

  MonsterMashAnnouncementHelper(this._queue);

  // Announce game start
  void announceGameStart() {
    _queue.announce(
      'Welcome to Monster Mash! Let the battle begin!',
      AudioPriority.victory,
      soundEffect: MonsterMashSoundEffects.gameStart,
    );
  }

  // Announce turn transition
  void announceTurn(String playerName) {
    _queue.announce(
      '$playerName, your turn',
      AudioPriority.turnTransition,
      soundEffect: MonsterMashSoundEffects.turnStart,
    );
  }

  // Announce dart hit
  void announceHit(int number, String multiplier, {bool isMiss = false}) {
    if (isMiss) {
      _queue.announce('Miss', AudioPriority.hitConfirm, soundEffect: MonsterMashSoundEffects.dartHit);
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

    _queue.announce(text, AudioPriority.hitConfirm, soundEffect: MonsterMashSoundEffects.dartHit);
  }

  // Announce healing
  void announceHealing(String multiplier, int amount) {
    if (amount <= 0) return;

    String text;
    if (amount >= 50) {
      text = 'Max Health!';
    } else if (amount == 5) {
      text = 'Plus 5!';
    } else {
      text = 'Plus $amount!';
    }

    _queue.announce(text, AudioPriority.hitConfirm, soundEffect: MonsterMashSoundEffects.healing);
  }

  // Announce attack on opponent
  void announceAttack(String playerName, String multiplier, int damage) {
    String text;
    if (damage <= 0) {
      text = 'The shadows protect $playerName!';
    } else if (multiplier == 'triple') {
      text = 'Devastating strike! $playerName takes $damage damage!';
    } else if (multiplier == 'double') {
      text = 'Powerful hit! $playerName feels the pain!';
    } else {
      text = 'A glancing blow! $playerName feels the sting.';
    }

    _queue.announce(text, AudioPriority.hitConfirm, soundEffect: MonsterMashSoundEffects.attack);
  }

  // Announce health warning at thresholds
  void announceHealthWarning(String playerName, double percentage) {
    String text;
    if (percentage <= 0.10) {
      text = '$playerName is barely clinging to life!';
    } else if (percentage <= 0.30) {
      text = '$playerName is in critical condition!';
    } else if (percentage <= 0.70) {
      text = '$playerName is starting to weaken!';
    } else {
      return; // No announcement above 70%
    }

    _queue.announce(text, AudioPriority.shieldStatus, soundEffect: MonsterMashSoundEffects.healthWarning);
  }

  // Announce elimination
  void announceElimination(String playerName) {
    _queue.announce(
      '$playerName! Back to the shadows!',
      AudioPriority.statusChange,
      soundEffect: MonsterMashSoundEffects.elimination,
    );
  }

  // Announce hat trick (3 darts all hit same opponent)
  void announceHatTrick(String playerName) {
    _queue.announce(
      'MONSTROUS! Triple strike on $playerName!',
      AudioPriority.statusChange,
      soundEffect: MonsterMashSoundEffects.hatTrick,
    );
  }

  // Announce clutch heal (hit own number while below 10 HP)
  void announceClutchHeal(String playerName) {
    _queue.announce(
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

    _queue.announce(text, AudioPriority.statusChange, soundEffect: MonsterMashSoundEffects.buffActivation);
  }

  // Announce remove darts
  void announceRemoveDarts() {
    _queue.announce(
      'Remove your darts',
      AudioPriority.turnTransition,
      soundEffect: MonsterMashSoundEffects.removeDarts,
    );
  }

  // Announce winner
  void announceWinner(String playerName) {
    _queue.announce('GAME OVER! The night belongs to $playerName!', AudioPriority.victory);
  }

  // Announce winners (ties)
  void announceWinners(List<String> playerNames) {
    if (playerNames.length == 1) {
      announceWinner(playerNames.first);
      return;
    }
    final names = playerNames.join(' and ');
    _queue.announce('GAME OVER! The night is shared by $names!', AudioPriority.victory);
  }

  // Dispose the underlying queue
  void dispose() {
    _queue.dispose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:dart_games/models/monster_mash_game.dart';

/// Mock audio queue service that captures announcements for testing
/// instead of actually playing them through web audio APIs.
///
/// Each method mirrors MonsterMashAnnouncementHelper exactly,
/// capturing the announcement text for verification.
class MockMonsterMashAudioQueueService {
  final List<String> _announcements = [];

  /// Get all announcements that have been queued
  List<String> get announcements => List.unmodifiable(_announcements);

  /// Clear all captured announcements
  void clearAnnouncements() {
    _announcements.clear();
  }

  /// Mock implementation of announce - just captures the text
  void announce(String text) {
    _announcements.add(text);
    debugPrint('Mock announcement: $text');
  }

  // --- Game-specific announcement methods (matching MonsterMashAnnouncementHelper) ---

  void announceGameStart() {
    announce('Welcome to Monster Mash! Let the battle begin!');
  }

  void announceTurn(String playerName) {
    announce('$playerName, your turn');
  }

  void announceHit(int number, String multiplier, {bool isMiss = false}) {
    if (isMiss) {
      announce('Miss');
      return;
    }

    String text = '';
    if (number == 50) {
      text = 'Bullseye!';
    } else if (number == 25) {
      text = 'Outer bull';
    } else {
      final mult = multiplier == 'double'
          ? 'Double'
          : (multiplier == 'triple' ? 'Triple' : 'Single');
      text = '$mult $number';
    }

    announce(text);
  }

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

    announce(text);
  }

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

    announce(text);
  }

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

    announce(text);
  }

  void announceElimination(String playerName) {
    announce('$playerName! Back to the shadows!');
  }

  void announceHatTrick(String playerName) {
    announce('MONSTROUS! Triple strike on $playerName!');
  }

  void announceHatTrickElimination(String playerName) {
    announce('MONSTROUS! Triple strike eliminates $playerName!');
  }

  void announceCombinedElimination(List<String> playerNames) {
    final names = playerNames.join(' and ');
    announce('$names! Back to the shadows!');
  }

  void announceClutchHeal(String playerName) {
    announce('$playerName rises from near death!');
  }

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

    announce(text);
  }

  void announceRemoveDarts() {
    announce('Remove your darts');
  }

  void announceWinner(String playerName) {
    announce('GAME OVER! The night belongs to $playerName!');
  }

  void announceWinners(List<String> playerNames) {
    if (playerNames.length == 1) {
      announceWinner(playerNames.first);
      return;
    }
    final names = playerNames.join(' and ');
    announce('GAME OVER! The night is shared by $names!');
  }

  void dispose() {
    _announcements.clear();
  }
}

import 'package:flutter/foundation.dart';
import 'package:dart_games/models/reef_royale_game.dart';

/// Mock audio queue service that captures announcements for testing
/// instead of playing them through web audio APIs.
class MockReefRoyaleAudioQueueService {
  final List<String> _announcements = [];

  List<String> get announcements => List.unmodifiable(_announcements);

  void clearAnnouncements() {
    _announcements.clear();
  }

  void announce(String text) {
    _announcements.add(text);
    debugPrint('Mock announcement: $text');
  }

  // --- Game Events ---

  void announceGameStart() {
    announce('Dive in! The reef awaits!');
  }

  void announceRandomReefs() {
    announce('The reef has shifted!');
  }

  void announceTurn(String playerName) {
    announce('$playerName, your turn to swim!');
  }

  void announceRemoveDarts() {
    announce('Remove your darts');
  }

  // --- Dart Events ---

  void announceMiss() {
    announce('That one drifted with the current!');
  }

  void announceNonTarget() {
    announce("That reef isn't on the map!");
  }

  void announceSingleMark(String coralName) {
    announce('A fish arrives at $coralName!');
  }

  void announceDoubleMark(String coralName) {
    announce('A school gathers at $coralName!');
  }

  void announceTripleMark(String coralName) {
    announce('A triple! $coralName blooms!');
  }

  void announceNeighborMark(String coralName) {
    announce('A neighbor fish drifts to $coralName!');
  }

  void announceCoralClaimed(String playerName, String coralName) {
    announce('$playerName claims $coralName! It blooms!');
  }

  void announceReefLocked(String coralName) {
    announce('$coralName is locked! The reef is sealed!');
  }

  void announceScoring(String playerName, int pearls) {
    if (pearls >= 40) {
      announce('A massive pearl haul! $pearls pearls!');
    } else {
      announce('$playerName harvests $pearls pearls!');
    }
  }

  void announceCursedScoring(int pearls, String opponentName) {
    announce('Cursed tide! $pearls pearls weigh down $opponentName!');
  }

  void announceNearVictory(String playerName) {
    announce('$playerName has six corals! One more!');
  }

  // --- Buff Events ---

  void announceBuff(ReefBuff buff) {
    String text;
    switch (buff) {
      case ReefBuff.riptideRush:
        text = 'Riptide rush! Double marks this round!';
      case ReefBuff.pearlFever:
        text = 'Pearl fever! Double pearls this round!';
      case ReefBuff.inkCloud:
        text = 'Ink cloud! The reef goes dark!';
    }
    announce(text);
  }

  // --- Game Completion ---

  void announceSpeedPlayEnd() {
    announce("Time's up! The tides decide the winner!");
  }

  void announceVictory(String playerName) {
    announce('All hail $playerName, Crown of the Reef!');
  }

  void dispose() {
    _announcements.clear();
  }
}

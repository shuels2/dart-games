import 'package:flutter/foundation.dart';
import 'package:dart_games/models/player.dart';

/// Mock announcement service for Clockwork Quest tests.
///
/// Captures announcement text without invoking web audio APIs.
/// Mirrors the methods of ClockworkQuestAnnouncementHelper.
class MockClockworkQuestAudioQueueService {
  final List<String> _announcements = [];

  List<String> get announcements => List.unmodifiable(_announcements);

  void clearAnnouncements() {
    _announcements.clear();
  }

  void announce(String text) {
    _announcements.add(text);
    debugPrint('Mock announcement: $text');
  }

  void announceGameStart() {
    announce('Wind the gears! The quest begins!');
  }

  void announcePlayerTurn(Player player) {
    announce('${player.name}, your turn to tinker!');
  }

  void announceGearActivated(int gearNumber) {
    announce('Gear $gearNumber turns! Onward!');
  }

  void announceDoubleAdvance(Player player) {
    announce('${player.name} hits a double! Two gears turn!');
  }

  void announceTripleAdvance(Player player) {
    announce('${player.name} hits a triple! Three gears turn!');
  }

  void announceMiss() {
    announce('Steam vents! That\'s not the right gear!');
  }

  void announceBullseyeTarget() {
    announce('One final gear! Hit the bullseye to crown the clock!');
  }

  void announceBullseyeHit() {
    announce('The crown gear turns! Magnificent!');
  }

  void announceHalfway(Player player) {
    announce('${player.name} is halfway! The clock is ticking!');
  }

  void announceNearVictory(Player player, int gearsLeft) {
    announce('${player.name} is almost there! Just $gearsLeft gears left!');
  }

  void announceLapComplete() {
    announce('Lap complete! Wind it again!');
  }

  void announceTimeExpiry() {
    announce('Time\'s up! The gears wait for no one!');
  }

  void announceVictory(Player winner) {
    announce('All gears turn! ${winner.name} wins the Clockwork Crown!');
  }

  void announceRemoveDarts(Player player) {
    announce('${player.name}, remove your darts!');
  }

  void dispose() {
    _announcements.clear();
  }
}

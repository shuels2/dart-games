import 'package:flutter/foundation.dart';

/// Mock audio queue service that captures announcements for testing
/// instead of actually playing them through web audio APIs
class MockTargetTagAudioQueueService {
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

  // ─── Name formatting (mirrors TargetTagAnnouncementHelper) ─────────────

  static String _formatNames(List<String> names, {List<String>? allPlayerNames}) {
    if (allPlayerNames != null && names.length == allPlayerNames.length && allPlayerNames.length > 1) {
      return 'all players';
    }
    if (allPlayerNames == null || names.length <= 4) {
      if (names.length == 1) return names[0];
      if (names.length == 2) return '${names[0]} and ${names[1]}';
      return '${names.sublist(0, names.length - 1).join(', ')}, and ${names.last}';
    }
    final excluded = allPlayerNames!.where((n) => !names.contains(n)).toList();
    if (excluded.isEmpty) return 'all players';
    if (excluded.length == 1) return 'all players except ${excluded[0]}';
    if (excluded.length == 2) return 'all players except ${excluded[0]} and ${excluded[1]}';
    return 'all players except ${excluded.sublist(0, excluded.length - 1).join(', ')}, and ${excluded.last}';
  }

  static String _verb(List<String> names, {List<String>? allPlayerNames}) {
    if (names.length >= 5) return 'are';
    if (allPlayerNames != null && names.length == allPlayerNames.length && allPlayerNames.length > 1) return 'are';
    return names.length == 1 ? 'is' : 'are';
  }

  // ─── Game-specific announcement methods ────────────────────────────────

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
      final mult = multiplier == 'double' ? 'Double' : (multiplier == 'triple' ? 'Triple' : 'Single');
      text = '$mult $number';
    }
    announce(text);
  }

  void announceShieldGained(String playerName, int shields, int shieldMax) {
    announce('$shields shields');
  }

  void announceTaggedIn(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = _formatNames(playerNames, allPlayerNames: allPlayerNames);
    final verb = _verb(playerNames, allPlayerNames: allPlayerNames);
    announce('JACKPOT! $names $verb TAGGED IN!');
  }

  void announceTaggedOut(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = _formatNames(playerNames, allPlayerNames: allPlayerNames);
    final verb = _verb(playerNames, allPlayerNames: allPlayerNames);
    announce('Shield compromised! $names $verb back on the hunt.');
  }

  void announceLowShields(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = _formatNames(playerNames, allPlayerNames: allPlayerNames);
    announce('Warning! Shields almost gone for $names!');
  }

  void announceVulnerable(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = _formatNames(playerNames, allPlayerNames: allPlayerNames);
    final verb = _verb(playerNames, allPlayerNames: allPlayerNames);
    announce('DANGER! $names $verb vulnerable! One more hit and you\'re out!');
  }

  void announceEliminated(List<String> playerNames, {List<String>? allPlayerNames}) {
    final names = _formatNames(playerNames, allPlayerNames: allPlayerNames);
    final verb = _verb(playerNames, allPlayerNames: allPlayerNames);
    announce('$names $verb Tagged Out! Better luck next time!');
  }

  void announceSuccessfulTag() {
    announce('Tag! Got \'em!');
  }

  void announceTurn(String playerName) {
    announce('$playerName, your turn');
  }

  void announceGameStart() {
    announce('Welcome to Target Tag! Fill those shields!');
  }

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
      names = '${playerNames.sublist(0, playerNames.length - 1).join(', ')}, and ${playerNames.last}';
      verb = 'are the Target Tag Champions';
    }
    announce('GAME OVER! $names $verb!');
  }

  void announceRemoveDarts() {
    announce('Remove your darts');
  }

  void dispose() {
    _announcements.clear();
  }
}

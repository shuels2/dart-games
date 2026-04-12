import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import '../../../mocks/mock_clockwork_quest_audio_queue_service.dart';

/// Clockwork Quest Announcement Tests
///
/// Validates that each announcement method produces the correct text.
/// Uses a mock queue service to capture announcements without web audio APIs.
/// Based on spec Section 9.
void main() {
  late MockClockworkQuestAudioQueueService mockQueue;
  late Player testPlayer;

  setUp(() {
    mockQueue = MockClockworkQuestAudioQueueService();
    testPlayer = Player.create(name: 'TestPlayer');
  });

  tearDown(() {
    mockQueue.dispose();
  });

  group('Clockwork Quest Announcements', () {
    test('Game Start announcement', () {
      mockQueue.announceGameStart();
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'Wind the gears! The quest begins!');
    });

    test('Player Turn announcement', () {
      mockQueue.announcePlayerTurn(testPlayer);
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'TestPlayer, your turn to tinker!');
    });

    test('Gear Activated announcement', () {
      mockQueue.announceGearActivated(5);
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'Gear 5 turns! Onward!');
    });

    test('Double Advance announcement', () {
      mockQueue.announceDoubleAdvance(testPlayer);
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'TestPlayer hits a double! Two gears turn!');
    });

    test('Triple Advance announcement', () {
      mockQueue.announceTripleAdvance(testPlayer);
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'TestPlayer hits a triple! Three gears turn!');
    });

    test('Miss announcement', () {
      mockQueue.announceMiss();
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'Steam vents! That\'s not the right gear!');
    });

    test('Bullseye Target announcement', () {
      mockQueue.announceBullseyeTarget();
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0],
          'One final gear! Hit the bullseye to crown the clock!');
    });

    test('Bullseye Hit announcement', () {
      mockQueue.announceBullseyeHit();
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'The crown gear turns! Magnificent!');
    });

    test('Halfway announcement', () {
      mockQueue.announceHalfway(testPlayer);
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'TestPlayer is halfway! The clock is ticking!');
    });

    test('Near Victory announcement', () {
      mockQueue.announceNearVictory(testPlayer, 2);
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0],
          'TestPlayer is almost there! Just 2 gears left!');
    });

    test('Lap Complete announcement', () {
      mockQueue.announceLapComplete();
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'Lap complete! Wind it again!');
    });

    test('Speed Mode Time Expiry announcement', () {
      mockQueue.announceTimeExpiry();
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'Time\'s up! The gears wait for no one!');
    });

    test('Victory announcement', () {
      mockQueue.announceVictory(testPlayer);
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0],
          'All gears turn! TestPlayer wins the Clockwork Crown!');
    });

    test('Remove Darts announcement', () {
      mockQueue.announceRemoveDarts(testPlayer);
      expect(mockQueue.announcements.length, 1);
      expect(mockQueue.announcements[0], 'TestPlayer, remove your darts!');
    });

    test('Multiple announcements accumulate', () {
      mockQueue.announceGearActivated(20);
      mockQueue.announceVictory(testPlayer);
      mockQueue.announceRemoveDarts(testPlayer);
      expect(mockQueue.announcements.length, 3);
    });

    test('clearAnnouncements resets the list', () {
      mockQueue.announceGameStart();
      mockQueue.clearAnnouncements();
      expect(mockQueue.announcements.isEmpty, isTrue);
    });

    test('Gear 1 announcement', () {
      mockQueue.announceGearActivated(1);
      expect(mockQueue.announcements[0], 'Gear 1 turns! Onward!');
    });

    test('Gear 20 announcement', () {
      mockQueue.announceGearActivated(20);
      expect(mockQueue.announcements[0], 'Gear 20 turns! Onward!');
    });
  });
}

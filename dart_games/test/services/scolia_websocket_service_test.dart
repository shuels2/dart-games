// Unit tests for ScoliaWebSocketService pure-function helpers.
//
// The full service (channel.connect, listen, dispose) requires a live
// WebSocket and isn't exercised here. The heartbeat-stale check IS
// pure and is the production-critical bit — it's what detects the
// client-sleep / wake half-dead WebSocket case, so we cover it
// directly.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/scolia_websocket_service.dart';

void main() {
  group('ScoliaWebSocketService.isHeartbeatStale', () {
    test('null lastSentAt is never stale', () {
      // No GET_SBC_STATUS outstanding → connection isn't being tested.
      expect(
        ScoliaWebSocketService.isHeartbeatStale(
          lastSentAt: null,
          now: DateTime(2026, 1, 1),
        ),
        isFalse,
      );
    });

    test('fresh send (within window) is not stale', () {
      final sent = DateTime(2026, 1, 1, 12, 0, 0);
      final now = sent.add(const Duration(milliseconds: 1000));
      expect(
        ScoliaWebSocketService.isHeartbeatStale(lastSentAt: sent, now: now),
        isFalse,
      );
    });

    test('exactly at the timeout threshold is not stale (strict >)', () {
      final sent = DateTime(2026, 1, 1, 12, 0, 0);
      final now = sent.add(Duration(
          milliseconds: ScoliaWebSocketService.heartbeatTimeoutMs));
      expect(
        ScoliaWebSocketService.isHeartbeatStale(lastSentAt: sent, now: now),
        isFalse,
      );
    });

    test('past the timeout threshold is stale', () {
      final sent = DateTime(2026, 1, 1, 12, 0, 0);
      final now = sent.add(Duration(
          milliseconds: ScoliaWebSocketService.heartbeatTimeoutMs + 1));
      expect(
        ScoliaWebSocketService.isHeartbeatStale(lastSentAt: sent, now: now),
        isTrue,
      );
    });

    test('long-overdue (1 minute) is stale', () {
      final sent = DateTime(2026, 1, 1, 12, 0, 0);
      final now = sent.add(const Duration(minutes: 1));
      expect(
        ScoliaWebSocketService.isHeartbeatStale(lastSentAt: sent, now: now),
        isTrue,
      );
    });
  });
}

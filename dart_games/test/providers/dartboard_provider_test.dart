import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/dartboard_provider.dart';
import '../shared/mock_api_helpers.dart';

/// Helper: useEmulator is async void, so we must wait for the internal
/// `await _saveConfiguration(...)` to complete before the emulator is active.
Future<void> _waitForAsyncUseEmulator() async {
  // Allow microtask queue to drain (the mock API responds synchronously,
  // so one pump is sufficient).
  await Future.delayed(Duration.zero);
}

void main() {
  late MockApiServer mockServer;
  late DartboardProvider provider;

  setUp(() {
    mockServer = MockApiServer();
    provider = DartboardProvider();
    provider.initialize(mockServer.apiClient);
  });

  tearDown(() async {
    // Wait for any pending async work from useEmulator before disposing
    await Future.delayed(Duration.zero);
    provider.dispose();
  });

  group('DartboardProvider - initial state', () {
    test('starts disconnected with no dartboard', () {
      expect(provider.status, DartboardConnectionStatus.disconnected);
      expect(provider.dartboard, isNull);
      expect(provider.error, isNull);
      expect(provider.isConnected, false);
      expect(provider.isEmulator, false);
      expect(provider.canPlayGames, false);
      expect(provider.isRegistered, false);
    });

    test('savedProfiles starts empty', () {
      expect(provider.savedProfiles, isEmpty);
    });

    test('dartboardEventStream is a stable broadcast bus (never null)', () {
      // The stream is provider-owned so game screens can subscribe once
      // in initState and stay attached across WebSocket reconnects. When
      // no source is wired, the bus is simply idle — no events flow.
      final stream = provider.dartboardEventStream;
      expect(stream, isNotNull);
      expect(stream!.isBroadcast, isTrue);
    });
  });

  group('DartboardProvider - event bus (reconnect resilience)', () {
    // Regression guard for the bug where a WebSocket reconnect (or any
    // source swap) silently killed the dart-throw stream because game
    // screens held a subscription to the OLD source. The provider now
    // owns a stable bus and rewires the underlying source into it, so a
    // single subscription placed in a game screen's initState keeps
    // delivering events across arbitrarily many reconnects. Simulated
    // here with two `useEmulator` calls; each call swaps the mock
    // service under the subscriber.
    test('bus keeps delivering events after the source is swapped',
        () async {
      provider.useEmulator(name: 'Board A', serialNumber: 'SN-A');
      await _waitForAsyncUseEmulator();

      // Single, stable subscription — mirrors game screen's initState
      // listen(). NEVER re-subscribed for the rest of this test.
      final throws = <Map<String, dynamic>>[];
      final sub = provider.dartboardEventStream!.listen((event) {
        if (event['type'] == 'throw_detected') throws.add(event);
      });

      // First source fires a throw.
      provider.apiService!.simulateDartThrow(
        score: 20,
        multiplier: 'single',
        playerName: 'P1',
        baseScore: 20,
        widgetX: 100,
        widgetY: 100,
        widgetSize: 200,
      );
      await Future.delayed(Duration.zero);
      expect(throws, hasLength(1));

      // Source swap — this is what a real reconnect looks like from the
      // bus's perspective.
      provider.useEmulator(name: 'Board B', serialNumber: 'SN-B');
      await _waitForAsyncUseEmulator();

      // The NEW source fires a throw. The subscription from before the
      // swap must still receive it.
      provider.apiService!.simulateDartThrow(
        score: 10,
        multiplier: 'single',
        playerName: 'P1',
        baseScore: 10,
        widgetX: 100,
        widgetY: 100,
        widgetSize: 200,
      );
      await Future.delayed(Duration.zero);
      expect(throws, hasLength(2),
          reason: 'bus should forward events from the new source into '
              'the pre-existing subscription');

      await sub.cancel();
    });

    // In a real app the bus has more than one subscriber at a time:
    // the game screen listens for dart throws AND the app-root pause
    // announcer listens for status blips off the same stream. Both
    // must survive a source swap.
    test('multiple concurrent subscribers all survive a source swap',
        () async {
      provider.useEmulator(name: 'Board A', serialNumber: 'SN-A');
      await _waitForAsyncUseEmulator();

      final receivedA = <Map<String, dynamic>>[];
      final receivedB = <Map<String, dynamic>>[];
      final subA = provider.dartboardEventStream!.listen((e) {
        if (e['type'] == 'throw_detected') receivedA.add(e);
      });
      final subB = provider.dartboardEventStream!.listen((e) {
        if (e['type'] == 'throw_detected') receivedB.add(e);
      });

      // Source swap.
      provider.useEmulator(name: 'Board B', serialNumber: 'SN-B');
      await _waitForAsyncUseEmulator();

      // NEW source fires a throw. Both subscriptions receive it.
      provider.apiService!.simulateDartThrow(
        score: 5,
        multiplier: 'single',
        playerName: 'P1',
        baseScore: 5,
        widgetX: 100,
        widgetY: 100,
        widgetSize: 200,
      );
      await Future.delayed(Duration.zero);

      expect(receivedA, hasLength(1));
      expect(receivedB, hasLength(1));

      await subA.cancel();
      await subB.cancel();
    });

    // Guards against the old-source subscription leaking events after
    // a swap. When we rewire the bus, the prior _sourceSubscription
    // must be cancelled so events from a disposed/stale source can't
    // still bleed into the bus.
    test('after a swap, the OLD source no longer delivers to the bus',
        () async {
      provider.useEmulator(name: 'Board A', serialNumber: 'SN-A');
      await _waitForAsyncUseEmulator();
      final oldSource = provider.apiService!;

      final throws = <Map<String, dynamic>>[];
      final sub = provider.dartboardEventStream!.listen((e) {
        if (e['type'] == 'throw_detected') throws.add(e);
      });

      provider.useEmulator(name: 'Board B', serialNumber: 'SN-B');
      await _waitForAsyncUseEmulator();
      final newSource = provider.apiService!;
      expect(identical(oldSource, newSource), isFalse,
          reason: 'each useEmulator call must instantiate a fresh mock');

      // Fire on the OLD source. Must NOT reach the bus.
      oldSource.simulateDartThrow(
        score: 99,
        multiplier: 'single',
        playerName: 'ghost',
        baseScore: 20,
        widgetX: 100,
        widgetY: 100,
        widgetSize: 200,
      );
      await Future.delayed(Duration.zero);
      expect(throws, isEmpty,
          reason: 'stale source subscription should have been cancelled '
              'when the bus rewired to the new source');

      await sub.cancel();
    });
  });

  group('DartboardProvider - emulator mode', () {
    test('useEmulator sets emulator status after async completes', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();

      expect(provider.status, DartboardConnectionStatus.emulator);
      expect(provider.isEmulator, true);
      expect(provider.canPlayGames, true);
      expect(provider.isConnected, false);
      expect(provider.error, isNull);
      expect(provider.dartboard, isNotNull);
      expect(provider.dartboard!.name, 'Test Board');
      expect(provider.dartboard!.serialNumber, 'SN-001');
    });

    test('useEmulator sets dartboard synchronously', () {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');

      // Dartboard is set synchronously, but status is not yet emulator
      expect(provider.dartboard, isNotNull);
      expect(provider.dartboard!.name, 'Test Board');
      expect(provider.isRegistered, true);
    });

    test('useEmulator saves configuration to API', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();

      expect(mockServer.dartboard['name'], 'Test Board');
      expect(mockServer.dartboard['serialNumber'], 'SN-001');
      expect(mockServer.dartboard['useEmulator'], true);
    });

    test('useEmulator provides event stream', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();

      expect(provider.dartboardEventStream, isNotNull);
      expect(provider.apiService, isNotNull);
    });
  });

  group('DartboardProvider - clear dartboard', () {
    test('clearDartboard resets all state', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();
      expect(provider.isEmulator, true);

      await provider.clearDartboard();

      expect(provider.status, DartboardConnectionStatus.disconnected);
      expect(provider.dartboard, isNull);
      expect(provider.error, isNull);
      expect(provider.canPlayGames, false);
      expect(provider.isRegistered, false);
    });

    test('clearDartboard clears API state', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();
      await provider.clearDartboard();

      expect(mockServer.dartboard['name'], isNull);
      expect(mockServer.dartboard['serialNumber'], isNull);
    });
  });

  group('DartboardProvider - clear error', () {
    test('clearError sets error to null', () {
      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  group('DartboardProvider - connection profiles', () {
    test('saveConnectionProfile stores profile', () async {
      await provider.saveConnectionProfile('Board A', 'SN-A', 'key-A');

      expect(mockServer.dartboardProfiles, hasLength(1));
      expect(mockServer.dartboardProfiles[0]['name'], 'Board A');
      expect(mockServer.dartboardProfiles[0]['serialNumber'], 'SN-A');
      expect(mockServer.dartboardProfiles[0]['apiKey'], 'key-A');
    });

    test('saveConnectionProfile upserts by serial number', () async {
      await provider.saveConnectionProfile('Board A', 'SN-A', 'key-A');
      await provider.saveConnectionProfile('Board A Updated', 'SN-A', 'key-A-new');

      expect(mockServer.dartboardProfiles, hasLength(1));
      expect(mockServer.dartboardProfiles[0]['name'], 'Board A Updated');
      expect(mockServer.dartboardProfiles[0]['apiKey'], 'key-A-new');
    });

    test('saveConnectionProfile adds multiple unique profiles', () async {
      await provider.saveConnectionProfile('Board A', 'SN-A', 'key-A');
      await provider.saveConnectionProfile('Board B', 'SN-B', 'key-B');

      expect(mockServer.dartboardProfiles, hasLength(2));
    });

    test('loadSavedProfiles loads from API', () async {
      await provider.saveConnectionProfile('Board A', 'SN-A', 'key-A');
      await provider.saveConnectionProfile('Board B', 'SN-B', 'key-B');

      final newProvider = DartboardProvider();
      newProvider.initialize(mockServer.apiClient);
      await newProvider.loadSavedProfiles();

      expect(newProvider.savedProfiles, hasLength(2));
      newProvider.dispose();
    });

    test('loadSavedProfiles sorts by lastUsed descending', () async {
      await provider.saveConnectionProfile('Board A', 'SN-A', 'key-A');
      await Future.delayed(const Duration(milliseconds: 10));
      await provider.saveConnectionProfile('Board B', 'SN-B', 'key-B');

      final newProvider = DartboardProvider();
      newProvider.initialize(mockServer.apiClient);
      await newProvider.loadSavedProfiles();

      expect(newProvider.savedProfiles[0].serialNumber, 'SN-B');
      expect(newProvider.savedProfiles[1].serialNumber, 'SN-A');
      newProvider.dispose();
    });

    test('deleteConnectionProfile removes profile', () async {
      await provider.saveConnectionProfile('Board A', 'SN-A', 'key-A');
      await provider.saveConnectionProfile('Board B', 'SN-B', 'key-B');

      await provider.deleteConnectionProfile('SN-A');

      expect(mockServer.dartboardProfiles, hasLength(1));
      expect(mockServer.dartboardProfiles[0]['serialNumber'], 'SN-B');
    });

    test('deleteConnectionProfile updates local list', () async {
      await provider.saveConnectionProfile('Board A', 'SN-A', 'key-A');
      await provider.deleteConnectionProfile('SN-A');

      expect(provider.savedProfiles, isEmpty);
    });
  });

  group('DartboardProvider - loadConfiguration', () {
    test('loadConfiguration with emulator config activates emulator', () async {
      mockServer.dartboard = {
        'name': 'My Board',
        'serialNumber': 'SN-123',
        'apiKey': null,
        'useEmulator': true,
      };

      await provider.loadConfiguration();

      expect(provider.status, DartboardConnectionStatus.emulator);
      expect(provider.dartboard!.name, 'My Board');
      expect(provider.canPlayGames, true);
    });

    test('loadConfiguration with no config stays disconnected', () async {
      await provider.loadConfiguration();

      expect(provider.status, DartboardConnectionStatus.disconnected);
      expect(provider.dartboard, isNull);
    });

    test('loadConfiguration loads saved profiles', () async {
      mockServer.dartboardProfiles.add({
        'name': 'Saved Board',
        'serialNumber': 'SN-SAVED',
        'apiKey': 'saved-key',
        'lastUsed': DateTime.now().toIso8601String(),
      });

      await provider.loadConfiguration();

      expect(provider.savedProfiles, hasLength(1));
      expect(provider.savedProfiles[0].name, 'Saved Board');
    });
  });

  group('DartboardProvider - switchToEmulator', () {
    test('switchToEmulator does nothing without dartboard', () {
      provider.switchToEmulator();
      expect(provider.status, DartboardConnectionStatus.disconnected);
    });
  });

  group('DartboardProvider - status checking', () {
    test('startStatusChecking does nothing in emulator mode', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();

      provider.startStatusChecking();
      expect(provider.isEmulator, true);
    });

    test('stopStatusChecking is safe to call multiple times', () {
      provider.stopStatusChecking();
      provider.stopStatusChecking();
    });
  });

  group('DartboardProvider - getters', () {
    test('canPlayGames is true for emulator', () async {
      expect(provider.canPlayGames, false);

      provider.useEmulator(name: 'Test', serialNumber: 'SN');
      await _waitForAsyncUseEmulator();

      expect(provider.canPlayGames, true);
    });

    test('isRegistered reflects dartboard state', () {
      expect(provider.isRegistered, false);

      provider.useEmulator(name: 'Test', serialNumber: 'SN');
      // Dartboard is set synchronously
      expect(provider.isRegistered, true);
    });

    test('savedProfiles returns unmodifiable list', () {
      expect(() => (provider.savedProfiles as List).add(null), throwsA(anything));
    });
  });

  group('DartboardProvider - notifyListeners', () {
    test('clearDartboard triggers change notification', () async {
      provider.useEmulator(name: 'Test', serialNumber: 'SN');
      await _waitForAsyncUseEmulator();

      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.clearDartboard();
      expect(notified, true);
    });

    test('clearError triggers change notification', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.clearError();
      expect(notified, true);
    });

    test('saveConnectionProfile triggers change notification', () async {
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.saveConnectionProfile('Board', 'SN', 'key');
      expect(notified, true);
    });

    test('deleteConnectionProfile triggers change notification', () async {
      await provider.saveConnectionProfile('Board', 'SN', 'key');

      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.deleteConnectionProfile('SN');
      expect(notified, true);
    });
  });

  group('DartboardProvider - test simulation methods', () {
    test('simulateDisconnection sets status to error', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();
      expect(provider.status, DartboardConnectionStatus.emulator);

      provider.simulateDisconnection();
      expect(provider.status, DartboardConnectionStatus.error);
    });

    test('simulateDisconnection sets isEmulator to false', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();
      expect(provider.isEmulator, true);

      provider.simulateDisconnection();
      expect(provider.isEmulator, false);
    });

    test('simulateReconnection restores emulator status', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();

      provider.simulateDisconnection();
      expect(provider.status, DartboardConnectionStatus.error);

      provider.simulateReconnection();
      expect(provider.status, DartboardConnectionStatus.emulator);
      expect(provider.isEmulator, true);
    });

    test('simulateDisconnection then simulateReconnection round-trips', () async {
      provider.useEmulator(name: 'Test Board', serialNumber: 'SN-001');
      await _waitForAsyncUseEmulator();

      provider.simulateDisconnection();
      expect(provider.isEmulator, false);
      expect(provider.canPlayGames, false);

      provider.simulateReconnection();
      expect(provider.isEmulator, true);
      expect(provider.canPlayGames, true);
      expect(provider.error, null);
    });
  });

  group('DartboardProvider.backoffMs (auto-reconnect curve)', () {
    test('first attempt waits 1s', () {
      expect(DartboardProvider.backoffMs(0), 1000);
    });

    test('curve doubles each attempt: 1, 2, 4, 8 s', () {
      expect(DartboardProvider.backoffMs(0), 1000);
      expect(DartboardProvider.backoffMs(1), 2000);
      expect(DartboardProvider.backoffMs(2), 4000);
      expect(DartboardProvider.backoffMs(3), 8000);
    });

    test('caps at 15s once the doubling curve exceeds it', () {
      // 2^4 * 1000 = 16000 > cap; clamps to 15000.
      expect(DartboardProvider.backoffMs(4), 15000);
      expect(DartboardProvider.backoffMs(5), 15000);
      expect(DartboardProvider.backoffMs(10), 15000);
    });

    test('never returns 0 or negative', () {
      for (var i = 0; i < 12; i++) {
        expect(DartboardProvider.backoffMs(i), greaterThan(0));
      }
    });
  });
}

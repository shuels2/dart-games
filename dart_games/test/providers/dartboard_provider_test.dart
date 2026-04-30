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

    test('dartboardEventStream is null when disconnected', () {
      expect(provider.dartboardEventStream, isNull);
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
}

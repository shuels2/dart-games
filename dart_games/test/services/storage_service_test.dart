import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/storage_service.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late StorageService storage;

  setUp(() {
    mockServer = MockApiServer();
    storage = StorageService(mockServer.apiClient);
    // Clear static singleton to avoid cross-test contamination
    StorageService.testInstance = null;
  });

  tearDown(() {
    StorageService.testInstance = null;
  });

  group('StorageService - static singleton', () {
    test('initialize creates instance accessible via instance getter', () {
      StorageService.initialize(mockServer.apiClient);
      expect(StorageService.instance, isA<StorageService>());
    });

    test('instance throws StateError when not initialized', () {
      expect(
        () => StorageService.instance,
        throwsA(isA<StateError>()),
      );
    });

    test('testInstance setter allows setting singleton directly', () {
      StorageService.testInstance = storage;
      expect(StorageService.instance, same(storage));
    });

    test('testInstance null clears the singleton', () {
      StorageService.initialize(mockServer.apiClient);
      StorageService.testInstance = null;
      expect(
        () => StorageService.instance,
        throwsA(isA<StateError>()),
      );
    });
  });

  group('StorageService - bearer token', () {
    test('saveBearerToken and getBearerToken round-trip', () async {
      await storage.saveBearerToken('my-secret-token');
      final result = await storage.getBearerToken();
      expect(result, 'my-secret-token');
    });

    test('getBearerToken returns null when not set', () async {
      final result = await storage.getBearerToken();
      expect(result, isNull);
    });

    test('saveBearerToken overwrites previous value', () async {
      await storage.saveBearerToken('first-token');
      await storage.saveBearerToken('second-token');
      final result = await storage.getBearerToken();
      expect(result, 'second-token');
    });
  });

  group('StorageService - serial number', () {
    test('saveSerialNumber and getSerialNumber round-trip', () async {
      await storage.saveSerialNumber('SN-12345');
      final result = await storage.getSerialNumber();
      expect(result, 'SN-12345');
    });

    test('getSerialNumber returns null when not set', () async {
      final result = await storage.getSerialNumber();
      expect(result, isNull);
    });

    test('saveSerialNumber overwrites previous value', () async {
      await storage.saveSerialNumber('SN-111');
      await storage.saveSerialNumber('SN-222');
      final result = await storage.getSerialNumber();
      expect(result, 'SN-222');
    });
  });

  group('StorageService - setup complete', () {
    test('setSetupComplete true and isSetupComplete returns true', () async {
      await storage.setSetupComplete(true);
      final result = await storage.isSetupComplete();
      expect(result, isTrue);
    });

    test('setSetupComplete false and isSetupComplete returns false', () async {
      await storage.setSetupComplete(false);
      final result = await storage.isSetupComplete();
      expect(result, isFalse);
    });

    test('isSetupComplete defaults to false when not set', () async {
      final result = await storage.isSetupComplete();
      expect(result, isFalse);
    });

    test('setSetupComplete can toggle', () async {
      await storage.setSetupComplete(true);
      expect(await storage.isSetupComplete(), isTrue);

      await storage.setSetupComplete(false);
      expect(await storage.isSetupComplete(), isFalse);
    });
  });

  group('StorageService - clearAll', () {
    test('clearAll removes all stored settings', () async {
      await storage.saveBearerToken('token');
      await storage.saveSerialNumber('SN-123');
      await storage.setSetupComplete(true);

      await storage.clearAll();

      expect(await storage.getBearerToken(), isNull);
      expect(await storage.getSerialNumber(), isNull);
      expect(await storage.isSetupComplete(), isFalse);
    });

    test('clearAll works when nothing is stored', () async {
      // Should not throw
      await storage.clearAll();
      expect(await storage.getBearerToken(), isNull);
    });
  });

  group('StorageService - hasAuth', () {
    test('returns false when no bearer token is set', () async {
      final result = await storage.hasAuth();
      expect(result, isFalse);
    });

    test('returns true when bearer token is set', () async {
      await storage.saveBearerToken('some-token');
      final result = await storage.hasAuth();
      expect(result, isTrue);
    });

    test('returns false when bearer token is empty string', () async {
      await storage.saveBearerToken('');
      final result = await storage.hasAuth();
      expect(result, isFalse);
    });
  });

  group('StorageService - hasDartboard', () {
    test('returns false when no serial number is set', () async {
      final result = await storage.hasDartboard();
      expect(result, isFalse);
    });

    test('returns true when serial number is set', () async {
      await storage.saveSerialNumber('SN-999');
      final result = await storage.hasDartboard();
      expect(result, isTrue);
    });

    test('returns false when serial number is empty string', () async {
      await storage.saveSerialNumber('');
      final result = await storage.hasDartboard();
      expect(result, isFalse);
    });
  });

  group('StorageService - integration', () {
    test('different settings are independent', () async {
      await storage.saveBearerToken('token-abc');
      await storage.saveSerialNumber('SN-xyz');

      expect(await storage.getBearerToken(), 'token-abc');
      expect(await storage.getSerialNumber(), 'SN-xyz');
    });

    test('hasAuth and hasDartboard reflect current state', () async {
      expect(await storage.hasAuth(), isFalse);
      expect(await storage.hasDartboard(), isFalse);

      await storage.saveBearerToken('token');
      expect(await storage.hasAuth(), isTrue);
      expect(await storage.hasDartboard(), isFalse);

      await storage.saveSerialNumber('SN-1');
      expect(await storage.hasAuth(), isTrue);
      expect(await storage.hasDartboard(), isTrue);

      await storage.clearAll();
      expect(await storage.hasAuth(), isFalse);
      expect(await storage.hasDartboard(), isFalse);
    });
  });
}

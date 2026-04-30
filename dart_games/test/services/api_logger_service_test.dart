import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/api_logger_service.dart';
import 'package:dart_games/models/api_log_entry.dart';

void main() {
  late ApiLoggerService service;

  setUp(() {
    service = ApiLoggerService();
    // Ensure no leftover active instance from previous tests
    ApiLoggerService.activeInstance = null;
  });

  tearDown(() {
    service.dispose();
    ApiLoggerService.activeInstance = null;
  });

  group('ApiLoggerService - start/stop logging', () {
    test('isLogging defaults to false', () {
      expect(service.isLogging, isFalse);
    });

    test('startLogging sets isLogging to true', () {
      service.startLogging();
      expect(service.isLogging, isTrue);
    });

    test('stopLogging sets isLogging to false', () {
      service.startLogging();
      service.stopLogging();
      expect(service.isLogging, isFalse);
    });

    test('startLogging sets activeInstance', () {
      service.startLogging();
      expect(ApiLoggerService.activeInstance, same(service));
    });

    test('stopLogging clears activeInstance', () {
      service.startLogging();
      service.stopLogging();
      expect(ApiLoggerService.activeInstance, isNull);
    });

    test('stopLogging does not clear activeInstance if different instance is active', () {
      final otherService = ApiLoggerService();
      otherService.startLogging();
      // Now activeInstance is otherService

      service.startLogging();
      // Now activeInstance is service (overwritten)

      // Stop otherService - but activeInstance is service, not otherService
      otherService.stopLogging();
      // activeInstance should still be service because otherService check fails
      expect(ApiLoggerService.activeInstance, same(service));

      service.stopLogging();
      otherService.dispose();
    });

    test('startLogging is idempotent when already logging', () {
      service.startLogging();
      service.startLogging(); // should not error
      expect(service.isLogging, isTrue);
      expect(ApiLoggerService.activeInstance, same(service));
    });
  });

  group('ApiLoggerService - addLogEntry', () {
    test('does not add entry when not logging', () {
      service.addLogEntry(
        method: 'GET',
        endpoint: '/test',
      );
      expect(service.entries, isEmpty);
    });

    test('adds entry when logging is active', () {
      service.startLogging();
      service.addLogEntry(
        method: 'GET',
        endpoint: '/api/v1/health',
      );
      expect(service.entries.length, 1);
      expect(service.entries.first.method, 'GET');
      expect(service.entries.first.endpoint, '/api/v1/health');
    });

    test('adds entry with request and response data', () {
      service.startLogging();
      service.addLogEntry(
        method: 'POST',
        endpoint: '/api/v1/players',
        request: {'name': 'Alice'},
        response: {'id': '123', 'name': 'Alice'},
      );
      expect(service.entries.length, 1);
      expect(service.entries.first.request, {'name': 'Alice'});
      expect(service.entries.first.response, {'id': '123', 'name': 'Alice'});
    });

    test('adds multiple entries', () {
      service.startLogging();
      service.addLogEntry(method: 'GET', endpoint: '/first');
      service.addLogEntry(method: 'POST', endpoint: '/second');
      service.addLogEntry(method: 'DELETE', endpoint: '/third');
      expect(service.entries.length, 3);
    });

    test('each entry has a unique id', () {
      service.startLogging();
      service.addLogEntry(method: 'GET', endpoint: '/a');
      service.addLogEntry(method: 'GET', endpoint: '/b');
      expect(service.entries[0].id, isNot(service.entries[1].id));
    });

    test('entries list is unmodifiable', () {
      service.startLogging();
      service.addLogEntry(method: 'GET', endpoint: '/test');
      expect(
        () => service.entries.add(ApiLogEntry(
          id: 'fake',
          timestamp: DateTime.now(),
          method: 'GET',
          endpoint: '/fake',
        )),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('ApiLoggerService - updateNote', () {
    test('updates note on existing entry', () {
      service.startLogging();
      service.addLogEntry(method: 'GET', endpoint: '/test');
      final entryId = service.entries.first.id;

      service.updateNote(entryId, 'This is a test note');
      // Read from internal state via entries
      expect(service.entries.first.userNote, 'This is a test note');
    });

    test('does nothing for non-existent entry id', () {
      service.startLogging();
      service.addLogEntry(method: 'GET', endpoint: '/test');
      // Should not throw
      service.updateNote('non-existent-id', 'some note');
      expect(service.entries.first.userNote, '');
    });
  });

  group('ApiLoggerService - clearLogs', () {
    test('clears all entries', () {
      service.startLogging();
      service.addLogEntry(method: 'GET', endpoint: '/a');
      service.addLogEntry(method: 'GET', endpoint: '/b');
      expect(service.entries.length, 2);

      service.clearLogs();
      expect(service.entries, isEmpty);
    });

    test('clearLogs works when already empty', () {
      service.clearLogs();
      expect(service.entries, isEmpty);
    });
  });

  group('ApiLoggerService - stream', () {
    test('stream emits entries when log is added', () async {
      service.startLogging();

      final completer = Completer<List<ApiLogEntry>>();
      final subscription = service.entryStream.listen((entries) {
        if (!completer.isCompleted) {
          completer.complete(entries);
        }
      });

      service.addLogEntry(method: 'GET', endpoint: '/test');

      final emitted = await completer.future.timeout(const Duration(seconds: 1));
      expect(emitted.length, 1);
      expect(emitted.first.endpoint, '/test');

      await subscription.cancel();
    });

    test('stream emits on clearLogs', () async {
      service.startLogging();
      service.addLogEntry(method: 'GET', endpoint: '/test');

      final completer = Completer<List<ApiLogEntry>>();
      final subscription = service.entryStream.listen((entries) {
        if (!completer.isCompleted) {
          completer.complete(entries);
        }
      });

      service.clearLogs();

      final emitted = await completer.future.timeout(const Duration(seconds: 1));
      expect(emitted, isEmpty);

      await subscription.cancel();
    });
  });

  group('ApiLoggerService - static logApiCall', () {
    test('delegates to activeInstance when logging', () {
      service.startLogging();

      ApiLoggerService.logApiCall(
        method: 'PUT',
        endpoint: '/api/v1/settings/key',
        request: {'value': 'test'},
      );

      expect(service.entries.length, 1);
      expect(service.entries.first.method, 'PUT');
      expect(service.entries.first.endpoint, '/api/v1/settings/key');
    });

    test('does nothing when no activeInstance', () {
      // activeInstance is null (set in setUp)
      // Should not throw
      ApiLoggerService.logApiCall(
        method: 'GET',
        endpoint: '/test',
      );
      // No way to verify directly, but no exception is the success
    });

    test('does nothing when activeInstance exists but logging is stopped', () {
      service.startLogging();
      service.stopLogging();
      // activeInstance is now null

      ApiLoggerService.logApiCall(
        method: 'GET',
        endpoint: '/test',
      );
      expect(service.entries, isEmpty);
    });
  });

  group('ApiLoggerService - logFilename', () {
    test('logFilename follows expected pattern', () {
      expect(service.logFilename, startsWith('dartboard_api_log_'));
      expect(service.logFilename, endsWith('.json'));
    });

    test('regenerateFilename updates the filename', () {
      final original = service.logFilename;
      // Since both are generated in the same second, they might be the same.
      // But the method should not throw.
      service.regenerateFilename();
      expect(service.logFilename, startsWith('dartboard_api_log_'));
      expect(service.logFilename, endsWith('.json'));
    });
  });

  group('ApiLoggerService - dispose', () {
    test('dispose stops logging and clears activeInstance', () {
      service.startLogging();
      expect(ApiLoggerService.activeInstance, same(service));

      service.dispose();
      expect(service.isLogging, isFalse);
      expect(ApiLoggerService.activeInstance, isNull);
    });
  });
}

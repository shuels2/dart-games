import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/dartboard_routes.dart';

void main() {
  late Database database;
  late Function handler;

  setUp(() {
    database = Database(':memory:');
    final routes = DartboardRoutes(database.rawDb);
    handler = routes.router.call;
  });

  tearDown(() {
    database.close();
  });

  group('DartboardRoutes', () {
    group('GET / (config)', () {
      test('returns default config with nulls and useEmulator=false', () async {
        final response = await handler(
          Request('GET', Uri.parse('http://localhost/')),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['name'], isNull);
        expect(body['serialNumber'], isNull);
        expect(body['apiKey'], isNull);
        expect(body['useEmulator'], isFalse);
      });
    });

    group('PUT / (config)', () {
      test('updates config and returns updated values', () async {
        final response = await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/'),
            body: jsonEncode({
              'name': 'My Board',
              'serialNumber': 'SN-001',
              'apiKey': 'key-abc',
              'useEmulator': true,
            }),
            headers: {'content-type': 'application/json'},
          ),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['name'], equals('My Board'));
        expect(body['serialNumber'], equals('SN-001'));
        expect(body['apiKey'], equals('key-abc'));
        expect(body['useEmulator'], isTrue);
      });

      test('GET / after PUT returns the updated config', () async {
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/'),
            body: jsonEncode({
              'name': 'Board X',
              'serialNumber': 'SN-999',
              'apiKey': 'key-xyz',
              'useEmulator': false,
            }),
            headers: {'content-type': 'application/json'},
          ),
        );

        final response = await handler(
          Request('GET', Uri.parse('http://localhost/')),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['name'], equals('Board X'));
        expect(body['serialNumber'], equals('SN-999'));
        expect(body['apiKey'], equals('key-xyz'));
        expect(body['useEmulator'], isFalse);
      });
    });

    group('DELETE / (config)', () {
      test('resets config to defaults and returns 204', () async {
        // First set some config
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/'),
            body: jsonEncode({
              'name': 'Temp Board',
              'serialNumber': 'SN-TMP',
              'apiKey': 'key-tmp',
              'useEmulator': true,
            }),
            headers: {'content-type': 'application/json'},
          ),
        );

        // Reset
        final deleteResponse = await handler(
          Request('DELETE', Uri.parse('http://localhost/')),
        ) as Response;

        expect(deleteResponse.statusCode, equals(204));

        // Verify defaults restored
        final getResponse = await handler(
          Request('GET', Uri.parse('http://localhost/')),
        ) as Response;
        final body =
            jsonDecode(await getResponse.readAsString()) as Map<String, dynamic>;

        expect(body['name'], isNull);
        expect(body['serialNumber'], isNull);
        expect(body['apiKey'], isNull);
        expect(body['useEmulator'], isFalse);
      });
    });

    group('GET /profiles', () {
      test('returns empty list initially', () async {
        final response = await handler(
          Request('GET', Uri.parse('http://localhost/profiles')),
        ) as Response;
        final body = jsonDecode(await response.readAsString()) as List;

        expect(response.statusCode, equals(200));
        expect(body, isEmpty);
      });

      test('returns profiles sorted by last_used DESC', () async {
        // Create profiles with different lastUsed timestamps
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/profiles/SN-OLD'),
            body: jsonEncode({
              'name': 'Old Board',
              'apiKey': 'key-old',
              'lastUsed': '2024-01-01T00:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          ),
        );
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/profiles/SN-NEW'),
            body: jsonEncode({
              'name': 'New Board',
              'apiKey': 'key-new',
              'lastUsed': '2024-06-15T12:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          ),
        );
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/profiles/SN-MID'),
            body: jsonEncode({
              'name': 'Mid Board',
              'apiKey': 'key-mid',
              'lastUsed': '2024-03-10T06:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          ),
        );

        final response = await handler(
          Request('GET', Uri.parse('http://localhost/profiles')),
        ) as Response;
        final body = jsonDecode(await response.readAsString()) as List;

        expect(response.statusCode, equals(200));
        expect(body, hasLength(3));

        // Most recently used first
        expect(body[0]['serialNumber'], equals('SN-NEW'));
        expect(body[1]['serialNumber'], equals('SN-MID'));
        expect(body[2]['serialNumber'], equals('SN-OLD'));
      });
    });

    group('PUT /profiles/<serialNumber>', () {
      test('creates a new profile', () async {
        final response = await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/profiles/SN-100'),
            body: jsonEncode({
              'name': 'Test Board',
              'apiKey': 'key-100',
              'lastUsed': '2024-05-20T10:30:00Z',
            }),
            headers: {'content-type': 'application/json'},
          ),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['serialNumber'], equals('SN-100'));
        expect(body['name'], equals('Test Board'));
        expect(body['apiKey'], equals('key-100'));
        expect(body['lastUsed'], equals('2024-05-20T10:30:00Z'));
      });

      test('updates existing profile (upsert)', () async {
        // Create
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/profiles/SN-200'),
            body: jsonEncode({
              'name': 'Original Name',
              'apiKey': 'key-orig',
              'lastUsed': '2024-01-01T00:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          ),
        );

        // Update same serial number
        final response = await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/profiles/SN-200'),
            body: jsonEncode({
              'name': 'Updated Name',
              'apiKey': 'key-updated',
              'lastUsed': '2024-07-01T00:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          ),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['name'], equals('Updated Name'));
        expect(body['apiKey'], equals('key-updated'));

        // Verify only one profile exists with that serial number
        final listResponse = await handler(
          Request('GET', Uri.parse('http://localhost/profiles')),
        ) as Response;
        final profiles = jsonDecode(await listResponse.readAsString()) as List;

        expect(profiles, hasLength(1));
        expect(profiles[0]['name'], equals('Updated Name'));
      });
    });

    group('DELETE /profiles/<serialNumber>', () {
      test('removes profile and returns 204', () async {
        // Create a profile
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/profiles/SN-DEL'),
            body: jsonEncode({
              'name': 'Delete Me',
              'apiKey': 'key-del',
              'lastUsed': '2024-04-01T00:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          ),
        );

        // Delete it
        final deleteResponse = await handler(
          Request('DELETE', Uri.parse('http://localhost/profiles/SN-DEL')),
        ) as Response;

        expect(deleteResponse.statusCode, equals(204));

        // Verify it is gone
        final listResponse = await handler(
          Request('GET', Uri.parse('http://localhost/profiles')),
        ) as Response;
        final profiles = jsonDecode(await listResponse.readAsString()) as List;

        expect(profiles, isEmpty);
      });

      test('profile is gone after delete when other profiles remain',
          () async {
        // Create two profiles
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/profiles/SN-KEEP'),
            body: jsonEncode({
              'name': 'Keep Me',
              'apiKey': 'key-keep',
              'lastUsed': '2024-06-01T00:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          ),
        );
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/profiles/SN-REMOVE'),
            body: jsonEncode({
              'name': 'Remove Me',
              'apiKey': 'key-remove',
              'lastUsed': '2024-05-01T00:00:00Z',
            }),
            headers: {'content-type': 'application/json'},
          ),
        );

        // Delete one
        await handler(
          Request('DELETE', Uri.parse('http://localhost/profiles/SN-REMOVE')),
        );

        // Verify only the kept profile remains
        final listResponse = await handler(
          Request('GET', Uri.parse('http://localhost/profiles')),
        ) as Response;
        final profiles = jsonDecode(await listResponse.readAsString()) as List;

        expect(profiles, hasLength(1));
        expect(profiles[0]['serialNumber'], equals('SN-KEEP'));
      });
    });
  });
}

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/routes/settings_routes.dart';

void main() {
  late Database database;
  late Function handler;

  setUp(() {
    database = Database(':memory:');
    final routes = SettingsRoutes(database.rawDb);
    handler = routes.router.call;
  });

  tearDown(() {
    database.close();
  });

  group('SettingsRoutes', () {
    group('GET /', () {
      test('returns empty object initially', () async {
        final response = await handler(
          Request('GET', Uri.parse('http://localhost/')),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body, isEmpty);
      });

      test('returns all settings as flat object', () async {
        // Seed two settings
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/theme'),
            body: jsonEncode({'value': 'dark'}),
            headers: {'content-type': 'application/json'},
          ),
        );
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/volume'),
            body: jsonEncode({'value': '80'}),
            headers: {'content-type': 'application/json'},
          ),
        );

        final response = await handler(
          Request('GET', Uri.parse('http://localhost/')),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body, equals({'theme': 'dark', 'volume': '80'}));
      });
    });

    group('GET /<key>', () {
      test('retrieves an existing setting', () async {
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/lang'),
            body: jsonEncode({'value': 'en'}),
            headers: {'content-type': 'application/json'},
          ),
        );

        final response = await handler(
          Request('GET', Uri.parse('http://localhost/lang')),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body['key'], equals('lang'));
        expect(body['value'], equals('en'));
      });

      test('returns 404 for missing key', () async {
        final response = await handler(
          Request('GET', Uri.parse('http://localhost/nonexistent')),
        ) as Response;

        expect(response.statusCode, equals(404));

        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['error'], contains('nonexistent'));
      });
    });

    group('PUT /<key>', () {
      test('creates a setting and returns key/value', () async {
        final response = await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/color'),
            body: jsonEncode({'value': 'blue'}),
            headers: {'content-type': 'application/json'},
          ),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body, equals({'key': 'color', 'value': 'blue'}));
      });

      test('updates an existing setting', () async {
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/color'),
            body: jsonEncode({'value': 'blue'}),
            headers: {'content-type': 'application/json'},
          ),
        );

        final updateResponse = await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/color'),
            body: jsonEncode({'value': 'red'}),
            headers: {'content-type': 'application/json'},
          ),
        ) as Response;
        final updateBody = jsonDecode(await updateResponse.readAsString())
            as Map<String, dynamic>;

        expect(updateResponse.statusCode, equals(200));
        expect(updateBody, equals({'key': 'color', 'value': 'red'}));

        // Verify the update persisted
        final getResponse = await handler(
          Request('GET', Uri.parse('http://localhost/color')),
        ) as Response;
        final getBody = jsonDecode(await getResponse.readAsString())
            as Map<String, dynamic>;

        expect(getBody['value'], equals('red'));
      });
    });

    group('DELETE /<key>', () {
      test('removes a setting and returns 204', () async {
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/temp'),
            body: jsonEncode({'value': 'val'}),
            headers: {'content-type': 'application/json'},
          ),
        );

        final deleteResponse = await handler(
          Request('DELETE', Uri.parse('http://localhost/temp')),
        ) as Response;

        expect(deleteResponse.statusCode, equals(204));

        // Verify it is gone
        final getResponse = await handler(
          Request('GET', Uri.parse('http://localhost/temp')),
        ) as Response;

        expect(getResponse.statusCode, equals(404));
      });
    });

    group('PUT / (batch)', () {
      test('sets multiple settings at once', () async {
        final response = await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/'),
            body: jsonEncode({'a': '1', 'b': '2', 'c': '3'}),
            headers: {'content-type': 'application/json'},
          ),
        ) as Response;
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;

        expect(response.statusCode, equals(200));
        expect(body, equals({'a': '1', 'b': '2', 'c': '3'}));

        // Verify all were persisted
        final getAllResponse = await handler(
          Request('GET', Uri.parse('http://localhost/')),
        ) as Response;
        final allBody = jsonDecode(await getAllResponse.readAsString())
            as Map<String, dynamic>;

        expect(allBody, equals({'a': '1', 'b': '2', 'c': '3'}));
      });

      test('overwrites existing settings', () async {
        // Create initial settings
        await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/x'),
            body: jsonEncode({'value': 'old'}),
            headers: {'content-type': 'application/json'},
          ),
        );

        // Batch upsert including the existing key
        final response = await handler(
          Request(
            'PUT',
            Uri.parse('http://localhost/'),
            body: jsonEncode({'x': 'new', 'y': 'fresh'}),
            headers: {'content-type': 'application/json'},
          ),
        ) as Response;

        expect(response.statusCode, equals(200));

        // Verify the overwritten value and the new one
        final getAllResponse = await handler(
          Request('GET', Uri.parse('http://localhost/')),
        ) as Response;
        final allBody = jsonDecode(await getAllResponse.readAsString())
            as Map<String, dynamic>;

        expect(allBody['x'], equals('new'));
        expect(allBody['y'], equals('fresh'));
      });
    });
  });
}

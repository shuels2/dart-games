import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/database/database_registry.dart';

void main() {
  group('DatabaseRegistry', () {
    late Database defaultDb;
    late DatabaseRegistry registry;
    late Directory tempDir;

    setUp(() {
      defaultDb = Database(':memory:');
      tempDir = Directory.systemTemp.createTempSync('registry_test_');
      registry = DatabaseRegistry(defaultDb, tempDir.path);
      DatabaseRegistry.initialize(registry);
    });

    tearDown(() {
      registry.closeAll();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('defaultDb returns the raw handle of the default database', () {
      expect(registry.defaultDb, same(defaultDb.rawDb));
    });

    test('current returns default database when no zone session is active',
        () {
      expect(DatabaseRegistry.current, same(defaultDb.rawDb));
    });

    test('session databases are isolated from the default database', () async {
      final middleware = dbSessionMiddleware();
      final handler = middleware((Request request) {
        final db = DatabaseRegistry.current;
        db.execute(
          "INSERT INTO settings (key, value) VALUES ('color', 'blue');",
        );
        return Response.ok('inserted');
      });

      await handler(Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'X-DB-Session': 'session-a'},
      ));

      final defaultRows = defaultDb.rawDb.select('SELECT * FROM settings');
      expect(defaultRows, isEmpty);
    });

    test('different sessions get separate databases', () async {
      final middleware = dbSessionMiddleware();
      final handler = middleware((Request request) {
        final db = DatabaseRegistry.current;
        final session = request.headers['x-db-session']!;
        db.execute(
          "INSERT INTO settings (key, value) VALUES ('session', '$session');",
        );
        final rows = db.select('SELECT * FROM settings');
        return Response.ok('${rows.length}');
      });

      await handler(Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'X-DB-Session': 'session-a'},
      ));

      final resp = await handler(Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'X-DB-Session': 'session-b'},
      ));

      expect(await resp.readAsString(), '1');
    });

    test('same session ID returns the same database', () async {
      final middleware = dbSessionMiddleware();
      final hashes = <int>[];

      final handler = middleware((Request request) {
        hashes.add(DatabaseRegistry.current.hashCode);
        return Response.ok('ok');
      });

      await handler(Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'X-DB-Session': 'same-session'},
      ));
      await handler(Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'X-DB-Session': 'same-session'},
      ));

      expect(hashes[0], hashes[1]);
    });

    test('closeAll clears the singleton', () {
      registry.closeAll();

      expect(
        () => DatabaseRegistry.current,
        throwsA(isA<TypeError>()),
      );
    });

    test('session databases are created in sessions subdirectory', () async {
      final middleware = dbSessionMiddleware();
      final handler = middleware((Request request) {
        DatabaseRegistry.current;
        return Response.ok('ok');
      });

      await handler(Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'X-DB-Session': 'file-test'},
      ));

      final sessDir = Directory('${tempDir.path}/sessions');
      expect(sessDir.existsSync(), isTrue);
      final files = sessDir.listSync().map((f) => f.path).toList();
      expect(files.any((f) => f.contains('file-test')), isTrue);
    });
  });

  group('dbSessionMiddleware', () {
    late Database defaultDb;
    late DatabaseRegistry registry;
    late Directory tempDir;

    setUp(() {
      defaultDb = Database(':memory:');
      tempDir = Directory.systemTemp.createTempSync('middleware_test_');
      registry = DatabaseRegistry(defaultDb, tempDir.path);
      DatabaseRegistry.initialize(registry);
    });

    tearDown(() {
      registry.closeAll();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('uses default database when no X-DB-Session header', () async {
      final middleware = dbSessionMiddleware();
      int? dbHash;

      final handler = middleware((Request request) {
        dbHash = DatabaseRegistry.current.hashCode;
        return Response.ok('ok');
      });

      await handler(
        Request('GET', Uri.parse('http://localhost/test')),
      );

      expect(dbHash, defaultDb.rawDb.hashCode);
    });

    test('routes to session database when X-DB-Session header is present',
        () async {
      final middleware = dbSessionMiddleware();
      int? dbHash;

      final handler = middleware((Request request) {
        dbHash = DatabaseRegistry.current.hashCode;
        return Response.ok('ok');
      });

      await handler(Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'X-DB-Session': 'my-session'},
      ));

      expect(dbHash, isNot(defaultDb.rawDb.hashCode));
    });

    test('empty X-DB-Session header uses default database', () async {
      final middleware = dbSessionMiddleware();
      int? dbHash;

      final handler = middleware((Request request) {
        dbHash = DatabaseRegistry.current.hashCode;
        return Response.ok('ok');
      });

      await handler(Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'X-DB-Session': ''},
      ));

      expect(dbHash, defaultDb.rawDb.hashCode);
    });
  });
}

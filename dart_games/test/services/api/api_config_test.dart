import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/api/api_config.dart';

void main() {
  group('ApiConfig', () {
    setUp(() {
      // Reset to default before each test.
      ApiConfig.configure('http://localhost:8080');
    });

    test('default baseUrl is http://localhost:8080', () {
      expect(ApiConfig.baseUrl, 'http://localhost:8080');
    });

    test('configure sets new base URL', () {
      ApiConfig.configure('http://192.168.1.100:3000');
      expect(ApiConfig.baseUrl, 'http://192.168.1.100:3000');
    });

    test('configure strips trailing slash', () {
      ApiConfig.configure('http://example.com:8080/');
      expect(ApiConfig.baseUrl, 'http://example.com:8080');
    });

    test('url builds full URL from path', () {
      expect(
        ApiConfig.url('/api/v1/players'),
        'http://localhost:8080/api/v1/players',
      );
    });

    test('url with custom base URL', () {
      ApiConfig.configure('http://myserver:3000');
      expect(
        ApiConfig.url('/api/v1/settings'),
        'http://myserver:3000/api/v1/settings',
      );
    });
  });
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dartboard.dart';

class ScoliaApiService {
  static const String baseUrl = 'https://game.scoliadarts.com';

  // Login with username and password to get bearer token
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/social/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'bearerToken': data['accessToken'] ?? data['bearerToken'] ?? data['token'],
          'userId': data['userId'],
          'email': data['email'] ?? username,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Invalid username or password');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // Get all boards connected to the account
  Future<List<Dartboard>> getBoards(String bearerToken) async {
    final url = Uri.parse('$baseUrl/api/social/boards');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Dartboard.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid bearer token');
      } else {
        throw Exception('Failed to get boards: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Connect a board to the account
  Future<Dartboard> connectBoard(String bearerToken, String serialNumber) async {
    final url = Uri.parse('$baseUrl/api/social/boards');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'serialNumber': serialNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Dartboard.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid bearer token');
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Invalid serial number');
      } else if (response.statusCode == 409) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Board has already been connected');
      } else {
        throw Exception('Failed to connect board: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // Disconnect a board from the account
  Future<void> disconnectBoard(String bearerToken, String serialNumber) async {
    final url = Uri.parse('$baseUrl/api/social/boards/$serialNumber');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid bearer token');
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Board is not connected to this service account');
      } else {
        throw Exception('Failed to disconnect board: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // Validate bearer token by attempting to get boards
  Future<bool> validateToken(String bearerToken) async {
    try {
      await getBoards(bearerToken);
      return true;
    } catch (e) {
      return false;
    }
  }
}

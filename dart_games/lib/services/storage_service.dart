import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _bearerTokenKey = 'bearer_token';
  static const String _serialNumberKey = 'serial_number';
  static const String _setupCompleteKey = 'setup_complete';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Save bearer token securely
  Future<void> saveBearerToken(String token) async {
    await _secureStorage.write(key: _bearerTokenKey, value: token);
  }

  // Get bearer token
  Future<String?> getBearerToken() async {
    return await _secureStorage.read(key: _bearerTokenKey);
  }

  // Save serial number
  Future<void> saveSerialNumber(String serialNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serialNumberKey, serialNumber);
  }

  // Get serial number
  Future<String?> getSerialNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serialNumberKey);
  }

  // Mark setup as complete
  Future<void> setSetupComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompleteKey, complete);
  }

  // Check if setup is complete
  Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompleteKey) ?? false;
  }

  // Clear all stored data
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if user has authentication credentials
  Future<bool> hasAuth() async {
    final token = await getBearerToken();
    return token != null && token.isNotEmpty;
  }

  // Check if user has dartboard registered
  Future<bool> hasDartboard() async {
    final serial = await getSerialNumber();
    return serial != null && serial.isNotEmpty;
  }
}

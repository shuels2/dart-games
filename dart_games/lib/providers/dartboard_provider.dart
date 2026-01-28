import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/dartboard.dart';
import '../services/mock_scolia_api_service.dart';

enum DartboardConnectionStatus {
  disconnected,
  connecting,
  connected,
  emulator,
  error,
}

class DartboardProvider with ChangeNotifier {
  Dartboard? _dartboard;
  DartboardConnectionStatus _status = DartboardConnectionStatus.disconnected;
  String? _error;
  bool _useEmulatorMode = false;
  String? _apiKey;
  Timer? _statusCheckTimer;

  MockScoliaApiService? _mockApiService;

  static const String _scoliaBaseUrl = 'https://game.scoliadarts.com';

  // Getters
  Dartboard? get dartboard => _dartboard;
  DartboardConnectionStatus get status => _status;
  String? get error => _error;
  bool get isConnected => _status == DartboardConnectionStatus.connected;
  bool get isEmulator => _status == DartboardConnectionStatus.emulator;
  bool get canPlayGames => isConnected || isEmulator;
  bool get isRegistered => _dartboard != null;
  MockScoliaApiService? get apiService => _mockApiService;

  // Storage keys
  static const String _keyDartboardName = 'dartboard_name';
  static const String _keySerialNumber = 'dartboard_serial';
  static const String _keyApiKey = 'dartboard_api_key';
  static const String _keyUseEmulator = 'use_emulator';

  // Load dartboard configuration from storage
  Future<void> loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_keyDartboardName);
      final serial = prefs.getString(_keySerialNumber);
      final apiKey = prefs.getString(_keyApiKey);
      final useEmulator = prefs.getBool(_keyUseEmulator) ?? false;

      if (name != null && serial != null) {
        _dartboard = Dartboard(
          name: name,
          serialNumber: serial,
        );
        _apiKey = apiKey;
        _useEmulatorMode = useEmulator;

        // Try to connect if not using emulator
        if (_useEmulatorMode) {
          _activateEmulator();
        } else if (apiKey != null) {
          await _attemptConnection();
          // Start status checking for non-emulator dartboards
          startStatusChecking();
        }
      }
    } catch (e) {
      print('Error loading dartboard configuration: $e');
    }
    notifyListeners();
  }

  // Connect to Scolia with dartboard details
  Future<bool> connectToScolia({
    required String name,
    required String serialNumber,
    required String apiKey,
  }) async {
    _status = DartboardConnectionStatus.connecting;
    _error = null;
    notifyListeners();

    try {
      // Create dartboard object
      _dartboard = Dartboard(
        name: name,
        serialNumber: serialNumber,
      );
      _apiKey = apiKey;
      _useEmulatorMode = false;

      // TODO: Implement actual WebSocket connection to Scolia
      // For now, simulate connection attempt
      await Future.delayed(const Duration(seconds: 1));

      // Simulate connection failure (since we don't have real WebSocket yet)
      // In production, this would attempt actual WebSocket connection
      // For now, start status checking to monitor the dartboard
      await _saveConfiguration(name, serialNumber, apiKey, false);
      startStatusChecking();

      _status = DartboardConnectionStatus.error;
      _error = 'WebSocket connection not yet implemented. Use emulator mode for testing.';

      notifyListeners();
      return false;

      // When WebSocket is implemented:
      // final success = await _connectWebSocket(apiKey, serialNumber);
      // if (success) {
      //   await _saveConfiguration(name, serialNumber, apiKey, false);
      //   _status = DartboardConnectionStatus.connected;
      //   notifyListeners();
      //   return true;
      // } else {
      //   _status = DartboardConnectionStatus.error;
      //   _error = 'Failed to connect to Scolia WebSocket';
      //   notifyListeners();
      //   return false;
      // }
    } catch (e) {
      _status = DartboardConnectionStatus.error;
      _error = 'Connection failed: $e';
      notifyListeners();
      return false;
    }
  }

  // Use emulator mode
  void useEmulator({required String name, required String serialNumber}) async {
    // Stop any status checking for physical dartboard
    stopStatusChecking();

    _dartboard = Dartboard(
      name: name,
      serialNumber: serialNumber,
    );
    _useEmulatorMode = true;

    await _saveConfiguration(name, serialNumber, null, true);
    _activateEmulator();
  }

  // Activate emulator
  void _activateEmulator() {
    _mockApiService = MockScoliaApiService();
    _status = DartboardConnectionStatus.emulator;
    _error = null;
    notifyListeners();
  }

  // Attempt to reconnect with saved configuration
  Future<void> _attemptConnection() async {
    if (_apiKey == null || _dartboard == null) return;

    _status = DartboardConnectionStatus.connecting;
    notifyListeners();

    // Simulate connection attempt
    await Future.delayed(const Duration(milliseconds: 500));

    // Set to error state - actual connection status will be determined by status checking
    _status = DartboardConnectionStatus.error;
    _error = 'Connecting to dartboard...';
    notifyListeners();
  }

  // Save configuration to storage
  Future<void> _saveConfiguration(
    String name,
    String serialNumber,
    String? apiKey,
    bool useEmulator,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDartboardName, name);
    await prefs.setString(_keySerialNumber, serialNumber);
    if (apiKey != null) {
      await prefs.setString(_keyApiKey, apiKey);
    }
    await prefs.setBool(_keyUseEmulator, useEmulator);
  }

  // Clear dartboard configuration
  Future<void> clearDartboard() async {
    stopStatusChecking();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDartboardName);
    await prefs.remove(_keySerialNumber);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyUseEmulator);

    _dartboard = null;
    _apiKey = null;
    _useEmulatorMode = false;
    _mockApiService = null;
    _status = DartboardConnectionStatus.disconnected;
    _error = null;

    notifyListeners();
  }

  // Switch to emulator mode from failed connection
  void switchToEmulator() {
    if (_dartboard != null) {
      // Stop status checking before switching to emulator
      stopStatusChecking();

      useEmulator(
        name: _dartboard!.name,
        serialNumber: _dartboard!.serialNumber,
      );
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Check dartboard status via GET_SBC_STATUS API
  Future<void> checkDartboardStatus() async {
    // Don't check status for emulator
    if (_useEmulatorMode || _status == DartboardConnectionStatus.emulator || _dartboard == null || _apiKey == null) {
      return;
    }

    try {
      final url = Uri.parse('$_scoliaBaseUrl/api/sbc/status/${_dartboard!.serialNumber}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Successfully connected and got status
        if (_status != DartboardConnectionStatus.connected) {
          _status = DartboardConnectionStatus.connected;
          _error = null;
          notifyListeners();
        }
      } else {
        // API error
        if (_status != DartboardConnectionStatus.error) {
          _status = DartboardConnectionStatus.error;
          _error = 'Unable to Connect';
          notifyListeners();
        }
      }
    } catch (e) {
      // Network error or timeout
      if (_status != DartboardConnectionStatus.error) {
        _status = DartboardConnectionStatus.error;
        _error = 'Unable to Connect';
        notifyListeners();
      }
    }
  }

  // Start periodic status checking
  void startStatusChecking() {
    // Don't start for emulator
    if (_useEmulatorMode || _status == DartboardConnectionStatus.emulator) return;

    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => checkDartboardStatus(),
    );

    // Check immediately
    checkDartboardStatus();
  }

  // Stop status checking
  void stopStatusChecking() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  @override
  void dispose() {
    stopStatusChecking();
    super.dispose();
  }
}

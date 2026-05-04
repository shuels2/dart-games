import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/dartboard.dart';
import '../models/dartboard_connection_profile.dart';
import '../services/mock_scolia_api_service.dart';
import '../services/scolia_websocket_service.dart';
import '../services/api_logger_service.dart';
import '../services/api/api_client.dart';

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
  ScoliaWebSocketService? _webSocketService;

  List<DartboardConnectionProfile> _savedProfiles = [];

  ApiClient? _apiClient;

  /// Inject the ApiClient instance. Must be called before loadConfiguration().
  void initialize(ApiClient client) {
    _apiClient = client;
  }

  ApiClient get _api {
    assert(_apiClient != null, 'DartboardProvider.initialize() must be called before use');
    return _apiClient!;
  }

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
  ScoliaWebSocketService? get webSocketService => _webSocketService;
  List<DartboardConnectionProfile> get savedProfiles => List.unmodifiable(_savedProfiles);

  /// Unified event stream from whichever dartboard source is active
  /// (real WebSocket or emulator). Games subscribe to this for dart events.
  Stream<Map<String, dynamic>>? get dartboardEventStream {
    if (_webSocketService != null && _webSocketService!.isConnected) {
      return _webSocketService!.eventStream;
    }
    return _mockApiService?.eventStream;
  }

  // Load dartboard configuration from API
  Future<void> loadConfiguration() async {
    try {
      await loadSavedProfiles();
      final config = await _api.getDartboard();
      final name = config['name'] as String?;
      final serial = config['serialNumber'] as String?;
      final apiKey = config['apiKey'] as String?;
      final useEmulator = config['useEmulator'] as bool? ?? false;

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

      // Attempt real WebSocket connection to Scolia
      _webSocketService?.dispose();
      _webSocketService = ScoliaWebSocketService();

      final success = await _webSocketService!.connect(
        serialNumber: serialNumber,
        accessToken: apiKey,
      );

      if (success) {
        await _saveConfiguration(name, serialNumber, apiKey, false);
        _status = DartboardConnectionStatus.connected;
        _error = null;

        // Listen for disconnect events to update status
        _webSocketService!.eventStream.listen((event) {
          if (event['type'] == 'disconnected') {
            _status = DartboardConnectionStatus.error;
            _error = event['data']?['message'] ?? 'Dartboard disconnected';
            notifyListeners();
          } else if (event['type'] == 'sbc_status_changed') {
            final payload = event['data']?['payload'];
            final boardStatus = payload?['boardStatus'] as String?;
            if (boardStatus == 'Ready' || boardStatus == 'Throw' || boardStatus == 'Takeout') {
              _status = DartboardConnectionStatus.connected;
              _error = null;
            } else if (boardStatus == 'Offline' || boardStatus == 'Error' || boardStatus == null) {
              _status = DartboardConnectionStatus.error;
              _error = boardStatus == 'Offline'
                  ? 'Dartboard is offline'
                  : 'Dartboard error: ${payload?['errorType'] ?? 'unknown'}';
            }
            notifyListeners();
          }
        });

        notifyListeners();
        return true;
      } else {
        // WebSocket connection failed
        _webSocketService?.dispose();
        _webSocketService = null;
        _status = DartboardConnectionStatus.error;
        _error = 'Could not connect to Scolia dartboard. Check serial number and API key.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _webSocketService?.dispose();
      _webSocketService = null;
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

    // Try real WebSocket connection
    _webSocketService?.dispose();
    _webSocketService = ScoliaWebSocketService();

    final success = await _webSocketService!.connect(
      serialNumber: _dartboard!.serialNumber,
      accessToken: _apiKey!,
    );

    if (success) {
      _status = DartboardConnectionStatus.connected;
      _error = null;

      // Listen for disconnect/status events
      _webSocketService!.eventStream.listen((event) {
        if (event['type'] == 'disconnected') {
          _status = DartboardConnectionStatus.error;
          _error = event['data']?['message'] ?? 'Dartboard disconnected';
          notifyListeners();
        } else if (event['type'] == 'sbc_status_changed') {
          final payload = event['data']?['payload'];
          final boardStatus = payload?['boardStatus'] as String?;
          if (boardStatus == 'Ready' || boardStatus == 'Throw' || boardStatus == 'Takeout') {
            _status = DartboardConnectionStatus.connected;
            _error = null;
          } else if (boardStatus == 'Offline' || boardStatus == 'Error' || boardStatus == null) {
            _status = DartboardConnectionStatus.error;
            _error = boardStatus == 'Offline'
                ? 'Dartboard is offline'
                : 'Dartboard error: ${payload?['errorType'] ?? 'unknown'}';
          }
          notifyListeners();
        }
      });
    } else {
      // WebSocket failed — fall back to status checking via REST
      _webSocketService?.dispose();
      _webSocketService = null;
      _status = DartboardConnectionStatus.error;
      _error = 'Unable to Connect';
    }
    notifyListeners();
  }

  // Save configuration to API
  Future<void> _saveConfiguration(
    String name,
    String serialNumber,
    String? apiKey,
    bool useEmulator,
  ) async {
    await _api.updateDartboard({
      'name': name,
      'serialNumber': serialNumber,
      if (apiKey != null) 'apiKey': apiKey,
      'useEmulator': useEmulator,
    });

    // Save connection profile for non-emulator connections
    if (!useEmulator && apiKey != null) {
      await saveConnectionProfile(name, serialNumber, apiKey);
    }
  }

  // Clear dartboard configuration
  Future<void> clearDartboard() async {
    stopStatusChecking();

    await _api.clearDartboard();

    _dartboard = null;
    _apiKey = null;
    _useEmulatorMode = false;
    _mockApiService = null;
    _webSocketService?.dispose();
    _webSocketService = null;
    _status = DartboardConnectionStatus.disconnected;
    _error = null;

    notifyListeners();
  }

  // Switch to emulator mode from failed connection
  void switchToEmulator() {
    if (_dartboard != null) {
      // Stop status checking and disconnect WebSocket before switching
      stopStatusChecking();
      _webSocketService?.dispose();
      _webSocketService = null;

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
      final endpoint = '/api/sbc/status/${_dartboard!.serialNumber}';
      final url = Uri.parse('$_scoliaBaseUrl$endpoint');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      // Log the API call
      Map<String, dynamic>? responseBody;
      try {
        responseBody = json.decode(response.body) as Map<String, dynamic>;
      } catch (_) {
        responseBody = {'statusCode': response.statusCode, 'body': response.body};
      }
      ApiLoggerService.logApiCall(
        method: 'GET',
        endpoint: endpoint,
        request: {'serial': _dartboard!.serialNumber},
        response: responseBody,
      );

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
      // Log the failed call
      ApiLoggerService.logApiCall(
        method: 'GET',
        endpoint: '/api/sbc/status/${_dartboard!.serialNumber}',
        request: {'serial': _dartboard!.serialNumber},
        response: {'error': e.toString()},
      );

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

  // Load saved connection profiles from API
  Future<void> loadSavedProfiles() async {
    try {
      final profilesList = await _api.getDartboardProfiles();
      _savedProfiles = profilesList
          .map((item) => DartboardConnectionProfile.fromJson(item))
          .toList();
      // Sort by lastUsed descending (most recent first)
      _savedProfiles.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    } catch (e) {
      print('Error loading saved profiles: $e');
      _savedProfiles = [];
    }
  }

  // Save or update a connection profile (upserts by serial number)
  Future<void> saveConnectionProfile(String name, String serialNumber, String apiKey) async {
    final now = DateTime.now();

    // Remove existing profile with same serial number from local list
    _savedProfiles.removeWhere((p) => p.serialNumber == serialNumber);

    // Add new/updated profile locally
    _savedProfiles.insert(0, DartboardConnectionProfile(
      name: name,
      serialNumber: serialNumber,
      apiKey: apiKey,
      lastUsed: now,
    ));

    // Persist to API
    await _api.upsertDartboardProfile(serialNumber, {
      'name': name,
      'serialNumber': serialNumber,
      'apiKey': apiKey,
      'lastUsed': now.toIso8601String(),
    });
    notifyListeners();
  }

  // Delete a connection profile by serial number
  Future<void> deleteConnectionProfile(String serialNumber) async {
    _savedProfiles.removeWhere((p) => p.serialNumber == serialNumber);
    await _api.deleteDartboardProfile(serialNumber);
    notifyListeners();
  }

  @visibleForTesting
  void simulateDisconnection() {
    _status = DartboardConnectionStatus.error;
    _error = 'Simulated disconnection for testing';
    notifyListeners();
  }

  @visibleForTesting
  void simulateReconnection() {
    _status = DartboardConnectionStatus.emulator;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopStatusChecking();
    _webSocketService?.dispose();
    super.dispose();
  }
}

import 'dart:convert';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

/// Mock Scolia API Service for testing
/// Simulates dartboard events and API responses
class MockScoliaApiService {
  final _uuid = const Uuid();
  final StreamController<Map<String, dynamic>> _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventStreamController.stream;

  final List<Map<String, dynamic>> _apiLogs = [];
  List<Map<String, dynamic>> get apiLogs => List.unmodifiable(_apiLogs);

  void _logApiCall(String endpoint, String method, Map<String, dynamic>? requestData, Map<String, dynamic> responseData) {
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'endpoint': endpoint,
      'method': method,
      'request': requestData,
      'response': responseData,
    };
    _apiLogs.add(log);
    _eventStreamController.add({
      'type': 'api_log',
      'data': log,
    });
  }

  /// Simulate a dart throw event - sends THROW_DETECTED message per Scolia API
  void simulateDartThrow({
    required int score,
    required String multiplier, // 'single', 'double', 'triple', 'bullseye', 'outer_bull', 'miss'
    required String playerName,
    required int baseScore, // The base number (1-20)
    required double widgetX, // X position in widget coordinates
    required double widgetY, // Y position in widget coordinates
    required double widgetSize, // Size of widget for coordinate conversion
  }) {
    // Convert multiplier to Scolia sector format
    String sector = _convertToScoliaFormat(multiplier, baseScore, widgetX, widgetY, widgetSize);

    // Convert widget coordinates to Scolia format (-250 to +250 mm)
    List<double> coordinates = _convertCoordinates(widgetX, widgetY, widgetSize);

    // Calculate angles (simulate realistic dart throw angles)
    Map<String, double> angle = _calculateAngles(coordinates);

    // Determine if this is a bounceout (always false for clicks on board)
    bool bounceout = multiplier == 'miss';

    // Generate sector suggestions (nearby sectors)
    List<String> sectorSuggestions = _generateSectorSuggestions(sector, baseScore, multiplier);

    // Create THROW_DETECTED message per Scolia API spec
    final throwDetectedMessage = {
      'type': 'THROW_DETECTED',
      'id': _uuid.v4(),
      'payload': {
        'sector': sector,
        'coordinates': coordinates,
        'angle': angle,
        'bounceout': bounceout,
        'sectorSuggestions': sectorSuggestions,
        'detectionTime': DateTime.now().toIso8601String(),
      },
    };

    _logApiCall(
      '/api/scolia/incoming',
      'INCOMING',
      throwDetectedMessage,
      {
        'acknowledged': true,
        'messageId': throwDetectedMessage['id'],
      },
    );

    _eventStreamController.add({
      'type': 'throw_detected',
      'data': throwDetectedMessage,
    });
  }

  /// Convert multiplier to Scolia sector notation
  /// Format: ([SsDT]{1})(20|1[0-9]|[1-9])|25|Bull|None
  String _convertToScoliaFormat(String multiplier, int baseScore, double x, double y, double size) {
    switch (multiplier) {
      case 'bullseye':
        return 'Bull';
      case 'outer_bull':
        return '25';
      case 'miss':
        return 'None';
      case 'double':
        return 'D$baseScore';
      case 'triple':
        return 'T$baseScore';
      case 'single':
        // Determine if inner single (s) or outer single (S)
        final center = size / 2;
        final dx = x - center;
        final dy = y - center;
        final distance = math.sqrt(dx * dx + dy * dy);
        final radius = size / 2;

        // Inner single (between bull and triple ring)
        if (distance < radius * 0.582) {
          return 's$baseScore'; // lowercase s for inner single
        } else {
          return 'S$baseScore'; // uppercase S for outer single
        }
      default:
        return 'None';
    }
  }

  /// Convert widget coordinates to Scolia API format (-250 to +250 mm)
  List<double> _convertCoordinates(double x, double y, double size) {
    // Convert from widget coordinates (0 to size) to Scolia format (-250 to +250)
    // Center of widget corresponds to (0, 0) in Scolia coordinates
    final center = size / 2;
    final dx = x - center;
    final dy = y - center;

    // Scale to -250 to +250 range
    // Max distance from center is size/2, which maps to 250mm
    final scaleX = (dx / (size / 2)) * 250;
    final scaleY = (dy / (size / 2)) * 250;

    return [scaleX.roundToDouble(), scaleY.roundToDouble()];
  }

  /// Calculate realistic dart throw angles
  Map<String, double> _calculateAngles(List<double> coordinates) {
    // Simulate realistic angles based on dart position
    // Darts generally come in at 70-85 degrees vertical
    // Horizontal angle varies based on position
    final random = math.Random();

    // Vertical angle: mostly straight down (70-85 degrees)
    final verticalAngle = 75.0 + (random.nextDouble() * 10 - 5);

    // Horizontal angle: slight variation (-5 to +5 degrees)
    final horizontalAngle = random.nextDouble() * 10 - 5;

    return {
      'vertical': double.parse(verticalAngle.toStringAsFixed(4)),
      'horizontal': double.parse(horizontalAngle.toStringAsFixed(4)),
    };
  }

  /// Generate sector suggestions for nearby sectors
  List<String> _generateSectorSuggestions(String sector, int baseScore, String multiplier) {
    List<String> suggestions = [];

    // Don't suggest for Bull or None
    if (sector == 'Bull' || sector == 'None' || sector == '25') {
      return suggestions;
    }

    // Dartboard number sequence
    const List<int> dartboardNumbers = [
      20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
    ];

    // Find index of current number
    int currentIndex = dartboardNumbers.indexOf(baseScore);
    if (currentIndex == -1) return suggestions;

    // Get neighboring numbers
    int leftNeighbor = dartboardNumbers[(currentIndex - 1 + 20) % 20];
    int rightNeighbor = dartboardNumbers[(currentIndex + 1) % 20];

    // Add suggestions based on multiplier
    if (multiplier == 'triple') {
      suggestions.add('T$leftNeighbor');
      suggestions.add('T$rightNeighbor');
      suggestions.add('S$baseScore'); // Outer single of same number
    } else if (multiplier == 'double') {
      suggestions.add('D$leftNeighbor');
      suggestions.add('D$rightNeighbor');
      suggestions.add('S$baseScore');
    } else {
      // Single suggestions
      suggestions.add('S$leftNeighbor');
      suggestions.add('S$rightNeighbor');
      if (currentIndex >= 0) {
        suggestions.add('T$baseScore');
      }
    }

    // Limit to 3 suggestions
    return suggestions.take(3).toList();
  }

  /// Simulate a game event
  void simulateGameEvent(String eventType, Map<String, dynamic> data) {
    final eventData = {
      'eventType': eventType,
      'timestamp': DateTime.now().toIso8601String(),
      ...data,
    };

    _logApiCall(
      '/api/social/events/$eventType',
      'POST',
      eventData,
      {
        'success': true,
        'eventId': 'evt_${DateTime.now().millisecondsSinceEpoch}',
      },
    );

    _eventStreamController.add({
      'type': eventType,
      'data': eventData,
    });
  }

  /// Simulate board connection status
  void simulateBoardConnected(String serialNumber) {
    final eventData = {
      'eventType': 'board_connected',
      'timestamp': DateTime.now().toIso8601String(),
      'serialNumber': serialNumber,
      'status': 'connected',
      'batteryLevel': 87,
      'firmwareVersion': '2.1.5',
    };

    _logApiCall(
      '/api/social/boards/$serialNumber/status',
      'GET',
      null,
      eventData,
    );

    _eventStreamController.add({
      'type': 'board_connected',
      'data': eventData,
    });
  }

  /// Simulate board disconnected
  void simulateBoardDisconnected(String serialNumber) {
    final eventData = {
      'eventType': 'board_disconnected',
      'timestamp': DateTime.now().toIso8601String(),
      'serialNumber': serialNumber,
      'status': 'disconnected',
    };

    _logApiCall(
      '/api/social/boards/$serialNumber/status',
      'GET',
      null,
      eventData,
    );

    _eventStreamController.add({
      'type': 'board_disconnected',
      'data': eventData,
    });
  }

  /// Simulate TAKEOUT_STARTED event
  void simulateTakeoutStarted() {
    final takeoutStartedMessage = {
      'type': 'TAKEOUT_STARTED',
      'id': _uuid.v4(),
      'payload': {
        'time': DateTime.now().toIso8601String(),
      },
    };

    _logApiCall(
      '/api/scolia/incoming',
      'INCOMING',
      takeoutStartedMessage,
      {
        'acknowledged': true,
        'messageId': takeoutStartedMessage['id'],
      },
    );

    _eventStreamController.add({
      'type': 'takeout_started',
      'data': takeoutStartedMessage,
    });
  }

  /// Simulate TAKEOUT_FINISHED event
  void simulateTakeoutFinished({bool falseTakeout = false}) {
    final takeoutFinishedMessage = {
      'type': 'TAKEOUT_FINISHED',
      'id': _uuid.v4(),
      'payload': {
        'falseTakeout': falseTakeout,
        'time': DateTime.now().toIso8601String(),
      },
    };

    _logApiCall(
      '/api/scolia/incoming',
      'INCOMING',
      takeoutFinishedMessage,
      {
        'acknowledged': true,
        'messageId': takeoutFinishedMessage['id'],
      },
    );

    _eventStreamController.add({
      'type': 'takeout_finished',
      'data': takeoutFinishedMessage,
    });
  }

  /// Calculate display score based on multiplier
  int _calculateDisplayScore(int score, String multiplier) {
    switch (multiplier) {
      case 'double':
        return score * 2;
      case 'triple':
        return score * 3;
      case 'bullseye':
        return 50;
      case 'outer_bull':
        return 25;
      default:
        return score;
    }
  }

  /// Clear all logs
  void clearLogs() {
    _apiLogs.clear();
    _eventStreamController.add({
      'type': 'logs_cleared',
      'data': {},
    });
  }

  void dispose() {
    _eventStreamController.close();
  }
}

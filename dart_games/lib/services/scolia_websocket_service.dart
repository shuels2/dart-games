import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_logger_service.dart';

/// Real WebSocket connection to Scolia dartboard API.
/// Exposes events in the same stream format as MockScoliaApiService
/// so game screens can consume events identically.
class ScoliaWebSocketService {
  static const String _wsBaseUrl = 'wss://game.scoliadarts.com/api/v1/social';

  final _uuid = const Uuid();
  final StreamController<Map<String, dynamic>> _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _statusCheckTimer;

  String? _serialNumber;
  String? _accessToken;

  String? _boardStatus;
  String? _boardPhase;

  bool _isConnected = false;
  bool _isDisposed = false;

  /// Timestamp of the most-recent outbound GET_SBC_STATUS for which no
  /// reply has been observed yet. Cleared by any inbound message that
  /// proves the socket is still alive (SBC_STATUS / SBC_STATUS_CHANGED /
  /// THROW_DETECTED / TAKEOUT_*). If the next periodic tick fires and
  /// this is still set with elapsed > [_heartbeatTimeoutMs], we treat
  /// the connection as half-dead and emit a synthetic disconnect.
  ///
  /// Why this exists: when the client computer sleeps and wakes up the
  /// WebSocket can be in a "half-open" state — both sides appear
  /// connected but data won't flow. Without this, GET_SBC_STATUS sends
  /// into the void and status sits at error forever.
  DateTime? _lastStatusSentAt;

  /// Max age of an unanswered GET_SBC_STATUS before we declare the WS
  /// half-dead. Tuned so a single dropped reply doesn't trigger it (the
  /// ticker is 10s, so 7s leaves ~3s of slack for normal reply jitter)
  /// but a fully wedged connection is detected within one tick.
  @visibleForTesting
  static const int heartbeatTimeoutMs = 7000;

  /// Pure-function helper used by the periodic status-check tick to
  /// decide whether the connection is half-dead. Exposed for tests so
  /// the logic can be exercised without a real WebSocket.
  @visibleForTesting
  static bool isHeartbeatStale({
    required DateTime? lastSentAt,
    required DateTime now,
  }) {
    if (lastSentAt == null) return false;
    return now.difference(lastSentAt).inMilliseconds > heartbeatTimeoutMs;
  }

  Stream<Map<String, dynamic>> get eventStream =>
      _eventStreamController.stream;
  bool get isConnected => _isConnected;
  String? get boardStatus => _boardStatus;
  String? get boardPhase => _boardPhase;

  /// Connect to Scolia WebSocket API.
  /// Returns true if connection succeeds (HELLO_CLIENT received),
  /// false on connection failure or timeout.
  Future<bool> connect({
    required String serialNumber,
    required String accessToken,
  }) async {
    _serialNumber = serialNumber;
    _accessToken = accessToken;

    try {
      final uri = Uri.parse(
          '$_wsBaseUrl?serialNumber=$serialNumber&accessToken=$accessToken');
      debugPrint('[Dartboard][WS] Connecting to $_wsBaseUrl '
          '(serial=$serialNumber, token=<present>)');
      _channel = WebSocketChannel.connect(uri);

      // Wait for the underlying connection to be ready
      await _channel!.ready;
      debugPrint('[Dartboard][WS] Channel ready, waiting for HELLO_CLIENT...');

      final completer = Completer<bool>();

      _channelSubscription = _channel!.stream.listen(
        (message) {
          final parsed = _handleMessage(message);

          // First HELLO_CLIENT message means successful auth
          if (!completer.isCompleted && parsed != null) {
            if (parsed['type'] == 'HELLO_CLIENT') {
              debugPrint('[Dartboard][WS] HELLO_CLIENT received — auth OK');
              _isConnected = true;
              completer.complete(true);
            }
          }
        },
        onError: (error) {
          debugPrint('[Dartboard][WS] onError: $error');
          _isConnected = false;
          if (!completer.isCompleted) completer.complete(false);
          _handleDisconnect(error: error.toString());
        },
        onDone: () {
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          debugPrint('[Dartboard][WS] onDone: closeCode=$closeCode '
              'closeReason=${closeReason ?? "<null>"}');
          _isConnected = false;
          if (!completer.isCompleted) completer.complete(false);
          _handleDisconnect(
            closeCode: closeCode,
            closeReason: closeReason,
          );
        },
      );

      // Wait for HELLO_CLIENT or timeout after 10 seconds
      final connected = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          disconnect();
          return false;
        },
      );

      // Start periodic SBC status check over WebSocket
      if (connected) {
        _startStatusCheckTimer();
      }

      return connected;
    } catch (e) {
      _isConnected = false;
      // A channel opened before the failure would otherwise stay open with a
      // live listener on it.
      disconnect();
      ApiLoggerService.logApiCall(
        method: 'WS_CONNECT',
        endpoint: _wsBaseUrl,
        request: {'serialNumber': serialNumber},
        response: {'error': e.toString()},
      );
      return false;
    }
  }

  /// Parse and route an incoming WebSocket message.
  /// Returns the parsed JSON map, or null on parse error.
  Map<String, dynamic>? _handleMessage(dynamic rawMessage) {
    try {
      final message =
          json.decode(rawMessage as String) as Map<String, dynamic>;
      final type = message['type'] as String?;

      ApiLoggerService.logApiCall(
        method: 'WS_IN',
        endpoint: '/api/v1/social',
        request: null,
        response: message,
      );

      switch (type) {
        case 'HELLO_CLIENT':
          _handleHelloClient(message);
          break;
        case 'THROW_DETECTED':
          _handleThrowDetected(message);
          break;
        case 'TAKEOUT_STARTED':
          _handleTakeoutStarted(message);
          break;
        case 'TAKEOUT_FINISHED':
          _handleTakeoutFinished(message);
          break;
        case 'SBC_STATUS_CHANGED':
          _handleStatusChanged(message);
          break;
        case 'SBC_STATUS':
          _handleSbcStatus(message);
          break;
        case 'ACKNOWLEDGED':
        case 'REFUSED':
        case 'CAMERA_IMAGES':
        case 'SBC_CONFIGURATION':
          // Logged above but not forwarded to game event stream
          break;
      }

      // Any inbound message proves the connection is alive — clear
      // the heartbeat-pending stamp regardless of message type. (Even
      // an ACKNOWLEDGED or REFUSED that isn't forwarded counts.)
      _lastStatusSentAt = null;

      return message;
    } catch (e) {
      print('Error parsing WebSocket message: $e');
      return null;
    }
  }

  void _handleHelloClient(Map<String, dynamic> message) {
    final payload = message['payload'] as Map<String, dynamic>?;
    _boardStatus = payload?['boardStatus'] as String?;
    _boardPhase = payload?['boardPhase'] as String?;

    _eventStreamController.add({
      'type': 'hello_client',
      'data': message,
    });
  }

  /// Forward THROW_DETECTED to game stream in same format as MockScoliaApiService.
  void _handleThrowDetected(Map<String, dynamic> message) {
    _eventStreamController.add({
      'type': 'throw_detected',
      'data': message,
    });
  }

  void _handleTakeoutStarted(Map<String, dynamic> message) {
    _eventStreamController.add({
      'type': 'takeout_started',
      'data': message,
    });
  }

  void _handleTakeoutFinished(Map<String, dynamic> message) {
    _eventStreamController.add({
      'type': 'takeout_finished',
      'data': message,
    });
  }

  void _handleStatusChanged(Map<String, dynamic> message) {
    final payload = message['payload'] as Map<String, dynamic>?;
    _boardStatus = payload?['boardStatus'] as String?;
    _boardPhase = payload?['boardPhase'] as String?;

    _eventStreamController.add({
      'type': 'sbc_status_changed',
      'data': message,
    });
  }

  void _handleSbcStatus(Map<String, dynamic> message) {
    final payload = message['payload'] as Map<String, dynamic>?;
    final newStatus = payload?['boardStatus'] as String?;
    final oldStatus = _boardStatus;
    _boardStatus = newStatus;
    _boardPhase = payload?['boardPhase'] as String?;

    // If status changed, emit as status_changed event so provider can update
    if (newStatus != oldStatus) {
      _eventStreamController.add({
        'type': 'sbc_status_changed',
        'data': message,
      });
    }
  }

  /// Periodically send GET_SBC_STATUS over WebSocket to detect SBC going offline.
  void _startStatusCheckTimer() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (!_isConnected) return;

        // Heartbeat-timeout check: if a previous GET_SBC_STATUS is
        // still unanswered after _heartbeatTimeoutMs, the WS is
        // half-dead (the most common cause is the client OS sleeping
        // and waking — the socket stays "open" both ends but data
        // won't flow). Synthesize a disconnect so the provider can
        // tear down + reconnect.
        if (isHeartbeatStale(
          lastSentAt: _lastStatusSentAt,
          now: DateTime.now(),
        )) {
          final age =
              DateTime.now().difference(_lastStatusSentAt!).inMilliseconds;
          debugPrint('[Dartboard][WS] Heartbeat timeout: GET_SBC_STATUS '
              'unanswered for ${age}ms — treating connection as dead');
          _isConnected = false;
          _handleDisconnect(
            closeCode: -1,
            closeReason: 'client heartbeat timeout',
          );
          // Tear down the channel so callers don't try to send into it.
          // The provider's reconnect logic will create a fresh service.
          disconnect();
          return;
        }

        sendGetSbcStatus();
      },
    );
  }

  // --- Outgoing messages ---

  /// Request current SBC status and phase.
  void sendGetSbcStatus() {
    _sendMessage({'type': 'GET_SBC_STATUS', 'id': _uuid.v4()});
    // Stamp send time so the next tick can detect a missing reply.
    _lastStatusSentAt = DateTime.now();
  }

  /// Reset the SBC phase to "Throw" and clear current round throws.
  void sendResetPhase() {
    _sendMessage({'type': 'RESET_PHASE', 'id': _uuid.v4()});
  }

  /// Notify the SBC that a throw was corrected by the user.
  void sendThrowCorrected(int throwIndex) {
    _sendMessage({
      'type': 'THROW_CORRECTED',
      'id': _uuid.v4(),
      'payload': {'throwIndex': throwIndex},
    });
  }

  /// Notify the SBC that a throw was deleted from the current round.
  void sendDeleteThrow(int throwIndex) {
    _sendMessage({
      'type': 'DELETE_THROW',
      'id': _uuid.v4(),
      'payload': {'throwIndex': throwIndex},
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null || !_isConnected) return;

    final jsonString = json.encode(message);
    _channel!.sink.add(jsonString);

    ApiLoggerService.logApiCall(
      method: 'WS_OUT',
      endpoint: '/api/v1/social',
      request: message,
      response: null,
    );
  }

  void _handleDisconnect({int? closeCode, String? closeReason, String? error}) {
    if (_isDisposed) return;

    debugPrint('[Dartboard][WS] _handleDisconnect: closeCode=$closeCode '
        'closeReason=${closeReason ?? "<null>"} error=${error ?? "<null>"}');

    String disconnectInfo = 'WebSocket disconnected';
    if (closeCode != null) {
      disconnectInfo += ' (code: $closeCode';
      // Map Scolia-specific close codes
      switch (closeCode) {
        case 4000:
          disconnectInfo += ' - pong timeout';
          break;
        case 4100:
          disconnectInfo += ' - invalid serial number';
          break;
        case 4101:
          disconnectInfo += ' - duplicate connection';
          break;
        case 4102:
          disconnectInfo += ' - invalid access token';
          break;
      }
      disconnectInfo += ')';
    }
    if (closeReason != null && closeReason.isNotEmpty) {
      disconnectInfo += ': $closeReason';
    }
    if (error != null) {
      disconnectInfo += ' error: $error';
    }

    _eventStreamController.add({
      'type': 'disconnected',
      'data': {
        'message': disconnectInfo,
        'closeCode': closeCode,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
  }

  /// Close the WebSocket connection gracefully.
  void disconnect() {
    _isConnected = false;
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventStreamController.close();
  }
}

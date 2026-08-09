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
import '../services/dartboard_wake_listener.dart';

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

  // Auto-reconnect state — see _scheduleReconnect. Used when a previously-
  // healthy WebSocket disconnects (network blip, sleep/wake, hardware
  // power-cycle). Retries forever with exponential backoff capped at 15s.
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  // Guards the 5-second "hardware never answered" timeout armed while
  // resolving the initial SBC status. The generation counter identifies
  // which connection attempt armed the timer, so a stale timer from an
  // earlier attempt cannot fail a newer one that is still connecting.
  Timer? _statusTimeoutTimer;
  int _connectGeneration = 0;
  bool _disposed = false;

  // Handler for connection/status events on the current WebSocket. Held so
  // it can be replaced on reconnect and cancelled on dispose.
  StreamSubscription? _statusSubscription;

  // Page-visibility wake listener (web-only; no-op on native). When the
  // browser tab regains focus after sleep, this triggers an immediate
  // reconnect bypassing the current backoff window.
  final DartboardWakeListener _wakeListener = DartboardWakeListener();

  MockScoliaApiService? _mockApiService;
  ScoliaWebSocketService? _webSocketService;

  // Stable, provider-owned broadcast of dartboard events. Sources come
  // and go (WebSocket reconnects, emulator swap-in, etc.) but this
  // stream is created once and stays alive for the lifetime of the
  // provider. Game screens subscribe here in initState and NEVER have
  // to re-subscribe across reconnects — the provider rewires the
  // underlying source into this bus via [_rewireEventForwarding].
  //
  // Past bug: game screens listened directly to
  // `_webSocketService!.eventStream`. On a WebSocket reconnect
  // (network blip, hardware power-cycle) the provider swapped
  // `_webSocketService` for a new instance, but the game's
  // subscription was still tied to the old (dead) stream. Dart throws
  // stopped registering until the user save/resumed the game — which
  // rebuilt the game screen and re-subscribed. The bus + rewire logic
  // fixes it at the source so every game gets it for free.
  final StreamController<Map<String, dynamic>> _eventBus =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _sourceSubscription;

  List<DartboardConnectionProfile> _savedProfiles = [];

  ApiClient? _apiClient;

  /// Inject the ApiClient instance. Must be called before loadConfiguration().
  void initialize(ApiClient client) {
    _apiClient = client;
    // Subscribe to browser tab visibility (web only — stub on native).
    // When the tab becomes visible again after sleep, force an
    // immediate reconnect if we're currently paused.
    _wakeListener.start(() {
      if (_status == DartboardConnectionStatus.error) {
        forceReconnectNow();
      }
    });
  }

  ApiClient get _api {
    assert(_apiClient != null, 'DartboardProvider.initialize() must be called before use');
    return _apiClient!;
  }

  static const String _scoliaBaseUrl = 'https://game.scoliadarts.com';

  // Getters
  Dartboard? get dartboard => _dartboard;
  DartboardConnectionStatus get status => _status;

  /// Completes as soon as [status] leaves `connecting`, or after [timeout].
  ///
  /// Replaces the splash screen's 100ms polling loop (WS04 4.8), which woke
  /// up sixty times on a cold start just to read a field. This listens for
  /// the notification that already fires on every status change, so it
  /// resolves on the first frame the answer is actually known.
  ///
  /// Returns the status it settled on. Safe to call when already resolved —
  /// it returns immediately without registering a listener.
  Future<DartboardConnectionStatus> whenStatusResolved({
    Duration timeout = const Duration(seconds: 6),
  }) {
    if (_status != DartboardConnectionStatus.connecting) {
      return Future.value(_status);
    }

    final completer = Completer<DartboardConnectionStatus>();
    Timer? timer;

    void listener() {
      if (_status == DartboardConnectionStatus.connecting) return;
      if (completer.isCompleted) return;
      timer?.cancel();
      removeListener(listener);
      completer.complete(_status);
    }

    addListener(listener);
    timer = Timer(timeout, () {
      if (completer.isCompleted) return;
      removeListener(listener);
      // Timed out still connecting — hand back whatever we have so the
      // caller makes the same decision the polling loop would have.
      completer.complete(_status);
    });

    return completer.future;
  }
  String? get error => _error;
  bool get isConnected => _status == DartboardConnectionStatus.connected;
  bool get isEmulator => _status == DartboardConnectionStatus.emulator;
  bool get canPlayGames => isConnected || isEmulator;
  bool get isRegistered => _dartboard != null;
  MockScoliaApiService? get apiService => _mockApiService;
  ScoliaWebSocketService? get webSocketService => _webSocketService;
  List<DartboardConnectionProfile> get savedProfiles => List.unmodifiable(_savedProfiles);

  /// Unified event stream from whichever dartboard source is active
  /// (real WebSocket or emulator). Games subscribe to this once in
  /// initState — the bus is provider-owned, so it survives underlying
  /// source swaps (reconnects, emulator toggle) transparently.
  Stream<Map<String, dynamic>>? get dartboardEventStream => _eventBus.stream;

  /// Point the bus at a new source, cancelling any prior forwarding.
  /// Called every time [_webSocketService] or [_mockApiService] is
  /// (re)created so game screens keep receiving events without having
  /// to re-subscribe.
  void _rewireEventForwarding(Stream<Map<String, dynamic>> source) {
    _sourceSubscription?.cancel();
    _sourceSubscription = source.listen(
      _eventBus.add,
      // Absorb source-stream errors so the provider-owned bus never
      // closes; the failure surfaces through status transitions
      // instead (which trigger reconnects).
      onError: (Object err, StackTrace st) {
        debugPrint('[Dartboard] event-forwarding source error: $err');
      },
    );
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

      debugPrint('[Dartboard] loadConfiguration response: '
          'name=${name ?? "<null>"}, '
          'serial=${serial ?? "<null>"}, '
          'apiKey=${apiKey == null ? "<null>" : "<present>"}, '
          'useEmulator=$useEmulator');

      if (name != null && serial != null) {
        _dartboard = Dartboard(
          name: name,
          serialNumber: serial,
        );
        _apiKey = apiKey;
        _useEmulatorMode = useEmulator;

        // Try to connect if not using emulator
        if (_useEmulatorMode) {
          debugPrint('[Dartboard] Activating emulator mode');
          _activateEmulator();
        } else if (apiKey != null) {
          debugPrint('[Dartboard] Attempting real connection to Scolia...');
          await _attemptConnection();
          // Only fall back to REST polling if the WebSocket connection
          // failed. When the WS is alive it does its own GET_SBC_STATUS
          // every 10s over the existing channel (see
          // scolia_websocket_service.dart `_startStatusCheckTimer`) —
          // no CORS, no redundant REST, no overwriting the `connected`
          // status the WS just established. Past failure: on web the
          // REST endpoint at https://game.scoliadarts.com/api/sbc/status/
          // is CORS-blocked from the browser, so calling it
          // unconditionally caused `ClientException: Failed to fetch`
          // every 10 seconds, which flipped status from connected back
          // to error and re-popped the Pause modal even though the
          // WebSocket was perfectly fine.
          if (_webSocketService == null) {
            debugPrint('[Dartboard] WebSocket unavailable — falling back '
                'to REST status polling.');
            startStatusChecking();
          } else {
            debugPrint('[Dartboard] WebSocket established — skipping REST '
                'status polling (the WS does its own 10s GET_SBC_STATUS).');
          }
        } else {
          debugPrint('[Dartboard] SKIPPED connection: useEmulator=false but '
              'apiKey is null. Status stays at "disconnected". Modal will '
              'remain up until a real dartboard config is saved.');
        }
      } else {
        debugPrint('[Dartboard] SKIPPED connection: name or serialNumber is '
            'null in saved config. Status stays at "disconnected". Modal '
            'will remain up until a dartboard config is saved.');
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
        _onWebSocketConnected();
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
  //
  // Flips status to `emulator` SYNCHRONOUSLY and notifies listeners before
  // awaiting the configuration persist. Without this ordering, the dartboard
  // setup screen's `pushReplacementNamed('/home')` runs while `_status` is
  // still its previous value (e.g. `disconnected` from a failed connect),
  // causing the home screen to briefly render its conditional
  // DartboardPausedModal overlay before the post-await `_activateEmulator()`
  // notification arrives. Persistence runs in the background — a save
  // failure shouldn't block the UI from entering emulator mode.
  void useEmulator({required String name, required String serialNumber}) {
    // Stop any status checking for physical dartboard
    stopStatusChecking();

    _dartboard = Dartboard(
      name: name,
      serialNumber: serialNumber,
    );
    _useEmulatorMode = true;

    _activateEmulator();
    // Background-persist; intentionally not awaited.
    // ignore: discarded_futures
    _saveConfiguration(name, serialNumber, null, true);
  }

  // Activate emulator
  void _activateEmulator() {
    // Replacing without disposing leaves the old service's broadcast
    // controller and its accumulated logs alive for the session.
    _mockApiService?.dispose();
    _mockApiService = MockScoliaApiService();
    _rewireEventForwarding(_mockApiService!.eventStream);
    _status = DartboardConnectionStatus.emulator;
    _error = null;
    notifyListeners();
  }

  // Attempt to reconnect with saved configuration
  Future<void> _attemptConnection() async {
    if (_apiKey == null || _dartboard == null) {
      debugPrint('[Dartboard] _attemptConnection bailed early: '
          'apiKey=${_apiKey == null ? "<null>" : "<present>"}, '
          'dartboard=${_dartboard == null ? "<null>" : _dartboard!.serialNumber}');
      return;
    }

    debugPrint('[Dartboard] _attemptConnection starting WebSocket for '
        'serial=${_dartboard!.serialNumber}');
    _status = DartboardConnectionStatus.connecting;
    notifyListeners();

    // Try real WebSocket connection
    _webSocketService?.dispose();
    _webSocketService = ScoliaWebSocketService();

    final success = await _webSocketService!.connect(
      serialNumber: _dartboard!.serialNumber,
      accessToken: _apiKey!,
    );

    debugPrint('[Dartboard] WebSocket connect() returned: $success');

    if (success) {
      _onWebSocketConnected();
    } else {
      // WebSocket failed — fall back to status checking via REST
      debugPrint('[Dartboard] WebSocket connect() returned false. '
          'Status -> error. NOTE: no automatic retry on startup either; '
          'the modal will remain up.');
      _webSocketService?.dispose();
      _webSocketService = null;
      _status = DartboardConnectionStatus.error;
      _error = 'Unable to Connect';
      notifyListeners();
    }
  }

  /// Wire the post-connect event listener and resolve the initial status
  /// based on what the dartboard hardware reports — NOT just on the
  /// WebSocket auth handshake. Called from both connectToScolia (the
  /// setup-screen explicit connect) and _attemptConnection (the saved-
  /// config reconnect on app startup) after `connect()` returns true.
  ///
  /// Past bug: we used to flip status to `connected` the instant
  /// HELLO_CLIENT arrived. HELLO_CLIENT only proves Scolia's server
  /// accepted the WebSocket auth — it says nothing about whether the
  /// physical dartboard is powered on. With the hardware off, the user
  /// saw "connected" and tappable game tiles even though throws would
  /// never register. This helper instead:
  ///
  ///   1. Subscribes to events FIRST (so a racing SBC reply isn't lost).
  ///   2. Reads any boardStatus that was already attached to HELLO_CLIENT
  ///      and only declares `connected` if it's Ready/Throw/Takeout.
  ///   3. Otherwise stays in `connecting`, explicitly sends GET_SBC_STATUS
  ///      (instead of waiting up to 10s for the status-check timer's
  ///      first tick), and falls through to `error` after 5s if the
  ///      hardware never replies (the "dartboard powered off" case —
  ///      Scolia may not respond at all).
  void _onWebSocketConnected() {
    // 1. Subscribe BEFORE setting status so any SBC status event that
    //    races us (e.g. arrives between connect() returning and us
    //    subscribing) is caught. Also rewire the provider-owned event
    //    bus so game screens (which listen once in initState) keep
    //    receiving throw events across reconnect boundaries.
    debugPrint('[Dartboard] WebSocket auth OK. Subscribing to event stream '
        'before resolving status.');
    _rewireEventForwarding(_webSocketService!.eventStream);
    // Replace any listener left from a previous connection so reconnects
    // don't stack handlers on top of each other.
    _statusSubscription?.cancel();
    _statusSubscription = _webSocketService!.eventStream.listen((event) {
      if (event['type'] == 'disconnected') {
        debugPrint('[Dartboard] event: disconnected '
            '(message=${event['data']?['message']}). Status -> error. '
            'Scheduling auto-reconnect.');
        _status = DartboardConnectionStatus.error;
        _error = event['data']?['message'] ?? 'Dartboard disconnected';
        notifyListeners();
        _scheduleReconnect();
      } else if (event['type'] == 'sbc_status_changed') {
        final payload = event['data']?['payload'];
        final boardStatus = payload?['boardStatus'] as String?;
        debugPrint('[Dartboard] event: sbc_status_changed '
            'boardStatus=$boardStatus');
        _applyBoardStatus(boardStatus, payload);
      }
    });

    // 2. Use whatever boardStatus HELLO_CLIENT already gave us. When the
    //    hardware is online Scolia typically embeds it; when it's offline
    //    the field is missing or null.
    final initialBoardStatus = _webSocketService?.boardStatus;
    debugPrint('[Dartboard] HELLO_CLIENT carried boardStatus='
        '${initialBoardStatus ?? "<null>"}');

    if (initialBoardStatus == 'Ready' ||
        initialBoardStatus == 'Throw' ||
        initialBoardStatus == 'Takeout') {
      _status = DartboardConnectionStatus.connected;
      _error = null;
      // Healthy connection re-established — clear any pending reconnect
      // schedule and reset the backoff curve.
      _resetReconnectState();
      debugPrint('[Dartboard] Status -> connected (HELLO_CLIENT confirmed '
          'hardware online).');
      notifyListeners();
      return;
    }

    // 3. HELLO_CLIENT didn't confirm online. Stay in `connecting`,
    //    explicitly request the current status, and arm a 5-second
    //    timeout for the "hardware powered off, no reply at all" case.
    _status = DartboardConnectionStatus.connecting;
    debugPrint('[Dartboard] Status -> connecting. Sending explicit '
        'GET_SBC_STATUS. Timeout: 5s.');
    notifyListeners();
    _webSocketService?.sendGetSbcStatus();

    final generation = ++_connectGeneration;
    _statusTimeoutTimer?.cancel();
    _statusTimeoutTimer = Timer(const Duration(seconds: 5), () {
      // Ignore a timer left over from a superseded attempt, and never touch
      // a disposed provider — either would report a failure that belongs to
      // a connection nobody is waiting on any more.
      if (_disposed || generation != _connectGeneration) return;
      if (_status == DartboardConnectionStatus.connecting) {
        debugPrint('[Dartboard] SBC status timeout (5s) — hardware did NOT '
            'respond. Status -> error. The dartboard is likely powered off '
            'or unreachable.');
        _status = DartboardConnectionStatus.error;
        _error = 'Dartboard did not respond. Is it powered on?';
        notifyListeners();
      }
    });
  }

  /// Test seam for [_applyBoardStatus], which is otherwise only reachable
  /// through a live WebSocket connection.
  @visibleForTesting
  void applyBoardStatusForTest(String? boardStatus, [dynamic payload]) =>
      _applyBoardStatus(boardStatus, payload);

  /// Apply a boardStatus value from an SBC_STATUS_CHANGED event and
  /// notify listeners. Shared between the live event handler and the
  /// initial-status resolver. Recognized values are Ready/Throw/Takeout
  /// (→ connected) and Offline/Error/null (→ error). Anything else
  /// leaves the current status untouched.
  void _applyBoardStatus(String? boardStatus, dynamic payload) {
    final DartboardConnectionStatus newStatus;
    final String? newError;

    if (boardStatus == 'Ready' ||
        boardStatus == 'Throw' ||
        boardStatus == 'Takeout') {
      newStatus = DartboardConnectionStatus.connected;
      newError = null;
      // Always runs: a live board means any pending reconnect/timeout work
      // is stale, whether or not the reported status changed.
      _resetReconnectState();
    } else if (boardStatus == 'Offline' ||
        boardStatus == 'Error' ||
        boardStatus == null) {
      newStatus = DartboardConnectionStatus.error;
      newError = boardStatus == 'Offline'
          ? 'Dartboard is offline'
          : 'Dartboard error: ${payload?['errorType'] ?? 'unknown'}';
    } else {
      debugPrint('[Dartboard]   (unrecognized boardStatus="$boardStatus" — '
          'status stays at ${_status.name})');
      return;
    }

    // Hardware emits SBC_STATUS_CHANGED on every Throw/Takeout transition —
    // several times per turn — and all three healthy values collapse to
    // `connected`. Notifying unconditionally rebuilt every screen watching
    // this provider on each of those no-op events.
    if (newStatus == _status && newError == _error) return;

    _status = newStatus;
    _error = newError;
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
    _resetReconnectState();

    await _api.clearDartboard();

    _dartboard = null;
    _apiKey = null;
    _useEmulatorMode = false;
    _mockApiService?.dispose();
    _mockApiService = null;
    _sourceSubscription?.cancel();
    _sourceSubscription = null;
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
      debugPrint('[Dartboard][REST] GET $url');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      debugPrint('[Dartboard][REST] -> statusCode=${response.statusCode}, '
          'body=${response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body}');

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
          debugPrint('[Dartboard][REST] 200 OK — flipping status from '
              '${_status.name} to connected');
          _status = DartboardConnectionStatus.connected;
          _error = null;
          notifyListeners();
        }
      } else {
        // API error
        if (_status != DartboardConnectionStatus.error) {
          debugPrint('[Dartboard][REST] non-200 (${response.statusCode}) — '
              'flipping status from ${_status.name} to error. THIS IS '
              'LIKELY WHAT IS KEEPING THE PAUSE MODAL UP even though the '
              'WebSocket connected successfully.');
          _status = DartboardConnectionStatus.error;
          _error = 'Unable to Connect';
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[Dartboard][REST] threw: $e — flipping status from '
          '${_status.name} to error. THIS IS LIKELY WHAT IS KEEPING THE '
          'PAUSE MODAL UP even though the WebSocket connected successfully. '
          'Common causes on web: CORS blocked, network error, or timeout.');
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

  /// Direct test-only status mutator. Used by DartboardStatusAnnouncer
  /// widget tests that need to drive the full status lifecycle (e.g.
  /// connected → disconnected → connected) without going through the
  /// hardware-shaped simulate* helpers above.
  @visibleForTesting
  void setStatusForTesting(DartboardConnectionStatus status) {
    _status = status;
    _error = null;
    notifyListeners();
  }

  // ─── Auto-reconnect ────────────────────────────────────────────────────────

  /// Schedule the next reconnect attempt using an exponential-backoff
  /// curve capped at 15s: 1s, 2s, 4s, 8s, 15s, 15s, ...
  ///
  /// Retries forever — there's no give-up state. The user is staring at
  /// the paused modal; the cheapest way back to gameplay is to keep
  /// trying. Cancellation hooks: [_resetReconnectState] (success),
  /// [clearDartboard] (user removed the board), [dispose] (provider
  /// going away).
  void _scheduleReconnect() {
    if (_useEmulatorMode || _dartboard == null || _apiKey == null) {
      // Nothing to reconnect to.
      return;
    }
    _reconnectTimer?.cancel();
    final delayMs = backoffMs(_reconnectAttempt);
    debugPrint('[Dartboard] Scheduling reconnect attempt '
        '#${_reconnectAttempt + 1} in ${delayMs}ms');
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), _attemptReconnect);
  }

  /// 1s → 2s → 4s → 8s → 15s → 15s ... (cap at 15s).
  @visibleForTesting
  static int backoffMs(int attempt) {
    const cap = 15000;
    final ms = 1000 * (1 << attempt); // 2^attempt seconds
    return ms > cap ? cap : ms;
  }

  Future<void> _attemptReconnect() async {
    _reconnectTimer = null;
    if (_useEmulatorMode || _dartboard == null || _apiKey == null) return;
    if (_status == DartboardConnectionStatus.connected) return;

    _reconnectAttempt++;
    debugPrint('[Dartboard] Reconnect attempt #$_reconnectAttempt');
    await _attemptConnection();

    if (_status != DartboardConnectionStatus.connected) {
      // Schedule the next attempt. _reconnectAttempt has already been
      // incremented, so the next call uses a larger backoff.
      _scheduleReconnect();
    }
    // Success path: _resetReconnectState was called via the success
    // handler inside _onWebSocketConnected (or _applyBoardStatus).
  }

  /// Cancel any pending reconnect timer and reset the backoff counter.
  /// Called by every code path that establishes a healthy connection,
  /// plus from clearDartboard / dispose to stop background work.
  void _resetReconnectState() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    // A resolved (or abandoned) connection has no pending status timeout.
    _statusTimeoutTimer?.cancel();
    _statusTimeoutTimer = null;
    _connectGeneration++;
  }

  /// Public hook used by visibility / lifecycle listeners on web to
  /// kick off an immediate reconnect when the tab becomes visible
  /// again after a sleep/wake cycle. Resets the backoff counter so
  /// the user doesn't have to wait through a stale backoff window.
  void forceReconnectNow() {
    if (_status == DartboardConnectionStatus.connected) return;
    if (_useEmulatorMode || _dartboard == null || _apiKey == null) return;
    debugPrint('[Dartboard] forceReconnectNow — wake-up trigger');
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    _attemptReconnect();
  }

  @override
  void dispose() {
    _disposed = true;
    stopStatusChecking();
    _resetReconnectState();
    _wakeListener.stop();
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _sourceSubscription?.cancel();
    _sourceSubscription = null;
    _mockApiService?.dispose();
    _mockApiService = null;
    _eventBus.close();
    _webSocketService?.dispose();
    super.dispose();
  }
}

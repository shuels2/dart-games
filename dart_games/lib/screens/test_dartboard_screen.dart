import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mock_scolia_api_service.dart';
import '../services/dart_announcer_service.dart';
import '../services/app_settings.dart';
import '../widgets/interactive_dartboard.dart';

class TestDartboardScreen extends StatefulWidget {
  final DartAnnouncerService announcer;

  const TestDartboardScreen({
    super.key,
    required this.announcer,
  });

  @override
  State<TestDartboardScreen> createState() => _TestDartboardScreenState();
}

class _TestDartboardScreenState extends State<TestDartboardScreen> {
  final MockScoliaApiService _mockApi = MockScoliaApiService();
  final ScrollController _logScrollController = ScrollController();
  final GlobalKey<InteractiveDartboardState> _dartboardKey = GlobalKey();
  String _playerName = 'Player 1';
  bool _autoScroll = true;
  int _dartThrowCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
    _loadSettings();
    _mockApi.eventStream.listen((_) {
      if (mounted) {
        setState(() {});
        if (_autoScroll && _logScrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_logScrollController.hasClients) {
              _logScrollController.animateTo(
                _logScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });

    // Simulate board connection on start
    Future.delayed(const Duration(milliseconds: 500), () {
      _mockApi.simulateBoardConnected('TEST-BOARD-001');
    });
  }

  /// Initialize default settings if they don't exist
  Future<void> _initializeDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if defaults have been set
    final hasDefaults = prefs.containsKey('voice_engine');

    if (!hasDefaults) {
      // Set initial defaults: ResponsiveVoice, Australian Female, Professional
      await prefs.setString('voice_engine', VoiceEngine.responsiveVoice.name);
      await prefs.setString('announcer_style', AnnouncerVoice.professional.name);
      await prefs.setString('responsive_voice', 'Australian Female');
      await prefs.setString('system_voice', '');
    }
  }

  /// Load saved settings and apply them to the announcer
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load voice engine
    final engineStr = prefs.getString('voice_engine') ?? 'responsiveVoice';
    final voiceEngine = VoiceEngine.values.firstWhere(
      (e) => e.name == engineStr,
      orElse: () => VoiceEngine.responsiveVoice,
    );

    // Load announcer style
    final styleStr = prefs.getString('announcer_style') ?? 'professional';
    final announcerStyle = AnnouncerVoice.values.firstWhere(
      (v) => v.name == styleStr,
      orElse: () => AnnouncerVoice.professional,
    );

    // Load ResponsiveVoice
    final responsiveVoice = prefs.getString('responsive_voice') ?? 'Australian Female';

    // Load system voice
    final systemVoice = prefs.getString('system_voice') ?? '';

    // Apply settings to announcer
    widget.announcer.setVoice(announcerStyle);

    if (voiceEngine == VoiceEngine.responsiveVoice) {
      // Wait a bit for ResponsiveVoice to load
      await Future.delayed(const Duration(seconds: 2));
      if (widget.announcer.isResponsiveVoiceReady()) {
        widget.announcer.useResponsiveVoice();
        widget.announcer.setResponsiveVoice(responsiveVoice);
      } else {
        // Fall back to browser voices if ResponsiveVoice isn't ready
        widget.announcer.useBrowserVoices();
        if (systemVoice.isNotEmpty) {
          widget.announcer.setSystemVoice(systemVoice);
        }
      }
    } else {
      widget.announcer.useBrowserVoices();
      if (systemVoice.isNotEmpty) {
        widget.announcer.setSystemVoice(systemVoice);
      }
    }
  }

  @override
  void dispose() {
    _mockApi.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _handleDartThrow(int score, String multiplier, int baseScore, Offset position) {
    setState(() {
      _dartThrowCount++;
    });

    // Announce the dart throw
    widget.announcer.announceDart(score, multiplier);

    _mockApi.simulateDartThrow(
      score: score,
      multiplier: multiplier,
      playerName: _playerName,
      baseScore: baseScore,
      widgetX: position.dx,
      widgetY: position.dy,
      widgetSize: 600, // Match the dartboard size
    );
  }

  Future<void> _handleRemoveDarts() async {
    // Don't start if already removing darts
    if (_dartThrowCount == 0) return;

    final dartboardState = _dartboardKey.currentState;
    if (dartboardState == null) return;

    final totalDarts = dartboardState.dartCount;
    if (totalDarts == 0) return;

    // Trigger TAKEOUT_STARTED event
    _mockApi.simulateTakeoutStarted();

    // Remove darts one at a time with 0.5 second delays
    for (int i = 0; i < totalDarts; i++) {
      await Future.delayed(const Duration(milliseconds: 500));

      final removed = dartboardState.removeSingleDart();
      if (removed) {
        setState(() {
          _dartThrowCount--;
        });
      }
    }

    // Trigger TAKEOUT_FINISHED event
    _mockApi.simulateTakeoutFinished(falseTakeout: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 12),
            const Text('Scolia 2 Dartboard Emulator'),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Logs',
            onPressed: () {
              setState(() {
                _mockApi.clearLogs();
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'disconnect') {
                _mockApi.simulateBoardDisconnected('TEST-BOARD-001');
              } else if (value == 'reconnect') {
                _mockApi.simulateBoardConnected('TEST-BOARD-001');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'disconnect',
                child: Text('Simulate Disconnect'),
              ),
              const PopupMenuItem(
                value: 'reconnect',
                child: Text('Simulate Reconnect'),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Dartboard
          Expanded(
            flex: 2,
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                  const Text(
                    'Click on the dartboard to simulate throws',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: InteractiveDartboard(
                      key: _dartboardKey,
                      onDartThrow: _handleDartThrow,
                      onRemoveDarts: _handleRemoveDarts,
                      size: 600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Dart Throws: $_dartThrowCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: _dartThrowCount > 0 ? _handleRemoveDarts : null,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove Darts'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            ),
          ),

          // Right side - API Logs
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black87,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade900,
                    child: Row(
                      children: [
                        const Icon(Icons.api, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Scolia API Call Logs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Checkbox(
                              value: _autoScroll,
                              onChanged: (value) {
                                setState(() {
                                  _autoScroll = value ?? true;
                                });
                              },
                            ),
                            const Text(
                              'Auto-scroll',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${_mockApi.apiLogs.length} calls',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _mockApi.apiLogs.isEmpty
                        ? const Center(
                            child: Text(
                              'No API calls yet. Click on the dartboard to start!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _logScrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: _mockApi.apiLogs.length,
                            itemBuilder: (context, index) {
                              final log = _mockApi.apiLogs[index];
                              return _buildLogEntry(log, index);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log, int index) {
    final timestamp = log['timestamp'] as String;
    final endpoint = log['endpoint'] as String;
    final method = log['method'] as String;
    final request = log['request'];
    final response = log['response'];

    final time = DateTime.parse(timestamp);
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade800,
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getMethodColor(method),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                method,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                endpoint,
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Text(
              timeStr,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (request != null) ...[
                  const Text(
                    'REQUEST:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    const JsonEncoder.withIndent('  ').convert(request),
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'RESPONSE:',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  const JsonEncoder.withIndent('  ').convert(response),
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

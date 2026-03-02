import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/api_log_entry.dart';
import '../services/api_logger_service.dart';
import '../widgets/dartboard_connection_info/dartboard_connection_info.dart';
import '../widgets/dartboard_connection_info/dartboard_connection_info_config.dart';

class ApiLoggerScreen extends StatefulWidget {
  const ApiLoggerScreen({super.key});

  @override
  State<ApiLoggerScreen> createState() => _ApiLoggerScreenState();
}

class _ApiLoggerScreenState extends State<ApiLoggerScreen> {
  final ApiLoggerService _loggerService = ApiLoggerService();
  final ScrollController _logScrollController = ScrollController();
  final Map<String, TextEditingController> _noteControllers = {};
  bool _autoScroll = true;
  StreamSubscription<List<ApiLogEntry>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _loggerService.entryStream.listen((_) {
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
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _logScrollController.dispose();
    for (final controller in _noteControllers.values) {
      controller.dispose();
    }
    _noteControllers.clear();
    _loggerService.dispose();
    super.dispose();
  }

  TextEditingController _getNoteController(ApiLogEntry entry) {
    return _noteControllers.putIfAbsent(entry.id, () {
      final controller = TextEditingController(text: entry.userNote);
      controller.addListener(() {
        _loggerService.updateNote(entry.id, controller.text);
      });
      return controller;
    });
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
      case 'INCOMING':
        return Colors.purple;
      case 'WS_IN':
        return Colors.deepPurple;
      case 'WS_OUT':
        return Colors.teal;
      case 'WS_CONNECT':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _loggerService.entries;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF004D40), // Teal 900
                Color(0xFF00897B), // Teal 600
                Color(0xFF4DB6AC), // Teal 300
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 32,
          onPressed: () => Navigator.of(context).pop(),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        title: const Text('Dartboard API Logger'),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DartboardConnectionInfo(
              config: DartboardConnectionInfoConfig.apiLogger(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Logs',
            onPressed: () {
              setState(() {
                _loggerService.clearLogs();
                for (final controller in _noteControllers.values) {
                  controller.dispose();
                }
                _noteControllers.clear();
              });
            },
          ),
          IconButton(
            icon: Icon(
              _loggerService.isLogging ? Icons.stop : Icons.play_arrow,
            ),
            tooltip: _loggerService.isLogging
                ? 'Stop Logging'
                : 'Start Logging API Traffic',
            onPressed: () {
              setState(() {
                if (_loggerService.isLogging) {
                  _loggerService.stopLogging();
                } else {
                  _loggerService.startLogging();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Download Log File',
            onPressed: entries.isEmpty
                ? null
                : () async {
                    final result = await _loggerService.exportToJson();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Log downloaded as $result',
                          ),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // File path bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                const Icon(Icons.save_alt, color: Colors.teal, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Export as: ',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: Text(
                    _loggerService.logFilename,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  color: Colors.tealAccent,
                  tooltip: 'Generate new filename',
                  onPressed: () {
                    setState(() {
                      _loggerService.regenerateFilename();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  color: Colors.white54,
                  tooltip: 'Copy filename',
                  onPressed: () {
                    // Copy filename logic handled by clipboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Filename: ${_loggerService.logFilename}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Log header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withValues(alpha: 0.7),
            ),
            child: Row(
              children: [
                const Icon(Icons.api, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'API Call Logs',
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
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entries.length} calls',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_loggerService.isLogging) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Logging',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Log entries
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No API calls logged yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Press the play button to start logging API traffic',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _logScrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _buildLogEntry(entries[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(ApiLogEntry entry, int index) {
    final time = entry.timestamp;
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';

    final noteController = _getNoteController(entry);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade800,
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getMethodColor(entry.method),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.method,
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
                entry.endpoint,
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
                if (entry.request != null) ...[
                  const Text(
                    'REQUEST:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    const JsonEncoder.withIndent('  ').convert(entry.request),
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (entry.response != null) ...[
                  const Text(
                    'RESPONSE:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    const JsonEncoder.withIndent('  ').convert(entry.response),
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'NOTES:',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: noteController,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add notes about this API call...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

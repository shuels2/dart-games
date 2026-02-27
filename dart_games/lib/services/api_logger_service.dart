import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../models/api_log_entry.dart';
import 'api_logger_download.dart'
    if (dart.library.js_interop) 'api_logger_download_web.dart';

class ApiLoggerService {
  final List<ApiLogEntry> _entries = [];
  final _controller = StreamController<List<ApiLogEntry>>.broadcast();
  final _uuid = const Uuid();
  bool _isLogging = false;
  late String _logFilename;

  /// Global instance so DartboardProvider can feed real API traffic in.
  static ApiLoggerService? activeInstance;

  List<ApiLogEntry> get entries => List.unmodifiable(_entries);
  Stream<List<ApiLogEntry>> get entryStream => _controller.stream;
  bool get isLogging => _isLogging;
  String get logFilename => _logFilename;

  ApiLoggerService() {
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    _logFilename = 'dartboard_api_log_${date}_$time.json';
  }

  void regenerateFilename() {
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    _logFilename = 'dartboard_api_log_${date}_$time.json';
  }

  void addLogEntry({
    required String method,
    required String endpoint,
    Map<String, dynamic>? request,
    Map<String, dynamic>? response,
  }) {
    if (!_isLogging) return;
    final entry = ApiLogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      method: method,
      endpoint: endpoint,
      request: request,
      response: response,
    );
    _entries.add(entry);
    _controller.add(_entries);
  }

  void updateNote(String entryId, String note) {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      _entries[index].userNote = note;
    }
  }

  void clearLogs() {
    _entries.clear();
    _controller.add(_entries);
  }

  void startLogging() {
    if (_isLogging) return;
    _isLogging = true;
    activeInstance = this;
  }

  void stopLogging() {
    _isLogging = false;
    if (activeInstance == this) {
      activeInstance = null;
    }
  }

  /// Called by DartboardProvider (or any HTTP layer) to log real API traffic.
  /// Only records if logging is active.
  static void logApiCall({
    required String method,
    required String endpoint,
    Map<String, dynamic>? request,
    Map<String, dynamic>? response,
  }) {
    activeInstance?.addLogEntry(
      method: method,
      endpoint: endpoint,
      request: request,
      response: response,
    );
  }

  Future<String> exportToJson() async {
    final jsonList = _entries.map((e) => e.toJson()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
    return downloadLogFile(_logFilename, jsonString);
  }

  void dispose() {
    stopLogging();
    _controller.close();
  }
}

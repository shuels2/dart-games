class ApiLogEntry {
  final String id;
  final DateTime timestamp;
  final String method;
  final String endpoint;
  final Map<String, dynamic>? request;
  final Map<String, dynamic>? response;
  String userNote;

  ApiLogEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.endpoint,
    this.request,
    this.response,
    this.userNote = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'method': method,
      'endpoint': endpoint,
      'request': request,
      'response': response,
      'userNote': userNote,
    };
  }

  factory ApiLogEntry.fromJson(Map<String, dynamic> json) {
    return ApiLogEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      method: json['method'] as String,
      endpoint: json['endpoint'] as String,
      request: json['request'] as Map<String, dynamic>?,
      response: json['response'] as Map<String, dynamic>?,
      userNote: json['userNote'] as String? ?? '',
    );
  }
}

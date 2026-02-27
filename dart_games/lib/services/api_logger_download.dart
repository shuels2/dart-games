import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> downloadLogFile(String filename, String jsonString) async {
  final dir = await getApplicationDocumentsDirectory();
  final logDir = Directory('${dir.path}/api_logs');
  if (!await logDir.exists()) {
    await logDir.create(recursive: true);
  }
  final file = File('${logDir.path}/$filename');
  await file.writeAsString(jsonString);
  return file.path;
}

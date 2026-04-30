import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Native platform stub - not used since music is now handled by the backend API
// These functions exist only to satisfy the conditional import

Future<void> storeMusic(String fileName, String dataUrl) async {
  // Not used on native platforms
}

Future<Map<String, String>?> loadStoredMusic() async {
  // Not used on native platforms
  return null;
}

Future<void> clearStoredMusic() async {
  // Not used on native platforms
}

Future<void> storeMusicFiles(List<Map<String, dynamic>> filesJson) async {
  // Not used - handled by the backend API
}

Future<List<Map<String, dynamic>>?> loadStoredMusicFiles() async {
  // Not used - handled by the backend API
  return null;
}

/// Copy music file to app storage for persistent access.
Future<String> copyMusicToAppStorage(
    String sourcePath, String fileName, String id) async {
  // Get app documents directory
  final directory = await getApplicationDocumentsDirectory();
  final musicDir = Directory('${directory.path}/victory_music');

  // Create directory if it doesn't exist
  if (!await musicDir.exists()) {
    await musicDir.create(recursive: true);
  }

  // Determine file extension
  final extension = fileName.split('.').last.toLowerCase();
  final newFileName = '$id.$extension';
  final targetPath = '${musicDir.path}/$newFileName';

  // Copy file to app storage
  final sourceFile = File(sourcePath);
  await sourceFile.copy(targetPath);

  return targetPath;
}

/// Delete a music file from app storage.
Future<void> deleteMusicFile(String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    print('Error deleting music file: $e');
    // Don't throw - file might already be deleted
  }
}

/// Check if a file exists at the given path.
Future<bool> fileExists(String filePath) async {
  try {
    final file = File(filePath);
    return await file.exists();
  } catch (e) {
    return false;
  }
}

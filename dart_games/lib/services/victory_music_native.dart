// Native platform stub - not used since we use SharedPreferences directly
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

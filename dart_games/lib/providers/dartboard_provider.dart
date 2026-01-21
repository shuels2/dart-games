import 'package:flutter/foundation.dart';
import '../models/dartboard.dart';
import '../services/scolia_api_service.dart';
import '../services/storage_service.dart';

class DartboardProvider with ChangeNotifier {
  final ScoliaApiService _apiService = ScoliaApiService();
  final StorageService _storageService = StorageService();

  Dartboard? _dartboard;
  bool _isRegistered = false;
  bool _isLoading = false;
  String? _error;

  Dartboard? get dartboard => _dartboard;
  bool get isRegistered => _isRegistered;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if user has a dartboard registered
  Future<void> checkDartboardStatus(String bearerToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if there's a stored serial number
      final serialNumber = await _storageService.getSerialNumber();

      if (serialNumber != null) {
        // Get all boards from API
        final boards = await _apiService.getBoards(bearerToken);

        // Find the board with matching serial number
        try {
          _dartboard = boards.firstWhere(
            (board) => board.serialNumber == serialNumber,
          );
          _isRegistered = true;
        } catch (e) {
          // Board not found in API, clear local storage
          await _storageService.saveSerialNumber('');
          _dartboard = null;
          _isRegistered = false;
        }
      } else {
        _isRegistered = false;
      }
    } catch (e) {
      _error = 'Failed to check dartboard status: $e';
      _isRegistered = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register a new dartboard
  Future<bool> registerDartboard(String bearerToken, String serialNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if user already has a board registered
      final boards = await _apiService.getBoards(bearerToken);

      if (boards.isNotEmpty) {
        _error = 'You can only register one dartboard. Please disconnect your existing board first.';
        return false;
      }

      // Connect the board
      _dartboard = await _apiService.connectBoard(bearerToken, serialNumber);

      // Save to local storage
      await _storageService.saveSerialNumber(serialNumber);

      _isRegistered = true;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get dartboard info
  Future<void> getDartboard(String bearerToken) async {
    await checkDartboardStatus(bearerToken);
  }

  // Clear dartboard
  Future<void> clearDartboard() async {
    await _storageService.saveSerialNumber('');
    _dartboard = null;
    _isRegistered = false;
    notifyListeners();
  }

  // Disconnect dartboard
  Future<bool> disconnectDartboard(String bearerToken) async {
    if (_dartboard == null) {
      _error = 'No dartboard to disconnect';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.disconnectBoard(bearerToken, _dartboard!.serialNumber);
      await clearDartboard();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

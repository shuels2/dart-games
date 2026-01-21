import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class SetupWizardProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  int _currentStep = 0;
  bool _isComplete = false;

  int get currentStep => _currentStep;
  bool get isComplete => _isComplete;
  int get totalSteps => 3; // Welcome, Login, Register Board

  // Move to next step
  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  // Move to previous step
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  // Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // Complete setup
  Future<void> completeSetup() async {
    _isComplete = true;
    await _storageService.setSetupComplete(true);
    notifyListeners();
  }

  // Check if setup is complete
  Future<void> checkSetupStatus() async {
    _isComplete = await _storageService.isSetupComplete();
    notifyListeners();
  }

  // Reset wizard (for testing or logout)
  Future<void> resetWizard() async {
    _currentStep = 0;
    _isComplete = false;
    await _storageService.setSetupComplete(false);
    notifyListeners();
  }

  // Get progress percentage
  double get progress {
    return (_currentStep + 1) / totalSteps;
  }
}

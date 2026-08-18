import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeButtonColorWhenEnabledTest(saveResumeSpec,
      description: 'button is visible with correct color when enabled');
}

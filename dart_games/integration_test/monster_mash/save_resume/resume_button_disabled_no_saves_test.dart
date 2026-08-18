import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeButtonDisabledNoSavesTest(saveResumeSpec,
      description: 'button is disabled when no saved games exist');
}

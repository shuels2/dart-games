import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeGameLoadsScreenTest(saveResumeSpec,
      description: 'Resume Game loads game screen with correct state');
}

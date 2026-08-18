import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeButtonEnabledAfterResaveTest(saveResumeSpec,
      description: 'button stays shown after resume (save still exists)');
}

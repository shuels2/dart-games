import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeAutoDeletesOnCompletionTest(saveResumeSpec,
      description: 'resumed game auto-deletes saved game on completion');
}

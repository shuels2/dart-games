import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeResaveOverwritesTest(saveResumeSpec,
      description: 'Re-saving a resumed game overwrites the original save');
}

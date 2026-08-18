import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeButtonEnabledAfterSaveTest(saveResumeSpec,
      description: 'button becomes enabled after saving a game');
}

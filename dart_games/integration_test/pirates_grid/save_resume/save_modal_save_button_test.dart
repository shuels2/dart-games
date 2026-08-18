import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runSaveModalSaveButtonTest(saveResumeSpec,
      description: 'Save button saves game and navigates back');
}

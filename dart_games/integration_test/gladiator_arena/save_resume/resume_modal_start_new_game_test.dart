import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeModalStartNewGameTest(saveResumeSpec,
      description: 'Start New Game button in resume modal dismisses modal');
}

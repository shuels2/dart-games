import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeModalStartNewGameTest(saveResumeSpec,
      description: 'Start New Game dismisses modal and shows menu');
}

import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runSaveModalBack0DartsTest(saveResumeSpec,
      description: 'back button with 0 darts navigates without save modal');
}

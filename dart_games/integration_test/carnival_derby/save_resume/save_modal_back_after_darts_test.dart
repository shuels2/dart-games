import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runSaveModalBackAfterDartsTest(saveResumeSpec,
      description: 'back button after darts thrown shows save modal');
}

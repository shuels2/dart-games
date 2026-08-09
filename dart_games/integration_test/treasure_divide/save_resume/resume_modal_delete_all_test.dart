import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeModalDeleteAllTest(saveResumeSpec,
      description: 'delete all saved games shows empty state');
}

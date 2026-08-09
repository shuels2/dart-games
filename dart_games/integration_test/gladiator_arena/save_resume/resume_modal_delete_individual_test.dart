import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeModalDeleteIndividualTest(saveResumeSpec,
      description: 'delete individual save removes it from modal list');
}

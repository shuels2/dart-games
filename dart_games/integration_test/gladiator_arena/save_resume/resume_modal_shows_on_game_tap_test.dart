import 'package:integration_test/integration_test.dart';

import '../../shared/save_resume_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runResumeModalShowsOnGameTapTest(saveResumeSpec,
      description: 'tapping game card shows resume modal when saves exist');
}

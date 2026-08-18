import 'package:integration_test/integration_test.dart';

import '../../shared/play_to_complete_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runPlayToCompleteDefaultTest(playToCompleteSpec,
      description: 'Play to Complete: Pirate\'s Grid with default settings (Easy, Bo1, Steal OFF, Speed OFF)');
}

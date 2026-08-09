import 'package:integration_test/integration_test.dart';

import '../../shared/play_to_complete_suite.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  runPlayToCompleteMidGameTest(playToCompleteSpec,
      description: 'Play to Complete: Monster Mash mid-game pickup');
}

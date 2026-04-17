import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/provider_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/ui_test_helpers.dart';

/// Debug test to find WHERE the failure is being injected into binding.results.
/// The test body passes, but flutter drive reports failure.
/// Theory: an async exception occurs during post-test cleanup (after testBody()
/// returns but during _runTestBody's widget unmount/pump phase).

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.targetTag();

  // Track all Flutter errors — keep this GLOBAL so it persists through cleanup
  final List<String> capturedErrors = [];
  int errorCount = 0;

  MockScoliaApiService? getMockApi(WidgetTester tester) {
    final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
    return dartboardProvider.apiService;
  }

  Future<void> throwDartViaMock(WidgetTester tester, int number, {String multiplier = 'single'}) async {
    final mockApi = getMockApi(tester);
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: number * (multiplier == 'double' ? 2 : multiplier == 'triple' ? 3 : 1),
        multiplier: multiplier,
        playerName: 'Player',
        baseScore: number,
        widgetX: 125.0,
        widgetY: 125.0,
        widgetSize: 250.0,
      );
      await PumpSequences.simpleUpdate(tester);
    }
  }

  group('Debug Test 6 - post-test cleanup investigation', () {
    // Use tearDown to check if failure was injected after test body
    tearDown(() {
      print('\n========== tearDown CALLBACK ==========');
      print('  binding.results: ${binding.results}');
      print('  binding.failureMethodsDetails: ${binding.failureMethodsDetails}');
      print('  capturedErrors count: $errorCount');
      if (capturedErrors.isNotEmpty) {
        for (int i = 0; i < capturedErrors.length; i++) {
          print('  --- Captured Error $i ---');
          final err = capturedErrors[i];
          print(err.length > 300 ? err.substring(0, 300) : err);
          print('  ---');
        }
      }
    });

    testWidgets('Test 6 with cleanup monitoring', (WidgetTester tester) async {
      print('\n========== DEBUG TEST 6 START ==========');
      print('  binding.results BEFORE test: ${binding.results}');

      // Install FlutterError.onError interceptor
      // DELIBERATELY do NOT restore it — we want it active during post-test cleanup
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errorCount++;
        final errorStr = '[$errorCount] ${details.summary} | ${details.exception}';
        capturedErrors.add(errorStr);
        print('\n!!!!! FLUTTER ERROR #$errorCount !!!!!');
        print('  summary: ${details.summary}');
        print('  exception type: ${details.exception.runtimeType}');
        print('  exception: ${details.exception}');
        print('  context: ${details.context}');
        print('  library: ${details.library}');
        print('  stack (first 8 lines):');
        final stackLines = details.stack?.toString().split('\n') ?? ['no stack'];
        for (int i = 0; i < stackLines.length && i < 8; i++) {
          print('    ${stackLines[i]}');
        }
        print('  binding.results at error time: ${binding.results}');
        print('!!!!! END FLUTTER ERROR #$errorCount !!!!!\n');
        // STILL call original so the framework processes it normally
        originalOnError?.call(details);
      };

      // Step 1: Navigate to game menu
      print('\n--- Step 1: navigateToGameMenu ---');
      await UITestHelpers.navigateToGameMenu(tester, config);
      print('navigateToGameMenu complete (errors so far: $errorCount)');

      // Check player state
      final playerProvider = Provider.of<PlayerProvider>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      print('  allPlayers.length: ${playerProvider.allPlayers.length}');

      // Step 2: Add players
      print('\n--- Step 2: Adding players ---');
      await UITestHelpers.addPlayer(tester, 'Shield1', config);
      print('  Shield1 added (errors: $errorCount, players: ${playerProvider.allPlayers.length})');
      await UITestHelpers.addPlayer(tester, 'Shield2', config);
      print('  Shield2 added (errors: $errorCount, players: ${playerProvider.allPlayers.length})');

      // Step 3: Start game
      print('\n--- Step 3: Starting game ---');
      await UITestHelpers.startGame(tester, config);
      print('  Game started (errors: $errorCount)');

      // Check state
      final targetTagProvider = Provider.of<TargetTagProvider>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      final currentPlayerId = targetTagProvider.getCurrentPlayerId();
      print('  currentPlayerId: $currentPlayerId');
      print('  targetNumbers: ${targetTagProvider.currentGame?.targetNumbers}');
      print('  allPlayers: ${playerProvider.allPlayers.map((p) => '${p.name}(${p.id})').toList()}');

      // Step 4: Core test logic
      print('\n--- Step 4: Test 6 assertion ---');
      expect(currentPlayerId, isNotNull, reason: 'currentPlayerId should not be null');

      final allPlayers = ProviderHelpers.getAllPlayers(tester);
      final opponent = allPlayers.firstWhere((p) => p.id != currentPlayerId, orElse: () => allPlayers.first);
      final opponentTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, opponent.id);
      print('  opponent: ${opponent.name}, target: $opponentTarget');

      expect(opponentTarget, isNotNull, reason: 'Opponent target should not be null');
      print('  expect(opponentTarget, isNotNull) PASSED (errors: $errorCount)');

      final shieldsBefore = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId!);
      await throwDartViaMock(tester, opponentTarget!);
      final shieldsAfter = ProviderHelpers.getTargetTagPlayerShields(tester, currentPlayerId);
      expect(shieldsAfter, equals(shieldsBefore));
      print('  shields assertion PASSED');

      // Step 5: Extra pumps to flush any pending async ops BEFORE test body ends
      print('\n--- Step 5: Extended pump to flush pending async ---');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (errorCount > 0) {
          print('  ERROR appeared after pump $i!');
          break;
        }
      }
      print('  After 5s of pumps: errors=$errorCount');
      print('  binding.results: ${binding.results}');

      print('\n========== TEST BODY COMPLETE (errors: $errorCount) ==========');
      // NOTE: We deliberately do NOT restore FlutterError.onError here
      // so our interceptor stays active during post-test cleanup
    });
  });
}

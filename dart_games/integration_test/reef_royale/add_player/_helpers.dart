import 'package:flutter_test/flutter_test.dart';

import '../../shared/element_finders.dart';
import '../../shared/game_ui_config.dart';

final config = GameUIConfig.reefRoyale();

/// Get whichever add player button is visible (empty state or normal)
Finder getAddPlayerButton(WidgetTester tester) {
  final emptyState = ElementFinders.getReefRoyaleAddPlayerButtonEmptyState();
  if (emptyState.evaluate().isNotEmpty) return emptyState;
  return ElementFinders.getReefRoyaleAddPlayerButton();
}

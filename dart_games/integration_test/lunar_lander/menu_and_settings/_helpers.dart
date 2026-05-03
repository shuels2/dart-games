import 'package:flutter_test/flutter_test.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/settings_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/settings_helpers.dart';

final config = GameUIConfig.lunarLander();

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> setAltitude(WidgetTester tester, int value) =>
    SettingsHelpers.setLunarLanderAltitude(tester, value);

Future<void> setHardLanding(WidgetTester tester, {required bool enabled}) =>
    SettingsHelpers.setLunarLanderHardLanding(tester, enabled: enabled);

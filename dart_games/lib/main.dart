import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/dartboard_provider.dart';
import 'providers/player_provider.dart';
import 'providers/horse_race_provider.dart';
import 'providers/target_tag_provider.dart';
import 'providers/monster_mash_provider.dart';
import 'providers/reef_royale_provider.dart';
import 'providers/clockwork_quest_provider.dart';
import 'providers/lunar_lander_provider.dart';
import 'services/api/api_client.dart';
import 'services/api/api_config.dart';
import 'services/app_settings.dart';
import 'services/storage_service.dart';
import 'services/victory_music_service.dart';
import 'screens/splash_screen.dart';
import 'screens/dartboard_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/games/clockwork_quest/clockwork_quest_menu_screen.dart';
import 'screens/games/clockwork_quest/clockwork_quest_game_screen.dart';
import 'screens/games/clockwork_quest/clockwork_quest_results_screen.dart';
import 'screens/games/lunar_lander/lunar_lander_menu_screen.dart';
import 'screens/games/lunar_lander/lunar_lander_game_screen.dart';
import 'screens/games/lunar_lander/lunar_lander_results_screen.dart';

/// Global API client instance, shared across all services.
///
/// Tracked via [_previousApiClient] so that each [main] call can dispose
/// the old client before creating a fresh one.  On the web this calls
/// `XMLHttpRequest.abort()` on every pending request, preventing stale
/// POST/PUT calls from a prior integration-test run from completing and
/// writing data to the server after it has been reset.
ApiClient? _previousApiClient;
late ApiClient apiClient;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dispose previous ApiClient to cancel any in-flight HTTP requests
  // from a prior integration-test run or hot restart.
  _previousApiClient?.dispose();

  // Initialize API client — port comes from --dart-define=SERVER_PORT (tests)
  // or falls back to 8080 (production).
  ApiConfig.configure(ApiConfig.baseUrl);
  apiClient = ApiClient();
  _previousApiClient = apiClient;

  // Initialize services with the API client
  AppSettings.initialize(apiClient);
  StorageService.initialize(apiClient);
  VictoryMusicService().initializeApi(apiClient);

  // Preload all Google Fonts used in the app to prevent FOUT (Flash of Unstyled Text)
  await _preloadFonts();

  // UniqueKey forces Flutter to create a fresh element tree (and fresh
  // providers) each time runApp() is called.  Without it, runApp() with a
  // const widget reuses the existing elements via canUpdate(), which leaks
  // in-memory provider state across integration-test runs.
  runApp(DartGamesApp(key: UniqueKey()));
}

Future<void> _preloadFonts() async {
  // Preload Nunito (main app font) with all weights
  GoogleFonts.nunito(fontWeight: FontWeight.w300);
  GoogleFonts.nunito(fontWeight: FontWeight.w400);
  GoogleFonts.nunito(fontWeight: FontWeight.w500);
  GoogleFonts.nunito(fontWeight: FontWeight.w600);
  GoogleFonts.nunito(fontWeight: FontWeight.w700);
  GoogleFonts.nunito(fontWeight: FontWeight.w900);

  // Preload Carnival Derby fonts
  GoogleFonts.rye(fontWeight: FontWeight.bold);
  GoogleFonts.bangers();
  GoogleFonts.luckiestGuy();
  GoogleFonts.montserrat(fontWeight: FontWeight.w300);
  GoogleFonts.montserrat(fontWeight: FontWeight.w500);
  GoogleFonts.montserrat(fontWeight: FontWeight.w900);
  GoogleFonts.robotoCondensed(fontWeight: FontWeight.w300);

  // Preload Target Tag fonts
  GoogleFonts.fredoka(fontWeight: FontWeight.w400);
  GoogleFonts.fredoka(fontWeight: FontWeight.w500);
  GoogleFonts.fredoka(fontWeight: FontWeight.w700);

  // Preload Monster Mash fonts
  GoogleFonts.creepster();
  GoogleFonts.pirataOne();
  // Montserrat already loaded for Carnival Derby

  // Preload Clockwork Quest fonts
  GoogleFonts.cinzelDecorative(fontWeight: FontWeight.w400);
  GoogleFonts.cinzelDecorative(fontWeight: FontWeight.w700);
  GoogleFonts.lato(fontWeight: FontWeight.w400);
  GoogleFonts.lato(fontWeight: FontWeight.w600);
  GoogleFonts.lato(fontWeight: FontWeight.w700);

  // Preload Lunar Lander fonts
  GoogleFonts.orbitron(fontWeight: FontWeight.w400);
  GoogleFonts.orbitron(fontWeight: FontWeight.w700);
  GoogleFonts.exo2(fontWeight: FontWeight.w400);
  GoogleFonts.exo2(fontWeight: FontWeight.w600);
  GoogleFonts.exo2(fontWeight: FontWeight.w700);

  // Wait for all fonts to load
  await GoogleFonts.pendingFonts([
    GoogleFonts.nunito(),
    GoogleFonts.rye(),
    GoogleFonts.bangers(),
    GoogleFonts.luckiestGuy(),
    GoogleFonts.montserrat(),
    GoogleFonts.robotoCondensed(),
    GoogleFonts.fredoka(),
    GoogleFonts.creepster(),
    GoogleFonts.pirataOne(),
    GoogleFonts.cinzelDecorative(),
    GoogleFonts.lato(),
    GoogleFonts.orbitron(),
    GoogleFonts.exo2(),
  ]);
}

class DartGamesApp extends StatelessWidget {
  const DartGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final provider = DartboardProvider();
          provider.initialize(apiClient);
          return provider;
        }),
        ChangeNotifierProvider(create: (_) {
          final provider = PlayerProvider();
          provider.initialize(apiClient);
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => HorseRaceProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => TargetTagProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => MonsterMashProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => ReefRoyaleProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => ClockworkQuestProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => LunarLanderProvider(apiClient: apiClient)),
      ],
      child: MaterialApp(
        title: 'Dart Games',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6B35),
            primary: const Color(0xFFFF6B35), // Flame Orange
            secondary: const Color(0xFFF7931E), // Tangerine Orange
            tertiary: const Color(0xFF004E89), // Deep Ocean Blue
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.nunitoTextTheme().copyWith(
            // Hero Headers - Black (900), 32-40pt, negative letter spacing
            displayLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 40,
              letterSpacing: -0.02 * 40, // -0.02em
              height: 1.2,
            ),
            displayMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 36,
              letterSpacing: -0.02 * 36,
              height: 1.2,
            ),
            displaySmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              letterSpacing: -0.02 * 32,
              height: 1.2,
            ),
            // Screen Titles - Bold (700), 24pt
            headlineLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 28,
              height: 1.3,
            ),
            headlineMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.3,
            ),
            headlineSmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.3,
            ),
            // Live Scores - Semi-Bold (600), 28pt+, tabular nums
            titleLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              fontSize: 28,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.2,
            ),
            // Sub-headers - Medium (500), 18pt
            titleMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              height: 1.3,
            ),
            // Primary Actions - Bold (700), 18pt
            titleSmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.2,
            ),
            // Body/Rules - Regular (400), 16pt, line height 1.4x
            bodyLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.4,
            ),
            // Body - Regular (400), 16pt, line height 1.4x
            bodyMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.4,
            ),
            // Secondary Info - Regular (400), 14pt
            bodySmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.3,
            ),
            // Micro-Copy - Light (300), 12pt
            labelSmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w300,
              fontSize: 12,
              height: 1.3,
            ),
            // Labels Medium - Medium (500), 14pt
            labelMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.3,
            ),
            // Labels Large - Bold (700), 16pt for buttons
            labelLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.2,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shadowColor: Colors.black45,
              textStyle: const TextStyle(decoration: TextDecoration.none),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(decoration: TextDecoration.none),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              textStyle: const TextStyle(decoration: TextDecoration.none),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6B35),
            primary: const Color(0xFFFF8C5A), // Lighter Flame Orange for dark mode
            secondary: const Color(0xFFFFB347), // Lighter Tangerine Orange
            tertiary: const Color(0xFF4A90E2), // Lighter Ocean Blue
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).copyWith(
            // Hero Headers - Black (900), 32-40pt, negative letter spacing
            displayLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 40,
              letterSpacing: -0.02 * 40,
              height: 1.2,
            ),
            displayMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 36,
              letterSpacing: -0.02 * 36,
              height: 1.2,
            ),
            displaySmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              letterSpacing: -0.02 * 32,
              height: 1.2,
            ),
            // Screen Titles - Bold (700), 24pt
            headlineLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 28,
              height: 1.3,
            ),
            headlineMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.3,
            ),
            headlineSmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.3,
            ),
            // Live Scores - Semi-Bold (600), 28pt+, tabular nums
            titleLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              fontSize: 28,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.2,
            ),
            // Sub-headers - Medium (500), 18pt
            titleMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              height: 1.3,
            ),
            // Primary Actions - Bold (700), 18pt
            titleSmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.2,
            ),
            // Body/Rules - Regular (400), 16pt, line height 1.4x
            bodyLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.4,
            ),
            // Body - Regular (400), 16pt, line height 1.4x
            bodyMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.4,
            ),
            // Secondary Info - Regular (400), 14pt
            bodySmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.3,
            ),
            // Micro-Copy - Light (300), 12pt
            labelSmall: GoogleFonts.nunito(
              fontWeight: FontWeight.w300,
              fontSize: 12,
              height: 1.3,
            ),
            // Labels Medium - Medium (500), 14pt
            labelMedium: GoogleFonts.nunito(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.3,
            ),
            // Labels Large - Bold (700), 16pt for buttons
            labelLarge: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.2,
            ),
          ),
        ),
        themeMode: ThemeMode.light, // Default to light mode for carnival feel
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/dartboard-setup': (context) => const DartboardSetupScreen(),
          '/home': (context) => const HomeScreen(),
          '/clockwork_quest_menu': (context) => const ClockworkQuestMenuScreen(),
          '/clockwork_quest_game': (context) => const ClockworkQuestGameScreen(),
          '/clockwork_quest_results': (context) => const ClockworkQuestResultsScreen(),
          '/lunar_lander_menu': (context) => const LunarLanderMenuScreen(),
          '/lunar_lander_game': (context) => const LunarLanderGameScreen(),
          '/lunar_lander_results': (context) => const LunarLanderResultsScreen(),
        },
      ),
    );
  }
}

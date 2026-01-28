import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/dartboard_provider.dart';
import 'providers/player_provider.dart';
import 'providers/horse_race_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/dartboard_setup_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DartGamesApp());
}

class DartGamesApp extends StatelessWidget {
  const DartGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DartboardProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => HorseRaceProvider()),
      ],
      child: MaterialApp(
        title: 'Dart Games',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            primary: Colors.red,
            secondary: const Color(0xFFFFC107), // Amber/Yellow
            tertiary: const Color(0xFF2196F3), // Blue
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
            seedColor: Colors.red,
            primary: const Color(0xFFEF5350), // Lighter red for dark mode
            secondary: const Color(0xFFFFD54F), // Lighter amber
            tertiary: const Color(0xFF42A5F5), // Lighter blue
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
        },
      ),
    );
  }
}

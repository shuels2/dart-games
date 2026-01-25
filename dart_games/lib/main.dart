import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              letterSpacing: 1.2,
            ),
            headlineMedium: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 1.1,
            ),
            headlineSmall: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.0,
            ),
            titleLarge: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
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
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              letterSpacing: 1.2,
            ),
            headlineMedium: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 1.1,
            ),
            headlineSmall: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.0,
            ),
            titleLarge: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dartboard_provider.dart';
import 'providers/setup_wizard_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/setup_wizard/welcome_screen.dart';
import 'screens/setup_wizard/login_screen.dart';
import 'screens/setup_wizard/register_board_screen.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DartboardProvider()),
        ChangeNotifierProvider(create: (_) => SetupWizardProvider()),
      ],
      child: MaterialApp(
        title: 'Dart Games',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register-board': (context) => const RegisterBoardScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

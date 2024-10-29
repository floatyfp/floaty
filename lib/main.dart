import 'package:floaty/frontend/root.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:floaty/frontend/screens/login_screen.dart';
import 'package:floaty/backend/checkers.dart';
import 'package:floaty/frontend/screens/home_screen.dart';
import 'package:floaty/frontend/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/fpapi.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
 
  final Checkers checkers = Checkers();

  final ThemeData customDarkTheme = ThemeData(
    useMaterial3: true, // Ensure Material 3 is used
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue.shade600,       // Accent color
      onPrimary: Colors.blueAccent.shade400, // Contrasting color on primary
      secondary: Colors.grey.shade800,     // Medium gray for secondary elements
      onSecondary: Colors.black,           // Contrasting color on secondary
      surface: Colors.grey.shade800,       // Dark gray for cards and surfaces
      onSurface: Colors.grey.shade200,     // Light gray on surfaces
      error: Colors.red.shade400,          // Red for error states
      onError: Colors.black,               // Contrasting color on error
    ),
    scaffoldBackgroundColor: Colors.grey.shade900, // Background color for the main screen
    appBarTheme: AppBarTheme(
      backgroundColor: const Color.fromARGB(255, 40, 40, 40),          // Custom dark gray color for AppBar
      foregroundColor: Colors.grey.shade200,       // Text/icon color in AppBar
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromARGB(255, 40, 40, 40),          // Custom dark gray color for Drawer (sidebar)
    ),
    cardColor: Colors.grey.shade800,               // Color for card widgets
    dividerColor: Colors.grey.shade800,            // Color for dividers
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade700,     // Background color for elevated buttons
        foregroundColor: Colors.white,             // Text color on buttons
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const SplashScreen();
          },
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) {
            return LoginScreen();
          },
        ),
        GoRoute(
          path: '/2fa',
          builder: (BuildContext context, GoRouterState state) {
            return TwoFaScreen();
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            return RootLayout(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) async {
        final isAuthenticated = await checkers.isAuthenticated();
        final hasAccessTo2FA = await checkers.twoFAAuthenticated();
        final currentPath = state.uri.path;

        switch (currentPath) {
          case '/':
            if (!isAuthenticated) return '/login';
            if (isAuthenticated && !hasAccessTo2FA) return '/home';
            if (!isAuthenticated && hasAccessTo2FA) return '/2fa';
            break;

          case '/login':
            if (isAuthenticated) return '/home';
            if (hasAccessTo2FA) return '/2fa';
            return null;
            
          case '/2fa':
            if (hasAccessTo2FA) return null;
            if (isAuthenticated) return '/home';
            if (!isAuthenticated) return '/login';
            return null;
            
          case '/home':
            if (!isAuthenticated && !hasAccessTo2FA) return '/login';
            if (!isAuthenticated && hasAccessTo2FA) return '/2fa';
            if (isAuthenticated) return null;
            return null;
            
          default:
            if (isAuthenticated) return null;
            return '/';
        }
        return null;
      },
    );

    return MaterialApp.router(
      title: 'Floaty',
      theme: ThemeData.light(),
      darkTheme: customDarkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        context.go('/'); 
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0d47a1),
              Color(0xFF1976d2),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
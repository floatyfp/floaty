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
    useMaterial3: true, 
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue.shade600,
      onPrimary: Colors.blueAccent.shade400,
      secondary: Colors.grey.shade800,
      onSecondary: Colors.black,
      surface: Colors.grey.shade800,
      onSurface: Colors.grey.shade200,
      error: Colors.red.shade400,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.grey.shade900,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color.fromARGB(255, 40, 40, 40),
      foregroundColor: Colors.grey.shade200,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromARGB(255, 40, 40, 40),
    ),
    cardColor: Colors.grey.shade800,
    dividerColor: Colors.grey.shade800,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade700,
        foregroundColor: Colors.white,
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

    FPApiRequests().purgeOldEtags();
    
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
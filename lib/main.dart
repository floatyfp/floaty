import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:floaty/frontend/screens/login_screen.dart';
import 'package:floaty/backend/checkers.dart';
import 'package:floaty/frontend/screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
 
  final Checkers checkers = Checkers();

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
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return HomeScreen();
          },
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = checkers.isAuthenticated();
        final hasAccessTo2FA = checkers.twoFAAuthenticated();
        final currentPath = state.uri.path;

        // Handle authentication flow
        switch (currentPath) {
          case '/':
            // From splash screen, direct to appropriate screen based on auth state
            if (!isAuthenticated) return '/login';
            if (isAuthenticated && !hasAccessTo2FA) return '/2fa';
            if (isAuthenticated && hasAccessTo2FA) return '/home';
            break;

          case '/login':
            // If already authenticated, prevent accessing login
            if (isAuthenticated) return '/';
            return null; // Allow access to login
            
          case '/2fa':
            if (hasAccessTo2FA) return null;
            if (isAuthenticated) return '/home';
            if (!isAuthenticated) return '/login';
            return null;
            
          case '/home':
            // Protect home route
            if (!isAuthenticated && !hasAccessTo2FA) return '/login';
            if (!isAuthenticated && hasAccessTo2FA) return '/2fa';
            if (isAuthenticated) return null;
            return null;
            
          default:
            if (isAuthenticated) return null;
            return '/';
        }
        
        // If no specific redirect needed
        return null;
      },
    );

    return MaterialApp.router(
      title: 'Floaty',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
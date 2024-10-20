import 'package:flutter/material.dart';
import 'package:floaty/frontend/login_screen.dart'; // Import your LoginScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floatplane Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => SplashScreen(), // Redirect from splash screen
        '/login': (context) => LoginScreen(), // Route to the login page
        // Add other routes as needed
      },
      // Use a builder to handle any necessary platform-specific logic or settings
      builder: (context, child) {
        return child!;
      },
    );
  }
}

// Optional: You can create a splash screen to manage redirection
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simulate some loading time
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

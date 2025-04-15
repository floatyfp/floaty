import 'package:floaty/settings.dart';
import 'package:flutter/material.dart';
import 'package:floaty/backend/login_api.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cookie_jar/cookie_jar.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future login(String username, String password, BuildContext context) async {
    Map<String, dynamic> response;
    if (username.isNotEmpty || password.isNotEmpty) {
      response = await loginApi.login(username, password);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Center(
                child: Text('Please enter both Password and username.',
                    style: TextStyle(color: Colors.white))),
            backgroundColor: Colors.black.withValues(alpha: 0.4),
          ),
        );
      }
      return;
    }
    if (response['needs2FA'] == true) {
      if (context.mounted) {
        context.pushReplacement('/2fa');
      }
    }
    if (response.containsKey('message')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
                child: Text(response['message'],
                    style: const TextStyle(color: Colors.white))),
            backgroundColor: Colors.black.withValues(alpha: 0.4),
          ),
        );
      }
    }
    if (context.mounted) {
      context.pushReplacement('/home');
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Image(
                  image: AssetImage('assets/app_foreground.png'),
                  width: 60,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Welcome to Floaty',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (String value) {
                      login(value, _passwordController.text, context);
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (String value) {
                      login(_usernameController.text, value, context);
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () {
                      login(_usernameController.text, _passwordController.text,
                          context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1e88e5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TwoFaScreen extends StatelessWidget {
  TwoFaScreen({super.key});
  final TextEditingController twofaCodeController = TextEditingController();

  Future twofa(String code, BuildContext context) async {
    Map<String, dynamic> response;
    if (code.isNotEmpty) {
      response = await loginApi.twofa(code);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Center(
                child: Text('Please enter 2fa code.',
                    style: TextStyle(color: Colors.white))),
            backgroundColor: Colors.black.withValues(alpha: 0.4),
          ),
        );
      }
      return;
    }
    if (response.containsKey('message')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
                child: Text(response['message'],
                    style: const TextStyle(color: Colors.white))),
            backgroundColor: Colors.black.withValues(alpha: 0.4),
          ),
        );
      }
    }
    if (response['needs2FA'] == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Center(
                child: Text('An Unknown Error has occured. Please try again.',
                    style: TextStyle(color: Colors.white))),
            backgroundColor: Colors.black.withValues(alpha: 0.4),
          ),
        );
      }
    }

    if (context.mounted) {
      context.pushReplacement('/home');
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Image(
                  image: AssetImage('assets/app_foreground.png'),
                  width: 60,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Enter 2FA Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: twofaCodeController,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (String value) {
                      twofa(value, context);
                    },
                    decoration: InputDecoration(
                      labelText: 'Code',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () async {
                      twofa(twofaCodeController.text, context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1e88e5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

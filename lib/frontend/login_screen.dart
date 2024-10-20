import 'package:flutter/material.dart';
import 'package:floaty/backend/login_controller.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Floaty'),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async{
                var result = await LoginController.login(_usernameController.text, _passwordController.text);
                if (result == '2fa') {
                  Navigator.pushNamed(context, '/2fa');
                }
                if (result == 'Success') {
                  Navigator.pushNamed(context, '/home');
                }
                // Add your login logic here
                print('Username: ${_usernameController.text}');
                print('Password: ${_passwordController.text}');
              },
              child: Text('Login'),
            )
          ],
        ),
      ),
    );
  }
}

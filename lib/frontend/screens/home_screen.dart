import 'package:flutter/material.dart';
import '../sidebar.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Floatplane Home'),
      ),
      drawer: AppDrawer(), // Include the sidebar here
      body: Center(
        child: Text('Welcome to Floatplane!'),
      ),
    );
  }
}

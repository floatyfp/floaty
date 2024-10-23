import 'package:flutter/material.dart';
import '../sidebar.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Floatplane Home'),
      ),
      drawer: ResponsiveSidebar(), // Include the sidebar here
      body: Center(
        child: Text('Welcome to Floatplane!'),
      ),
    );
  }
}

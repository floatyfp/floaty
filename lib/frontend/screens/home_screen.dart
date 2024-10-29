import 'package:flutter/material.dart';
import 'package:floaty/backend/fpapi.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  late final FPApiRequests api = FPApiRequests();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        //child: Text('Welcome to Floatplane!'),
        child: TextButton(onPressed: () async {
        }, child: const Text('Welcome to Floatplane!'))
      ),
    );
  }
}

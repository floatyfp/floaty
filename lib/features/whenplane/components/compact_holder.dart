import 'package:floaty/features/whenplane/views/whenplane.dart';
import 'package:flutter/material.dart';

class WhenplaneCompactHolder extends StatelessWidget {
  const WhenplaneCompactHolder(this.onWPExit, {super.key});
  final VoidCallback onWPExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          toolbarHeight: 40,
          backgroundColor: theme.appBarTheme.backgroundColor,
          surfaceTintColor: theme.appBarTheme.backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              onWPExit();
            },
          ),
          title: Text("Whenplane Statistics", style: TextStyle(fontSize: 18))),
      body: WhenplaneScreen(),
    );
  }
}

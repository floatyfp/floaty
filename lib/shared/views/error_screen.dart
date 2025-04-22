import 'package:flutter/material.dart';

class ErrorScreen extends StatefulWidget {
  final String? message;
  const ErrorScreen({super.key, this.message});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool revealed = false;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Image(
            image: AssetImage('assets/error.png'),
            width: 200,
          ),
          const SizedBox(height: 16),
          const Text(
            'Well this is embarrassing.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const Text('An error has occurred.',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            if (!revealed)
              TextButton(
                  onPressed: () {
                    setState(() => revealed = true);
                  },
                  child: const Text('More Details')),
            if (revealed)
              Text(
                widget.message ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ]
        ],
      ),
    );
  }
}

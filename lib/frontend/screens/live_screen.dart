import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key, required this.channelName});
  final String channelName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Placeholder();
  }
}

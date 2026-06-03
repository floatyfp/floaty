import 'dart:io';

import 'package:floaty/features/logs/repositories/log_service.dart';
import 'package:floaty/features/logs/views/log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('floaty_logs_test');
    Hive.init(hiveDirectory.path);
    await LogService.init();
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('shows remote debug upload status and action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LogScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.textContaining('Remote debug logging is off'), findsOneWidget);
  });
}

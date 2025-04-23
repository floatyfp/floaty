import 'package:flutter/material.dart';
import 'package:floaty/features/logs/repositories/log_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  List<String> logs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => loading = true);
    logs = await LogService.getLogs();
    setState(() => loading = false);
  }

  Future<void> _clearLogs() async {
    await LogService.clearLogs();
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: logs.isEmpty ? null : _clearLogs,
            tooltip: 'Clear Logs',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : logs.isEmpty
              ? const Center(child: Text('No logs found.'))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, i) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: SelectableText(logs[i],
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
    );
  }
}

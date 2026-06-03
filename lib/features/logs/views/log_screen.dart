import 'package:flutter/material.dart';
import 'package:floaty/features/logs/repositories/log_service.dart';

enum LogType { app, download }

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  List<String> logs = [];
  bool loading = true;
  bool uploading = false;
  LogType selectedLogType = LogType.app;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => loading = true);
    if (selectedLogType == LogType.app) {
      logs = await LogService.getLogs();
    } else {
      logs = await LogService.getDownloadLogs();
    }
    setState(() => loading = false);
  }

  Future<void> _clearLogs() async {
    if (selectedLogType == LogType.app) {
      await LogService.clearLogs();
    } else {
      await LogService.clearDownloadLogs();
    }
    await _loadLogs();
  }

  Future<void> _uploadLogs() async {
    setState(() => uploading = true);
    final result = await LogService.uploadLogSnapshot(
      source: selectedLogType.name,
      logs: logs,
    );
    if (!mounted) return;
    setState(() => uploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  void _switchLogType(LogType? type) {
    if (type != null && type != selectedLogType) {
      setState(() {
        selectedLogType = type;
      });
      _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Logs'),
        actions: [
          IconButton(
            icon: uploading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            onPressed: uploading ? null : _uploadLogs,
            tooltip: 'Upload selected logs',
          ),
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
      body: Column(
        children: [
          // Log type switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<LogType>(
              segments: const [
                ButtonSegment<LogType>(
                  value: LogType.app,
                  label: Text('App Logs'),
                  icon: Icon(Icons.bug_report),
                ),
                ButtonSegment<LogType>(
                  value: LogType.download,
                  label: Text('Download Logs'),
                  icon: Icon(Icons.download),
                ),
              ],
              selected: {selectedLogType},
              onSelectionChanged: (Set<LogType> selection) {
                _switchLogType(selection.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(
                  LogService.remoteLoggingConfigured
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LogService.remoteLoggingConfigured
                        ? 'Remote debug logging is configured. Use the upload button to send these logs.'
                        : 'Remote debug logging is off. Set FLOATY_REMOTE_LOG_ENDPOINT to send logs externally.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          // Logs display
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                    ? Center(
                        child: Text(
                          'No ${selectedLogType == LogType.app ? 'app' : 'download'} logs found.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: SelectableText(
                            logs[i],
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

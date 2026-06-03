# Remote debug logging

Floaty can mirror app logs and uncaught Flutter/Dart errors to an external HTTP
endpoint for debugging white-screen or startup issues.

Remote logging is off by default. Enable it at build or run time with Dart
defines:

```sh
flutter run -d linux \
  --dart-define=FLOATY_REMOTE_LOG_ENDPOINT=https://example.com/floaty-logs
```

If the endpoint requires bearer auth, also pass:

```sh
--dart-define=FLOATY_REMOTE_LOG_TOKEN=your-token
```

The app sends JSON payloads with a session id, timestamp, platform, level, and
message. The developer logs screen can also upload the currently selected app or
download log view on demand.

Before logs are saved or sent, common authorization, token, and cookie patterns
are redacted.

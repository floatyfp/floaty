import 'package:floaty/features/logs/repositories/log_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogService.isRemoteLogEndpointAllowed', () {
    test('allows https endpoints', () {
      expect(
        LogService.isRemoteLogEndpointAllowed(
          Uri.parse('https://logs.example.com/floaty'),
        ),
        isTrue,
      );
    });

    test('allows http loopback endpoints for local debugging', () {
      expect(
        LogService.isRemoteLogEndpointAllowed(
          Uri.parse('http://localhost:8080/logs'),
        ),
        isTrue,
      );
      expect(
        LogService.isRemoteLogEndpointAllowed(
          Uri.parse('http://127.0.0.1:8080/logs'),
        ),
        isTrue,
      );
    });

    test('rejects insecure non-loopback endpoints', () {
      expect(
        LogService.isRemoteLogEndpointAllowed(
          Uri.parse('http://logs.example.com/floaty'),
        ),
        isFalse,
      );
    });
  });

  group('LogService.redactSensitiveLogData', () {
    test('redacts common auth tokens and cookies', () {
      const input =
          'Authorization: Bearer abc123 token=secret accessToken=abc sails.sid=session-cookie';

      final redacted = LogService.redactSensitiveLogData(input);

      expect(redacted, isNot(contains('abc123')));
      expect(redacted, isNot(contains('secret')));
      expect(redacted, isNot(contains('session-cookie')));
      expect(redacted, contains('Authorization: [REDACTED]'));
      expect(redacted, contains('token= [REDACTED]'));
      expect(redacted, contains('sails.sid= [REDACTED]'));
    });
  });
}

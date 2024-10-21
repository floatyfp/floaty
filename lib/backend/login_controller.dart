import 'package:floaty/backend/api.dart';

class LoginController {
  late final api = FPApi();
  Future<String> login(String username, String password) async {
    final response = await api.login(username, password);
    if (response['needs2FA'] == true) {
      return '2fa';
    }
    return 'Success';
  }
  Future<String> twofa(String code) async {
    final response = await api.twofa(code);
    if (response['needs2FA'] == true) {
      return 'invalid';
    }
    return 'Success';
  }
}
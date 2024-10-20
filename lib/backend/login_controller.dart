import 'package:Floaty/backend/api.dart';

class LoginController {
  late final Api = fpApi();
  Future<String> login(String username, String password) async {
    final response = await Api.login(username, password);
    print('Responselc: $response');
    if (response['needs2FA'] == true) {
      return '2fa';
    }
    return 'Success';
  }
  Future<String> twofa(String code) async {
    final response = await Api.twofa(code);
    print('Responsetwofa: $response');
    if (response['needs2FA'] == true) {
      return 'invalid';
    }
    return 'Success';
  }
}
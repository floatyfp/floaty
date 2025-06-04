import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:floaty/features/router/controllers/router.dart';

final UpdaterController updatercontroller = GetIt.I<UpdaterController>();

class UpdaterController {
  Dio dio = Dio();
  late String flavor;

  @override
  UpdaterController() {
    const flavorenv =
        String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
    if (flavorenv == 'dev') {
      flavor = 'nightly';
    } else {
      flavor = flavorenv;
    }
  }

  Future<bool> updateAvailable() async {
    final response =
        await dio.get('https://floaty.fyi/api/latest-update?flavor=$flavor');
    final packageInfo = await PackageInfo.fromPlatform();
    if (response.data['deployment']['version'] ==
        '${packageInfo.version}+${packageInfo.buildNumber}') {
      return true;
    }
    return false;
  }

  Future<void> initialCheck() async {
    final response =
        await dio.get('https://floaty.fyi/api/latest-update?flavor=$flavor');
    final packageInfo = await PackageInfo.fromPlatform();
    if (response.data['deployment']['version'] !=
        '${packageInfo.version}+${packageInfo.buildNumber}') {
      return;
    }
    if (response.data['deployment']['required'] == 0) {
      routerController.go('/update');
      return;
    }
    return;
  }

  Future<dynamic> getUpdate() async {
    final response =
        await dio.get('https://floaty.fyi/api/latest-update?flavor=$flavor');
    return response.data;
  }
}

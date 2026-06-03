import 'package:floaty/features/helpers/respositories/capitalize.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/whitelabels.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get_it/get_it.dart';

import 'platform_check_stub.dart' if (dart.library.io) 'platform_check_io.dart'
    as platform_check;

final discordRPCController = GetIt.I<DiscordRPCController>();
bool get isDiscordRPCSupported => platform_check.isDiscordRPCSupported;

class DiscordRPCController {
  bool initialized = false;

  DiscordRPCController() {
    init();
    FlutterDiscordRPC.instance.isConnectedStream.listen((isConnected) {
      if (!isConnected) {
        FlutterDiscordRPC.instance.reconnect();
      }
    });
  }

  void init() {
    FlutterDiscordRPC.initialize('1383892249133318144');
    FlutterDiscordRPC.instance.connect(autoRetry: true);
    FlutterDiscordRPC.instance.isConnectedStream.listen((isConnected) {
      if (isConnected) {
        initialized = true;
      }
    });
  }

  Future<void> updateRPC(String whitelabel, String title, String author,
      String authorImage, String thumbnailUrl, String postId,
      {RPCTimestamps? timestamps}) async {
    final discordRPC =
        await settings.getBool('discord_rpc', defaultValue: true);
    if (!discordRPC) {
      clearRPC();
      return;
    }
    final whiteLabel = whitelabels.getWhitelabel(whitelabel);
    const flavor =
        String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
    final packageInfo = await PackageInfo.fromPlatform();
    while (!FlutterDiscordRPC.instance.isConnected) {
      await Future.delayed(const Duration(seconds: 1));
    }
    FlutterDiscordRPC.instance.setActivity(
        activity: RPCActivity(
            state: author,
            details: title,
            timestamps: timestamps,
            assets: RPCAssets(
                largeImage: thumbnailUrl,
                largeText: author,
                smallImage: authorImage,
                smallText:
                    'Floaty ${capitalize(flavor)} ${packageInfo.version} (${packageInfo.buildNumber})'),
            buttons: [
              RPCButton(
                  label: 'Watch on ${whiteLabel.name}',
                  url: 'https://${whiteLabel.domain}/post/$postId'),
              RPCButton(
                  label: 'Download Floaty', url: 'https://floaty.fyi/download'),
            ],
            activityType: ActivityType.watching));
  }

  void clearRPC() {
    FlutterDiscordRPC.instance.clearActivity();
  }

  void disconnect() {
    FlutterDiscordRPC.instance.disconnect();
  }

  void dispose() {
    FlutterDiscordRPC.instance.dispose();
    initialized = false;
  }
}

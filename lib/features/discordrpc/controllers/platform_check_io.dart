import 'dart:io' show Platform;

bool get isDiscordRPCSupported => Platform.isWindows || Platform.isLinux;

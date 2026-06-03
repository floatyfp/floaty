import 'dart:io' as io;

bool get isAndroid => io.Platform.isAndroid;
bool get isIOS => io.Platform.isIOS;
bool get isWindows => io.Platform.isWindows;
bool get isLinux => io.Platform.isLinux;
bool get isMacOS => io.Platform.isMacOS;
bool get isDesktop => isWindows || isLinux || isMacOS;

void exitApp(int code) => io.exit(code);

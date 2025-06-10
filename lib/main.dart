import 'package:floaty/features/authentication/repositories/login_api.dart';
import 'package:floaty/features/updater/respositories/updater_controllers.dart';
import 'package:floaty/features/whenplane/repositories/whenplaneintergration.dart';
import 'package:floaty/features/router/controllers/router.dart';
import 'package:floaty/features/deeplinks/controllers/deeplinks.dart';
import 'package:flutter/material.dart';
// import 'package:floaty/features/logs/repositories/log_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:floaty/features/api/repositories/fpwebsockets.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/shared/services/system/single_instance_service.dart';
import 'package:floaty/shared/services/system/tray_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform, exit;
import 'package:media_kit/media_kit.dart';
import 'package:get_it/get_it.dart';
import 'package:floaty/features/api/repositories/download_manager.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:floaty/features/notifications/controllers/firebase.dart';
// import 'package:floaty/features/notifications/controllers/notification.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

GetIt getIt = GetIt.instance;
late final Color? flavorPrimary;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('settings');
  const flavor =
      String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');

  // Initialize MediaKit
  MediaKit.ensureInitialized();

  // Initialize download manager
  await DownloadManager().initialize();

  // Initialize deep link service
  final deepLinkService = DeepLinkService();
  deepLinkService.setRouter(routerController);
  deepLinkService.initDeepLinks();

  final packageInfo = await PackageInfo.fromPlatform();
  final userAgent =
      'Floaty/${packageInfo.version} (${packageInfo.buildNumber})';

  getIt.registerSingleton<FPWebsockets>(
    FPWebsockets(
        token: (await Settings().getAuthTokenFromCookieJar()) ?? '',
        userAgent: userAgent),
  );

  getIt.registerSingleton<FPApiRequests>(
    FPApiRequests(),
  );

  getIt.registerSingleton<WhenPlaneIntegration>(
    WhenPlaneIntegration(),
  );

  getIt.registerSingleton<LoginApi>(
    LoginApi(),
  );

  getIt.registerSingleton<Settings>(
    Settings(),
  );

  getIt.registerSingleton<UpdaterController>(
    UpdaterController(),
  );

  // if (Platform.isAndroid) {
  //   //init notifications
  //   await LogService.init();
  //   await Firebase.initializeApp(
  //     name: 'floaty',
  //     options: firebaseOptions,
  //   );
  //   await initializeNotifications();
  //   await setupFirebaseMessaging();
  //   final fcmToken = await FirebaseMessaging.instance.getToken();
  //   await Settings().setKey('fcmToken', fcmToken ?? '');
  //   // await fpApiRequests.registerNotifications(fcmToken ?? '');
  //   final messaging = FirebaseMessaging.instance;
  //   final settings = await messaging.requestPermission(
  //     alert: true,
  //     announcement: false,
  //     badge: true,
  //     carPlay: false,
  //     criticalAlert: false,
  //     provisional: false,
  //     sound: true,
  //   );

  //   registerBackgroundHandler();
  //   LogService.logInfo(
  //       'Notification permissions: ${settings.authorizationStatus}');

  //   try {
  //     final fcmToken = await FirebaseMessaging.instance.getToken();
  //     LogService.logInfo('Firebase initialized! FCM Token: $fcmToken');
  //   } catch (e) {
  //     LogService.logError('Firebase initialization failed: $e');
  //   }
  // }

  switch (flavor) {
    case 'release':
      flavorPrimary = Colors.blue.shade600;
      break;
    case 'beta':
      flavorPrimary = Color.fromRGBO(255, 165, 0, 1);
      break;
    case 'nightly':
      flavorPrimary = Color.fromRGBO(106, 13, 173, 1);
      break;
    case 'dev':
      flavorPrimary = Color.fromRGBO(200, 35, 35, 1);
      break;
    default:
      flavorPrimary = Colors.blue.shade600;
      break;
  }

  if (!Platform.isAndroid && !Platform.isIOS) {
    // // Initialize single instance service
    final singleInstanceService = await SingleInstanceService.getInstance();
    await singleInstanceService.initialize();

    // // Only continue if this is the first instance
    // // Note: For Windows, this is handled in initialize()
    if (!Platform.isWindows) {
      final isFirstInstance = await singleInstanceService.isFirstInstance();
      if (!isFirstInstance) {
        exit(0);
      }
    }

    // Initialize tray service
    final trayService = await TrayService.getInstance();
    await trayService.initialize();

    // Initialize window manager
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      skipTaskbar: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);

    switch (flavor) {
      case 'release':
        if (Platform.isWindows) {
          await windowManager.setIcon('assets/icon/app_icon_win.ico');
        } else {
          await windowManager.setIcon('assets/app_icon.png');
        }
        await windowManager.setTitle('Floaty');
        break;
      case 'beta':
        if (Platform.isWindows) {
          await windowManager.setIcon('assets/icon/beta_icon_win.ico');
        } else {
          await windowManager.setIcon('assets/beta_icon.png');
        }
        await windowManager.setTitle('Floaty Beta');
        break;
      case 'nightly':
        if (Platform.isWindows) {
          await windowManager.setIcon('assets/icon/nightly_icon_win.ico');
        } else {
          await windowManager.setIcon('assets/nightly_icon.png');
        }
        await windowManager.setTitle('Floaty Nightly');
        break;
      case 'dev':
        if (Platform.isWindows) {
          await windowManager.setIcon('assets/icon/dev_icon_win.ico');
        } else {
          await windowManager.setIcon('assets/dev_icon.png');
        }
        await windowManager.setTitle('Floaty Development');
        break;
      default:
        if (Platform.isWindows) {
          await windowManager.setIcon('assets/icon/app_icon_win.ico');
        } else {
          await windowManager.setIcon('assets/app_icon.png');
        }
        await windowManager.setTitle('Floaty');
        break;
    }
  }
  runApp(ProviderScope(
    child: DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MyApp(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
        );
      },
    ),
  ));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, this.lightDynamic, this.darkDynamic}) {
    // Set up window manager event handlers
    windowManager.addListener(_AppWindowListener());
  }
  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final box = Hive.box('settings');

        return ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (_, Box settingsBox, __) {
            final themeType =
                settingsBox.get('theme_type', defaultValue: 1) as int;
            final src =
                settingsBox.get('material_source', defaultValue: 0) as int;
            final seed = settingsBox.get('material_seed_color',
                defaultValue: flavorPrimary?.toARGB32() ?? 0 as int?);

            late ThemeMode themeMode;
            late ThemeData lightTheme;
            late ThemeData darkTheme;
            switch (themeType) {
              case 0:
                themeMode = ThemeMode.light;
                final primaryColor = flavorPrimary ?? Colors.blue.shade600;
                lightTheme = ThemeData(
                  //which flutter dev ever caused this bug you need to fucking stand up and fix it im fed up of flutters stupid shit.
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  useMaterial3: true,
                  colorScheme: ColorScheme.light(
                    primary: primaryColor,
                    primaryContainer: primaryColor.withValues(alpha: 0.2),
                    secondary: Colors.blueGrey,
                    secondaryContainer: Colors.blueGrey.shade100,
                    surface: Colors.white,
                    error: Colors.red.shade700,
                    onPrimary: Colors.white,
                    onSecondary: Colors.white,
                    onSurface: Colors.grey.shade900,
                    onError: Colors.white,
                    brightness: Brightness.light,
                  ),
                  scaffoldBackgroundColor: Colors.grey.shade50,
                  appBarTheme: AppBarTheme(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  cardTheme: CardThemeData(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  dividerTheme: DividerThemeData(
                    color: Colors.grey.shade300,
                    thickness: 1,
                    space: 1,
                  ),
                );

                darkTheme = ThemeData(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  useMaterial3: true,
                  colorScheme: ColorScheme.dark(
                    primary: primaryColor,
                    primaryContainer: primaryColor.withValues(alpha: 0.2),
                    secondary: Colors.blueGrey.shade300,
                    secondaryContainer: Colors.blueGrey.shade800,
                    surface: const Color(0xFF1E1E1E),
                    error: Colors.red.shade400,
                    onPrimary: Colors.black,
                    onSecondary: Colors.black,
                    onSurface: Colors.white,
                    onError: Colors.black,
                    brightness: Brightness.dark,
                  ),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  appBarTheme: AppBarTheme(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  cardTheme: CardThemeData(
                    color: const Color(0xFF1E1E1E),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  dividerTheme: DividerThemeData(
                    color: Colors.grey.shade800,
                    thickness: 1,
                    space: 1,
                  ),
                );
                break;
              case 1:
                themeMode = ThemeMode.dark;
                final primaryColor = flavorPrimary ?? Colors.blue.shade600;
                lightTheme = ThemeData(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  useMaterial3: true,
                  colorScheme: ColorScheme.light(
                    primary: primaryColor,
                    primaryContainer: primaryColor.withValues(alpha: 0.2),
                    secondary: Colors.blueGrey,
                    secondaryContainer: Colors.blueGrey.shade100,
                    surface: Colors.white,
                    error: Colors.red.shade700,
                    onPrimary: Colors.white,
                    onSecondary: Colors.white,
                    onSurface: Colors.grey.shade900,
                    onError: Colors.white,
                    brightness: Brightness.light,
                  ),
                  scaffoldBackgroundColor: Colors.grey.shade50,
                  appBarTheme: AppBarTheme(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  cardTheme: CardThemeData(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  dividerTheme: DividerThemeData(
                    color: Colors.grey.shade300,
                    thickness: 1,
                    space: 1,
                  ),
                );

                darkTheme = ThemeData(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  useMaterial3: true,
                  colorScheme: ColorScheme.dark(
                    primary: primaryColor,
                    primaryContainer: primaryColor.withValues(alpha: 0.2),
                    secondary: Colors.blueGrey.shade300,
                    secondaryContainer: Colors.blueGrey.shade800,
                    surface: const Color(0xFF1E1E1E),
                    error: Colors.red.shade400,
                    onPrimary: Colors.black,
                    onSecondary: Colors.black,
                    onSurface: Colors.white,
                    onError: Colors.black,
                    brightness: Brightness.dark,
                  ),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  cardTheme: CardThemeData(
                    color: const Color(0xFF1E1E1E),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  dividerTheme: DividerThemeData(
                    color: Colors.grey.shade800,
                    thickness: 1,
                    space: 1,
                  ),
                  dialogTheme: const DialogThemeData(
                    backgroundColor: Color(0xFF1E1E1E),
                  ),
                  bottomSheetTheme: const BottomSheetThemeData(
                    backgroundColor: Color(0xFF1E1E1E),
                  ),
                );
                break;
              default:
                final dynamicMode = settingsBox.get('material_dynamic_mode',
                    defaultValue: 0) as int;
                if (dynamicMode == 1) {
                  themeMode = ThemeMode.light;
                } else if (dynamicMode == 2) {
                  themeMode = ThemeMode.dark;
                } else {
                  themeMode = ThemeMode.system;
                }
                if (src == 0 && lightDynamic != null && darkDynamic != null) {
                  lightTheme = ThemeData(
                      colorScheme: lightDynamic,
                      useMaterial3: true,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap);
                  darkTheme = ThemeData(
                      colorScheme: darkDynamic,
                      useMaterial3: true,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap);
                } else {
                  lightTheme = ThemeData(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      colorScheme: ColorScheme.fromSeed(
                          seedColor: Color(seed),
                          brightness: Brightness.light));
                  darkTheme = ThemeData(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      colorScheme: ColorScheme.fromSeed(
                          seedColor: Color(seed), brightness: Brightness.dark));
                }
            }

            //TODO: later
            // updatercontroller.initialCheck();

            return MaterialApp.router(
              // Force rebuild when theme settings change
              key: ValueKey('$themeType-$src-$seed'),
              routerConfig: routerController,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeMode,
              title: 'Floaty',
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        context.go('/');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0d47a1),
              Color(0xFF1976d2),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _AppWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }
}

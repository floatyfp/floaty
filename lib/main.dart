import 'dart:async';

import 'package:floaty/features/deeplinks/controllers/deeplinks.dart';
import 'package:floaty/features/discordrpc/controllers/discord_rpc_controller.dart';
import 'package:floaty/features/download/controllers/fp_download_service.dart';
import 'package:floaty/features/updater/respositories/updater_controllers.dart';
import 'package:floaty/features/whenplane/repositories/whenplaneintergration.dart';
import 'package:floaty/app/flavor_theme.dart';
import 'package:floaty/features/router/controllers/router.dart';
import 'package:floaty/whitelabels.dart';
import 'package:flutter/material.dart';
import 'package:floaty/features/logs/repositories/log_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:floaty/features/api/repositories/fpwebsockets.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/shared/services/system/single_instance_service.dart';
import 'package:floaty/shared/services/system/tray_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:media_kit/media_kit.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:floaty/features/deeplinks/controllers/protocol_handler.dart';
import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:floaty/shared/utils/platform_info_stub.dart'
    if (dart.library.io) 'package:floaty/shared/utils/platform_info_io.dart'
    as platform_info;
import 'package:floaty/shared/utils/safe_connectivity.dart';
// import 'package:floaty/features/notifications/controllers/firebase.dart';
// import 'package:floaty/features/notifications/controllers/notification.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

GetIt getIt = GetIt.instance;

void main() {
  runZonedGuarded(() async {
    await _main();
  }, (error, stackTrace) {
    LogService.logUncaughtError(error, stackTrace, source: 'zone');
  });
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL;

  final dir = await getApplicationSupportDirectory();
  await Hive.initFlutter(dir.path);

  // Initialize LogService to capture logs
  await LogService.init();
  _installGlobalErrorHandlers();

  // Configure logging to print to console and save to LogService
  Logger.root.onRecord.listen((record) {
    final logMessage =
        '[${record.level.name}] ${record.loggerName}: ${record.message}${record.error != null ? '\n${record.error}' : ''}${record.stackTrace != null ? '\n${record.stackTrace}' : ''}';
    // ignore: avoid_print
    print(logMessage);

    // Save to LogService for viewing in app
    LogService.addLog(logMessage, level: record.level.name);
  });
  await Hive.openBox('settings');
  // Register Settings early so services/listeners started above can access it
  getIt.registerSingleton<Settings>(
    Settings(),
  );

  getIt.registerSingleton<UpdaterController>(
    UpdaterController(),
  );

  const flavor =
      String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');

  // Initialize MediaKit
  MediaKit.ensureInitialized();

  // Monitor connectivity and sync offline progress when online
  if (!kIsWeb && !connectivityLikelyUnavailableOnLinux) {
    listenForConnectivity((_) async {
      try {
        final whitelabel = await Whitelabels().getSelectedWhitelabel();
        await fpApiRequests.syncOfflineProgress(whitelabel.friendlyName);
      } catch (e) {
        debugPrint(
            'Failed to sync offline progress on connectivity change: $e');
      }
    });
  }

  // Initialize deep link service
  final deepLinkService = DeepLinkService();
  deepLinkService.setRouter(routerController);
  deepLinkService.initDeepLinks();

  // Handle initial deep link if app was launched with one
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!kIsWeb) {
      try {
        final appLinks = AppLinks();
        // Get the initial link if the app was launched from a link
        final initialUri = await appLinks.getInitialLink();
        if (initialUri != null) {
          // The DeepLinkService will handle the initial link through uriLinkStream
          debugPrint('App launched with initial link: $initialUri');
        }
      } catch (e) {
        debugPrint('Error handling initial deep link: $e');
      }
    }
  });

  final packageInfo = await PackageInfo.fromPlatform();
  final userAgent =
      'Floaty/${packageInfo.version} (${packageInfo.buildNumber})';

  getIt.registerSingleton<Whitelabels>(
    Whitelabels(),
  );

  final whitelabel = await Whitelabels().getSelectedWhitelabel();

  getIt.registerSingleton<FPWebsockets>(
    FPWebsockets(userAgent: userAgent, whitelabel: whitelabel),
  );

  getIt.registerSingleton<FPApiRequests>(
    FPApiRequests(),
  );

  getIt.registerSingleton<WhenPlaneIntegration>(
    WhenPlaneIntegration(),
  );

  if (isDiscordRPCSupported) {
    getIt.registerSingleton<DiscordRPCController>(
      DiscordRPCController(),
    );
  }

  // if (platform_info.isAndroid) {
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

  if (!platform_info.isAndroid && !platform_info.isIOS) {
    // Initialize single instance service
    final singleInstanceService = await SingleInstanceService.getInstance();
    await singleInstanceService.initialize();

    // Only continue if this is the first instance
    // Note: For Windows, this is handled in initialize()
    if (!platform_info.isWindows) {
      final isFirstInstance = await singleInstanceService.isFirstInstance();
      if (!isFirstInstance) {
        platform_info.exitApp(0);
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
        if (platform_info.isWindows) {
          await windowManager.setIcon('assets/icon/app_icon_win.ico');
        } else {
          //await windowManager.setIcon('assets/app_icon.png');
        }
        await windowManager.setTitle('Floaty');
        break;
      case 'beta':
        if (platform_info.isWindows) {
          await windowManager.setIcon('assets/icon/beta_icon_win.ico');
        } else {
          await windowManager.setIcon('assets/beta_icon.png');
        }
        await windowManager.setTitle('Floaty Beta');
        break;
      case 'nightly':
        if (platform_info.isWindows) {
          await windowManager.setIcon('assets/icon/nightly_icon_win.ico');
        } else {
          await windowManager.setIcon('assets/nightly_icon.png');
        }
        await windowManager.setTitle('Floaty Nightly');
        break;
      case 'dev':
        if (platform_info.isWindows) {
          await windowManager.setIcon('assets/icon/dev_icon_win.ico');
        } else {
          await windowManager.setIcon('assets/dev_icon.png');
        }
        await windowManager.setTitle('Floaty Development');
        break;
      default:
        if (platform_info.isWindows) {
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

  _schedulePostFrameStartup();
}

void _installGlobalErrorHandlers() {
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    LogService.logFlutterError(details);
    if (previousFlutterErrorHandler != null) {
      previousFlutterErrorHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    LogService.logUncaughtError(error, stackTrace, source: 'platform');
    return previousPlatformErrorHandler?.call(error, stackTrace) ?? true;
  };
}

class MyApp extends StatelessWidget {
  MyApp({super.key, this.lightDynamic, this.darkDynamic}) {
    // Set up window manager event handlers
    if (!platform_info.isAndroid && !platform_info.isIOS) {
      windowManager.addListener(_AppWindowListener());
    }
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

            updatercontroller.initialCheck();

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

class _AppWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }
}

void _schedulePostFrameStartup() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!kIsWeb) {
      _runStartupTask(
        'protocol handler registration',
        ProtocolHandler.register,
      );
    }

    _runStartupTask(
      'download service initialization',
      _initFPDownloadService,
    );

    _runStartupTask(
      'offline progress sync',
      _syncOfflineProgressOnStartup,
    );
  });
}

void _runStartupTask(String name, Future<void> Function() task) {
  unawaited(() async {
    try {
      await task();
    } catch (error, stackTrace) {
      debugPrint('Startup task failed ($name): $error');
      LogService.logError('Startup task failed ($name): $error\n$stackTrace');
    }
  }());
}

Future<void> _syncOfflineProgressOnStartup() async {
  try {
    final whitelabel = await Whitelabels().getSelectedWhitelabel();
    await fpApiRequests
        .syncOfflineProgress(whitelabel.friendlyName)
        .timeout(const Duration(seconds: 15));
  } on TimeoutException catch (e, stackTrace) {
    debugPrint('Timed out syncing offline progress on startup');
    LogService.logError(
        'Timed out syncing offline progress on startup: $e\n$stackTrace');
  } catch (e, stackTrace) {
    debugPrint('Failed to sync offline progress on startup: $e');
    LogService.logError(
        'Failed to sync offline progress on startup: $e\n$stackTrace');
  }
}

/// Initialize the Floatplane download service
Future<void> _initFPDownloadService() async {
  // Initialize FFI database for desktop platforms
  if (platform_info.isDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Open/create the database for FP downloads
  final dbPath = p.join(await getDatabasesPath(), 'fp_downloads.db');
  final db = await openDatabase(
    dbPath,
    version: 1,
    onCreate: (Database db, int version) async {
      // Tables will be created by fpDownloadService.init()
    },
  );

  // Initialize the FP download service
  await fpDownloadService.init(db);
}

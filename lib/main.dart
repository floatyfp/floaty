import 'package:floaty/backend/login_api.dart';
import 'package:floaty/backend/whenplaneintergration.dart';
import 'package:floaty/frontend/screens/live_chat.dart';
import 'package:floaty/frontend/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/checkers.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/backend/fpwebsockets.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/frontend/screens/login_screen.dart';
import 'package:floaty/frontend/screens/home_screen.dart';
import 'package:floaty/frontend/screens/settings_screen.dart';
import 'package:floaty/frontend/screens/browse_screen.dart';
import 'package:floaty/frontend/screens/history_screen.dart';
import 'package:floaty/frontend/screens/channel_screen.dart';
import 'package:floaty/frontend/screens/post_screen.dart';
import 'package:floaty/frontend/screens/live_screen.dart';
import 'package:floaty/frontend/root.dart';
import 'package:floaty/services/system/single_instance_service.dart';
import 'package:floaty/services/system/tray_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform, exit;
import 'package:media_kit/media_kit.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:floaty/frontend/widgets/pip_player_widget.dart';
import 'package:floaty/backend/download_manager.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';

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

  getIt.registerSingleton<FPWebsockets>(
    FPWebsockets(token: (await Settings().getAuthTokenFromCookieJar()) ?? ''),
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

  final Checkers checkers = Checkers();

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final box = Hive.box('settings');
        final GoRouter router = GoRouter(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) {
                return const SplashScreen();
              },
            ),
            GoRoute(
              path: '/login',
              builder: (BuildContext context, GoRouterState state) {
                return LoginScreen();
              },
            ),
            GoRoute(
              path: '/2fa',
              builder: (BuildContext context, GoRouterState state) {
                return TwoFaScreen();
              },
            ),
            GoRoute(
              path: '/pip',
              pageBuilder: (BuildContext context, GoRouterState state) {
                final Map<String, dynamic> args =
                    state.extra as Map<String, dynamic>;
                final videoController = args['controller'] as VideoController;
                final postId = args['postId'] as String;
                final live = args['live'] as bool;
                return MaterialPage(
                  fullscreenDialog: true,
                  child: PipPlayerWidget(
                    videoController: videoController,
                    postId: postId,
                    live: live,
                  ),
                );
              },
            ),
            ShellRoute(
              builder: (context, state, child) {
                return FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: RootLayout(key: rootLayoutKey, child: child),
                );
              },
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
                GoRoute(
                  path: '/browse',
                  builder: (context, state) => const BrowseScreen(),
                ),
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const HistoryScreen(),
                ),
                GoRoute(
                  path: '/channel/:ChannelName/:SubName',
                  builder: (context, state) {
                    final channelName =
                        state.pathParameters['ChannelName'] ?? 'defaultChannel';
                    final subName = state.pathParameters['SubName'];
                    return ChannelScreen(
                      channelName: channelName,
                      subName: subName,
                    );
                  },
                ),
                GoRoute(
                  path: '/liveold/:ChannelName',
                  builder: (context, state) {
                    final channelName =
                        state.pathParameters['ChannelName'] ?? 'defaultChannel';
                    return LiveChat(
                      liveId: channelName,
                    );
                  },
                ),
                GoRoute(
                  path: '/live/:ChannelName',
                  builder: (context, state) {
                    final channelName =
                        state.pathParameters['ChannelName'] ?? 'defaultChannel';
                    return LiveScreen(
                      channelName: channelName,
                    );
                  },
                ),
                GoRoute(
                  path: '/post/:postid',
                  builder: (context, state) {
                    final postid = state.pathParameters['postid'] ?? '';
                    return VideoDetailPage(
                      postId: postid,
                    );
                  },
                ),
                // thanks goRouter i hate it
                GoRoute(
                  path: '/channel/:ChannelName/:SubName?',
                  builder: (context, state) {
                    final channelName =
                        state.pathParameters['ChannelName'] ?? 'defaultChannel';
                    final subName = state.pathParameters['SubName'];
                    return ChannelScreen(
                      channelName: channelName,
                      subName: subName,
                    );
                  },
                ),
                GoRoute(
                  path: '/channel/:ChannelName',
                  builder: (context, state) {
                    final channelName =
                        state.pathParameters['ChannelName'] ?? 'defaultChannel';
                    return ChannelScreen(
                      channelName: channelName,
                    );
                  },
                ),
                GoRoute(
                  path: '/profile/:UserName',
                  builder: (context, state) {
                    final userName =
                        state.pathParameters['UserName'] ?? 'defaultChannel';
                    return ProfileScreen(
                      userName: userName,
                    );
                  },
                ),
                ShellRoute(
                  builder: (context, state, child) {
                    final isWideScreen =
                        MediaQuery.of(context).size.width >= 600;
                    final settingsContent =
                        isWideScreen ? SettingsScreen(child: child) : child;
                    return FocusTraversalGroup(
                      policy: ReadingOrderTraversalPolicy(),
                      child: settingsContent,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: '/settings',
                      builder: (context, state) {
                        final isWideScreen =
                            MediaQuery.of(context).size.width >= 600;
                        if (isWideScreen) {
                          // Redirect to default category
                          return AccountSettingsScreen();
                        } else {
                          return const SettingsListScreen(); // List of categories
                        }
                      },
                      routes: [
                        GoRoute(
                          path: 'account',
                          builder: (context, state) => AccountSettingsScreen(),
                        ),
                        GoRoute(
                          path: 'invoices',
                          builder: (context, state) =>
                              const InvoicesSettingsScreen(),
                        ),
                        GoRoute(
                          path: 'licenses',
                          builder: (context, state) =>
                              const LicensesSettingsScreen(),
                        ),
                        GoRoute(
                          path: 'about',
                          builder: (context, state) => AboutSettingsScreen(),
                        ),
                        GoRoute(
                          path: 'appearance',
                          builder: (context, state) =>
                              AppearanceSettingsScreen(),
                        ),
                        GoRoute(
                          path: 'player',
                          builder: (context, state) => PlayerSettingsScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
          redirect: (BuildContext context, GoRouterState state) async {
            final isAuthenticated = await checkers.isAuthenticated();
            final hasAccessTo2FA = await checkers.twoFAAuthenticated();
            final currentPath = state.uri.path;

            switch (currentPath) {
              case '/':
                if (hasAccessTo2FA) return '/2fa';
                if (!isAuthenticated) return '/login';
                if (isAuthenticated && !hasAccessTo2FA) return '/home';
                break;

              case '/login':
                if (hasAccessTo2FA) return '/2fa';
                if (!hasAccessTo2FA && isAuthenticated) return '/home';
                return null;

              case '/2fa':
                if (hasAccessTo2FA) return null;
                if (!hasAccessTo2FA && isAuthenticated) return '/home';
                if (!hasAccessTo2FA && !isAuthenticated) return '/login';
                return null;

              case '/home':
                if (hasAccessTo2FA) return '/2fa';
                if (!isAuthenticated && !hasAccessTo2FA) return '/login';
                if (isAuthenticated) return null;
                return null;

              default:
                if (hasAccessTo2FA) return '/2fa';
                if (isAuthenticated) return null;
                return '/';
            }
            return null;
          },
        );

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
                lightTheme = ThemeData(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    useMaterial3: true,
                    primaryColor: flavorPrimary,
                    colorScheme: ColorScheme.light(
                      primary: flavorPrimary ?? Colors.blue.shade600,
                      onPrimary: flavorPrimary ?? Colors.blue.shade400,
                    ),
                    brightness: Brightness.light);
                darkTheme = ThemeData(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    useMaterial3: true,
                    primaryColor: flavorPrimary,
                    brightness: Brightness.dark);
                break;
              case 1:
                themeMode = ThemeMode.dark;
                lightTheme = ThemeData(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    useMaterial3: true,
                    primaryColor: flavorPrimary,
                    brightness: Brightness.light);
                darkTheme = ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  //which flutter dev ever caused this bug you need to fucking stand up and fix it im fed up of flutters stupid shit.
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  colorScheme: ColorScheme.dark(
                    primary: flavorPrimary ?? Colors.blue.shade600,
                    onPrimary: flavorPrimary ?? Colors.blue.shade400,
                    secondary: Colors.grey.shade800,
                    onSecondary: Colors.black,
                    surface: Colors.grey.shade800,
                    onSurface: Colors.grey.shade200,
                    error: Colors.red.shade400,
                    onError: Colors.black,
                    surfaceContainer: const Color.fromARGB(255, 40, 40, 40),
                  ),
                  scaffoldBackgroundColor: Colors.grey.shade900,
                  appBarTheme: AppBarTheme(
                    backgroundColor: const Color.fromARGB(255, 40, 40, 40),
                    foregroundColor: Colors.grey.shade200,
                  ),
                  drawerTheme: const DrawerThemeData(
                    backgroundColor: Color.fromARGB(255, 40, 40, 40),
                  ),
                  cardColor: Colors.grey.shade800,
                  dividerColor: Colors.grey.shade800,
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                    ),
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
                  lightTheme = ThemeData.from(
                      colorScheme: ColorScheme.fromSeed(
                          seedColor: Color(seed),
                          brightness: Brightness.light));
                  darkTheme = ThemeData.from(
                      colorScheme: ColorScheme.fromSeed(
                          seedColor: Color(seed), brightness: Brightness.dark));
                }
            }
            return MaterialApp.router(
              // Force rebuild when theme settings change
              key: ValueKey('$themeType-$src-$seed'),
              routerConfig: router,
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

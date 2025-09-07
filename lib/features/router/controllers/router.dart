import 'package:floaty/features/api/utils/middleware.dart';
import 'package:floaty/features/authentication/views/login_screen.dart';
import 'package:floaty/features/browse/views/browse_screen.dart';
import 'package:floaty/features/channel/views/channel_screen.dart';
import 'package:floaty/features/history/views/history_screen.dart';
import 'package:floaty/features/home/views/home_screen.dart';
import 'package:floaty/features/live/views/live_screen.dart';
import 'package:floaty/features/logs/views/log_screen.dart';
import 'package:floaty/features/player/components/custom_player/custom_player.dart';
import 'package:floaty/features/post/views/ecc_warning.dart';
import 'package:floaty/features/post/views/post_screen.dart';
import 'package:floaty/features/profile/views/profile_screen.dart';
import 'package:floaty/features/settings/views/settings_screen.dart';
import 'package:floaty/features/router/views/root_layout.dart';
import 'package:floaty/features/player/components/pip_player_widget.dart';
import 'package:floaty/features/updater/views/update_screen.dart';
import 'package:floaty/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:better_player_plus/better_player_plus.dart';

final Middleware middleware = Middleware();

final GoRouter routerController = GoRouter(
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
      path: '/update',
      builder: (BuildContext context, GoRouterState state) {
        return const UpdateScreen();
      },
    ),
    GoRoute(
      path: '/pip',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
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
        return RootLayout(key: rootLayoutKey, child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            key: ValueKey(DateTime.now().millisecondsSinceEpoch),
          ),
        ),
        GoRoute(
          path: '/browse',
          builder: (context, state) => BrowseScreen(
            key: ValueKey(DateTime.now().millisecondsSinceEpoch),
          ),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => HistoryScreen(
            key: ValueKey(DateTime.now().millisecondsSinceEpoch),
          ),
        ),
        GoRoute(
          path: '/test',
          builder: (BuildContext context, GoRouterState state) {
            return MyHomePage();
          },
        ),
        GoRoute(
          path: '/channel/:ChannelName/:SubName',
          builder: (context, state) {
            final channelName =
                state.pathParameters['ChannelName'] ?? 'defaultChannel';
            final subName = state.pathParameters['SubName'];
            return ChannelScreen(
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              channelName: channelName,
              subName: subName,
            );
          },
        ),
        GoRoute(
          path: '/live/:ChannelName',
          builder: (context, state) {
            final channelName =
                state.pathParameters['ChannelName'] ?? 'defaultChannel';
            return LiveScreen(
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              channelName: channelName,
            );
          },
        ),
        GoRoute(
          path: '/post/:postid',
          builder: (context, state) {
            final postid = state.pathParameters['postid'] ?? '';
            return VideoDetailPage(
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              postId: postid,
            );
          },
        ),
        GoRoute(
          path: '/ecc-warning/:postId',
          builder: (context, state) {
            final postId = state.pathParameters['postId'] ?? '';
            return EccWarning(
              postId,
              discoverable: state.extra == 'discoverable',
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
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
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
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
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
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
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              userName: userName,
            );
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            final isWideScreen = MediaQuery.of(context).size.width >= 600;
            final settingsContent = isWideScreen
                ? SettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                    child: child)
                : child;
            return FocusTraversalGroup(
              policy: ReadingOrderTraversalPolicy(),
              child: settingsContent,
            );
          },
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                final isWideScreen = MediaQuery.of(context).size.width >= 600;
                if (isWideScreen) {
                  // Redirect to default category
                  return AccountSettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  );
                } else {
                  return SettingsListScreen(); // List of categories
                }
              },
              routes: [
                GoRoute(
                  path: 'account',
                  builder: (context, state) => AccountSettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
                GoRoute(
                  path: 'accounts',
                  builder: (context, state) => AccountsSettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
                GoRoute(
                  path: 'invoices',
                  builder: (context, state) => InvoicesSettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
                GoRoute(
                  path: 'licenses',
                  builder: (context, state) => LicensesSettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
                GoRoute(
                  path: 'about',
                  builder: (context, state) => AboutSettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
                GoRoute(
                  path: 'appearance',
                  builder: (context, state) => AppearanceSettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
                GoRoute(
                  path: 'player',
                  builder: (context, state) => PlayerSettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
                GoRoute(
                  path: 'developer',
                  builder: (context, state) => LogScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) async {
    final isAuthenticated = await middleware.isAuthenticated();
    final hasAccessTo2FA = await middleware.twoFAAuthenticated();
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  late BetterPlayerController _betterPlayerController;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(aspectRatio: 16 / 9, fit: BoxFit.contain);
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      "https://mtoczko.github.io/hls-test-streams/test-group/playlist.m3u8",
      useAsmsSubtitles: true,
      videoFormat: BetterPlayerVideoFormat.hls,
    );
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HLS tracks")),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Player with HLS stream which loads tracks from HLS."
              " You can choose tracks by using overflow menu (3 dots in right corner).",
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile =
                    constraints.maxWidth < 600; // Simple mobile detection

                return CustomPlayer(
                  isFullscreen: false,
                  isDesktop: !isMobile,
                  betterPlayerController: BetterPlayerController(
                    BetterPlayerConfiguration(
                      aspectRatio: 16 / 9,
                      fit: BoxFit.contain,
                      autoPlay: true,
                      controlsConfiguration:
                          const BetterPlayerControlsConfiguration(
                        enableFullscreen:
                            false, // We handle fullscreen ourselves
                        enableMute: false,
                        enablePlayPause: false,
                        enablePlaybackSpeed: false,
                        enableProgressBar: false,
                        enableProgressBarDrag: false,
                        enableProgressText: false,
                        enableQualities: false,
                        enableSkips: false,
                        enableSubtitles: false,
                        showControls: false, // Hide default controls
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

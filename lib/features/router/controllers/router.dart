import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:floaty/shared/utils/safe_connectivity.dart';
import 'package:floaty/features/api/models/definitions.dart';
import 'package:floaty/features/api/utils/middleware.dart';
import 'package:floaty/features/authentication/views/login_screen.dart';
import 'package:floaty/features/browse/views/browse_screen.dart';
import 'package:floaty/features/channel/views/channel_screen.dart';
import 'package:floaty/features/download/views/fp_downloads_combined_screen.dart';
import 'package:floaty/features/history/views/history_screen.dart';
import 'package:floaty/features/home/views/home_screen.dart';
import 'package:floaty/features/live/views/live_screen.dart';
import 'package:floaty/features/logs/views/log_screen.dart';
import 'package:floaty/features/post/views/ecc_warning.dart';
import 'package:floaty/features/post/views/post_screen.dart';
import 'package:floaty/features/profile/views/profile_screen.dart';
import 'package:floaty/features/settings/views/settings_screen.dart';
import 'package:floaty/features/router/views/root_layout.dart';
import 'package:floaty/features/router/views/splash_screen.dart';
import 'package:floaty/features/updater/respositories/updater_controllers.dart';
import 'package:floaty/features/updater/views/update_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      path: '/update',
      builder: (BuildContext context, GoRouterState state) {
        return const UpdateScreen();
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
          path: '/offline',
          builder: (context, state) => FPDownloadsCombinedScreen(
            key: ValueKey(DateTime.now().millisecondsSinceEpoch),
          ),
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
              key: ValueKey(channelName),
              channelName: channelName,
            );
          },
        ),
        GoRoute(
          path: '/post/:postid',
          builder: (context, state) {
            final postid = state.pathParameters['postid'] ?? '';
            final extra = state.extra as Map<String, dynamic>?;
            return VideoDetailPage(
              key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              postId: postid,
              isOffline: extra?['isOffline'] as bool? ?? false,
              offlinePost: extra?['offlinePost'] as ContentPostV3Response?,
              offlineAttachmentId: extra?['offlineAttachmentId'] as String?,
              offlineFilePath: extra?['offlineFilePath'] as String?,
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
                  path: 'downloads',
                  builder: (context, state) => DownloadsSettingsScreen(
                    key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                  ),
                ),
                GoRoute(
                  path: 'updater',
                  builder: (BuildContext context, GoRouterState state) {
                    return UpdateScreen(
                      key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                    );
                  },
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
  // Global redirect logic for authentication
  // This runs on every navigation to check if the user should be redirected
  redirect: (BuildContext context, GoRouterState state) async {
    try {
      return await _redirect(context, state);
    } catch (e, st) {
      debugPrint('Router redirect failed ($e), sending user to login: $st');
      final path = state.uri.path;
      if (path == '/login' || path == '/update') {
        return null;
      }
      return '/login';
    }
  },
);

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    final currentPath = state.uri.path;

    if (currentPath == '/update') {
      return null;
    }
    final updateRedirect = await updatercontroller.redirectPathIfUpdateRequired();
    if (updateRedirect != null) {
      return updateRedirect;
    }

    // Skip NetworkManager on Linux when D-Bus is unavailable (see safe_connectivity.dart).
    final isOffline = connectivityLikelyUnavailableOnLinux
        ? false
        : (await safeCheckConnectivity())
            .contains(ConnectivityResult.none);

    // If offline and user was previously authenticated, give full app access
    // No point trying to validate tokens when there's no internet anyway
    if (isOffline) {
      final wasPreviouslyAuthenticated =
          await middleware.wasPreviouslyAuthenticated();

      if (wasPreviouslyAuthenticated) {
        // User has stored auth data and is offline - give full access
        // They can browse their offline content, downloads, etc.
        debugPrint(
            'Offline mode: Allowing access to previously authenticated user');

        // If they're on login screen, redirect to offline library
        if (currentPath == '/login' || currentPath == '/') {
          return '/offline';
        }

        // Otherwise let them navigate freely
        return null;
      } else {
        // User has never authenticated and is offline - they can only access offline routes
        final isOfflineRoute = currentPath == '/offline' ||
            (currentPath.startsWith('/post/') &&
                state.extra is Map &&
                (state.extra as Map)['isOffline'] == true);

        if (isOfflineRoute) {
          return null; // Allow access to offline routes
        }

        // Redirect to offline library since they can't login anyway
        return '/offline';
      }
    }

    // Online - perform normal authentication checks
    bool isAuthenticated = false;
    bool wasPreviouslyAuthenticated = false;

    try {
      isAuthenticated = await middleware.isAuthenticated();
      wasPreviouslyAuthenticated =
          await middleware.wasPreviouslyAuthenticated();
    } catch (e) {
      debugPrint('Redirect auth check failed: $e');
    }

    // Special handling for users with expired tokens but who were previously authenticated
    // This allows them to access offline content instead of being kicked to login
    if (!isAuthenticated && wasPreviouslyAuthenticated) {
      // User has expired tokens but was previously logged in
      // Allow them to stay in the app but redirect to offline library
      // unless they're already on a safe route

      final isOfflineRoute = currentPath == '/offline' ||
          (currentPath.startsWith('/post/') &&
              state.extra is Map &&
              (state.extra as Map)['isOffline'] == true);

      final isSafeRoute = isOfflineRoute ||
          currentPath == '/downloads' ||
          currentPath == '/settings' ||
          currentPath.startsWith('/settings/');

      if (!isSafeRoute) {
        // Redirect to offline library instead of login
        // This way they can still watch their downloaded videos
        debugPrint(
            'Session expired but user has offline access - redirecting to offline library');
        return '/offline';
      }

      // Already on a safe route, let them stay
      return null;
    }

    // Allow access to offline content routes even without any authentication
    final isOfflineRoute = currentPath == '/offline' ||
        (currentPath.startsWith('/post/') &&
            state.extra is Map &&
            (state.extra as Map)['isOffline'] == true);

    if (isOfflineRoute) {
      // Allow access to offline routes regardless of auth status
      return null;
    }

    switch (currentPath) {
      case '/':
        if (!isAuthenticated) return '/login';
        if (isAuthenticated) return '/home';
        break;

      case '/login':
        if (isAuthenticated) return '/home';
        return null;

      default:
        if (isAuthenticated) return null;
        return '/';
    }
    return null;
}

import 'package:floaty/features/router/components/picture_sidebar_item.dart';
import 'package:floaty/features/router/components/sidebar_channel_item.dart';
import 'package:floaty/features/router/components/sidebar_item.dart';
import 'package:floaty/features/router/components/sidebar_size_control.dart';
import 'package:floaty/features/router/components/sidebar_text.dart';
import 'package:floaty/shared/components/switcher.dart';
import 'package:floaty/whitelabels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:floaty/features/api/models/definitions.dart';
import 'package:floaty/shared/controllers/root_provider.dart';
import 'package:floaty/features/player/components/mini_player_widget.dart';
import 'package:floaty/features/player/controllers/media_player_service.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<RootLayoutState> rootLayoutKey = GlobalKey<RootLayoutState>();

class RootLayout extends ConsumerStatefulWidget {
  const RootLayout({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<RootLayout> createState() => RootLayoutState();
}

class RootLayoutState extends ConsumerState<RootLayout>
    with SingleTickerProviderStateMixin {
  UserSelfV3Response? user;
  late bool isSmallScreen;
  @override
  void initState() {
    super.initState();
    ref.read(rootProvider.notifier).loadsidebar();
  }

  void setAppBar(Widget title, {List<Widget>? actions, Widget? leading}) {
    ref
        .read(rootProvider.notifier)
        .setAppBar(title, actions: actions ?? [], leading: leading);
  }

  @override
  void didUpdateWidget(RootLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    user = ref.watch(rootProvider).user;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rootNotifier = ref.read(rootProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    isSmallScreen = screenWidth < 600;
    final isLargeScreen = screenWidth >= 1024;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    final isSidebarCollapsed =
        isSmallScreen ? false : ref.watch(rootProvider).isCollapsed;

    if (isLargeScreen && isSidebarCollapsed) {
      rootNotifier.setExpanded();
    } else if (isMediumScreen && !isSidebarCollapsed) {
      rootNotifier.setCollapsed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rootState = ref.watch(rootProvider);
    final rootNotifier = ref.read(rootProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    isSmallScreen = screenWidth < 600;

    final isSidebarCollapsed = isSmallScreen ? false : rootState.isCollapsed;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isSidebarCollapsed) {
        if (!rootState.showText) {
          if (mounted) {
            ref.read(rootProvider.notifier).setText(true);
          }
        }
      } else {
        ref.read(rootProvider.notifier).setText(false);
      }
    });

    Widget buildSidebarContent() {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SidebarItem(
                    icon: Icons.home,
                    title: 'Home',
                    route: '/home',
                    isSidebarCollapsed: isSidebarCollapsed,
                    isSmallScreen: isSmallScreen,
                    showText: rootState.showText,
                  ),
                  SidebarItem(
                    icon: Icons.view_carousel,
                    title: 'Browse creators',
                    route: '/browse',
                    isSidebarCollapsed: isSidebarCollapsed,
                    isSmallScreen: isSmallScreen,
                    showText: rootState.showText,
                  ),
                  SidebarItem(
                    icon: Icons.history,
                    title: 'Watch history',
                    route: '/history',
                    isSidebarCollapsed: isSidebarCollapsed,
                    isSmallScreen: isSmallScreen,
                    showText: rootState.showText,
                  ),
                  SidebarItem(
                    icon: Icons.bug_report,
                    title: 'test',
                    route: '/test',
                    isSidebarCollapsed: isSidebarCollapsed,
                    isSmallScreen: isSmallScreen,
                    showText: rootState.showText,
                  ),
                  SidebarText(
                    title: 'Your Subscriptions',
                    isSidebarCollapsed: isSidebarCollapsed,
                    isSmallScreen: isSmallScreen,
                    showText: rootState.showText,
                  ),
                  if (rootState.isLoading)
                    const CircularProgressIndicator()
                  else
                    ...rootState.creators
                        .map((creatorResponse) => SidebarChannelItem(
                              id: creatorResponse.id ?? '',
                              response: creatorResponse,
                              isSidebarCollapsed: isSidebarCollapsed,
                              isSmallScreen: isSmallScreen,
                              showText: rootState.showText,
                            )),
                ],
              ),
            ),
          ),
          FutureBuilder(
            future: whitelabels.getLoggedInLabelsLength(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              if (snapshot.data! > 1) {
                return Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.5),
                    child: Switcher(
                      whitelabels: whitelabels.getWhitelabels(),
                      onSwitch: (whitelabel) {
                        ref.read(rootProvider.notifier).loadsidebar();
                        final currentPath = GoRouterState.of(context).uri.path;
                        if (currentPath.startsWith('/post/') ||
                            currentPath.startsWith('/channel/')) {
                          // If current route is /post or /channel, go to home
                          context.pushReplacement(
                              '/home?time=${DateTime.now().millisecondsSinceEpoch}');
                          ref
                              .read(mediaPlayerServiceProvider.notifier)
                              .changeState(MediaPlayerState.none);
                        } else {
                          // Otherwise, refresh the current page
                          final location =
                              GoRouterState.of(context).uri.toString();
                          context.pushReplacement(
                              '$location?time=${DateTime.now().millisecondsSinceEpoch}');
                          ref
                              .read(mediaPlayerServiceProvider.notifier)
                              .changeState(MediaPlayerState.none);
                        }
                      },
                      sidebar: true,
                      compact: isSidebarCollapsed,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Column(
            children: [
              SidebarItem(
                icon: Icons.settings,
                title: 'Settings',
                route: '/settings',
                isSidebarCollapsed: isSidebarCollapsed,
                isSmallScreen: isSmallScreen,
                showText: rootState.showText,
              ),
              if (rootState.isLoading)
                const CircularProgressIndicator()
              else
                PictureSidebarItem(
                  picture: rootState.user?.profileImage?.path ?? '',
                  title: rootState.user?.username ?? '',
                  route: '/profile/${rootState.user?.username}',
                  isSidebarCollapsed: isSidebarCollapsed,
                  isSmallScreen: isSmallScreen,
                  showText: rootState.showText,
                ),
              if (!isSmallScreen)
                SidebarSizeControl(
                  title: 'Collapse Sidebar',
                  route: '',
                  isSidebarCollapsed: isSidebarCollapsed,
                  isSmallScreen: isSmallScreen,
                  showText: rootState.showText,
                  onTap: () => rootNotifier.toggleCollapse(),
                ),
            ],
          ),
        ],
      );
    }

    Widget sidebar = isSmallScreen
        ? SafeArea(child: Drawer(child: buildSidebarContent()))
        : SafeArea(
            bottom: false,
            child: Consumer(
              builder: (context, ref, _) {
                return AnimatedContainer(
                  width: isSidebarCollapsed ? 70 : 260,
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: colorScheme.surfaceContainer,
                    elevation: 2,
                    child: SafeArea(child: buildSidebarContent()),
                  ),
                );
              },
            ));

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: colorScheme.surfaceContainer,
        title: rootState.appBarTitle,
        actions: rootState.appBarActions,
        leading: isSmallScreen
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  scaffoldKey.currentState?.openDrawer();
                },
              )
            : null,
      ),
      drawer: isSmallScreen ? sidebar : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isSmallScreen) sidebar,
            Expanded(
              child: Stack(
                children: [
                  widget.child,
                  Consumer(
                    builder: (context, ref, _) {
                      final mediaService =
                          ref.watch(mediaPlayerServiceProvider.notifier);
                      final mediaState = ref.watch(mediaPlayerServiceProvider);

                      if (mediaState == MediaPlayerState.mini) {
                        return Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: MiniPlayerWidget(
                            title: mediaService.currentTitle ?? '',
                            artist: mediaService.currentArtist ?? '',
                            postId: mediaService.currentPostId ?? '',
                            live: mediaService.currentLive,
                            thumbnailUrl: mediaService.currentThumbnailUrl,
                            videoController: mediaService.videoController,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

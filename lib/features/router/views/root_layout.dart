import 'package:floaty/features/router/components/picture_sidebar_item.dart';
import 'package:floaty/features/router/components/sidebar_channel_item.dart';
import 'package:floaty/features/router/components/sidebar_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:floaty/features/api/models/definitions.dart';
import 'package:floaty/shared/controllers/root_provider.dart';
import 'package:floaty/features/player/components/mini_player_widget.dart';
import 'package:floaty/features/player/controllers/media_player_service.dart';

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
        .setAppBar(title, actions: actions, leading: leading);
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
                    color: Theme.of(context).colorScheme.surfaceContainer,
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
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceContainer,
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

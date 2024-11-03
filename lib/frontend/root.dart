import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/state_mgmt.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:floaty/backend/fpapi.dart';

final GlobalKey<_RootLayoutState> rootLayoutKey = GlobalKey<_RootLayoutState>();

class RootLayout extends ConsumerStatefulWidget {
  const RootLayout({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends ConsumerState<RootLayout>
    with SingleTickerProviderStateMixin {
  bool showText = false;
  List<CreatorModelV3> creators = [];
  UserSelfV3Response? user;
  bool isLoading = true;
  String _appBarTitle = 'Floaty';

  @override
  void initState() {
    super.initState();
    _loadsidebar();
  }

  void _loadsidebar() async {
    creators = await FPApiRequests().getSubscribedCreators();
    user = await FPApiRequests().getUser();
    setState(() {
      isLoading = false;
    });
  }

  // Public method to set the app bar title
  void setAppBarTitle(String title) {
    setState(() {
      _appBarTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sidebarState = ref.watch(sidebarStateProvider);
    final sidebarNotifier = ref.read(sidebarStateProvider.notifier);
    final isSidebarCollapsed = sidebarState.isCollapsed;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isLargeScreen = screenWidth >= 1024;
    final bool isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    Future.microtask(() async {
      if (isLargeScreen && isSidebarCollapsed) {
        sidebarNotifier.setExpanded();
      } else if (isMediumScreen && !isSidebarCollapsed) {
        sidebarNotifier.setCollapsed();
      } else if (isSmallScreen && isSidebarCollapsed) {
        //note to self: when i get a bug report in 6months of the the app not respecting user choice you can blame this line right here.
        sidebarNotifier.forceExpandMobile();
      }
    });

    if (!isSidebarCollapsed) {
      if (!showText) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              showText = true;
            });
          }
        });
      }
    } else {
      setState(() {
        showText = false;
      });
    }
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
                    showText: showText,
                  ),
                  SidebarItem(
                    icon: Icons.view_carousel,
                    title: 'Browse creators',
                    route: '/browse',
                    isSidebarCollapsed: isSidebarCollapsed,
                    isSmallScreen: isSmallScreen,
                    showText: showText,
                  ),
                  SidebarItem(
                    icon: Icons.history,
                    title: 'Watch history',
                    route: '/history',
                    isSidebarCollapsed: isSidebarCollapsed,
                    isSmallScreen: isSmallScreen,
                    showText: showText,
                  ),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    ...creators.map((creatorResponse) => SidebarChannelItem(
                          response: creatorResponse,
                          isSidebarCollapsed: isSidebarCollapsed,
                          isSmallScreen: isSmallScreen,
                          showText: showText,
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
                showText: showText,
              ),
              if (isLoading)
                const CircularProgressIndicator()
              else
                PictureSidebarItem(
                  picture: user?.profileImage!.path ?? '',
                  title: user?.username ?? '',
                  route: '/profile',
                  isSidebarCollapsed: isSidebarCollapsed,
                  isSmallScreen: isSmallScreen,
                  showText: showText,
                ),
              if (!isSmallScreen)
                SidebarSizeControl(
                  title: 'Collapse Sidebar',
                  route: '',
                  isSidebarCollapsed: isSidebarCollapsed,
                  isSmallScreen: isSmallScreen,
                  showText: showText,
                  onTap: () => sidebarNotifier.toggleCollapse(),
                ),
            ],
          ),
        ],
      );
    }

    Widget sidebar = isSmallScreen
        ? SafeArea(child: Drawer(child: buildSidebarContent()))
        : AnimatedContainer(
            width: isSidebarCollapsed ? 70 : 260,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: const Color.fromARGB(255, 40, 40, 40),
              elevation: 2,
              child: buildSidebarContent(),
            ),
          );

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        surfaceTintColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(_appBarTitle),
        leading: isSmallScreen
            ? Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              )
            : null,
      ),
      drawer: isSmallScreen ? sidebar : null,
      //i got u people who use gesture based navigation controls on android (im talking to myself this is literally for myself)
      drawerEdgeDragWidth: 125,
      body: Row(
        children: [
          if (!isSmallScreen) sidebar,
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

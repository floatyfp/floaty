import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/state_mgmt.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:floaty/backend/fpapi.dart';

// ignore: library_private_types_in_public_api
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
  Widget _appBarTitle = const Text('Floaty');
  List<Widget>? _appBarActions;
  Widget? _appBarLeading;

  @override
  void initState() {
    super.initState();
    _loadsidebar();
  }

  void _loadsidebar() {
    setState(() {
      isLoading = true;
    });
    FPApiRequests().getSubscribedCreatorsStream().listen((fetchedCreators) {
      setState(() {
        creators = fetchedCreators;
      });
      FPApiRequests().getUserStream().listen((fetchedUser) {
        setState(() {
          user = fetchedUser;
          isLoading = false;
        });
      }, onError: (error) {
        setState(() {
          isLoading = false;
        });
      });
    }, onError: (error) {
      setState(() {
        isLoading = false;
      });
    });
  }

  void setAppBar(Widget title, {List<Widget>? actions, Widget? leading}) {
    setState(() {
      _appBarTitle = title;
      _appBarActions = actions;
      _appBarLeading = leading;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sidebarState = ref.watch(sidebarStateProvider);
    final sidebarNotifier = ref.read(sidebarStateProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isLargeScreen = screenWidth >= 1024;
    final bool isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    // Force expanded state on small screens
    final isSidebarCollapsed = isSmallScreen ? false : sidebarState.isCollapsed;

    Future.microtask(() async {
      if (isLargeScreen && isSidebarCollapsed) {
        sidebarNotifier.setExpanded();
      } else if (isMediumScreen && !isSidebarCollapsed) {
        sidebarNotifier.setCollapsed();
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
        title: _appBarTitle,
        actions: _appBarActions,
        leading: isSmallScreen
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      );
                    },
                  ),
                  if (_appBarLeading != null) _appBarLeading!,
                ],
              )
            : _appBarLeading,
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

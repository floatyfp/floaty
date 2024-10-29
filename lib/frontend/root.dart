import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/state_mgmt.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:floaty/backend/fpapi.dart';

class RootLayout extends ConsumerStatefulWidget {
  RootLayout({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends ConsumerState<RootLayout> with SingleTickerProviderStateMixin {
  bool showText = false;
  var creators = <CreatorResponse>[];

  @override
  void initState() {
    super.initState();
    _getcreator();
  }

  void _getcreator() async {
    creators = await FPApiRequests().getSubscribedCreators();
  }

  @override
  Widget build(BuildContext context) {
    final sidebarState = ref.watch(sidebarStateProvider);
    final sidebarNotifier = ref.read(sidebarStateProvider.notifier);
    final isSidebarCollapsed = sidebarState.isCollapsed;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isLargeScreen = screenWidth >= 1024;

    // Sidebar open/close logic
    Future.microtask(() async {
      if (isLargeScreen && isSidebarCollapsed) {
        sidebarNotifier.setExpanded();
      } else if (!isLargeScreen && !isSidebarCollapsed) {
        sidebarNotifier.setCollapsed();
      }
    });

    // Manage text appearance after sidebar animation
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
        showText = false; // Immediately hide text when collapsing
      });
    }

   Widget buildSidebarContent() {
      return Column(
        children: [
          // This Expanded widget with SingleChildScrollView will make the top items scrollable
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
          
          // Bottom pinned items
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
              PictureSidebarItem(
                picture: 'https://pbs.floatplane.com/profile_images/6142144ed18325f197211b18/657133415086207_1711875353613_100x100.jpeg',
                title: 'bw86',
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
        ? Drawer(child: buildSidebarContent())
        : AnimatedContainer(
            width: isSidebarCollapsed ? 70 : 260, // Sidebar width
            duration: const Duration(milliseconds: 200), // Container animation duration
            child: Material(
              color: const Color.fromARGB(255, 40, 40, 40),  
              elevation: 2,
              child: buildSidebarContent(),
            ),
          );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        surfaceTintColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text('Responsive Sidebar'),
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
      body: Row(
        children: [
          if (!isSmallScreen) sidebar,
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
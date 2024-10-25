import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:floaty/backend/state_mgmt.dart';

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarState = ref.watch(sidebarStateProvider);
    final sidebarNotifier = ref.read(sidebarStateProvider.notifier);
    final isSidebarCollapsed = sidebarState.isCollapsed;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final bool isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final bool isLargeScreen = screenWidth >= 1024;

    // Move the default collapse state logic to a microtask
    Future.microtask(() {
      if (isLargeScreen && isSidebarCollapsed) {
        sidebarNotifier.setExpanded();
      } else if (isMediumScreen && !isSidebarCollapsed) {
        sidebarNotifier.setCollapsed();
      }
    });

    // Sidebar content using ListTile with icons and optional text
    Widget buildSidebarContent() {
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.home),
            title: !isSmallScreen ? isSidebarCollapsed ? null : const Text('Home') : const Text('Home'),
            selected: GoRouterState.of(context).uri.path == '/home',
            onTap: () => _navigate('/home', context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: !isSmallScreen ? isSidebarCollapsed ? null : const Text('Settings') : const Text('Settings'),
            selected: GoRouterState.of(context).uri.path == '/settings',
            onTap: () => _navigate('/settings', context),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: !isSmallScreen ? isSidebarCollapsed ? null : const Text('About') : const Text('About'),
            selected: GoRouterState.of(context).uri.path == '/about',
            onTap: () => _navigate('/about', context),
          ),
        ],
      );
    }

    // Sidebar as Drawer for small screens, and AnimatedContainer for medium/large
    Widget sidebar = isSmallScreen
        ? Drawer(child: buildSidebarContent())
        : AnimatedContainer(
            width: isSidebarCollapsed ? 70 : 250,
            duration: const Duration(milliseconds: 50),
            child: Material(
              elevation: 2,
              child: buildSidebarContent(),
            ),
          );

    return Scaffold(
      appBar: AppBar(
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
            : IconButton(
                icon: Icon(
                  isSidebarCollapsed ? Icons.arrow_forward : Icons.arrow_back,
                ),
                onPressed: () => sidebarNotifier.toggleCollapse(),
              ),
      ),
      drawer: isSmallScreen ? sidebar : null,
      body: Row(
        children: [
          if (!isSmallScreen) sidebar,
          Expanded(child: child),
        ],
      ),
    );
  }

  // Navigate without collapsing sidebar on larger screens
  void _navigate(String route, BuildContext context) {
    context.go(route);
  }
}

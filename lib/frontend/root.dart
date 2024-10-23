import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:floaty/backend/state_mgmt.dart'; // Import your state management file

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access the sidebar state using the notifier
    final sidebarState = ref.watch(sidebarStateProvider); // Sidebar state
    final isSidebarExpanded = !sidebarState.isCollapsed; // Determine if sidebar is expanded
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine screen size
    bool isSmallScreen = screenWidth < 600;
    bool isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    bool isLargeScreen = screenWidth >= 1024;

    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        // Small screens: full open/close
        if (isSmallScreen) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            ref.read(sidebarStateProvider).state = true; // Open
          } else if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            ref.read(sidebarStateProvider).state = false; // Close
          }
        } 
        // Medium and large screens: collapse/expand
        else {
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            ref.read(sidebarStateProvider).state = true; // Expand
          } else if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            ref.read(sidebarStateProvider).state = false; // Collapse
          }
        }
      },
      child: Row(
        children: [
          // Sidebar with conditional width
          AnimatedContainer(
            width: isSmallScreen
                ? (isSidebarExpanded ? 250 : 0) // Show or hide on small screens
                : (isSidebarExpanded ? 250 : 70), // Collapse on medium/large screens
            duration: const Duration(milliseconds: 200),
            child: Drawer(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Home'),
                    onTap: () {
                      context.go('/l/home'); // Navigate to the home route
                    },
                  ),
                  ListTile(
                    title: const Text('Settings'),
                    onTap: () {
                      context.go('/l/settings'); // Navigate to settings
                    },
                  ),
                  ListTile(
                    title: const Text('About'),
                    onTap: () {
                      context.go('/l/about'); // Navigate to about
                    },
                  ),
                ],
              ),
            ),
          ),
          // Main content area
          Expanded(
            child: Navigator(
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute(
                  builder: (context) {
                    switch (settings.name) {
                      case '/l/home':
                        return const Center(child: Text('Home Screen'));
                      case '/l/settings':
                        return const Center(child: Text('Settings Screen'));
                      case '/l/about':
                        return const Center(child: Text('About Screen'));
                      default:
                        return const Center(child: Text('Main content goes here'));
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

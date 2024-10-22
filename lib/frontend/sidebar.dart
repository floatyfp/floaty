import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/state_mgmt.dart';

final sidebarStateProvider = StateProvider<bool>((ref) => true); // true = expanded, false = collapsed

class ResponsiveSidebar extends ConsumerWidget {
  const ResponsiveSidebar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSidebarExpanded = ref.watch(sidebarStateProvider).state;
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine if it's a small, medium, or large screen
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
                ? (isSidebarExpanded ? 250 : 0) // Small screens fully hide/show
                : (isSidebarExpanded ? 250 : 70), // Medium/large screens collapse
            duration: const Duration(milliseconds: 200),
            child: const Drawer(
              child: Column(
                children: [
                  ListTile(title: Text('Item 1')),
                  ListTile(title: Text('Item 2')),
                  ListTile(title: Text('Item 3')),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Responsive Sidebar'),
                leading: isSmallScreen
                    ? IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          ref.read(sidebarStateProvider).state = !isSidebarExpanded;
                        },
                      )
                    : null,
              ),
              body: const Center(child: Text('Main content goes here')),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResponsiveSidebar extends StatefulWidget {
  @override
  _ResponsiveSidebarState createState() => _ResponsiveSidebarState();
}

class _ResponsiveSidebarState extends State<ResponsiveSidebar> {
  bool _isCollapsed = false;
  bool _isDropdownOpen = false;

  bool isLargeScreen(BuildContext context) => MediaQuery.of(context).size.width >= 1200;
  bool isMediumScreen(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  bool isSmallScreen(BuildContext context) => MediaQuery.of(context).size.width < 600;

  void _toggleCollapseExpand() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isSmallScreen(context)) {
      // Sidebar as Drawer for small screens
      return Drawer(
        child: _buildSidebarContent(context),
      );
    } else {
      // Sidebar for medium and large screens
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isCollapsed ? 70 : 250,
        child: Material(
          elevation: 8,
          color: Colors.blueGrey,
          child: _buildSidebarContent(context),
        ),
      );
    }
  }

  Widget _buildSidebarContent(BuildContext context) {
    return Column(
      children: [
        // Logo at the top
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _isCollapsed
              ? Image.asset('assets/logo-mini.png', width: 50)
              : Image.asset('assets/logo-large.png', width: 200),
        ),
        if (!isSmallScreen(context))
          IconButton(
            icon: Icon(_isCollapsed ? Icons.arrow_right : Icons.arrow_left),
            onPressed: _toggleCollapseExpand,
          ),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.home),
                title: _isCollapsed ? null : const Text("Home"),
                onTap: () {
                  context.go('/home');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: _isCollapsed ? null : const Text("Settings"),
                onTap: () {
                  context.go('/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.expand_more),
                title: _isCollapsed ? null : const Text("Channels"),
                onTap: _toggleDropdown,
                trailing: _isDropdownOpen
                    ? const Icon(Icons.arrow_drop_up)
                    : const Icon(Icons.arrow_drop_down),
              ),
              if (_isDropdownOpen)
                Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.subdirectory_arrow_right),
                      title: _isCollapsed ? null : const Text("Subchannel 1"),
                      onTap: () {
                        context.go('/channel/1');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.subdirectory_arrow_right),
                      title: _isCollapsed ? null : const Text("Subchannel 2"),
                      onTap: () {
                        context.go('/channel/2');
                      },
                    ),
                  ],
                ),
              ListTile(
                leading: const Icon(Icons.info),
                title: _isCollapsed ? null : const Text("About"),
                onTap: () {
                  context.go('/about');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

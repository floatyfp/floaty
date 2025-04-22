import 'package:floaty/shared/controllers/root_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SidebarSizeControl extends StatelessWidget {
  final String title;
  final String route;
  final bool isSidebarCollapsed;
  final bool isSmallScreen;
  final bool showText;
  final VoidCallback? onTap;

  const SidebarSizeControl({
    super.key,
    required this.title,
    required this.route,
    required this.isSidebarCollapsed,
    required this.isSmallScreen,
    required this.showText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: GoRouterState.of(context).uri.path == route,
      leading: Icon(
        isSidebarCollapsed ? Icons.arrow_forward : Icons.arrow_back,
      ),
      title: isSidebarCollapsed
          ? null
          : showText || isSmallScreen
              ? Text(title)
              : const SizedBox.shrink(),
      onTap: onTap ??
          () {
            context.go(route);
            scaffoldKey.currentState?.closeDrawer();
          },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}

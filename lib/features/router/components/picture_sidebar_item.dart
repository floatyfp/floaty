import 'package:cached_network_image/cached_network_image.dart';
import 'package:floaty/shared/controllers/root_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PictureSidebarItem extends StatelessWidget {
  final String picture;
  final String title;
  final String route;
  final bool isSidebarCollapsed;
  final bool isSmallScreen;
  final bool showText;
  final VoidCallback? onTap;

  const PictureSidebarItem({
    super.key,
    required this.picture,
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
      leading: AnimatedContainer(
        width: 24,
        height: 24,
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: GoRouterState.of(context).uri.path == route
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
          borderRadius: BorderRadius.circular(100),
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: picture.isNotEmpty
                ? CachedNetworkImage(
                    width: 24,
                    height: 24,
                    imageUrl: picture,
                  )
                : Image.asset('assets/placeholder.png')),
      ),
      title: isSidebarCollapsed
          ? null
          : showText || isSmallScreen
              ? title.isEmpty
                  ? Text('Error')
                  : Text(title)
              : const SizedBox.shrink(),
      onTap: onTap ??
          () {
            context.pushReplacement(route);
            scaffoldKey.currentState?.closeDrawer();
          },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}

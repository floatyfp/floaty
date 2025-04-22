import 'package:flutter/material.dart';

class SidebarText extends StatelessWidget {
  final String title;
  final bool isSidebarCollapsed;
  final bool isSmallScreen;
  final bool showText;

  const SidebarText({
    super.key,
    required this.title,
    required this.isSidebarCollapsed,
    required this.isSmallScreen,
    required this.showText,
  });

  @override
  Widget build(BuildContext context) {
    return showText || isSmallScreen
        ? ListTile(
            title: isSidebarCollapsed
                ? null
                : showText || isSmallScreen
                    ? Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold))
                    : const SizedBox.shrink(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          )
        : const SizedBox.shrink();
  }
}

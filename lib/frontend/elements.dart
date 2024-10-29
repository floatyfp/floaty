import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SidebarSizeControl extends StatefulWidget {
  final String title;
  final String route;
  final bool isSidebarCollapsed;
  final bool isSmallScreen;
  final bool showText;
  final VoidCallback? onTap;

  const SidebarSizeControl({
    Key? key,
    required this.title,
    required this.route,
    required this.isSidebarCollapsed,
    required this.isSmallScreen,
    required this.showText,
    this.onTap,
  }) : super(key: key);

  @override
  _SidebarSizeControlState createState() => _SidebarSizeControlState();
}

class _SidebarSizeControlState extends State<SidebarSizeControl> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    if (widget.showText || widget.isSmallScreen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(SidebarSizeControl oldWidget) {
    super.didUpdateWidget(oldWidget);

    if ((widget.showText || widget.isSmallScreen) && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!(widget.showText || widget.isSmallScreen) && _animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return ListTile(
      selected: GoRouterState.of(context).uri.path == widget.route,
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          widget.isSidebarCollapsed ? Icons.arrow_forward : Icons.arrow_back,
        ),
      ),
      title: widget.isSidebarCollapsed
          ? null
          : FadeTransition(
              opacity: _fadeAnimation,
              child: widget.showText || widget.isSmallScreen
                  ? Text(
                      widget.title,
                    )
                  : const SizedBox.shrink(),
            ),
      onTap: widget.onTap ?? () => context.go(widget.route),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}

class SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isSidebarCollapsed;
  final bool isSmallScreen;
  final bool showText;
  final VoidCallback? onTap;

  const SidebarItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.route,
    required this.isSidebarCollapsed,
    required this.isSmallScreen,
    required this.showText,
    this.onTap,
  }) : super(key: key);

  @override
  _SidebarItemState createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    if (widget.showText || widget.isSmallScreen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(SidebarItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if ((widget.showText || widget.isSmallScreen) && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!(widget.showText || widget.isSmallScreen) && _animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return ListTile(
      selected: GoRouterState.of(context).uri.path == widget.route,
      leading: Icon(
        widget.icon,
      ),
      title: widget.isSidebarCollapsed
          ? null
          : FadeTransition(
              opacity: _fadeAnimation,
              child: widget.showText || widget.isSmallScreen
                  ? Text(
                      widget.title,
                    )
                  : const SizedBox.shrink(),
            ),
      onTap: widget.onTap ?? () => context.go(widget.route),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}

class PictureSidebarItem extends StatefulWidget {
  final String picture;
  final String title;
  final String route;
  final bool isSidebarCollapsed;
  final bool isSmallScreen;
  final bool showText;
  final VoidCallback? onTap;

  const PictureSidebarItem({
    Key? key,
    required this.picture,
    required this.title,
    required this.route,
    required this.isSidebarCollapsed,
    required this.isSmallScreen,
    required this.showText,
    this.onTap,
  }) : super(key: key);

  @override
  _PictureSidebarItemState createState() => _PictureSidebarItemState();
}

class _PictureSidebarItemState extends State<PictureSidebarItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    if (widget.showText || widget.isSmallScreen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(PictureSidebarItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if ((widget.showText || widget.isSmallScreen) && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!(widget.showText || widget.isSmallScreen) && _animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: GoRouterState.of(context).uri.path == widget.route,
        leading: AnimatedContainer(
          width: 24,
          height: 24,
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: GoRouterState.of(context).uri.path == widget.route ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null, // Border color and width
            borderRadius: BorderRadius.circular(100), // Slightly larger radius than the image
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              width: 24,
              height: 24,
              imageUrl: widget.picture,
            ),
          ),
        ),
      title: widget.isSidebarCollapsed
          ? null
          : FadeTransition(
              opacity: _fadeAnimation,
              child: widget.showText || widget.isSmallScreen
                  ? Text(
                      widget.title,
                    )
                  : const SizedBox.shrink(),
            ),
      onTap: widget.onTap ?? () => context.go(widget.route),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}

class SidebarChannelItem extends StatefulWidget {
  final CreatorResponse response;
  final bool isSidebarCollapsed;
  final bool isSmallScreen;
  final bool showText;

  const SidebarChannelItem({
    Key? key,
    required this.response,
    required this.isSidebarCollapsed,
    required this.isSmallScreen,
    required this.showText,
  }) : super(key: key);

  @override
  _SidebarChannelItemState createState() => _SidebarChannelItemState();
}

class _SidebarChannelItemState extends State<SidebarChannelItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    if (widget.showText || widget.isSmallScreen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(SidebarChannelItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if ((widget.showText || widget.isSmallScreen) && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!(widget.showText || widget.isSmallScreen) && _animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  List<Channel> _sortedChannels(List<Channel> channels) {
    return List<Channel>.from(channels)..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Widget build(BuildContext context) {
    bool hasSubChannels = widget.response.channels.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          selected: GoRouterState.of(context).uri.path == 'channel/${widget.response.urlname}/home',
          leading: AnimatedContainer(
          width: 24,
          height: 24,
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: GoRouterState.of(context).uri.path == 'channel/${widget.response.urlname}/home' ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null, // Border color and width
            borderRadius: BorderRadius.circular(100), // Slightly larger radius than the image
          ),
          child: ClipRRect( 
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                width: 24,
                height: 24,
                imageUrl: widget.response.icon.path,
              )
            ),
          ),
          title: widget.isSidebarCollapsed
              ? null
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: widget.showText || widget.isSmallScreen
                      ? Text(
                          widget.response.title,
                        )
                      : const SizedBox.shrink(),
                ),
          onTap: () {
            context.go('channel/${widget.response.urlname}/home');
            if (!widget.isSidebarCollapsed && hasSubChannels) {
              _toggleExpansion();
            }
          },
          trailing: hasSubChannels && !widget.isSidebarCollapsed
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 200), // Duration for the animation
                child: IconButton(
                  key: ValueKey<bool>(_isExpanded), // Unique key for each state
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: _toggleExpansion,
                ),
              )
            : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        if (hasSubChannels && _isExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _sortedChannels(widget.response.channels).map((subChannel) {
                return ListTile(
                  selected: GoRouterState.of(context).uri.path == 'channel/${widget.response.urlname}/${subChannel.urlname}',
                    leading: Padding(
                      padding: widget.isSidebarCollapsed ? const EdgeInsets.only(left: 2.23) : const EdgeInsets.only(left: 20.0),
                      child: AnimatedContainer(
                        width: 22,
                        height: 22,
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          border: GoRouterState.of(context).uri.path == 'channel/${widget.response.urlname}/${subChannel.urlname}' ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null, // Border color and width
                          borderRadius: BorderRadius.circular(100), // Slightly larger radius than the image
                        ),
                        child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: CachedNetworkImage(
                          width: 22,
                          height: 22,
                          imageUrl: subChannel.icon.path,
                        )
                      )
                    ),
                    ),
                    title: widget.isSidebarCollapsed
                      ? null
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: widget.showText || widget.isSmallScreen
                              ? Text(
                                  subChannel.title,
                                )
                              : const SizedBox.shrink(),
                        ),
                    onTap: () => context.go('channel/${widget.response.urlname}/${subChannel.urlname}'),
                );
              }).toList(),
          ),
      ],
    );
  }
}

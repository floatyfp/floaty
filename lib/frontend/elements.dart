// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:floaty/backend/state_mgmt.dart';
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

class _SidebarSizeControlState extends State<SidebarSizeControl>
    with SingleTickerProviderStateMixin {
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

    if ((widget.showText || widget.isSmallScreen) &&
        !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!(widget.showText || widget.isSmallScreen) &&
        _animationController.isCompleted) {
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
      onTap: widget.onTap ??
          () {
            context.go(widget.route);
            scaffoldKey.currentState?.closeDrawer();
          },
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

class _SidebarItemState extends State<SidebarItem>
    with SingleTickerProviderStateMixin {
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

    if ((widget.showText || widget.isSmallScreen) &&
        !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!(widget.showText || widget.isSmallScreen) &&
        _animationController.isCompleted) {
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
      onTap: widget.onTap ??
          () {
            context.go(widget.route);
            scaffoldKey.currentState?.closeDrawer();
          },
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

class _PictureSidebarItemState extends State<PictureSidebarItem>
    with SingleTickerProviderStateMixin {
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

    if ((widget.showText || widget.isSmallScreen) &&
        !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!(widget.showText || widget.isSmallScreen) &&
        _animationController.isCompleted) {
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
          border: GoRouterState.of(context).uri.path == widget.route
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
          borderRadius: BorderRadius.circular(100),
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
      onTap: widget.onTap ??
          () {
            context.go(widget.route);
            scaffoldKey.currentState?.closeDrawer();
          },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}

class SidebarChannelItem extends StatefulWidget {
  final CreatorModelV3 response;
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

class _SidebarChannelItemState extends State<SidebarChannelItem>
    with SingleTickerProviderStateMixin {
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

    if ((widget.showText || widget.isSmallScreen) &&
        !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!(widget.showText || widget.isSmallScreen) &&
        _animationController.isCompleted) {
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

  List<ChannelModel> _sortedChannels(List<ChannelModel> channels) {
    return List<ChannelModel>.from(channels)
      ..sort((a, b) => a.order!.compareTo(b.order ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    bool hasSubChannels = widget.response.channels!.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          selected: GoRouterState.of(context).uri.path ==
              '/channel/${widget.response.urlname}',
          leading: AnimatedContainer(
            width: 24,
            height: 24,
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: GoRouterState.of(context).uri.path ==
                      '/channel/${widget.response.urlname}'
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(100),
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  width: 24,
                  height: 24,
                  imageUrl: widget.response.icon!.path ?? '',
                )),
          ),
          title: widget.isSidebarCollapsed
              ? null
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: widget.showText || widget.isSmallScreen
                      ? Text(
                          widget.response.title ?? '',
                        )
                      : const SizedBox.shrink(),
                ),
          onTap: () {
            context.push('/channel/${widget.response.urlname}');
            scaffoldKey.currentState?.closeDrawer();
            if (hasSubChannels) {
              _toggleExpansion();
            }
          },
          trailing: hasSubChannels && !widget.isSidebarCollapsed
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    key: ValueKey<bool>(_isExpanded),
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
            children: _sortedChannels(widget.response.channels ?? [])
                .map((subChannel) {
              return ListTile(
                selected: GoRouterState.of(context).uri.path ==
                    '/channel/${widget.response.urlname}/${subChannel.urlname}',
                leading: Padding(
                  padding: widget.isSidebarCollapsed
                      ? const EdgeInsets.only(left: 2.23)
                      : const EdgeInsets.only(left: 20.0),
                  child: AnimatedContainer(
                      width: 22,
                      height: 22,
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: GoRouterState.of(context).uri.path ==
                                '/channel/${widget.response.urlname}/${subChannel.urlname}'
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: CachedNetworkImage(
                            width: 22,
                            height: 22,
                            imageUrl: subChannel.icon!.path ?? '',
                          ))),
                ),
                title: widget.isSidebarCollapsed
                    ? null
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: widget.showText || widget.isSmallScreen
                            ? Text(
                                subChannel.title ?? '',
                              )
                            : const SizedBox.shrink(),
                      ),
                onTap: () {
                  context.push(
                      '/channel/${widget.response.urlname}/${subChannel.urlname}');
                  scaffoldKey.currentState?.closeDrawer();
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}

class BlogPostCard extends StatefulWidget {
  final BlogPostModelV3 blogPost;
  final GetProgressResponse? response;

  const BlogPostCard(this.blogPost, {this.response, super.key});

  @override
  _BlogPostCardState createState() => _BlogPostCardState();
}

class _BlogPostCardState extends State<BlogPostCard> {
  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));

    return hours != "00" ? "$hours:$minutes:$secs" : "$minutes:$secs";
  }

  String getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown date';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 6) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    var progressValue = 0;
    var computedValue = 0.0;
    if (widget.response != null) {
      progressValue = widget.response?.progress ?? 0;
      computedValue = (progressValue / 100).clamp(0.0, 1.0);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('post/${widget.blogPost.id}'),
        child: SizedBox(
          width: 300,
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(
                                widget.blogPost.thumbnail?.path ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (widget.blogPost.metadata?.hasAudio != false ||
                          widget.blogPost.metadata?.hasVideo != false)
                        Positioned(
                          bottom: widget.response != null ? 12 : 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.blogPost.metadata?.hasVideo == true
                                  ? formatDuration(widget
                                          .blogPost.metadata?.videoDuration
                                          ?.toInt() ??
                                      0)
                                  : formatDuration(widget
                                          .blogPost.metadata?.audioDuration
                                          ?.toInt() ??
                                      0),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      if (widget.response != null)
                        Positioned(
                            bottom: 2.5,
                            left: 10,
                            right: 10,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                    backgroundColor:
                                        Colors.black.withOpacity(0.7),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    minHeight: 5,
                                    value: computedValue))),
                      Positioned(
                        bottom: widget.response != null ? 12 : 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.blogPost.metadata?.hasVideo == true
                                ? 'Video'
                                : widget.blogPost.metadata?.hasAudio == true
                                    ? 'Audio'
                                    : widget.blogPost.metadata?.hasPicture ==
                                            true
                                        ? 'Image'
                                        : widget.blogPost.metadata
                                                    ?.hasGallery ==
                                                true
                                            ? 'Gallery'
                                            : 'Text',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      if (widget.blogPost.isAccessible == false)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(17),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Icon(
                              size: 45,
                              Icons.lock,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 3.35,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                            child: widget.blogPost.channel is ChannelModel
                                ? CachedNetworkImage(
                                    imageUrl:
                                        widget.blogPost.channel?.icon?.path ??
                                            '',
                                    width: 25,
                                    height: 25,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox.shrink()),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.blogPost.title ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.blogPost.channel is ChannelModel ? widget.blogPost.channel?.title ?? '' : widget.blogPost.creator.title ?? ''} • ${getRelativeTime(widget.blogPost.releaseDate ?? DateTime.now())}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreatorCard extends StatefulWidget {
  final CreatorModelV3 creator;

  const CreatorCard(this.creator, {super.key});

  @override
  _CreatorCardState createState() => _CreatorCardState();
}

class _CreatorCardState extends State<CreatorCard> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[850],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/channel/${widget.creator.urlname}'),
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 250,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1200),
                              image: DecorationImage(
                                image: NetworkImage(
                                    widget.creator.icon?.path ?? '',
                                    scale: 10),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  width: 250,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          textAlign: TextAlign.center,
                          widget.creator.title ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const StatColumn({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey.shade400, // Lighter grey color for the label
          ),
        ),
      ],
    );
  }
}

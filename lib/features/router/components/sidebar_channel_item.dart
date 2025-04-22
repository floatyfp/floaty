import 'package:cached_network_image/cached_network_image.dart';
import 'package:floaty/features/api/models/definitions.dart';
import 'package:floaty/shared/controllers/elements_provider.dart';
import 'package:floaty/shared/controllers/root_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SidebarChannelItem extends ConsumerStatefulWidget {
  final String id;
  final CreatorModelV3 response;
  final bool isSidebarCollapsed;
  final bool isSmallScreen;
  final bool showText;
  final VoidCallback? onTap;

  const SidebarChannelItem({
    super.key,
    required this.id,
    required this.response,
    required this.isSidebarCollapsed,
    required this.isSmallScreen,
    required this.showText,
    this.onTap,
  });

  @override
  ConsumerState<SidebarChannelItem> createState() => _SidebarChannelItemState();
}

class _SidebarChannelItemState extends ConsumerState<SidebarChannelItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool get isExpanded => ref.watch(channelExpansionProvider(widget.id));

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
    ref.read(channelExpansionProvider(widget.id).notifier).state =
        !ref.read(channelExpansionProvider(widget.id));
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
                child: widget.response.icon!.path != null &&
                        (widget.response.icon!.path ?? '').isNotEmpty
                    ? CachedNetworkImage(
                        width: 24,
                        height: 24,
                        imageUrl: widget.response.icon!.path ?? '',
                      )
                    : Image.asset('assets/placeholder.png')),
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
                    key: ValueKey<bool>(isExpanded),
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: _toggleExpansion,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        if (hasSubChannels && isExpanded)
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
                          child: subChannel.icon!.path != null &&
                                  (subChannel.icon!.path ?? '').isNotEmpty
                              ? CachedNetworkImage(
                                  width: 22,
                                  height: 22,
                                  imageUrl: subChannel.icon!.path ?? '',
                                )
                              : Image.asset('assets/placeholder.png'))),
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

import 'package:floaty/features/api/models/definitions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CreatorCard extends StatefulWidget {
  final CreatorDiscoveryResponse creator;

  const CreatorCard(this.creator, {super.key});

  @override
  CreatorCardState createState() => CreatorCardState();
}

class CreatorCardState extends State<CreatorCard> {
  bool _isHovered = false;
  bool _isHovered2 = false;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl =
        widget.creator.featuredBlogPosts?.first.thumbnail?.path;

    return Stack(
      children: [
        // Content
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.go('/channel/${widget.creator.urlname}'),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 47,
                          backgroundImage:
                              const AssetImage('assets/placeholder.png'),
                          foregroundImage:
                              NetworkImage(widget.creator.icon.path ?? ''),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.creator.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              if (widget.creator.stats?['subscribers'] != null)
                                Text(
                                  '${NumberFormat('#,###').format(widget.creator.stats!['subscribers'])} Subscribers',
                                ),
                              if (widget.creator.stats?['channels'] != null &&
                                  widget.creator.stats!['channels'].length > 1)
                                Text(
                                  '${widget.creator.stats!['channels'].length} Channels',
                                ),
                              if (widget.creator.stats?['posts'] != null)
                                Text(
                                  '${NumberFormat('#,###').format(widget.creator.stats!['posts'])} Posts',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.creator.featuredBlogPosts != null &&
                        widget.creator.featuredBlogPosts!.isNotEmpty)
                      // Featured post hoverable sub-widget
                      MouseRegion(
                        onEnter: (_) => setState(() {
                          _isHovered2 = true;
                          _isHovered = false;
                        }),
                        onExit: (_) => setState(() {
                          _isHovered2 = false;
                          _isHovered = true;
                        }),
                        child: GestureDetector(
                          onTap: () => widget.creator.featuredBlogPosts!.first
                                      .isAccessible ==
                                  true
                              ? context.go(
                                  '/post/${widget.creator.featuredBlogPosts!.first.id}')
                              : context
                                  .go('/channel/${widget.creator.urlname}'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isHovered2
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 1.8,
                              ),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Row(
                              children: [
                                if (thumbnailUrl != null &&
                                    thumbnailUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      thumbnailUrl,
                                      height: 40,
                                      width: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.creator.featuredBlogPosts!.first
                                            .title ??
                                        '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                if (widget.creator.featuredBlogPosts!.first
                                        .isAccessible ==
                                    true)
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Main card hover border
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _isHovered ? 1.0 : 0.0,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

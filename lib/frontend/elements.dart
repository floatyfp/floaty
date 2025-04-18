import 'package:floaty/settings.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/providers/elements_provider.dart';
import 'package:floaty/backend/whenplaneintergration.dart';

import 'dart:math';
import 'dart:convert';

import 'package:floaty/frontend/root.dart';
import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:floaty/providers/root_provider.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:floaty/backend/fpapi.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isSidebarCollapsed;
  final bool isSmallScreen;
  final bool showText;
  final VoidCallback? onTap;

  const SidebarItem({
    super.key,
    required this.icon,
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
      leading: Icon(icon),
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

class StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const StatColumn({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final double valueFontSize = (maxWidth * 0.15).clamp(16.0, 24.0);
        final double labelFontSize = (maxWidth * 0.08).clamp(12.0, 14.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4.0),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}

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

class CustomCacheManager extends CacheManager {
  static const key = 'customCache';

  static final instance = CustomCacheManager._();

  CustomCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 1), // Shorter cache lifetime
          maxNrOfCacheObjects: 100, // Limit number of cached files
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ));
}

class BlogPostCard extends StatelessWidget {
  final BlogPostModelV3 blogPost;
  final GetProgressResponse? response;
  final double computedValue;
  final String formattedDuration;
  final String mediaTypeLabel;
  final String relativeTime;

  BlogPostCard(this.blogPost, {this.response, super.key})
      : computedValue = (response?.progress ?? 0) / 100,
        formattedDuration = _formatDuration(blogPost),
        mediaTypeLabel = _getMediaTypeLabel(blogPost),
        relativeTime = _getRelativeTime(blogPost.releaseDate);

  static String _formatDuration(BlogPostModelV3 blogPost) {
    final duration = Duration(
        seconds: (blogPost.metadata?.videoDuration ??
                blogPost.metadata?.audioDuration ??
                0)
            .toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String _getMediaTypeLabel(BlogPostModelV3 blogPost) {
    final meta = blogPost.metadata;
    final typeHierarchy = [
      if (meta?.hasVideo == true) 'Video',
      if (meta?.hasAudio == true) 'Audio',
      if (meta?.hasPicture == true) 'Image',
      if (meta?.hasGallery == true) 'Gallery',
      'Text'
    ];
    return typeHierarchy.first;
  }

  static String _getRelativeTime(DateTime? dateTime) =>
      dateTime?.relativeTime ?? 'Unknown date';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => blogPost.isAccessible == true
            ? context.push('/post/${blogPost.id}')
            : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = constraints.maxWidth * 0.08;
            final fontSize = constraints.maxWidth * 0.04;

            return Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnailSection(context, constraints, fontSize),
                  const SizedBox(height: 8),
                  _buildFooterSection(iconSize, fontSize, context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnailSection(
      BuildContext context, BoxConstraints constraints, double fontSize) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: blogPost.thumbnail?.path != null
                ? FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: blogPost.thumbnail?.path ?? '',
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                  )
                : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
          ),

          // Duration label
          if (blogPost.metadata?.hasAudio == true ||
              blogPost.metadata?.hasVideo == true)
            Positioned(
              bottom: response != null ? 12 : 8,
              right: 8,
              child: _InfoBubble(
                text: formattedDuration,
                fontSize: fontSize,
              ),
            ),

          // Progress indicator
          if (response != null)
            Positioned(
              bottom: 2.5,
              left: 10,
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  color: Theme.of(context).colorScheme.primary,
                  minHeight: 5,
                  value: computedValue,
                ),
              ),
            ),

          // Media type label
          Positioned(
            bottom: response != null ? 12 : 8,
            left: 8,
            child: _InfoBubble(
              text: mediaTypeLabel,
              fontSize: fontSize,
            ),
          ),

          // Lock icon
          if (blogPost.isAccessible == false)
            Center(
              child: Container(
                padding: EdgeInsets.all(constraints.maxWidth * 0.06),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(
                  Icons.lock,
                  size: constraints.maxWidth * 0.15,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(
      double iconSize, double fontSize, BuildContext context) {
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel icon
          if (blogPost.channel is ChannelModel)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: blogPost.channel?.icon?.path ??
                    blogPost.creator.icon?.path ??
                    '',
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
              ),
            ),
          if (blogPost.channel is! ChannelModel &&
              blogPost.creator.icon != null &&
              blogPost.creator.icon is ImageModel)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: blogPost.creator.icon?.path ?? '',
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 8),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  blogPost.title ?? '',
                  stepGranularity: 0.25,
                  minFontSize: 10,
                  maxFontSize: 13,
                  textScaleFactor: 0.95,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize * 1.150, // 0.047 of constraints
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  '${blogPost.channel is ChannelModel ? blogPost.channel?.title ?? '' : blogPost.creator.title ?? ''} • $relativeTime',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleMedium?.color,
                    fontSize: fontSize,
                  ),
                  stepGranularity: 0.25,
                  minFontSize: 2,
                  maxFontSize: 10,
                  textScaleFactor: 0.95,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension TimeDifference on DateTime {
  String get relativeTime {
    final diff = DateTime.now().difference(this);
    const thresholds = {
      365 * 24 * 60: 'year',
      30 * 24 * 60: 'month',
      7 * 24 * 60: 'week',
      24 * 60: 'day',
      60: 'hour',
      1: 'minute'
    };

    final minutes = diff.inMinutes;
    final entry = thresholds.entries.firstWhere((e) => minutes >= e.key,
        orElse: () => const MapEntry(0, 'just now'));

    return entry.key == 0
        ? 'Just now'
        : '${(minutes / entry.key).floor()} ${entry.value}${(minutes ~/ entry.key) > 1 ? 's' : ''} ago';
  }
}

class _InfoBubble extends StatelessWidget {
  final String text;
  final double fontSize;

  const _InfoBubble({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class GradientPlaceholder extends StatelessWidget {
  const GradientPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF23A6D5),
            Color(0xFF23D5AB),
          ],
          transform: GradientRotation(-45 * 3.14159 / 180),
        ),
      ),
    );
  }
}

class CreatorCard extends StatefulWidget {
  final CreatorModelV3 creator;

  const CreatorCard(this.creator, {super.key});

  @override
  CreatorCardState createState() => CreatorCardState();
}

class CreatorCardState extends State<CreatorCard> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push('/channel/${widget.creator.urlname}'),
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(
                              widget.creator.icon?.path ?? '',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Center(
                      child: Text(
                        widget.creator.title ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FilterPanel extends ConsumerStatefulWidget {
  final Function(String, Set<String>, RangeValues, DateTime?, DateTime?, bool)
      onFilterChanged;
  final Set<String>? initialContentTypes;
  final String? initialSearchQuery;
  final RangeValues? initialDurationRange;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool? initialIsAscending;
  final double? parentWidth;

  const FilterPanel({
    super.key,
    required this.onFilterChanged,
    this.initialContentTypes,
    this.initialSearchQuery,
    this.initialDurationRange,
    this.initialStartDate,
    this.initialEndDate,
    this.initialIsAscending,
    this.parentWidth,
  });

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel>
    with SingleTickerProviderStateMixin {
  DateTime? startDate;
  DateTime? endDate;
  final List<String> contentTypes = ['Video', 'Audio', 'Picture', 'Text'];
  late Set<String> selectedContentTypes;
  static const double _inputHeight = 40.0;
  final _key = GlobalKey();
  bool _isDefault = true;
  final TextEditingController _searchController = TextEditingController();
  RangeValues _durationRange = const RangeValues(0, 180);
  bool _durationRangeInitialized = false;
  bool _isAscending = false;
  late AnimationController _sortAnimController;
  Timer? _debounce;
  String? _previousText;

  @override
  void initState() {
    super.initState();
    selectedContentTypes = Set<String>.from(widget.initialContentTypes ?? {});
    _searchController.text = widget.initialSearchQuery ?? '';
    _durationRange = widget.initialDurationRange ?? const RangeValues(0, 180);
    _durationRangeInitialized = widget.initialDurationRange != null;
    startDate = widget.initialStartDate;
    endDate = widget.initialEndDate;
    _isAscending = widget.initialIsAscending ?? false;

    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        return;
      }
      if (_searchController.text.isNotEmpty) {
        setState(() {
          _isDefault = false;
        });
      }
      if (_previousText == _searchController.text) {
        return;
      }
      _previousText = _searchController.text;
      _debouncedNotifyFilterChanged();
    });

    _sortAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _isAscending ? 0.75 : 0.0,
    );

    _checkIfDefault();
  }

  void _checkIfDefault() {
    final isDurationDefault = !_durationRangeInitialized ||
        (_durationRange.start == 0 && _durationRange.end == 180);
    final isContentTypeDefault = selectedContentTypes.isEmpty ||
        selectedContentTypes.length == contentTypes.length;
    final isDateDefault = startDate == null && endDate == null;
    final isSearchDefault = _searchController.text.isEmpty;
    final isSortDefault = !_isAscending;

    setState(() {
      _isDefault = isSearchDefault &&
          isDurationDefault &&
          isContentTypeDefault &&
          isDateDefault &&
          isSortDefault;
    });
  }

  void _debouncedNotifyFilterChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 3), () {
      widget.onFilterChanged(
        _searchController.text,
        selectedContentTypes,
        _durationRange,
        startDate,
        endDate,
        _isAscending,
      );
    });
  }

  @override
  void didUpdateWidget(FilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialContentTypes != widget.initialContentTypes ||
        oldWidget.initialSearchQuery != widget.initialSearchQuery ||
        oldWidget.initialDurationRange != widget.initialDurationRange ||
        oldWidget.initialStartDate != widget.initialStartDate ||
        oldWidget.initialEndDate != widget.initialEndDate ||
        oldWidget.initialIsAscending != widget.initialIsAscending) {
      setState(() {
        selectedContentTypes =
            Set<String>.from(widget.initialContentTypes ?? {});
        _searchController.text = widget.initialSearchQuery ?? '';
        _durationRange =
            widget.initialDurationRange ?? const RangeValues(0, 180);
        _durationRangeInitialized = widget.initialDurationRange != null;
        startDate = widget.initialStartDate;
        endDate = widget.initialEndDate;
        _isAscending = widget.initialIsAscending ?? false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sortAnimController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleContentTypeChange(String value) {
    setState(() {
      if (value == 'Text') {
        if (selectedContentTypes.contains('Text')) {
          selectedContentTypes.remove('Text');
        } else {
          selectedContentTypes.clear();
          selectedContentTypes.add('Text');
        }
      } else {
        selectedContentTypes.remove('Text');
        if (selectedContentTypes.contains(value)) {
          selectedContentTypes.remove(value);
        } else {
          selectedContentTypes.add(value);
        }
      }
      _checkIfDefault();
    });
    _debouncedNotifyFilterChanged();
  }

  void _handleDateChange(DateTime? date, bool isStart) {
    setState(() {
      if (isStart) {
        startDate = date;
      } else {
        endDate = date;
      }
      _checkIfDefault();
    });
    _debouncedNotifyFilterChanged();
  }

  void _handleDurationChange(RangeValues values) {
    setState(() {
      _durationRange = values;
      _durationRangeInitialized = true;
      _checkIfDefault();
    });
    _debouncedNotifyFilterChanged();
  }

  void _toggleSort() {
    setState(() {
      _isAscending = !_isAscending;
      if (_isAscending) {
        _sortAnimController.animateTo(1.0);
      } else {
        _sortAnimController.animateTo(0.0);
      }
      _checkIfDefault();
    });
    _debouncedNotifyFilterChanged();
  }

  void _resetFilters() {
    setState(() {
      startDate = null;
      endDate = null;
      selectedContentTypes = Set.from({});
      _searchController.text = '';
      _durationRange = const RangeValues(0, 180);
      _durationRangeInitialized = false;
      _isAscending = false;
      _sortAnimController.animateTo(0.0);
      _checkIfDefault();
    });
    _debouncedNotifyFilterChanged();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          key: _key,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainerHigh),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          color: Colors.grey.shade200,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axis: Axis.horizontal,
                              child: child,
                            ),
                          );
                        },
                        child: !_isDefault
                            ? TextButton.icon(
                                onPressed: _resetFilters,
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                icon: const Icon(Icons.restart_alt, size: 16),
                                label: const Text('Reset'),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (constraints.maxWidth > 900)
                  _buildWideLayout(constraints.maxWidth)
                else
                  _buildNarrowLayout(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(double maxWidth) {
    const spacing = 16.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        _buildFilterItem(
          'Search',
          _buildSearchField(),
        ),
        _buildFilterItem(
          'Start Date',
          _buildDateField(
            value: startDate,
            onChanged: (date) => _handleDateChange(date, true),
          ),
        ),
        _buildFilterItem(
          'End Date',
          _buildDateField(
            value: endDate,
            onChanged: (date) => _handleDateChange(date, false),
          ),
        ),
        _buildFilterItem(
          'Content Type',
          _buildContentTypeSelector(),
        ),
        _buildFilterItem(
          'Duration',
          _buildDurationSelector(),
        ),
      ],
    );
  }

  Widget _buildFilterItem(String label, Widget child) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          child,
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        _buildSearchField(),
        const SizedBox(height: 16.0),
        Text(
          'Start Date',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        _buildDateField(
          value: startDate,
          onChanged: (date) => _handleDateChange(date, true),
        ),
        const SizedBox(height: 16.0),
        Text(
          'End Date',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        _buildDateField(
          value: endDate,
          onChanged: (date) => _handleDateChange(date, false),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Content Type',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        _buildContentTypeSelector(),
        const SizedBox(height: 16.0),
        Text(
          'Duration',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        _buildDurationSelector(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _inputHeight,
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.grey.shade200),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: _inputHeight,
          width: _inputHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _toggleSort,
              child: RotationTransition(
                turns: Tween(begin: 1.0, end: 0.5).animate(_sortAnimController),
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.grey.shade200,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return SizedBox(
      height: _inputHeight,
      child: TextButton(
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(),
                child: child!,
              );
            },
          );
          if (date != null) {
            onChanged(date);
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value?.toString().split(' ')[0] ?? 'Select Date',
              style: TextStyle(
                color: value != null ? Colors.white : Colors.grey.shade500,
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeSelector() {
    return SizedBox(
      height: _inputHeight,
      child: PopupMenuButton<String>(
        onSelected: _handleContentTypeChange,
        itemBuilder: (BuildContext context) {
          return contentTypes.map((String value) {
            return PopupMenuItem<String>(
              value: value,
              enabled: true,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setItemState) {
                  return Row(
                    children: [
                      Checkbox(
                        value: selectedContentTypes.contains(value),
                        onChanged: (bool? checked) {
                          if (checked != null) {
                            setState(() {
                              setItemState(() {
                                if (value == 'Text') {
                                  if (checked) {
                                    selectedContentTypes.clear();
                                    selectedContentTypes.add('Text');
                                  } else {
                                    selectedContentTypes.remove('Text');
                                  }
                                } else {
                                  selectedContentTypes.remove('Text');
                                  if (selectedContentTypes.contains(value)) {
                                    selectedContentTypes.remove(value);
                                  } else {
                                    selectedContentTypes.add(value);
                                  }
                                }
                                _debouncedNotifyFilterChanged();
                                _checkIfDefault();
                              });
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(value,
                          style: TextStyle(color: Colors.grey.shade200)),
                    ],
                  );
                },
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedContentTypes.isEmpty
                    ? 'Select Types'
                    : selectedContentTypes.join(', '),
                style: TextStyle(
                  color: selectedContentTypes.isEmpty
                      ? Colors.grey.shade600
                      : Colors.grey.shade200,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    String formatDuration(double minutes) {
      if (!_durationRangeInitialized) return minutes == 0 ? 'min' : 'max';
      if (minutes == 0) return 'min';
      if (minutes == 180) return 'max';
      if (minutes >= 60) {
        final hours = (minutes / 60).floor();
        final mins = (minutes % 60).round();
        return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
      }
      return '${minutes.round()}m';
    }

    return SizedBox(
      height: _inputHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Stack(
          children: [
            SliderTheme(
              data: const SliderThemeData(
                showValueIndicator: ShowValueIndicator.never,
                rangeThumbShape: RoundRangeSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: 16,
                ),
              ),
              child: RangeSlider(
                values: _durationRange,
                min: 0,
                max: 180,
                divisions: 180,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.grey.shade700,
                onChanged: _handleDurationChange,
              ),
            ),
            Positioned(
              left: 4,
              bottom: 2,
              child: Text(
                formatDuration(_durationRange.start),
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 12,
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 2,
              child: Text(
                formatDuration(_durationRange.end),
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandableDescription extends ConsumerStatefulWidget {
  final String description;
  final int initialLines;

  const ExpandableDescription({
    super.key,
    required this.description,
    this.initialLines = 3,
  });

  @override
  ConsumerState<ExpandableDescription> createState() {
    return _ExpandableDescriptionState();
  }
}

class _ExpandableDescriptionState extends ConsumerState<ExpandableDescription> {
  final _textKey = GlobalKey();
  final String _uniqueId = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextOverflow();
    });
  }

  void _checkTextOverflow() {
    final textBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (textBox == null) return;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: widget.description,
        style: TextStyle(
          color: Theme.of(context).textTheme.titleMedium?.color,
          fontSize: 14,
        ),
      ),
      maxLines: widget.initialLines,
    )..layout(maxWidth: textBox.size.width);

    ref
        .read(expandableDescriptionProvider(_uniqueId).notifier)
        .setNeedsExpansion(painter.didExceedMaxLines);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expandableDescriptionProvider(_uniqueId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCrossFade(
          firstChild: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 14.0 * widget.initialLines * 1.5,
            ),
            child: ClipRect(
              child: Text(
                widget.description,
                key: _textKey,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontSize: 14,
                ),
                maxLines: widget.initialLines,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          secondChild: Text(
            widget.description,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontSize: 14,
            ),
          ),
          crossFadeState: state.expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (state.needsExpansion)
          TextButton(
            onPressed: () {
              ref
                  .read(expandableDescriptionProvider(_uniqueId).notifier)
                  .setExpanded(!state.expanded);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.expanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Icon(
                  state.expanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class CommentItem extends ConsumerStatefulWidget {
  final CommentModel comment;
  final ContentPostV3Response content;
  final Function(String)? onReply;

  const CommentItem({
    super.key,
    required this.comment,
    required this.content,
    this.onReply,
  });

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem> {
  bool _isEditing = false;
  late TextEditingController _editController;
  late String _commentText;
  bool _showReplyBox = false;
  bool _isLiked = false;
  bool _isDisliked = false;
  int _likeCount = 0;
  int _dislikeCount = 0;
  final _replyController = TextEditingController();
  final _focusNode = FocusNode();
  int _currentLength = 0;

  void _updateCharCount() {
    setState(() {
      _currentLength = _replyController.text.length;
    });
  }

  @override
  void initState() {
    super.initState();
    _commentText = widget.comment.text;
    _editController = TextEditingController(text: _commentText);
    _likeCount = widget.comment.likes;
    _replyController.addListener(_updateCharCount);
  }

  @override
  void dispose() {
    _editController.dispose();
    _replyController.removeListener(_updateCharCount);
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleEditSubmit() async {
    if (_editController.text.trim().length >= 3 &&
        _editController.text.trim().length <= 1500) {
      try {
        final editedComment = await fpApiRequests.editComment(
            widget.comment.id, _editController.text.trim());

        if (editedComment == 'OK') {
          if (mounted) {
            setState(() {
              _commentText = _editController.text.trim();
              _isEditing = false;
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to edit comment')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to edit comment: $e')),
          );
        }
      }
    }
  }

  void _toggleReplyBox() {
    setState(() {
      _showReplyBox = !_showReplyBox;
      if (_showReplyBox) {
        _replyController.text = '@${widget.comment.user.username} ';
        Future.delayed(Duration.zero, () => _focusNode.requestFocus());
      }
    });
  }

  void _handleReply() {
    if (_replyController.text.length >= 3 &&
        _replyController.text.length <= 1500) {
      if (widget.onReply != null) {
        widget.onReply!(_replyController.text);
      }
      setState(() {
        _showReplyBox = false;
      });
      _replyController.clear();
    }
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

  String formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    int hour = dateTime.hour % 12;
    hour = hour == 0 ? 12 : hour;

    return '${months[dateTime.month - 1]} ${dateTime.day.toString().padLeft(2, '0')}, ${dateTime.year} '
        '$hour:${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                    widget.comment.user.id != widget.content.creator?.owner
                        ? widget.comment.user.profileImage.path != null &&
                                (widget.comment.user.profileImage.path ?? '')
                                    .isNotEmpty
                            ? CachedNetworkImageProvider(
                                widget.comment.user.profileImage.path ?? '')
                            : AssetImage('assets/placeholder.png')
                        : widget.content.channel?.icon?.path != null &&
                                (widget.content.channel?.icon?.path ?? '')
                                    .isNotEmpty
                            ? CachedNetworkImageProvider(
                                widget.content.channel?.icon?.path ?? '')
                            : AssetImage('assets/placeholder.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.comment.user.id !=
                            widget.content.creator?.owner)
                          Text(
                            widget.comment.user.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (widget.comment.user.id ==
                            widget.content.creator?.owner)
                          Text(
                            widget.content.channel?.title ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (widget.comment.user.id ==
                            widget.content.creator?.owner)
                          Tooltip(
                            message: 'Creator',
                            child: const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ),
                        if (widget.comment.user.id ==
                            widget.content.creator?.owner)
                          const SizedBox(width: 8),
                        Tooltip(
                          message:
                              'Posted on ${formatDateTime(widget.comment.postDate)}',
                          child: Text(
                            getRelativeTime(widget.comment.postDate),
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          ),
                        ),
                        if (widget.comment.isEdited) const SizedBox(width: 8),
                        if (widget.comment.isEdited)
                          Tooltip(
                            message: widget.comment.editDate != null
                                ? 'Comment was edited ${widget.comment.editCount} times. Last edited on ${formatDateTime(widget.comment.editDate!)}'
                                : 'Comment was edited ${widget.comment.editCount} times',
                            child: Text(
                              '<edited>',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ),
                        if (widget.comment.pinDate != null)
                          const SizedBox(width: 8),
                        if (widget.comment.pinDate != null)
                          Tooltip(
                            message:
                                'Pinned on ${formatDateTime(widget.comment.pinDate!)}',
                            child: Icon(
                              Icons.push_pin,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                          ),
                        Spacer(),
                        if (widget.comment.user.id ==
                            rootLayoutKey.currentState?.user?.id)
                          MenuAnchor(
                            style: MenuStyle(
                              padding:
                                  WidgetStatePropertyAll(EdgeInsets.all(5)),
                              minimumSize: WidgetStatePropertyAll(Size.zero),
                            ),
                            menuChildren: [
                              MenuItemButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                    _editController.text = _commentText;
                                  });
                                },
                                child: const Text('Edit'),
                              ),
                              MenuItemButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      return AlertDialog(
                                        title: const Text('Delete Comment'),
                                        content: const Text(
                                            'Are you sure you want to delete this comment?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(dialogContext)
                                                    .pop(),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              var res = await fpApiRequests
                                                  .deleteComment(
                                                      widget.comment.id);

                                              if (res == 'OK') {
                                                if (mounted) {
                                                  setState(() {
                                                    _commentText =
                                                        'This comment has been deleted.';
                                                  });
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Failed to delete comment'),
                                                    ),
                                                  );
                                                }
                                              }

                                              if (context.mounted) {
                                                Navigator.of(dialogContext)
                                                    .pop();
                                              }
                                            },
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                            builder: (BuildContext context,
                                MenuController controller, Widget? child) {
                              return IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.more_vert, size: 17.0),
                                onPressed: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                },
                              );
                            },
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    _isEditing
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _editController,
                                maxLength: 1500,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                  hintText: 'Edit your comment',
                                  border: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey[800]!),
                                  ),
                                  counterText: '',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Text(
                                      '${_editController.text.length}/1500',
                                      style: TextStyle(
                                        color:
                                            _editController.text.length > 1500
                                                ? Colors.red
                                                : Colors.grey[400],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _isEditing = false),
                                      child: const Text('CANCEL'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed:
                                          _editController.text.trim().length >=
                                                      3 &&
                                                  _editController.text
                                                          .trim()
                                                          .length <=
                                                      1500
                                              ? _handleEditSubmit
                                              : null,
                                      child: const Text('SAVE'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ExpandableDescription(
                            description: _commentText,
                            initialLines: 6,
                          ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                            minimumSize: const Size(0, 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                          ),
                          icon: AnimatedTheme(
                            data: Theme.of(context).copyWith(
                              iconTheme: IconThemeData(
                                size: 16,
                                color: _isLiked
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.thumb_up_outlined),
                          ),
                          label: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 12,
                              color: _isLiked
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            child: Text('$_likeCount'),
                          ),
                          onPressed: () async {
                            final res = await fpApiRequests.likeComment(
                                widget.comment.id, widget.content.id!);
                            if (res == 'success') {
                              setState(() {
                                if (_isLiked) {
                                  _likeCount--;
                                  _isLiked = false;
                                } else {
                                  _likeCount++;
                                  if (_isDisliked) {
                                    _dislikeCount--;
                                    _isDisliked = false;
                                  }
                                  _isLiked = true;
                                }
                              });
                            } else if (res == 'removed') {
                              setState(() {
                                _likeCount--;
                                _isLiked = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 5),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                            minimumSize: const Size(0, 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                          ),
                          icon: AnimatedTheme(
                            data: Theme.of(context).copyWith(
                              iconTheme: IconThemeData(
                                size: 16,
                                color: _isDisliked
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.thumb_down_outlined),
                          ),
                          label: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 12,
                              color: _isDisliked
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            child: Text('$_dislikeCount'),
                          ),
                          onPressed: () async {
                            final res = await fpApiRequests.dislikeComment(
                                widget.comment.id, widget.content.id!);
                            if (res == 'success') {
                              setState(() {
                                if (_isDisliked) {
                                  _dislikeCount--;
                                  _isDisliked = false;
                                } else {
                                  _dislikeCount++;
                                  if (_isLiked) {
                                    _likeCount--;
                                    _isLiked = false;
                                  }
                                  _isDisliked = true;
                                }
                              });
                            } else if (res == 'removed') {
                              setState(() {
                                _dislikeCount--;
                                _isDisliked = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: _toggleReplyBox,
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                            minimumSize: const Size(0, 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                          ),
                          child: Text(
                            'REPLY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _replyController,
                    focusNode: _focusNode,
                    maxLength: 1500,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Write a reply',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _handleReply(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '$_currentLength/1500',
                          style: TextStyle(
                            color: _currentLength > 1500
                                ? Colors.red
                                : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showReplyBox = false),
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed:
                              _currentLength >= 3 && _currentLength <= 1500
                                  ? _handleReply
                                  : null,
                          style: TextButton.styleFrom(
                            splashFactory: InkRipple.splashFactory,
                            overlayColor: Colors.grey[800],
                          ),
                          child: Text(
                            'REPLY',
                            style: TextStyle(
                              color:
                                  _currentLength >= 3 && _currentLength <= 1500
                                      ? Colors.white
                                      : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _showReplyBox
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    ));
  }
}

class CommentHolder extends ConsumerStatefulWidget {
  final CommentModel comment;
  final ContentPostV3Response content;

  const CommentHolder({
    super.key,
    required this.comment,
    required this.content,
  });

  @override
  ConsumerState<CommentHolder> createState() => _CommentHolderState();
}

class ShowInfoCard extends StatelessWidget {
  final String preshowtime;
  final String mainshowtime;
  final String preshowlength;
  final String mainshowlength;
  final String lateness;
  final bool late;

  const ShowInfoCard({
    super.key,
    required this.preshowtime,
    required this.mainshowtime,
    required this.preshowlength,
    required this.mainshowlength,
    required this.lateness,
    required this.late,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: late ? Colors.red : Colors.green),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AutoSizeText(
              "Show Info from Whenplane",
              textScaleFactor: 1.15,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 15,
              children: [
                _buildShowSection("Pre Show", preshowtime, preshowlength),
                _buildShowSection("Main Show", mainshowtime, mainshowlength),
              ],
            ),
            Divider(),
            SizedBox(height: 3),
            AutoSizeText(
              late
                  ? lateness
                  : lateness == '0s'
                      ? 'On time!'
                      : '$lateness early',
              textScaleFactor: 1.05,
              style: TextStyle(
                color: late ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowSection(String title, String time, String duration) {
    return Column(
      children: [
        AutoSizeText(
          title,
          textScaleFactor: 1.15,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        AutoSizeText(
          time,
          textScaleFactor: 1.02,
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4),
        AutoSizeText(
          duration,
          textScaleFactor: 1.02,
        ),
      ],
    );
  }
}

class _CommentHolderState extends ConsumerState<CommentHolder> {
  late List<CommentModel> _replies;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _replies = widget.comment.replies ?? [];
  }

  Future<void> _loadMoreReplies() async {
    setState(() {
      _isLoadingMore = true;
    });

    await fpApiRequests
        .getReplies(
      widget.comment.id,
      widget.content.id!,
      5,
      _replies.last.id,
    )
        .then((replies) {
      setState(() {
        _replies.addAll(replies);
        _isLoadingMore = false;
      });
    });
  }

  Future<CommentModel> sendreply(
      String blogPost, String replyTo, String text) async {
    final reply = await fpApiRequests.comment(blogPost, text, replyto: replyTo);

    setState(() {
      _replies.insert(
          0,
          CommentModel(
            id: reply!.id,
            blogPost: reply.blogPost,
            user: reply.user,
            text: reply.text,
            replying: reply.replying,
            postDate: reply.postDate,
            editDate: reply.editDate,
            pinDate: reply.pinDate,
            editCount: reply.editCount,
            isEdited: reply.isEdited,
            likes: reply.likes,
            dislikes: reply.dislikes,
            score: reply.score,
            interactionCounts: reply.interactionCounts,
            totalReplies: reply.totalReplies,
            replies: reply.replies,
            userInteraction: reply.userInteraction,
          ));
    });
    return reply!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentItem(
          comment: widget.comment,
          content: widget.content,
          onReply: (text) {
            sendreply(widget.content.id!, widget.comment.id, text);
          },
        ),
        if (_replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._replies.map((reply) => CommentItem(
                      key: ValueKey(reply.id),
                      comment: reply,
                      content: widget.content,
                      onReply: (text) {
                        sendreply(widget.content.id!, widget.comment.id, text);
                      },
                    )),
                if ((widget.comment.totalReplies ?? 0) > _replies.length)
                  TextButton(
                    onPressed: _isLoadingMore ? null : _loadMoreReplies,
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(),
                          )
                        : Text(
                            'Show ${min(5, (widget.comment.totalReplies ?? 0) - _replies.length)} more ${((widget.comment.totalReplies ?? 0) - _replies.length) == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

enum CardState { initial, expanded }

class StateCard extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final Widget thumbnail;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool isViewing;
  final bool isSelected;
  final Widget? topIcon;

  const StateCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.thumbnail,
    this.onTap,
    this.width = 160,
    this.height = 90,
    this.isViewing = false,
    this.isSelected = false,
    this.topIcon,
  });

  @override
  ConsumerState<StateCard> createState() => _StateCardState();
}

class _StateCardState extends ConsumerState<StateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: widget.isSelected
                  ? Border.all(
                      color: Colors.blue,
                      width: 2,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail
                  widget.thumbnail,

                  // Viewing overlay
                  if (widget.isViewing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: Text(
                          'Viewing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Top icon
                  if (widget.topIcon != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: widget.topIcon!,
                      ),
                    ),

                  // Title and subtitle at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hover overlay
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatefulWidget {
  final String? message;
  const ErrorScreen({super.key, this.message});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool revealed = false;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Image(
            image: AssetImage('assets/error.png'),
            width: 200,
          ),
          const SizedBox(height: 16),
          const Text(
            'Well this is embarrassing.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const Text('An error has occurred.',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            if (!revealed)
              TextButton(
                  onPressed: () {
                    setState(() => revealed = true);
                  },
                  child: const Text('More Details')),
            if (revealed)
              Text(
                widget.message ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ]
        ],
      ),
    );
  }
}

class WhenplaneScreen extends StatefulWidget {
  const WhenplaneScreen({super.key, this.v = false, this.h});
  final bool v;
  final double? h;

  @override
  State<WhenplaneScreen> createState() => _WhenplaneScreenState();
}

class _WhenplaneScreenState extends State<WhenplaneScreen> {
  // Countdown timer
  Timer? _timer;
  String phrase = whenPlaneIntegration.newPhrase();
  late String jsonData;
  late String latenessData;
  bool isLoading = true;

  bool votingrevealed = true;
  String? selectedVote;
  late String k;

  @override
  void initState() {
    super.initState();
    loadSelectedVote();
    websocketStart();
    initFetch();
  }

  void initFetch() async {
    jsonData = await whenPlaneIntegration.aggregate();
    latenessData = await whenPlaneIntegration.lateness();
    setState(() {
      isLoading = false;
    });
  }

  void websocketStart() async {
    final stream = whenPlaneIntegration.streamWebsocket();
    stream.listen((message) {
      if (message != 'pong') {
        if (mounted) {
          setState(() {
            jsonData = message;
          });
        }
      }
    });
  }

  Future<void> loadSelectedVote() async {
    settings.getKey('votedname').then((value) {
      setState(() {
        selectedVote = value;
      });
    });
  }

  late dynamic platenessData;
  late dynamic pjsonData;

  bool isMainLate = false;
  String countdownString = '';
  bool isAfterStartTime = false;
  DateTime nextWan = whenPlaneIntegration.getNextWAN(DateTime.now());
  String sscountdownText = '';
  bool isSSlate = false;
  bool showPlayed = false;
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isLoading) return;
      bool isPreShow = pjsonData != null
          ? !(pjsonData['youtube']?['isLive'] ?? false) &&
              (pjsonData['twitch']?['isWAN'] ??
                  false || (pjsonData['floatplane']?['isWAN'] ?? false))
          : false;

      bool isMainShow = pjsonData != null
          ? (pjsonData['youtube']?['isWAN'] ?? false) &&
              (pjsonData['youtube']?['isLive'] ?? false)
          : false;
      if (pjsonData['specialStream'] != false &&
          pjsonData['specialStream'] != null) {
        final timeUntil = whenPlaneIntegration
            .getTimeUntil(DateTime.parse(pjsonData['specialStream']?['start']));

        sscountdownText = timeUntil['string'];
        isSSlate = timeUntil['late'];
      }
      if (isMainShow || isPreShow) {
        if (!isMainShow && isPreShow && pjsonData['floatplane']?['isLive']) {
          final mainScheduledStart =
              whenPlaneIntegration.getClosestWan(DateTime.now());
          setState(() {
            isMainLate = true;
            countdownString =
                whenPlaneIntegration.getTimeUntil(mainScheduledStart)['string'];
          });
        } else {
          setState(() {
            isMainLate = false;
          });
        }

        DateTime started = DateTime.parse(pjsonData['floatplane']?['started'] ??
            pjsonData['youtube']?['started'] ??
            '');

        isAfterStartTime = true;
        showPlayed = true;
        countdownString = whenPlaneIntegration.getTimeUntil(started)['string'];
      } else {
        if (showPlayed) {
          showPlayed = false;
          nextWan = whenPlaneIntegration.getNextWAN(DateTime.now(),
              hasDone: pjsonData['hasDone']);
        }

        final timeUntil = whenPlaneIntegration.getTimeUntil(nextWan);
        countdownString = timeUntil['string'];
        isAfterStartTime = timeUntil['late'];

        if (timeUntil['late']) {
          setState(() {
            isMainLate = true;
            countdownString = timeUntil['string'];
          });
        }
      }
      if (mounted) {
        setState(() {});
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      pjsonData = jsonDecode(jsonData);
      platenessData = jsonDecode(latenessData);
    }
    k = generateK();
    final day = DateTime.now().toUtc().weekday;
    final dayIsCloseEnough = day == 5 || day == 6;
    _startTimer();
    return isLoading
        ? Container(
            color: widget.v ? Colors.black : null,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Container(
            color: widget.v ? Colors.black : null,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (pjsonData['specialStream'] != false)
                    _buildSpecialStreamCard(),
                  const SizedBox(height: 12.0),
                  if (!pjsonData['floatplane']?['isLive'] &&
                      pjsonData['floatplane']?['isWAN'] &&
                      ((dayIsCloseEnough &&
                              (pjsonData['floatplane']?['isThumbnailNew'] ||
                                  pjsonData['floatplane']?['thumbnailAge'] <
                                      24 * 60 * 60e3)) &&
                          !pjsonData['hasDone']))
                    _buildShowMightStartSoonAlert(),
                  const SizedBox(height: 12.0),
                  _buildCountdownCard(),
                  const SizedBox(height: 12.0),
                  _buildPlatformStatusContainer(),
                  const SizedBox(height: 12.0),
                  _buildLatenessStats(),
                  const SizedBox(height: 3.0),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      launchUrl(Uri.parse('https://whenplane.com'));
                    },
                    child: Text('Data provided by Whenplane',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  const SizedBox(height: 12.0),
                  if (pjsonData['isThereWan']['text'] != null)
                    _buildSpecialAlert(),
                  const SizedBox(height: 12.0),
                  if (pjsonData['hasDone'] == false) _buildLatenessVoting(),
                ],
              ),
            ),
          );
  }

  Widget _buildSpecialStreamCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = 450.0;
        final width =
            constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth;
        final height = width * 9 / 16;

        return Center(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12.0),
              image: DecorationImage(
                image: NetworkImage(
                  pjsonData['specialStream']['thumbnail'],
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.7),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special Stream',
                    style: TextStyle(
                      fontSize: width * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    pjsonData['specialStream']['title'],
                    style: TextStyle(
                      fontSize: width * 0.04,
                      color: Colors.grey[300],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Center(
                    heightFactor: 1.388,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildPlatformIndicator(
                            'Floatplane',
                            pjsonData['specialStream']['onFloatplane'] == true,
                            width * 0.035),
                        SizedBox(height: height * 0.01),
                        _buildPlatformIndicator(
                            'Twitch',
                            pjsonData['specialStream']['onTwitch'] == true,
                            width * 0.035),
                        SizedBox(height: height * 0.01),
                        _buildPlatformIndicator(
                            'YouTube',
                            pjsonData['specialStream']['onYoutube'] == true,
                            width * 0.035),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pjsonData['floatplane']['isLive']
                                  ? 'Currently Live'
                                  : isSSlate
                                      ? '$sscountdownText $phrase'
                                      : sscountdownText,
                              style: TextStyle(
                                fontSize: width * 0.045,
                                fontWeight: FontWeight.bold,
                                color: pjsonData['floatplane']['isLive']
                                    ? Colors.green
                                    : isSSlate
                                        ? Colors.red
                                        : Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (pjsonData['specialStream']['isEstimated'] ==
                                true)
                              const SizedBox(width: 6),
                            if (pjsonData['specialStream']['isEstimated'] ==
                                true)
                              Tooltip(
                                message: 'estimated',
                                child: Icon(Icons.info_outline,
                                    size: width * 0.040),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlatformIndicator(
      String platform, bool isAvailable, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$platform:',
          style: TextStyle(
            fontSize: fontSize,
          ),
        ),
        const SizedBox(width: 8.0),
        Icon(
          isAvailable ? Icons.check_circle : Icons.cancel,
          color: isAvailable ? Colors.green : Colors.red,
          size: fontSize + 2,
        ),
      ],
    );
  }

  Widget _buildCountdownCard() {
    bool isPreShow = pjsonData != null
        ? !(pjsonData['youtube']?['isLive'] ?? false) &&
            (pjsonData['twitch']?['isWAN'] ??
                false || (pjsonData['floatplane']?['isWAN'] ?? false))
        : false;

    bool isMainShow = pjsonData != null
        ? (pjsonData['youtube']?['isWAN'] ?? false) &&
            (pjsonData['youtube']?['isLive'] ?? false)
        : false;

    // bool preShowStarted = pjsonData['twitch']['started'] != null;

    bool mainShowStarted = pjsonData['youtube']['started'] != null;

    bool isLate = isAfterStartTime && !isPreShow && !isMainShow;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display text based on the state
          if (isLate)
            AutoSizeText.rich(
              TextSpan(
                text: 'The WAN show is currently',
                style: TextStyle(fontSize: 16.0),
                children: [
                  TextSpan(
                    text: ' late',
                    style: TextStyle(fontSize: 16.0, color: Colors.red),
                  ),
                  TextSpan(
                    text: ' by',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
              maxLines: 2,
            )
          else if (isMainShow)
            AutoSizeText(
              'The WAN show has been live for',
              style: TextStyle(fontSize: 16.0),
              maxLines: 2,
            )
          else if (pjsonData['floatplane']['isLive'] &&
              pjsonData['floatplane']['isWAN'] &&
              !pjsonData['twitch']['isLive'])
            AutoSizeText(
              'The pre-pre-show has been live for',
              style: TextStyle(fontSize: 16.0),
              maxLines: 2,
            )
          else if (isPreShow)
            AutoSizeText(
              'The pre-show has been live for',
              style: TextStyle(fontSize: 16.0),
              maxLines: 2,
            )
          else
            AutoSizeText(
              'The WAN show is (supposed) to start in',
              style: TextStyle(fontSize: 16.0),
              maxLines: 2,
            ),
          AutoSizeText(
            '$countdownString ${isLate ? phrase : ''}',
            minFontSize: 16.0,
            style: TextStyle(
              fontSize: 50.0,
              color:
                  isLate ? Colors.red : Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            textScaleFactor: 1,
            maxLines: 1,
          ),

          if (!isAfterStartTime && !isMainShow) ...[
            AutoSizeText(
              'Next WAN: ${DateFormat('MM/dd/yyyy HH:mm:ss').format(whenPlaneIntegration.getNextWAN(DateTime.now()).toLocal())}',
              minFontSize: 8.0,
              maxLines: 1,
            ),
          ] else if (isLate) ...[
            const AutoSizeText(
                'It usually actually starts between 1 and 3 hours late.',
                maxLines: 2),
          ] else if ((isMainShow && mainShowStarted) || isPreShow) ...[
            AutoSizeText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: isPreShow
                        ? 'Pre-show started '
                        : (pjsonData['floatplane']['isLive'] &&
                                pjsonData['floatplane']['isWAN'] &&
                                !pjsonData['twitch']['isLive'])
                            ? 'Pre-pre-show started '
                            : 'Started ',
                  ),
                  const TextSpan(text: 'at '),
                  if (mounted)
                    TextSpan(
                      text: (() {
                        final raw = pjsonData['youtube']['started'] ??
                            pjsonData['twitch']['started'] ??
                            pjsonData['floatplane']['started'];
                        final parsed = DateTime.tryParse(raw ?? '');
                        if (parsed == null) return 'unknown time';
                        final formatter = DateFormat('HH:mm:ss');
                        return formatter.format(parsed.toLocal());
                      })(),
                      style: const TextStyle(fontSize: 16.0),
                    ),
                ],
              ),
              maxLines: 1,
            )
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformStatusContainer() {
    return Wrap(
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        _buildPlatformStatus(
          icon: SimpleIcons.twitch,
          platform: "Twitch",
          status: pjsonData['twitch']['isLive']
              ? pjsonData['twitch']['isWAN']
                  ? '(live)'
                  : '(live non-WAN)'
              : '(offline)',
          isLive: pjsonData['twitch']['isLive'],
        ),
        _buildPlatformStatus(
          icon: SimpleIcons.youtube,
          isUpcoming: pjsonData['youtube']['upcoming'],
          platform: "Youtube",
          status: pjsonData['youtube']['isLive']
              ? pjsonData['youtube']['isWAN']
                  ? '(live)'
                  : '(live non-WAN)'
              : '(offline)',
          isLive: pjsonData['youtube']['isLive'],
        ),
        _buildPlatformStatus(
          icon: SimpleIcons.floatplane,
          platform: "Floatplane",
          status: pjsonData['floatplane']['isLive']
              ? pjsonData['floatplane']['isWAN']
                  ? '(live)'
                  : '(live non-WAN)'
              : '(offline)',
          isLive: pjsonData['floatplane']['isLive'],
        ),
      ],
    );
  }

  Widget _buildPlatformStatus({
    required IconData icon,
    required String platform,
    required String status,
    required bool isLive,
    bool isUpcoming = false,
  }) {
    Color statusColor = isLive
        ? Colors.green
        : (isUpcoming ? Colors.yellow[700]! : Colors.grey);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Icon(icon, size: 45),
            ],
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                platform,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
                textScaleFactor: 1.0,
                maxLines: 1,
                minFontSize: 2.0,
              ),
              AutoSizeText(
                isUpcoming ? '(upcoming)' : status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12.0,
                ),
                minFontSize: 2.0,
                textScaleFactor: 1.0,
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatenessStats() {
    return Wrap(
      runSpacing: 8.0,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          child: Column(
            children: [
              const Text(
                'Average lateness',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'from the last 5 shows',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '${whenPlaneIntegration.timeString(
                  (platenessData['averageLateness'] as num).abs().toInt(),
                )} $phrase',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      '± ${whenPlaneIntegration.timeString(
                        (platenessData['latenessStandardDeviation'] as num)
                            .abs()
                            .toInt(),
                      )}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  const Tooltip(
                    message:
                        '''Think of standard deviation as a measure that tells you how much individual values in a set typically differ from the average of that set. If the standard deviation is small, it means most values are close to the average. If it's large, it means values are more spread out from the average, indicating greater variability in the data. Essentially, standard deviation gives you an idea of how consistent or varied the values are in relation to the average.''',
                    child: Icon(Icons.info_outline, size: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          child: Column(
            children: [
              const Text(
                'Median lateness',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'from the last 5 shows',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '${whenPlaneIntegration.timeString(
                  (platenessData['medianLateness'] as num).abs().toInt(),
                )} $phrase',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 17,
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShowMightStartSoonAlert() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.green[900],
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Wrap(
        spacing: 8.0,
        direction: Axis.horizontal,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 175,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: NetworkImage(
                      pjsonData['floatplane']['thumbnail'],
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pjsonData['floatplane']?['isThumbnailNew'])
                AutoSizeText(
                  maxLines: 1,
                  'The show might start soon!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              AutoSizeText(
                '"${pjsonData['floatplane']['title'].split(' - ')[0]}"',
                maxLines: 2,
                style: TextStyle(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
              AutoSizeText.rich(
                maxLines: 2,
                TextSpan(
                  text: 'The thumbnail was updated',
                  children: [
                    TextSpan(
                      text:
                          pjsonData['floatplane']?['isThumbnailNew'] ? "" : ",",
                    ),
                    TextSpan(
                      text: pjsonData['floatplane']?['isThumbnailNew']
                          ? ""
                          : " but they haven't gone live yet.",
                    ),
                  ],
                ),
              ),
              AutoSizeText.rich(
                maxLines: 2,
                TextSpan(
                  text: pjsonData['floatplane']?['isThumbnailNew']
                      ? ""
                      : "It was updated",
                  children: [
                    TextSpan(
                      text:
                          ' ${whenPlaneIntegration.timeString(pjsonData['floatplane']?['thumbnailAge'], long: true, showSeconds: false)}ago',
                    ),
                  ],
                ),
              ),
              Tooltip(
                message:
                    'Generally when a thumbnail is uploaded, all hosts are in their seats ready to start the show.\nUsually the show starts within 10 minutes of a thumbnail being uploaded.',
                child: Icon(Icons.info_outline, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialAlert() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber[900],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        Text(
          pjsonData['isThereWan']['text'],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14.0,
          ),
        ),
        if (pjsonData['isThereWan']['image'] != null)
          const SizedBox(height: 8.0),
        if (pjsonData['isThereWan']['image'] != null)
          Image.network(
            pjsonData['isThereWan']['image'],
            width: 400,
            fit: BoxFit.contain,
          ),
      ]),
    );
  }

  String generateK() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final base64 = base64Encode(utf8.encode(timestamp));
    return base64.replaceAll('=', '');
  }

  Widget _buildLatenessVoting() {
    // Calculate total votes
    int totalVotes = 0;
    for (var vote in pjsonData['votes']) {
      totalVotes += (vote['votes'] as int);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lateness Voting',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: votingrevealed
                  ? Icon(Icons.keyboard_arrow_up)
                  : Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                setState(() {
                  votingrevealed = !votingrevealed;
                });
              },
            ),
          ],
        ),
        if (votingrevealed) const SizedBox(height: 8.0),
        if (votingrevealed)
          const Row(
            children: [
              Text('How late do you think the show will be?'),
              SizedBox(width: 4.0),
              Tooltip(
                message:
                    'Lateness voting starts every Friday at midnight UTC, and runs until the show starts.',
                child: Icon(Icons.info_outline, size: 16.0),
              ),
            ],
          ),
        if (votingrevealed) const SizedBox(height: 16.0),
        // Voting options
        if (votingrevealed)
          ...pjsonData['votes'].map((vote) {
            // Calculate percentage
            double percentage = (vote['votes'] as int) / totalVotes * 100;
            String percentageText =
                percentage > 0 ? "${(percentage).toInt()}%" : "0%";
            String voteText = vote['name'] as String;

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                whenPlaneIntegration.sendVote(voteText, generateK());
                settings.setKey('votedname', voteText);

                setState(() {
                  selectedVote = vote['name'];
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$voteText ${selectedVote == voteText ? '(your vote)' : ''}',
                          style: TextStyle(
                            color: ((whenPlaneIntegration.getTimeUntil(nextWan,
                                                now: nextWan)['distance'] ??
                                            0)
                                        .abs()) >
                                    (vote['time'] ?? 0)
                                ? Colors.grey
                                : Colors.white,
                            decoration: ((whenPlaneIntegration.getTimeUntil(
                                                nextWan,
                                                now: nextWan)['distance'] ??
                                            0)
                                        .abs()) >
                                    (vote['time'] ?? 0)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(percentageText),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LinearProgressIndicator(
                        value: percentage > 0 ? percentage / 100 : 0,
                        backgroundColor: Colors.grey[700],
                        color: ((whenPlaneIntegration.getTimeUntil(nextWan,
                                            now: nextWan)['distance'] ??
                                        0)
                                    .abs()) >
                                (vote['time'] ?? 0)
                            ? Colors.grey[800]
                            : Theme.of(context).colorScheme.primary,
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}

class WhenplaneCompactHolder extends StatelessWidget {
  const WhenplaneCompactHolder(this.onWPExit, {super.key});
  final VoidCallback onWPExit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          toolbarHeight: 40,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          surfaceTintColor: Theme.of(context).appBarTheme.backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              onWPExit();
            },
          ),
          title: Text("Whenplane Statistics", style: TextStyle(fontSize: 18))),
      body: WhenplaneScreen(),
    );
  }
}

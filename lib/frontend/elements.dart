// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'dart:math';

import 'package:floaty/frontend/root.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:floaty/backend/state_mgmt.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:floaty/backend/fpapi.dart';

class SidebarSizeControl extends StatelessWidget {
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
    Key? key,
    required this.title,
    required this.isSidebarCollapsed,
    required this.isSmallScreen,
    required this.showText,
  }) : super(key: key);

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
  Widget build(BuildContext context) {
    return ListTile(
      selected: GoRouterState.of(context).uri.path == route,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          width: 24,
          height: 24,
          imageUrl: picture,
        ),
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
                  color: Colors.white,
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
                  color: Colors.grey.shade400,
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

class BlogPostCard extends StatelessWidget {
  final BlogPostModelV3 blogPost;
  final GetProgressResponse? response;

  const BlogPostCard(this.blogPost, {this.response, super.key});

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
    if (response != null) {
      progressValue = response?.progress ?? 0;
      computedValue = (progressValue / 100).clamp(0.0, 1.0);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/post/${blogPost.id}'),
        child: OverflowBox(
          maxHeight: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final iconSize = constraints.maxWidth * 0.08;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: blogPost.thumbnail?.path != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          blogPost.thumbnail?.path ?? ''),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: blogPost.thumbnail?.path == null
                                ? const ClipRRect(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)),
                                    child: GradientPlaceholder(),
                                  )
                                : null,
                          ),
                          if (blogPost.metadata?.hasAudio != false ||
                              blogPost.metadata?.hasVideo != false)
                            Positioned(
                              bottom: response != null ? 12 : 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  blogPost.metadata?.hasVideo == true
                                      ? formatDuration(blogPost
                                              .metadata?.videoDuration
                                              ?.toInt() ??
                                          0)
                                      : formatDuration(blogPost
                                              .metadata?.audioDuration
                                              ?.toInt() ??
                                          0),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: constraints.maxWidth * 0.04,
                                  ),
                                ),
                              ),
                            ),
                          if (response != null)
                            Positioned(
                              bottom: 2.5,
                              left: 10,
                              right: 10,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  backgroundColor:
                                      Colors.black.withValues(alpha: 0.7),
                                  color: Theme.of(context).colorScheme.primary,
                                  minHeight: 5,
                                  value: computedValue,
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: response != null ? 12 : 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                blogPost.metadata?.hasVideo == true
                                    ? 'Video'
                                    : blogPost.metadata?.hasAudio == true
                                        ? 'Audio'
                                        : blogPost.metadata?.hasPicture == true
                                            ? 'Image'
                                            : blogPost.metadata?.hasGallery ==
                                                    true
                                                ? 'Gallery'
                                                : 'Text',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: constraints.maxWidth * 0.04,
                                ),
                              ),
                            ),
                          ),
                          if (blogPost.isAccessible == false)
                            Center(
                              child: Container(
                                padding:
                                    EdgeInsets.all(constraints.maxWidth * 0.06),
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
                    ),
                    SizedBox(
                      height: constraints.maxWidth * 0.3,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipOval(
                              child: blogPost.channel is ChannelModel
                                  ? CachedNetworkImage(
                                      imageUrl:
                                          blogPost.channel?.icon?.path ?? '',
                                      width: iconSize,
                                      height: iconSize,
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    blogPost.title ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: constraints.maxWidth * 0.047,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${blogPost.channel is ChannelModel ? blogPost.channel?.title ?? '' : blogPost.creator.title ?? ''} • ${getRelativeTime(blogPost.releaseDate ?? DateTime.now())}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: constraints.maxWidth * 0.04,
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
              );
            },
          ),
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
  _CreatorCardState createState() => _CreatorCardState();
}

class _CreatorCardState extends State<CreatorCard> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: Colors.grey[850],
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
                          color: Colors.white,
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

class FilterPanel extends StatefulWidget {
  final Function(String, Set<String>, RangeValues, DateTime?, DateTime?, bool)
      onFilterChanged;
  final Set<String>? initialContentTypes;
  final String? initialSearchQuery;
  final RangeValues? initialDurationRange;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool? initialIsAscending;
  final Function(Size)? onSizeChanged;
  final double? parentWidth;

  const FilterPanel({
    Key? key,
    required this.onFilterChanged,
    this.initialContentTypes,
    this.initialSearchQuery,
    this.initialDurationRange,
    this.initialStartDate,
    this.initialEndDate,
    this.initialIsAscending,
    this.onSizeChanged,
    this.parentWidth,
  }) : super(key: key);

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel>
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

    //this is some of the stupidest shit ive written to date all because i just cant directly listen to text changes.
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifySizeChanged();
    });
  }

  void _notifySizeChanged() {
    if (widget.onSizeChanged != null && _key.currentContext != null) {
      final RenderBox box =
          _key.currentContext!.findRenderObject() as RenderBox;
      widget.onSizeChanged!(box.size);
    }
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
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade800),
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
                fillColor: Colors.grey.shade800,
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
            color: Colors.grey.shade800,
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
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        surface: Colors.grey.shade900,
                        primary: Colors.white,
                      ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            onChanged(date);
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
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
                        fillColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.blue.shade300;
                            }
                            return Colors.grey.shade600;
                          },
                        ),
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
            color: Colors.grey.shade800,
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
          color: Colors.grey.shade800,
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

class ExpandableDescription extends StatefulWidget {
  final String description;
  final int initialLines;

  const ExpandableDescription({
    Key? key,
    required this.description,
    this.initialLines = 3,
  }) : super(key: key);

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _expanded = false;
  bool _needsExpansion = false;
  final _textKey = GlobalKey();

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
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
      maxLines: widget.initialLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textBox.size.width);

    setState(() {
      _needsExpansion = painter.didExceedMaxLines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                      color: Colors.grey[400],
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
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            if (_needsExpansion)
              TextButton(
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Show less' : 'Show more',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class CommentItem extends StatefulWidget {
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
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
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
        final editedComment = await FPApiRequests()
            .editComment(widget.comment.id, _editController.text.trim());

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
    return Padding(
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
                backgroundImage: CachedNetworkImageProvider(
                    widget.comment.user.profileImage.path ?? ''),
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
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (widget.comment.user.id ==
                            widget.content.creator?.owner)
                          Text(
                            widget.content.channel?.title ?? '',
                            style: const TextStyle(
                              color: Colors.white,
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
                                              var res = await FPApiRequests()
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
                                                if (mounted) {
                                                  // ignore: use_build_context_synchronously
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Failed to delete comment'),
                                                    ),
                                                  );
                                                }
                                              }

                                              if (mounted) {
                                                // ignore: use_build_context_synchronously
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
                                style: const TextStyle(color: Colors.white),
                                maxLength: 1500,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                  hintText: 'Edit your comment',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
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
                                    : Colors.white,
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
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            child: Text('$_likeCount'),
                          ),
                          onPressed: () async {
                            final res = await FPApiRequests().likeComment(
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
                                    : Colors.white,
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
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            child: Text('$_dislikeCount'),
                          ),
                          onPressed: () async {
                            final res = await FPApiRequests().dislikeComment(
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
                              color: Colors.white,
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
                    style: const TextStyle(color: Colors.white),
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
                              color: Colors.white,
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
    );
  }
}

class CommentHolder extends StatefulWidget {
  final CommentModel comment;
  final ContentPostV3Response content;
  final Function(String, String)? onReply;

  const CommentHolder({
    super.key,
    required this.comment,
    required this.content,
    this.onReply,
  });

  @override
  State<CommentHolder> createState() => _CommentHolderState();
}

class _CommentHolderState extends State<CommentHolder> {
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

    await FPApiRequests()
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
    final reply =
        await FPApiRequests().comment(blogPost, text, replyto: replyTo);

    setState(() {
      _replies.insert(0, reply!);
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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

class StateCard extends StatefulWidget {
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
  State<StateCard> createState() => _StateCardState();
}

class _StateCardState extends State<StateCard>
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
      child: GestureDetector(
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

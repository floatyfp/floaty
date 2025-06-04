import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          key: _key,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.surfaceContainerHigh),
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
                                  foregroundColor: colorScheme.primary,
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
                  _buildWideLayout(constraints.maxWidth, colorScheme, theme)
                else
                  _buildNarrowLayout(colorScheme, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(
      double maxWidth, ColorScheme colorScheme, ThemeData theme) {
    const spacing = 16.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        _buildFilterItem(
          'Search',
          _buildSearchField(colorScheme),
        ),
        _buildFilterItem(
          'Start Date',
          _buildDateField(
            colorScheme,
            theme,
            value: startDate,
            onChanged: (date) => _handleDateChange(date, true),
          ),
        ),
        _buildFilterItem(
          'End Date',
          _buildDateField(
            colorScheme,
            theme,
            value: endDate,
            onChanged: (date) => _handleDateChange(date, false),
          ),
        ),
        _buildFilterItem(
          'Content Type',
          _buildContentTypeSelector(colorScheme),
        ),
        _buildFilterItem(
          'Duration',
          _buildDurationSelector(colorScheme),
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

  Widget _buildNarrowLayout(ColorScheme colorScheme, ThemeData theme) {
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
        _buildSearchField(colorScheme),
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
          colorScheme,
          theme,
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
          colorScheme,
          theme,
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
        _buildContentTypeSelector(colorScheme),
        const SizedBox(height: 16.0),
        Text(
          'Duration',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        _buildDurationSelector(colorScheme),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
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
                fillColor: colorScheme.surfaceContainerHigh,
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
            color: colorScheme.surfaceContainerHigh,
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

  Widget _buildDateField(
    ColorScheme colorScheme,
    ThemeData theme, {
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
                data: theme.copyWith(),
                child: child!,
              );
            },
          );
          if (date != null) {
            onChanged(date);
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHigh,
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

  Widget _buildContentTypeSelector(ColorScheme colorScheme) {
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
            color: colorScheme.surfaceContainerHigh,
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

  Widget _buildDurationSelector(ColorScheme colorScheme) {
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
          color: colorScheme.surfaceContainerHigh,
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
                activeColor: colorScheme.primary,
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

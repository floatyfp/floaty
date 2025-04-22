import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChannelScreenState {
  final int selectedIndex;
  final String? searchQuery;
  final Set<String> selectedContentTypes;
  final RangeValues? durationRange;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isAscending;
  final bool searchFieldVisible;

  const ChannelScreenState({
    this.selectedIndex = 0,
    this.searchQuery,
    this.selectedContentTypes = const {},
    this.durationRange,
    this.startDate,
    this.endDate,
    this.isAscending = false,
    this.searchFieldVisible = false,
  });

  ChannelScreenState copyWith({
    int? selectedIndex,
    String? searchQuery,
    Set<String>? selectedContentTypes,
    RangeValues? durationRange,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAscending,
    bool? searchFieldVisible,
  }) {
    return ChannelScreenState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      searchQuery: searchQuery,
      selectedContentTypes: selectedContentTypes ?? this.selectedContentTypes,
      durationRange: durationRange,
      startDate: startDate,
      endDate: endDate,
      isAscending: isAscending ?? this.isAscending,
      searchFieldVisible: searchFieldVisible ?? this.searchFieldVisible,
    );
  }
}

class ChannelScreenStateNotifier extends StateNotifier<ChannelScreenState> {
  ChannelScreenStateNotifier() : super(const ChannelScreenState());

  void updateSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  void resetSelectedIndex() {
    state = state.copyWith(selectedIndex: 0);
  }

  void toggleSearch() {
    state = state.copyWith(searchFieldVisible: !state.searchFieldVisible);
  }

  void updateFilters({
    String? searchQuery,
    Set<String>? contentTypes,
    RangeValues? durationRange,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAscending,
  }) {
    state = state.copyWith(
      searchQuery: searchQuery,
      selectedContentTypes: contentTypes,
      durationRange: durationRange,
      startDate: startDate,
      endDate: endDate,
      isAscending: isAscending,
    );
  }

  void resetState() {
    state = const ChannelScreenState();
  }
}

final channelScreenProvider = StateNotifierProvider.autoDispose<
    ChannelScreenStateNotifier, ChannelScreenState>(
  (ref) => ChannelScreenStateNotifier(),
);

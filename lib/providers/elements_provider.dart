import 'package:flutter_riverpod/flutter_riverpod.dart';

// SidebarChannelItem state
final channelExpansionProvider =
    StateProvider.family<bool, String>((ref, channelId) => false);

// FilterPanel state
final contentTypeProvider = StateProvider<String>((ref) => 'all');
final startDateProvider = StateProvider<DateTime?>((ref) => null);
final endDateProvider = StateProvider<DateTime?>((ref) => null);
final durationRangeProvider =
    StateProvider<(double, double)>((ref) => (0, 180));
final sortAscendingProvider = StateProvider<bool>((ref) => false);
final searchQueryProvider = StateProvider<String>((ref) => '');

// ExpandableDescription state
final expandableDescriptionProvider = StateNotifierProvider.family<
    ExpandableDescriptionNotifier, ExpandableDescriptionState, String>(
  (ref, textId) => ExpandableDescriptionNotifier(),
);

class ExpandableDescriptionState {
  final bool expanded;
  final bool needsExpansion;

  ExpandableDescriptionState({
    this.expanded = false,
    this.needsExpansion = false,
  });

  ExpandableDescriptionState copyWith({
    bool? expanded,
    bool? needsExpansion,
  }) {
    return ExpandableDescriptionState(
      expanded: expanded ?? this.expanded,
      needsExpansion: needsExpansion ?? this.needsExpansion,
    );
  }
}

class ExpandableDescriptionNotifier
    extends StateNotifier<ExpandableDescriptionState> {
  ExpandableDescriptionNotifier() : super(ExpandableDescriptionState());

  void setExpanded(bool value) => state = state.copyWith(expanded: value);
  void setNeedsExpansion(bool value) =>
      state = state.copyWith(needsExpansion: value);
}

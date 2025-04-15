import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreenState {
  final int selectedIndex;

  const ProfileScreenState({
    this.selectedIndex = 0,
  });

  ProfileScreenState copyWith({
    int? selectedIndex,
  }) {
    return ProfileScreenState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

class ProfileScreenStateNotifier extends StateNotifier<ProfileScreenState> {
  ProfileScreenStateNotifier() : super(const ProfileScreenState());

  void updateSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  void resetSelectedIndex() {
    state = state.copyWith(selectedIndex: 0);
  }

  void resetState() {
    state = const ProfileScreenState();
  }
}

final profileScreenProvider = StateNotifierProvider.autoDispose<
    ProfileScreenStateNotifier, ProfileScreenState>(
  (ref) => ProfileScreenStateNotifier(),
);

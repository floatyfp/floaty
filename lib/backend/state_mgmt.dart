import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Sidebar state for managing collapsed/expanded and open/closed
final sidebarStateProvider = StateNotifierProvider<SidebarStateNotifier, SidebarState>((ref) {
  return SidebarStateNotifier();
});

class SidebarState {
  final bool isCollapsed;
  final bool isOpen;
  
  SidebarState({required this.isCollapsed, required this.isOpen});
  
  SidebarState copyWith({bool? isCollapsed, bool? isOpen}) {
    return SidebarState(
      isCollapsed: isCollapsed ?? this.isCollapsed,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

class SidebarStateNotifier extends StateNotifier<SidebarState> {
  SidebarStateNotifier() : super(SidebarState(isCollapsed: false, isOpen: false));

  void toggleCollapseExpand() {
    state = state.copyWith(isCollapsed: !state.isCollapsed);
  }

  void toggleOpenClose() {
    state = state.copyWith(isOpen: !state.isOpen);
  }
}

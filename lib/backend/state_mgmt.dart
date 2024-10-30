import 'package:floaty/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

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

  void toggleCollapse() {
    Settings().setBool('sidebarCollapsed', !state.isCollapsed);
    state = state.copyWith(isCollapsed: !state.isCollapsed);
  }

  void setCollapsed() async {
    if (!await Settings().containsKey('sidebarCollapsed')) {
      state = state.copyWith(isCollapsed: true);
    }
  }

  void setExpanded() async {
    if (!await Settings().containsKey('sidebarCollapsed')) {
      state = state.copyWith(isCollapsed: false);
    }
  }

  void forceExpandMobile() async {
    state = state.copyWith(isCollapsed: false);
  }

  void setOpen() {
    state = state.copyWith(isOpen: true);
  }

  void setClosed() {
    state = state.copyWith(isOpen: false);
  }
}
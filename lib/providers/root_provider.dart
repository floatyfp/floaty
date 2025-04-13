import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/backend/definitions.dart';
import 'dart:async';
import 'package:floaty/settings.dart';

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

class RootState {
  final bool showText;
  final List<CreatorModelV3> creators;
  final UserSelfV3Response? user;
  final bool isLoading;
  final Widget appBarTitle;
  final List<Widget>? appBarActions;
  final Widget? appBarLeading;
  final StreamSubscription? creatorSubscription;
  final bool isCollapsed;
  final bool isOpen;

  RootState({
    this.showText = false,
    this.creators = const [],
    this.user,
    this.isLoading = true,
    this.appBarTitle = const Text('Floaty'),
    this.appBarActions,
    this.appBarLeading,
    this.creatorSubscription,
    required this.isCollapsed,
    required this.isOpen,
  });

  RootState copyWith(
      {bool? showText,
      List<CreatorModelV3>? creators,
      UserSelfV3Response? user,
      bool? isLoading,
      Widget? appBarTitle,
      List<Widget>? appBarActions,
      Widget? appBarLeading,
      StreamSubscription? creatorSubscription,
      bool? isCollapsed,
      bool? isOpen}) {
    return RootState(
      showText: showText ?? this.showText,
      creators: creators ?? this.creators,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      appBarTitle: appBarTitle ?? this.appBarTitle,
      appBarActions: appBarActions ?? this.appBarActions,
      appBarLeading: appBarLeading ?? this.appBarLeading,
      creatorSubscription: creatorSubscription ?? this.creatorSubscription,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

class RootNotifier extends StateNotifier<RootState> {
  RootNotifier()
      : super(RootState(
            showText: false,
            creators: [],
            user: null,
            isLoading: true,
            appBarTitle: const Text('Floaty'),
            appBarActions: null,
            appBarLeading: null,
            creatorSubscription: null,
            isCollapsed: false,
            isOpen: false)) {
    _loadSavedState();
  }

  Future<void> loadsidebar() async {
    if (!mounted) return;
    try {
      fpApiRequests.getSubscribedCreators().listen((fetchedCreators) {
        if (!mounted) return;
        state = state.copyWith(creators: fetchedCreators);
      });
      fpApiRequests.getUser().listen((fetchedUser) {
        if (!mounted) return;
        state = state.copyWith(user: fetchedUser, isLoading: false);
      }, onError: (error) {
        if (!mounted) return;
        state = state.copyWith(isLoading: false);
      });
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  void setAppBar(Widget title, {List<Widget>? actions, Widget? leading}) {
    if (!mounted) return;
    state = state.copyWith(
        appBarTitle: title, appBarActions: actions, appBarLeading: leading);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  Future<void> _loadSavedState() async {
    if (await Settings().containsKey('sidebarCollapsed')) {
      final savedState = await Settings().getBool('sidebarCollapsed');
      if (savedState ?? false) {
        state = state.copyWith(isCollapsed: savedState);
      }
    }
  }

  void toggleCollapseExpand() {
    state = state.copyWith(isCollapsed: !state.isCollapsed);
  }

  void toggleOpenClose() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void toggleCollapse() {
    final newState = !state.isCollapsed;
    state = state.copyWith(isCollapsed: newState);
    Future(() async {
      await Settings().setBool('sidebarCollapsed', newState);
    });
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

  void setText(bool bool) {
    state = state.copyWith(showText: bool);
  }

  void setOpen() {
    state = state.copyWith(isOpen: true);
  }

  void setClosed() {
    state = state.copyWith(isOpen: false);
  }
}

final rootProvider = StateNotifierProvider<RootNotifier, RootState>((ref) {
  return RootNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/frontend/root.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class BrowseState {
  final List<CreatorModelV3> creators;
  final bool isLoading;
  Timer? debounce;
  TextEditingController searchController = TextEditingController();

  BrowseState(
      {required this.creators,
      required this.isLoading,
      required this.searchController,
      this.debounce});

  BrowseState copyWith(
      {List<CreatorModelV3>? creators,
      bool? isLoading,
      TextEditingController? searchController,
      Timer? debounce}) {
    return BrowseState(
      creators: creators ?? this.creators,
      isLoading: isLoading ?? this.isLoading,
      searchController: searchController ?? this.searchController,
      debounce: debounce ?? this.debounce,
    );
  }
}

class BrowseNotifier extends StateNotifier<BrowseState> {
  BrowseNotifier()
      : super(BrowseState(
            creators: [],
            isLoading: true,
            searchController: TextEditingController(),
            debounce: null));

  void fetchCreators() async {
    state = state.copyWith(isLoading: true);
    try {
      fpApiRequests.getCreators().listen((fetchedCreators) {
        state = state.copyWith(creators: fetchedCreators, isLoading: false);
      }, onError: (error) {
        state = state.copyWith(creators: [], isLoading: false);
      });
    } catch (e) {
      state = state.copyWith(creators: [], isLoading: false);
    }
  }

  void setAppTitle() {
    rootLayoutKey.currentState?.setAppBar(
      TextField(
        controller: state.searchController,
        onChanged: (value) {
          //being kind to the floatplane api
          if (state.debounce?.isActive ?? false) state.debounce!.cancel();
          state.debounce = Timer(const Duration(seconds: 1), () {
            _performSearch(value);
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search creators...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  void _performSearch(String query) {
    state = state.copyWith(isLoading: true);
    fpApiRequests.getCreators(query: query).listen((fetchedCreators) {
      state = state.copyWith(
        creators: fetchedCreators,
        isLoading: false,
      );
    }, onError: (error) {
      state = state.copyWith(
        isLoading: false,
      );
    });
  }
}

final browseProvider =
    StateNotifierProvider<BrowseNotifier, BrowseState>((ref) {
  return BrowseNotifier();
});

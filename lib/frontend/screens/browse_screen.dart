import 'package:floaty/backend/definitions.dart';
import 'package:flutter/material.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/frontend/root.dart';
import 'dart:async';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BrowseScreenState createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<CreatorModelV3> creators = [];
  Timer? _debounce;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setAppTitle();
      fetchCreators();
    });
  }

  void setAppTitle() {
    rootLayoutKey.currentState?.setAppBar(
      TextField(
        controller: _searchController,
        onChanged: (value) {
          //being kind to the floatplane api
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(seconds: 1), () {
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
    setState(() {
      isLoading = true;
    });
    FPApiRequests().getCreators(query: query).listen((fetchedCreators) {
      setState(() {
        creators = fetchedCreators;
        isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        isLoading = false;
      });
    });
  }

  void fetchCreators() {
    setState(() {
      isLoading = true;
    });
    FPApiRequests().getCreators().listen((fetchedCreators) {
      setState(() {
        creators = fetchedCreators;
        isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width:
              MediaQuery.of(context).size.width > 1000 ? 1000 : double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : creators.isEmpty
                  ? const Center(child: Text("No items found."))
                  : SingleChildScrollView(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: creators.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return CreatorCard(creators[index]);
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}

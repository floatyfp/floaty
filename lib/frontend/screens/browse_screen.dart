import 'package:flutter/material.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/providers/browse_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(browseProvider.notifier).setAppTitle();
      ref.read(browseProvider.notifier).fetchCreators();
    });
  }

  @override
  Widget build(BuildContext context) {
    final browseState = ref.watch(browseProvider);
    return Scaffold(
      body: Center(
        child: Container(
          width:
              MediaQuery.of(context).size.width > 1000 ? 1000 : double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: browseState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : browseState.creators.isEmpty
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
                        itemCount: browseState.creators.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return CreatorCard(browseState.creators[index]);
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}

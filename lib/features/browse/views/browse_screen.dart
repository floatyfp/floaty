import 'package:floaty/features/browse/components/creator_card.dart';
import 'package:flutter/material.dart';
import 'package:floaty/features/browse/repositories/browse_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => BrowseScreenState();
}

class BrowseScreenState extends ConsumerState<BrowseScreen> {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final browseState = ref.watch(browseProvider);
        final creators = browseState.creators;
        final width = constraints.maxWidth;
        final crossAxisCount = (width / 300).floor().clamp(1, 3);

        List<Widget> rows = [];
        for (int i = 0; i < creators.length; i += crossAxisCount) {
          final rowItems = creators.skip(i).take(crossAxisCount).toList();

          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rowItems.map((creator) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: CreatorCard(creator),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Container(
                width: width > 1500 ? 1500 : double.infinity,
                child: Column(
                  children: rows,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

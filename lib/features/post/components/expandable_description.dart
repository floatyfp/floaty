import 'package:auto_size_text/auto_size_text.dart';
import 'package:floaty/shared/controllers/elements_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpandableDescription extends ConsumerStatefulWidget {
  final String description;
  final int initialLines;

  const ExpandableDescription({
    super.key,
    required this.description,
    this.initialLines = 3,
  });

  @override
  ConsumerState<ExpandableDescription> createState() {
    return _ExpandableDescriptionState();
  }
}

class _ExpandableDescriptionState extends ConsumerState<ExpandableDescription> {
  final _textKey = GlobalKey();
  final String _uniqueId = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextOverflow();
    });
  }

  void _checkTextOverflow() {
    final textBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (textBox == null) return;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: widget.description,
        style: TextStyle(
          color: Theme.of(context).textTheme.titleMedium?.color,
          fontSize: 14,
        ),
      ),
      maxLines: widget.initialLines,
    )..layout(maxWidth: textBox.size.width);

    ref
        .read(expandableDescriptionProvider(_uniqueId).notifier)
        .setNeedsExpansion(painter.didExceedMaxLines);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expandableDescriptionProvider(_uniqueId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCrossFade(
          firstChild: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 14.0 * widget.initialLines * 1.5,
            ),
            child: ClipRect(
              child: Text(
                widget.description,
                key: _textKey,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontSize: 14,
                ),
                maxLines: widget.initialLines,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          secondChild: Text(
            widget.description,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontSize: 14,
            ),
          ),
          crossFadeState: state.expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (state.needsExpansion)
          TextButton(
            onPressed: () {
              ref
                  .read(expandableDescriptionProvider(_uniqueId).notifier)
                  .setExpanded(!state.expanded);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.expanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Icon(
                  state.expanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ShowInfoCard extends StatelessWidget {
  final String preshowtime;
  final String mainshowtime;
  final String preshowlength;
  final String mainshowlength;
  final String lateness;
  final bool late;

  const ShowInfoCard({
    super.key,
    required this.preshowtime,
    required this.mainshowtime,
    required this.preshowlength,
    required this.mainshowlength,
    required this.lateness,
    required this.late,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: late ? Colors.red : Colors.green),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AutoSizeText(
              "Show Info from Whenplane",
              textScaleFactor: 1.15,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 15,
              children: [
                _buildShowSection("Pre Show", preshowtime, preshowlength),
                _buildShowSection("Main Show", mainshowtime, mainshowlength),
              ],
            ),
            Divider(),
            SizedBox(height: 3),
            AutoSizeText(
              late
                  ? lateness
                  : lateness == '0s'
                      ? 'On time!'
                      : '$lateness early',
              textScaleFactor: 1.05,
              style: TextStyle(
                color: late ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowSection(String title, String time, String duration) {
    return Column(
      children: [
        AutoSizeText(
          title,
          textScaleFactor: 1.15,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        AutoSizeText(
          time,
          textScaleFactor: 1.02,
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4),
        AutoSizeText(
          duration,
          textScaleFactor: 1.02,
        ),
      ],
    );
  }
}

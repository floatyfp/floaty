// ignore_for_file: use_build_context_synchronously

import 'package:audioplayers/audioplayers.dart';

import 'dart:async';
import 'package:floaty/features/router/views/root_layout.dart';
import 'package:floaty/shared/views/error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/features/live/controllers/live_chat_provider.dart';
import 'package:floaty/features/api/utils/chat_utils.dart';
import 'package:floaty/settings.dart';

class LiveChat extends ConsumerStatefulWidget {
  const LiveChat(
      {super.key,
      this.liveId,
      required this.creatorId,
      this.infoless = false,
      this.exit = false,
      this.onExit});

  final String? liveId;
  final String creatorId;
  final bool infoless;
  final bool exit;
  final Function? onExit;

  @override
  ConsumerState<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends ConsumerState<LiveChat> {
  final TextEditingController controller = TextEditingController();
  final _scrollController = ScrollController();
  String? trueliveid;
  bool isChatterListOpen = false;
  bool isSettingsOpen = false;
  bool showEmotePicker = false;
  bool showPoll = false;

  @override
  void initState() {
    super.initState();
    trueliveid = widget.liveId;
    _init();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <
          _scrollController.position.maxScrollExtent) {
        ref.read(chatbroken.notifier).state = true;
      } else {
        ref.read(chatbroken.notifier).state = false;
      }
    });
  }

  void _init() async {
    ref
        .read(webSocketEventHandlerProvider)
        .chatConnect(widget.liveId!, widget.creatorId, controller);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(chatterlistprovider.notifier).getChatterList(widget.creatorId);
      if (widget.creatorId != await settings.getKey('creatorId')) {
        ref.read(webSocketEventHandlerProvider).reset();
        await settings.setKey('creatorId', widget.creatorId);
      } else {
        ref.read(pollprovider.notifier).reset();
      }
    });
  }

  @override
  void deactivate() {
    ref.read(webSocketEventHandlerProvider).chatDisconnect(widget.creatorId);
    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messages = ref.watch(chatProvider);
    final errorState = ref.watch(errorProvider);
    ref.listen(chatProvider, (previous, next) {
      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ref.watch(chatbroken) == false) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    });

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
          elevation: 0,
          toolbarHeight: 40,
          backgroundColor: colorScheme.surfaceContainer,
          surfaceTintColor: colorScheme.surfaceContainer,
          automaticallyImplyLeading: false,
          leading: widget.exit
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    widget.onExit!();
                  },
                )
              : null,
          actions: [
            IconButton(
              onPressed: () async {
                if (isSettingsOpen) {
                  setState(() {
                    isSettingsOpen = false;
                  });
                }
                ref
                    .read(chatterlistprovider.notifier)
                    .getChatterList(trueliveid!);
                if (ref.read(chatterlistprovider).isEmpty) {
                  ref
                      .read(errorProvider.notifier)
                      .setError(ref.read(chatterlistprovider).toString());
                  setState(() {
                    isChatterListOpen = !isChatterListOpen;
                  });
                } else {
                  if (isChatterListOpen) {
                    setState(() {
                      isChatterListOpen = false;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (ref.watch(chatbroken) == false) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });
                  } else {
                    setState(() {
                      isChatterListOpen = true;
                    });
                  }
                }
              },
              icon: isChatterListOpen
                  ? Icon(Icons.chat, color: theme.textTheme.titleLarge?.color)
                  : Icon(Icons.list, color: theme.textTheme.titleLarge?.color),
            ),
            IconButton(
              onPressed: () async {
                if (isChatterListOpen) {
                  setState(() {
                    isChatterListOpen = false;
                  });
                }
                if (isSettingsOpen) {
                  setState(() {
                    isSettingsOpen = false;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (ref.watch(chatbroken) == false) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  });
                } else {
                  setState(() {
                    isSettingsOpen = true;
                  });
                }
              },
              icon: isSettingsOpen
                  ? Icon(Icons.chat, color: theme.textTheme.titleLarge?.color)
                  : Icon(Icons.settings,
                      color: theme.textTheme.titleLarge?.color),
            )
          ],
          title: Text(
              isChatterListOpen
                  ? "Viewer List"
                  : isSettingsOpen
                      ? "Settings"
                      : "Live Chat",
              style: TextStyle(
                  fontSize: 18, color: theme.textTheme.titleLarge?.color))),
      body: errorState.hasError
          ? ErrorScreen(message: errorState.errorMessage)
          : isChatterListOpen
              ? Column(
                  children: [
                    Expanded(
                        child: chatterList(ref.watch(chatterlistprovider))),
                  ],
                )
              : isSettingsOpen
                  ? Column(
                      children: [
                        Expanded(child: SettingsScreen()),
                      ],
                    )
                  : Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          if (controller.text.isNotEmpty) {
                            ref.read(chatProvider.notifier).sendMessage(
                                "User", controller.text, trueliveid!);
                            controller.clear();
                          }
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Stack(children: [
                        Column(
                          children: [
                            Flexible(
                              child: Stack(
                                children: [
                                  if (ref.watch(connectionProvider).isNotEmpty)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 7.5,
                                      child: Center(
                                        child: Badge(
                                          backgroundColor: ref.watch(
                                                          connectionProvider)[
                                                      'color'] ==
                                                  'success'
                                              ? colorScheme.secondaryContainer
                                              : ref.watch(connectionProvider)[
                                                          'color'] ==
                                                      'warning'
                                                  ? colorScheme
                                                      .tertiaryContainer
                                                  : colorScheme.errorContainer,
                                          label: Text(
                                            ref.watch(connectionProvider)[
                                                    'message'] ??
                                                'Disconnected',
                                            style: TextStyle(
                                              color: ref.watch(
                                                              connectionProvider)[
                                                          'color'] ==
                                                      'success'
                                                  ? colorScheme
                                                      .onSecondaryContainer
                                                  : ref.watch(connectionProvider)[
                                                              'color'] ==
                                                          'warning'
                                                      ? colorScheme
                                                          .onTertiaryContainer
                                                      : colorScheme
                                                          .onErrorContainer,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 3.5, horizontal: 10),
                                        ),
                                      ),
                                    ),
                                  ListView.builder(
                                    controller: _scrollController,
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final msg = messages[index];
                                      return Column(
                                        children: [
                                          ListTile(
                                            tileColor: msg.notification
                                                ? Colors.orange
                                                : null,
                                            minLeadingWidth: 0,
                                            minVerticalPadding: 0,
                                            minTileHeight: 1,
                                            title: Text.rich(
                                                TextSpan(children: msg.text)),
                                          ),
                                          Divider(
                                              indent: 2,
                                              endIndent: 2,
                                              height: 2)
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (ref.watch(pollprovider).isNotEmpty)
                              Column(
                                children: [
                                  Container(
                                    height: 35,
                                    color: colorScheme.surfaceContainerHighest,
                                    padding: EdgeInsets.only(top: 6),
                                    child: ListTile(
                                      minVerticalPadding: 0,
                                      minTileHeight: 1,
                                      dense: true,
                                      title: Text("Poll",
                                          style: TextStyle(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontSize: 16)),
                                      onTap: () {
                                        setState(() {
                                          showPoll = !showPoll;
                                        });
                                      },
                                      trailing: IconButton(
                                        iconSize: 15,
                                        icon: Icon(
                                          showPoll
                                              ? Icons.arrow_drop_down
                                              : Icons.arrow_drop_up,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            showPoll = !showPoll;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    height: showPoll ? null : 0,
                                    constraints: BoxConstraints(
                                      maxHeight: showPoll ? 170 : 0,
                                    ),
                                    color: colorScheme.surfaceContainerHighest,
                                    child: ListView.builder(
                                      itemCount: ref.watch(pollprovider).length,
                                      itemBuilder: (context, index) =>
                                          PollWidget(
                                        poll: ref.watch(pollprovider)[index],
                                        ref: ref,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            Column(
                              children: [
                                Container(
                                  height: 35,
                                  color: colorScheme.surfaceContainer,
                                  padding: EdgeInsets.only(top: 6),
                                  child: ListTile(
                                    minVerticalPadding: 0,
                                    minTileHeight: 1,
                                    dense: true,
                                    title: Text("Emotes",
                                        style: TextStyle(fontSize: 16)),
                                    onTap: () {
                                      setState(() {
                                        showEmotePicker = !showEmotePicker;
                                      });
                                    },
                                    trailing: IconButton(
                                      iconSize: 15,
                                      icon: Icon(
                                        showEmotePicker
                                            ? Icons.arrow_drop_down
                                            : Icons.arrow_drop_up,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          showEmotePicker = !showEmotePicker;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  height: showEmotePicker ? 90 : 0,
                                  color: colorScheme.surfaceContainer,
                                  child: ref.watch(emotepickerProvider).isEmpty
                                      ? CircularProgressIndicator()
                                      : emotePicker(ref, controller),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: TextField(
                                    maxLength: 500,
                                    maxLengthEnforcement:
                                        MaxLengthEnforcement.enforced,
                                    minLines: 1,
                                    maxLines: 2,
                                    controller: controller,
                                    onSubmitted: (String value) {
                                      ref
                                          .read(chatProvider.notifier)
                                          .sendMessage("User", controller.text,
                                              trueliveid!);
                                      controller.clear();
                                    },
                                    decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(4),
                                        border: InputBorder.none,
                                        counterText: '', // i love flutter
                                        hintText: "Enter your message"),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () {
                                    ref.read(chatProvider.notifier).sendMessage(
                                        "User", controller.text, trueliveid!);
                                    controller.clear();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 20,
                          right: 20,
                          child: AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            opacity: ref.watch(chatbroken) ? 1.0 : 0.0,
                            child: FloatingActionButton(
                              onPressed: () async {
                                await _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                ref.read(chatbroken.notifier).state =
                                    false; // Reset chatbroken state
                                //this is just in case (insurance policy)
                                Future.delayed(Duration(milliseconds: 10), () {
                                  _scrollController.jumpTo(
                                    _scrollController.position.maxScrollExtent,
                                  );
                                });
                              },
                              backgroundColor: colorScheme.primary,
                              child: Icon(Icons.arrow_downward),
                            ),
                          ),
                        ),
                      ])),
    ));
  }
}

Widget emotePicker(WidgetRef ref, TextEditingController controller) {
  return GridView.builder(
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 35,
      crossAxisSpacing: 5,
      mainAxisSpacing: 5,
    ),
    itemCount: ref.watch(emotepickerProvider).length,
    itemBuilder: (context, index) {
      return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              controller.text +=
                  ':${ref.watch(emotepickerProvider)[index].name}:';
            },
            child: Center(
              child: Image.network(
                ref.watch(emotepickerProvider)[index].url,
                fit: BoxFit.cover,
              ),
            ),
          ));
    },
  );
}

Widget chatterList(Map<String, dynamic> chatterdata) {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.only(top: 10, left: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${(chatterdata['pilots']?.length ?? 0) + (chatterdata['passengers']?.length ?? 0)} chatters present",
            textAlign: TextAlign.left,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          if (chatterdata['pilots']?.isNotEmpty ?? false)
            Text(
              "Pilots (${chatterdata['pilots']?.length ?? 0})",
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          if (chatterdata['pilots']?.isNotEmpty ?? false)
            Padding(
              padding: EdgeInsets.only(left: 15),
              child: Column(
                children: List.generate(
                  chatterdata['pilots']?.length ?? 0,
                  (index) {
                    List<String> sortedPilots = List<String>.from(
                        chatterdata['pilots'] ?? [])
                      ..sort(
                          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                    String username = sortedPilots[index];
                    String colorHex = getColorForUsername(username);
                    Color color =
                        Color(int.parse('0xFF$colorHex'.replaceAll('#', '')));

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 0,
                      minTileHeight: 0,
                      dense: true,
                      title: Text(
                        username,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (chatterdata['pilots']?.isNotEmpty ?? false) SizedBox(height: 10),
          Text(
            "Viewers (${chatterdata['passengers']?.length ?? 0})",
            textAlign: TextAlign.left,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: EdgeInsets.only(left: 15),
            child: Column(
              children: List.generate(
                chatterdata['passengers']?.length ?? 0,
                (index) {
                  List<String> sortedPassengers = List<String>.from(
                      chatterdata['passengers'] ?? [])
                    ..sort(
                        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                  String username = sortedPassengers[index];
                  String colorHex = getColorForUsername(username);
                  Color color =
                      Color(int.parse('0xFF$colorHex'.replaceAll('#', '')));

                  return ListTile(
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 0,
                      minTileHeight: 0,
                      dense: true,
                      title: Text(
                        username,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ));
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class PollWidget extends StatefulWidget {
  final WidgetRef ref;
  final PollWrapper poll;

  const PollWidget({
    super.key,
    required this.poll,
    required this.ref,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> with WidgetsBindingObserver {
  int? selectedOptionIndex;
  bool hasVoted = false;
  Timer? _timer;
  Duration timeRemaining = Duration.zero;
  bool showResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    _init();
  }

  void _init() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool resultsSettings =
          await settings.getBool('reveal_poll_results', defaultValue: false);
      setState(() {
        showResults = resultsSettings;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startTimer() {
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeRemaining();
      }
    });
  }

  void _updateTimeRemaining() {
    if (widget.poll.poll.endDate == null) {
      timeRemaining = Duration.zero;
      return;
    }
    final now = DateTime.now();
    if (now.isAfter(widget.poll.poll.endDate!)) {
      timeRemaining = Duration.zero;
      _timer?.cancel();
    } else {
      timeRemaining = widget.poll.poll.endDate!.difference(now);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    hasVoted = widget.poll.poll.voted ?? false;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              widget.poll.poll.title,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Options
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: List.generate(widget.poll.poll.options.length, (index) {
                String option = widget.poll.poll.options[index];
                double percentage =
                    getPercentage(widget.poll.poll.runningTally.counts[index]);
                int voteCount = widget.poll.poll.runningTally.counts[index];
                bool isSelected = hasVoted
                    ? widget.poll.poll.voteInfo?.entries.first.value == index
                    : selectedOptionIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (hasVoted) return;
                      selectedOptionIndex = index;
                    }),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Container(
                        width: double.infinity,
                        height: 33,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Progress bar (only shown after voting)
                            if (hasVoted || showResults)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width:
                                      constraints.maxWidth * (percentage / 100),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),

                            // Option content
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    // Radio button or checkmark
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.outline,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check,
                                              color: colorScheme.onPrimary,
                                              size: 12,
                                            )
                                          : null,
                                    ),

                                    const SizedBox(width: 12),

                                    // Option text
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),

                                    // Vote count and percentage (only shown after voting)
                                    if (hasVoted || showResults) ...[
                                      Text(
                                        '$voteCount Vote${voteCount != 1 ? 's' : ''}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${percentage.round()}%',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.poll.poll.endDate != null
                      ? _formatDuration(timeRemaining)
                      : 'No end time',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (hasVoted || showResults)
                  Text(
                    '${widget.poll.poll.runningTally.counts.reduce((a, b) => a + b)} Vote${widget.poll.poll.runningTally.counts.reduce((a, b) => a + b) != 1 ? 's' : ''}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (!hasVoted)
                  TextButton(
                    onPressed: selectedOptionIndex == null
                        ? null
                        : () => _vote(selectedOptionIndex!),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                    ),
                    child: const Text('Vote'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _vote(int index) {
    if (hasVoted) return;

    setState(() {
      selectedOptionIndex = index;
      hasVoted = true;
    });

    widget.ref
        .read(webSocketEventHandlerProvider)
        .submitVote(widget.poll.poll.id, index);
  }

  int get totalVotes {
    return widget.poll.poll.runningTally.counts
        .fold(0, (sum, option) => sum + option);
  }

  double getPercentage(int votes) {
    if (totalVotes == 0) return 0.0;
    return (votes / totalVotes) * 100;
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? sizeOption;
  bool showUsernameColors = true; // Default true
  bool playSoundWhenMentioned = false; // Default false
  bool highlightMentions = true; // Default true
  bool revealPollResultsBeforeVoting = false; // Default false
  bool timestampMessages = false; // Default false
  final player = AudioPlayer();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bool usernamecolors =
        await settings.getBool('show_username_colors', defaultValue: true);
    final bool soundMentions = await settings
        .getBool('play_sound_when_mentioned', defaultValue: false);
    final bool lightMentions =
        await settings.getBool('highlight_mentions', defaultValue: true);
    final bool pollResults =
        await settings.getBool('reveal_poll_results', defaultValue: false);
    final bool timestampOnMessages =
        await settings.getBool('timestamp_messages', defaultValue: false);

    if (mounted) {
      setState(() {
        showUsernameColors = usernamecolors;
        playSoundWhenMentioned = soundMentions;
        highlightMentions = lightMentions;
        revealPollResultsBeforeVoting = pollResults;
        timestampMessages = timestampOnMessages;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Chat Settings',
                  style: textTheme.titleMedium,
                ),
              ),
              SizedBox(height: 5),
              SwitchListTile(
                value: showUsernameColors,
                onChanged: (value) {
                  setState(() {
                    showUsernameColors = value;
                  });
                  settings.setBool('show_username_colors', value);
                },
                title: Text('Show username colors'),
              ),
              SwitchListTile(
                value: playSoundWhenMentioned,
                onChanged: (value) async {
                  setState(() {
                    playSoundWhenMentioned = value;
                  });
                  settings.setBool('play_sound_when_mentioned', value);
                  if (value) {
                    await player.play(AssetSource('livechat/pop.wav'));
                  }
                },
                title: Text('Play sound when mentioned'),
              ),
              SwitchListTile(
                value: highlightMentions,
                onChanged: (value) async {
                  setState(() {
                    highlightMentions = value;
                  });
                  settings.setBool('highlight_mentions', value);
                },
                title: Text(
                    'Highlight @${rootLayoutKey.currentState?.user?.username} mentions'),
              ),
              SwitchListTile(
                value: timestampMessages,
                onChanged: (value) async {
                  setState(() {
                    timestampMessages = value;
                  });
                  settings.setBool('timestamp_messages', value);
                },
                title: Text('Timestamp on messages'),
              ),
              SwitchListTile(
                value: revealPollResultsBeforeVoting,
                onChanged: (value) {
                  setState(() {
                    revealPollResultsBeforeVoting = value;
                  });
                  settings.setBool('reveal_poll_results', value);
                },
                title: Text('Reveal poll results before voting'),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Chat Message Size',
                  style: textTheme.titleMedium,
                ),
              ),
              SizedBox(height: 5),
              Center(
                child: FutureBuilder(
                  future:
                      settings.getDynamic('chat_message_size', defaultValue: 1),
                  builder: (context, snapshot) {
                    return ToggleButtons(
                      direction: Axis.horizontal,
                      onPressed: (int index) {
                        setState(() {
                          sizeOption = index;
                        });
                        settings.setDynamic('chat_message_size', index);
                      },
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      constraints: BoxConstraints(
                          minHeight: 40.0,
                          minWidth: constraints.maxWidth / 3 - 12),
                      isSelected: [
                        sizeOption != null
                            ? sizeOption == 0
                            : snapshot.data == 0,
                        sizeOption != null
                            ? sizeOption == 1
                            : snapshot.data == 1,
                        sizeOption != null
                            ? sizeOption == 2
                            : snapshot.data == 2,
                      ],
                      children: const [
                        Text('Small'),
                        Text('Medium'),
                        Text('Large'),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Chat Preview',
                  style: textTheme.titleMedium,
                ),
              ),
              SizedBox(height: 5),
              Divider(indent: 2, endIndent: 2, height: 2),
              FutureBuilder(
                future: _buildChatPreview(),
                builder: (context, snapshot) {
                  return snapshot.data ?? const SizedBox.shrink();
                },
              ),
              Divider(indent: 2, endIndent: 2, height: 2),
            ],
          );
        },
      ),
    );
  }
}

Future<Widget> _buildChatPreview() async {
  Color namecolor =
      await settings.getBool('show_username_colors', defaultValue: true)
          ? getColorForUsernameColor(
              rootLayoutKey.currentState?.user?.username ?? '')
          : Theme.of(rootLayoutKey.currentState!.context).colorScheme.primary;
  String pingText = '@${rootLayoutKey.currentState?.user?.username ?? ''}';
  Color pingcolor =
      await settings.getBool('show_username_colors', defaultValue: true)
          ? getColorForUsernameColor(
              rootLayoutKey.currentState?.user?.username ?? '')
          : Theme.of(rootLayoutKey.currentState!.context).colorScheme.primary;
  bool highlightMentions =
      await settings.getBool('highlight_mentions', defaultValue: true);
  int messageSize =
      await settings.getDynamic('chat_message_size', defaultValue: 1);
  double fontSize = messageSize == 0
      ? 10
      : messageSize == 1
          ? 14
          : 18;
  double emoteSize = messageSize == 0
      ? 14
      : messageSize == 1
          ? 20
          : 26;
  double pingSize = messageSize == 0
      ? 10
      : messageSize == 1
          ? 14
          : 18;
  bool showTimestamps =
      await settings.getBool('timestamp_messages', defaultValue: false);
  DateTime sentAt = DateTime.now();
  final List<InlineSpan> spans = [];

  if (showTimestamps) {
    final localTime = sentAt.toLocal();
    spans.add(TextSpan(
      text:
          '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')} ',
      style: TextStyle(
          fontSize: fontSize,
          color: Theme.of(rootLayoutKey.currentState!.context)
              .colorScheme
              .tertiary),
    ));
  }

  // Username button
  spans.add(WidgetSpan(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () {},
        style: ButtonStyle(
          padding:
              WidgetStateProperty.all(const EdgeInsets.only(left: 4, right: 4)),
          minimumSize: WidgetStateProperty.all(Size.zero),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return namecolor.withValues(alpha: 0.25);
            }
            return Colors.transparent;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Text(
          rootLayoutKey.currentState?.user?.username ?? '',
          style: TextStyle(
            color: namecolor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    ),
  ));

  // Message text
  spans.add(TextSpan(text: 'hello ', style: TextStyle(fontSize: fontSize)));

  // Mention button
  spans.add(WidgetSpan(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () {},
        style: ButtonStyle(
          padding:
              WidgetStateProperty.all(const EdgeInsets.only(left: 4, right: 4)),
          minimumSize: WidgetStateProperty.all(Size.zero),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return pingcolor.withValues(alpha: 0.25);
            }
            return highlightMentions &&
                    pingText.substring(1) ==
                        rootLayoutKey.currentState?.user!.username
                ? Theme.of(rootLayoutKey.currentState!.context)
                    .colorScheme
                    .primary
                : Colors.transparent;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Text(
          pingText,
          style: TextStyle(
            color: highlightMentions &&
                    pingText.substring(1) ==
                        rootLayoutKey.currentState?.user!.username
                ? Colors.white
                : pingcolor,
            fontWeight: FontWeight.bold,
            fontSize: pingSize,
          ),
        ),
      ),
    ),
  ));

  // Emote
  spans.add(WidgetSpan(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Image.asset(
        'assets/livechat/sample.png',
        fit: BoxFit.cover,
        height: emoteSize,
      ),
    ),
  ));

  return Text.rich(
    TextSpan(children: spans),
  );
}

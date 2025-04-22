import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:floaty/features/api/repositories/fpwebsockets.dart';
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
      required this.liveId,
      this.infoless = false,
      this.exit = false,
      this.onExit});
  final String liveId;
  final bool infoless;
  final bool exit;
  final Function? onExit;

  @override
  ConsumerState<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends ConsumerState<LiveChat> {
  final TextEditingController _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? trueliveid;
  List<Emote> emotes = [];
  bool emotesLoaded = false;
  bool isChatterListOpen = false;
  Map<String, dynamic> chatterdata = {};

  @override
  void initState() {
    super.initState();
    init();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <
          _scrollController.position.maxScrollExtent) {
        ref.read(chatbroken.notifier).state = true;
      } else {
        ref.read(chatbroken.notifier).state = false;
      }
    });
  }

  void init() async {
    if (!widget.infoless) {
      afterInit();
    } else {
      final res = await fpApiRequests.getCreator(urlname: widget.liveId).first;
      trueliveid = res.liveStream?.id;
      if (trueliveid != null) {
        afterInit();
      } else {
        ref.read(errorProvider.notifier).setError('Live ID fetch failed.');
      }
    }
  }

  void afterInit() async {
    if (!widget.infoless) {
      trueliveid = widget.liveId;
    }
    final storedLiveId = await settings.getKey('liveid');
    if (storedLiveId.isNotEmpty) {
      if (trueliveid != storedLiveId) {
        ref.read(chatProvider.notifier).reset(storedLiveId);
      }
    }
    await settings.setKey('liveid', trueliveid!);
    await ref
        .read(chatProvider.notifier)
        .joinLiveChat(trueliveid!, _controller);

    if (mounted) {
      emotes = await ref.read(emotesProvider.future);
      setState(() {
        emotesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    fpWebsockets.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final showEmotePicker = ref.watch(emotePickerProvider);
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
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          surfaceTintColor: Theme.of(context).colorScheme.surfaceContainer,
          leading: widget.exit
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    widget.onExit!();
                  },
                )
              : null,
          actions: [
            FutureBuilder(
              future: settings.getBool('developerMode'),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return IconButton(
                    onPressed: () {
                      ref.read(pollDataProvider.notifier).testPoll();
                    },
                    icon: Icon(
                      Icons.warning,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            IconButton(
              onPressed: () async {
                chatterdata = await fpWebsockets.chatterlist(trueliveid!);
                if (chatterdata.isEmpty) {
                  ref
                      .read(errorProvider.notifier)
                      .setError(chatterdata.toString());
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
                  ? Icon(Icons.chat,
                      color: Theme.of(context).textTheme.titleLarge?.color)
                  : Icon(Icons.list,
                      color: Theme.of(context).textTheme.titleLarge?.color),
            )
          ],
          title: Text(isChatterListOpen ? "Viewer List" : "Live Chat",
              style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.titleLarge?.color))),
      body: errorState.hasError
          ? ErrorScreen(message: errorState.errorMessage)
          : isChatterListOpen
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, left: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${chatterdata['pilots'].length + chatterdata['passengers'].length} chatters present",
                          textAlign: TextAlign.left,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        if (chatterdata['pilots'].isNotEmpty)
                          Text(
                            "Pilots (${chatterdata['pilots'].length})",
                            textAlign: TextAlign.left,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (chatterdata['pilots'].isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(left: 15),
                            child: Column(
                              children: List.generate(
                                chatterdata['pilots'].length,
                                (index) {
                                  List<String> sortedPilots =
                                      List<String>.from(chatterdata['pilots'])
                                        ..sort((a, b) => a
                                            .toLowerCase()
                                            .compareTo(b.toLowerCase()));

                                  String username = sortedPilots[index];
                                  String colorHex =
                                      getColorForUsername(username);
                                  Color color = Color(int.parse(
                                      '0xFF$colorHex'.replaceAll('#', '')));

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
                        if (chatterdata['pilots'].isNotEmpty)
                          SizedBox(height: 10),
                        Text(
                          "Viewers (${chatterdata['passengers'].length})",
                          textAlign: TextAlign.left,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Column(
                            children: List.generate(
                              chatterdata['passengers'].length,
                              (index) {
                                List<String> sortedPassengers =
                                    List<String>.from(chatterdata['passengers'])
                                      ..sort((a, b) => a
                                          .toLowerCase()
                                          .compareTo(b.toLowerCase()));

                                String username = sortedPassengers[index];
                                String colorHex = getColorForUsername(username);
                                Color color = Color(int.parse(
                                    '0xFF$colorHex'.replaceAll('#', '')));

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
                )
              : Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      if (_controller.text.isNotEmpty) {
                        ref
                            .read(chatProvider.notifier)
                            .sendMessage("User", _controller.text, trueliveid!);
                        _controller.clear();
                      }
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Stack(children: [
                    Column(
                      children: [
                        Flexible(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              return Column(
                                children: [
                                  ListTile(
                                    tileColor:
                                        msg.notification ? Colors.orange : null,
                                    minLeadingWidth: 0,
                                    minVerticalPadding: 0,
                                    minTileHeight: 1,
                                    title: Text.rich(TextSpan(
                                        style: TextStyle(fontSize: 14),
                                        children: msg.text)),
                                  ),
                                  Divider(
                                    color: Colors.grey.shade800,
                                    thickness: 1,
                                    height: 1,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Column(
                          children: [
                            Consumer(
                              builder: (context, ref, child) {
                                final pollData = ref.watch(pollDataProvider);
                                final showPoll = ref.watch(pollProvider);
                                final pollNotifier =
                                    ref.watch(pollDataProvider.notifier);

                                if (pollData == null ||
                                    !pollNotifier.isPollActive()) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  children: [
                                    Container(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      height: 35,
                                      child: ListTile(
                                        dense: true,
                                        visualDensity: VisualDensity.compact,
                                        title: Text(
                                          "Poll",
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        onTap: () => ref
                                            .read(pollProvider.notifier)
                                            .state = !showPoll,
                                        trailing: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          iconSize: 15,
                                          icon: Icon(
                                            showPoll
                                                ? Icons.arrow_drop_down
                                                : Icons.arrow_drop_up,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(pollProvider.notifier)
                                                .state = !showPoll;
                                          },
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      height: showPoll ? null : 0,
                                      constraints: BoxConstraints(
                                        maxHeight: showPoll ? 300 : 0,
                                      ),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                      child: showPoll
                                          ? SingleChildScrollView(
                                              child: Padding(
                                                padding: EdgeInsets.all(12),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      pollData.title,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    if (pollNotifier
                                                            .isVotingActive() &&
                                                        !pollNotifier
                                                            .hasVoted) // Voting state
                                                      Column(
                                                        children: [
                                                          ...List.generate(
                                                            pollData
                                                                .options.length,
                                                            (index) =>
                                                                RadioListTile<
                                                                    String>(
                                                              title: Text(
                                                                pollData.options[
                                                                    index],
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              value: pollData
                                                                      .options[
                                                                  index],
                                                              groupValue:
                                                                  pollNotifier
                                                                      .selectedOption,
                                                              onChanged:
                                                                  (value) {
                                                                if (value !=
                                                                    null) {
                                                                  pollNotifier
                                                                      .selectOption(
                                                                          value);
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                          SizedBox(height: 8),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                pollNotifier
                                                                    .getRemainingTime(),
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white70),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: pollNotifier
                                                                            .selectedOption !=
                                                                        null
                                                                    ? () => pollNotifier
                                                                        .submitVote()
                                                                    : null,
                                                                child: Text(
                                                                    'Submit Vote'),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      )
                                                    else // Results state
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          ...List.generate(
                                                            pollData
                                                                .options.length,
                                                            (index) => Padding(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          8),
                                                              child: Row(
                                                                children: [
                                                                  Text(
                                                                    pollData.options[
                                                                        index],
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                  SizedBox(
                                                                      width: 8),
                                                                  Flexible(
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          20,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .primary,
                                                                        borderRadius:
                                                                            BorderRadius.circular(2),
                                                                      ),
                                                                      child:
                                                                          FractionallySizedBox(
                                                                        widthFactor:
                                                                            pollNotifier.getOptionPercentage(index) /
                                                                                100,
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        child:
                                                                            Container(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .primary,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      width: 8),
                                                                  Text(
                                                                    '${pollNotifier.getOptionPercentage(index).toStringAsFixed(1)}%',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(height: 4),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                pollNotifier
                                                                    .getRemainingTime(),
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white70),
                                                              ),
                                                              Text(
                                                                '${pollNotifier.getTotalVotes()} Total Votes',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white70),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : SizedBox.shrink(),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              height: 35,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              padding: EdgeInsets.only(top: 6),
                              child: ListTile(
                                minVerticalPadding: 0,
                                minTileHeight: 1,
                                dense: true,
                                title: Text("Emotes",
                                    style: TextStyle(fontSize: 16)),
                                onTap: () => ref
                                    .read(emotePickerProvider.notifier)
                                    .state = !showEmotePicker,
                                trailing: IconButton(
                                  iconSize: 15,
                                  icon: Icon(
                                    showEmotePicker
                                        ? Icons.arrow_drop_down
                                        : Icons.arrow_drop_up,
                                  ),
                                  onPressed: () => ref
                                      .read(emotePickerProvider.notifier)
                                      .state = !showEmotePicker,
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              height: showEmotePicker ? 90 : 0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              child: !emotesLoaded
                                  ? CircularProgressIndicator()
                                  : GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 35,
                                        crossAxisSpacing: 5,
                                        mainAxisSpacing: 5,
                                      ),
                                      itemCount: emotes.length,
                                      itemBuilder: (context, index) {
                                        return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () {
                                                _controller.text +=
                                                    ':${emotes[index].name}:';
                                              },
                                              child: Center(
                                                child: Image.network(
                                                  emotes[index].url,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ));
                                      },
                                    ),
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
                                controller: _controller,
                                onSubmitted: (String value) {
                                  ref.read(chatProvider.notifier).sendMessage(
                                      "User", _controller.text, trueliveid!);
                                  _controller.clear();
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
                                    "User", _controller.text, trueliveid!);
                                _controller.clear();
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Icon(Icons.arrow_downward),
                        ),
                      ),
                    ),
                  ])),
    ));
  }
}

import 'package:floaty/backend/fpwebsockets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/providers/live_chat_provider.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/backend/chat_utils.dart';

class LiveChat extends ConsumerStatefulWidget {
  const LiveChat({super.key, required this.liveid});
  final String liveid;

  @override
  ConsumerState<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends ConsumerState<LiveChat> {
  final TextEditingController _controller = TextEditingController();
  final _scrollController = ScrollController();
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
    await ref
        .read(chatProvider.notifier)
        //TODO: get live id from page
        .joinLiveChat('5c13f3c006f1be15e08e05c0', _controller);
    emotes = await ref.read(emotesProvider.future);
    setState(() {
      emotesLoaded = true;
    });
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

    // _scrollController.addListener

    String id = '5c13f3c006f1be15e08e05c0';

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
          elevation: 0,
          toolbarHeight: 40,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          surfaceTintColor: Theme.of(context).appBarTheme.backgroundColor,
          actions: [
            // IconButton(
            //   onPressed: () {
            //     ref.read(pollDataProvider.notifier).testPoll();
            //   },
            //   icon: Icon(Icons.warning),
            // ),
            IconButton(
              onPressed: () async {
                chatterdata = await fpWebsockets.chatterlist(id);
                if (chatterdata.isEmpty) {
                  ref
                      .read(errorProvider.notifier)
                      .setError(chatterdata.toString());
                  setState(() {
                    isChatterListOpen = !isChatterListOpen;
                  });
                } else {
                  setState(() {
                    isChatterListOpen = !isChatterListOpen;
                  });
                }
              },
              icon: isChatterListOpen ? Icon(Icons.chat) : Icon(Icons.list),
            )
          ],
          title: Text(isChatterListOpen ? "Viewer List" : "Live Chat",
              style: TextStyle(fontSize: 18))),
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
                            .sendMessage("User", _controller.text, id);
                        _controller.clear();
                      }
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Stack(children: [
                    Column(
                      children: [
                        Expanded(
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
                                            color: Colors.white,
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
                                            color: Colors.white,
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
                                      color: Colors.grey.shade800,
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
                                                        color: Colors.white,
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
                                                                  Expanded(
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          20,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .blue
                                                                            .shade700,
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
                                                                          color:
                                                                              Colors.blue,
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
                              color: Colors.grey.shade800,
                              padding: EdgeInsets.only(top: 6),
                              child: ListTile(
                                minVerticalPadding: 0,
                                minTileHeight: 1,
                                dense: true,
                                title: Text("Emotes",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                                onTap: () => ref
                                    .read(emotePickerProvider.notifier)
                                    .state = !showEmotePicker,
                                trailing: IconButton(
                                  iconSize: 15,
                                  icon: Icon(
                                      showEmotePicker
                                          ? Icons.arrow_drop_down
                                          : Icons.arrow_drop_up,
                                      color: Colors.white),
                                  onPressed: () => ref
                                      .read(emotePickerProvider.notifier)
                                      .state = !showEmotePicker,
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              height: showEmotePicker ? 90 : 0,
                              color: Colors.grey.shade800,
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
                                            child: InkWell(
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
                            Expanded(
                              child: TextField(
                                maxLength: 500,
                                maxLengthEnforcement:
                                    MaxLengthEnforcement.enforced,
                                minLines: 1,
                                maxLines: 2,
                                controller: _controller,
                                onSubmitted: (String value) {
                                  ref.read(chatProvider.notifier).sendMessage(
                                      "User", _controller.text, id);
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
                                ref
                                    .read(chatProvider.notifier)
                                    .sendMessage("User", _controller.text, id);
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
                          child:
                              Icon(Icons.arrow_downward, color: Colors.white),
                        ),
                      ),
                    ),
                  ])),
    ));
  }
}

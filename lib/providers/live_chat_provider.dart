import 'package:floaty/backend/fpapi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/fpwebsockets.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:floaty/backend/chat_utils.dart';
import 'package:floaty/frontend/root.dart';

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ParsedChatMessage>>((ref) {
  return ChatNotifier(ref);
});

final emotePickerProvider = StateProvider<bool>((ref) => false);
final pollProvider = StateProvider<bool>((ref) => false);
final chatbroken = StateProvider<bool>((ref) => false);
final errorProvider = StateNotifierProvider<ErrorNotifier, ErrorState>((ref) {
  return ErrorNotifier();
});

class ErrorState {
  final bool hasError;
  final String errorMessage;

  ErrorState({this.hasError = false, this.errorMessage = ''});
}

class ErrorNotifier extends StateNotifier<ErrorState> {
  ErrorNotifier() : super(ErrorState());

  void setError(String message) {
    state = ErrorState(hasError: true, errorMessage: message);
  }
}

class ParsedChatMessage {
  final List<InlineSpan> text;
  final bool notification;

  ParsedChatMessage({required this.text, required this.notification});
}

class Emote {
  final String name;
  final String url;

  Emote({required this.name, required this.url});

  factory Emote.fromJson(Map<String, dynamic> json) {
    return Emote(name: json['code'], url: json['image']);
  }
}

class EmoteResult {
  final bool isValid;
  final Emote? emote;

  EmoteResult(this.isValid, this.emote);
}

final emotesProvider = FutureProvider<List<Emote>>((ref) {
  return ref.watch(chatProvider.notifier).getEmotes();
});

class ChatNotifier extends StateNotifier<List<ParsedChatMessage>> {
  ChatNotifier(this.ref) : super([]);
  List<Emote> emotes = [];
  bool emotesLoaded = false;
  late TextEditingController controller;
  final dynamic ref;

  Future<bool> joinLiveChat(String id, TextEditingController controller) async {
    this.controller = controller;
    await fpWebsockets.connect(ref);
    final res = await fpWebsockets.joinLiveChat(id);
    await fpWebsockets.joinpoll(id);
    if (res['success'] == false) {
      ref.read(errorProvider.notifier).setError(res.toString());
      return false;
    }
    emotes = [];
    res['emotes'].forEach((emote) {
      emotes = [
        ...emotes,
        Emote(name: emote['code'], url: emote['image']),
      ];
    });
    return true;
  }

  List<Emote> getEmotes() {
    return emotes;
  }

  void sendMessage(String username, String message, String id,
      {bool isModerator = false, bool isCreator = true}) {
    if (message.isNotEmpty) {
      fpWebsockets.sendMessage(id, message);
    }
  }

  void recieveMessage(ParsedChatMessage message) {
    state = [
      ...state,
      message,
    ];
  }

  List<InlineSpan> parseMessage(ChatMessage message) {
    final emoteRegex = RegExp(r':([a-zA-Z0-9_-]+):');
    final pingRegex = RegExp(r'@(\w+)(?=:|[^:\w]|$)');

    List<InlineSpan> spans = [];
    int lastIndex = 0;

    Color namecolor = message.username == 'System'
        ? Colors.white
        : getColorForUsernameColor(message.username);

    bool isAdmin =
        message.userType == 'Moderator' || message.username == 'System';

    if (isAdmin) {
      spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(Icons.settings, size: 14)));
    }

    spans.add(WidgetSpan(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: (4.0)),
            child: TextButton(
              onPressed: () {
                controller.text += ' @${message.username}';
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  EdgeInsets.only(left: 4, right: 4),
                ),
                minimumSize: WidgetStateProperty.all(Size(0, 0)),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return namecolor.withValues(alpha: 0.25);
                  }
                  return Colors.transparent;
                }),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
              ),
              child: Text(
                message.username,
                style: TextStyle(
                  color: namecolor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ))));

    void addTextSpan(String text) {
      if (text.isNotEmpty) {
        //i hate this
        String processedText = text
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'")
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&cent;', '¢')
            .replaceAll('&pound;', '£')
            .replaceAll('&yen;', '¥')
            .replaceAll('&euro;', '€')
            .replaceAll('&copy;', '©')
            .replaceAll('&reg;', '®')
            .replaceAll('&agrave;', 'à')
            .replaceAll('&aacute;', 'á')
            .replaceAll('&acirc;', 'â')
            .replaceAll('&atilde;', 'ã')
            .replaceAll('&Ograve;', 'Ò')
            .replaceAll('&Oacute;', 'Ó')
            .replaceAll('&Ocirc;', 'Ô')
            .replaceAll('&Otilde;', 'Õ');
        spans.add(TextSpan(text: processedText));
      }
    }

    List<Emote> messageemotes = message.emotes ?? [];

    EmoteResult findEmote(String emoteName) {
      try {
        Emote emote = messageemotes.firstWhere((e) => e.name == emoteName);
        return EmoteResult(true, emote);
      } catch (e) {
        return EmoteResult(false, null);
      }
    }

    List<Match> emoteMatches = emoteRegex.allMatches(message.message).toList();
    List<Match> pingMatches = pingRegex.allMatches(message.message).toList();

    List<Map<String, dynamic>> allMatches = [];

    for (var match in emoteMatches) {
      allMatches.add({
        'type': 'emote',
        'match': match,
        'start': match.start,
        'end': match.end
      });
    }

    for (var match in pingMatches) {
      allMatches.add({
        'type': 'ping',
        'match': match,
        'start': match.start,
        'end': match.end
      });
    }

    allMatches.sort((a, b) => a['start'].compareTo(b['start']));

    for (var matchData in allMatches) {
      if (lastIndex < matchData['start']) {
        addTextSpan(message.message.substring(lastIndex, matchData['start']));
      }

      if (matchData['type'] == 'emote') {
        var emoteMatch = matchData['match'] as Match;
        String emoteName = emoteMatch.group(1)!;
        EmoteResult result = findEmote(emoteName);

        if (result.isValid) {
          spans.add(WidgetSpan(
            child: Image.network(
              result.emote!.url,
              fit: BoxFit.cover,
              height: 20,
            ),
          ));
        } else {
          spans.add(TextSpan(text: emoteMatch.group(0)!));
        }
      } else if (matchData['type'] == 'ping') {
        var pingMatch = matchData['match'] as Match;
        String pingText = pingMatch.group(0)!;
        Color pingcolor = getColorForUsernameColor(pingText.substring(1));

        spans.add(WidgetSpan(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: (4.0)),
                child: TextButton(
                  onPressed: () {
                    controller.text += pingText;
                  },
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(
                      EdgeInsets.only(left: 4, right: 4),
                    ),
                    minimumSize: WidgetStateProperty.all(Size(0, 0)),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return pingcolor.withValues(alpha: 0.25);
                      }
                      return pingText.substring(1) ==
                              rootLayoutKey.currentState?.user!.username
                          ? Theme.of(rootLayoutKey.currentState!.context)
                              .colorScheme
                              .primary
                          : Colors.transparent;
                    }),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Text(
                    pingText,
                    style: TextStyle(
                      color: pingText.substring(1) ==
                              rootLayoutKey.currentState?.user!.username
                          ? Colors.white
                          : pingcolor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ))));
      }

      lastIndex = matchData['end'];
    }

    if (lastIndex < message.message.length) {
      addTextSpan(message.message.substring(lastIndex));
    }

    return spans;
  }

  void reset(String id) async {
    state = [];
  }
}

class PollObject {
  final String id;
  final String type;
  final String creator;
  final String title;
  final List<String> options;
  final String startDate;
  final String endDate;
  final TallyObject runningTally;

  PollObject(
      {required this.id,
      required this.type,
      required this.creator,
      required this.title,
      required this.options,
      required this.startDate,
      required this.endDate,
      required this.runningTally});

  factory PollObject.fromJson(Map<String, dynamic> json) {
    return PollObject(
      id: json['id'],
      type: json['type'],
      creator: json['creator'],
      title: json['title'],
      options: json['options'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      runningTally: TallyObject.fromJson(json['runningTally']),
    );
  }

  PollObject copyWith({
    String? id,
    String? type,
    String? creator,
    String? title,
    List<String>? options,
    String? startDate,
    String? endDate,
    TallyObject? runningTally,
  }) {
    return PollObject(
      id: id ?? this.id,
      type: type ?? this.type,
      creator: creator ?? this.creator,
      title: title ?? this.title,
      options: options ?? this.options,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      runningTally: runningTally ?? this.runningTally,
    );
  }
}

class TallyObject {
  final int tick;
  final List<int> counts;

  TallyObject({required this.tick, required this.counts});

  factory TallyObject.fromJson(Map<String, dynamic> json) {
    return TallyObject(
      tick: json['tick'],
      counts: json['counts'],
    );
  }
}

class TallyUpdateObject {
  final int tick;
  final List<int> counts;
  final String pollId;

  TallyUpdateObject(
      {required this.tick, required this.counts, required this.pollId});

  factory TallyUpdateObject.fromJson(Map<String, dynamic> json) {
    return TallyUpdateObject(
      tick: json['tick'],
      counts: json['counts'],
      pollId: json['pollId'],
    );
  }
}

final pollDataProvider =
    StateNotifierProvider<PollNotifier, PollObject?>((ref) {
  return PollNotifier(ref);
});

class PollNotifier extends StateNotifier<PollObject?> {
  PollNotifier(this.ref) : super(null);
  final dynamic ref;
  String? selectedOption;
  bool hasVoted = false;
  DateTime? endTime;
  Timer? _updateTimer;
  bool test = false;

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void openPoll(PollObject poll) {
    state = poll;
    endTime = DateTime.parse(poll.endDate);
    selectedOption = null;
    hasVoted = false;

    // Start a timer to update UI every second
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (state != null) {
        state = state!.copyWith(); // Force UI update
      }
    });
  }

  void closePoll(PollObject poll) {
    state = poll;
    endTime = DateTime.parse(poll.endDate);
  }

  void testPoll() {
    test = true;
    final testPoll = PollObject(
      id: 'test-poll-123',
      type: 'simple',
      creator: 'test-creator',
      title: 'Test Poll',
      options: ['Option A', 'Option B', 'Option C'],
      startDate: DateTime.now().toIso8601String(),
      endDate: DateTime.now().add(Duration(seconds: 7)).toIso8601String(),
      runningTally: TallyObject(
        tick: 0,
        counts: [5, 3, 2],
      ),
    );
    openPoll(testPoll);
  }

  void updateTally(TallyUpdateObject update) {
    if (state?.id == update.pollId) {
      state = state!.copyWith(
        runningTally: TallyObject(
          tick: update.tick,
          counts: update.counts,
        ),
      );
    }
  }

  void selectOption(String option) {
    if (!hasVoted && state != null) {
      selectedOption = option;
      state = state!.copyWith(); // Force UI update
    }
  }

  void submitVote() {
    if (!hasVoted && state != null && selectedOption != null) {
      hasVoted = true;
      if (test) {
        final currentTally = state!.runningTally.counts;
        final index = state!.options.indexOf(selectedOption!);
        if (index != -1) {
          List<int> newCounts = List.from(currentTally);
          newCounts[index]++;
          state = state!.copyWith(
            runningTally: TallyObject(
              tick: state!.runningTally.tick + 1,
              counts: newCounts,
            ),
          );
        }
      } else {
        fpApiRequests.submitVote(
            state!.id, state!.options.indexOf(selectedOption!));
      }
    }
  }

  bool isPollActive() {
    if (state == null || endTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(endTime!);

    // Show poll for 25 seconds after it ends
    if (difference.inSeconds <= 25) {
      return true;
    }

    // Schedule state clear after 25 seconds
    if (difference.inSeconds > 25 && state != null) {
      Future(() {
        _updateTimer?.cancel();
        state = null;
      });
    }

    // Return true if poll hasn't ended yet
    return difference.isNegative;
  }

  bool isVotingActive() {
    if (state == null || endTime == null) return false;
    return DateTime.now().isBefore(endTime!);
  }

  String getRemainingTime() {
    if (endTime == null) return '';
    final now = DateTime.now();
    final difference = endTime!.difference(now);

    if (difference.isNegative) {
      final afterEnd = now.difference(endTime!);
      if (afterEnd.inSeconds <= 25) {
        return 'Poll ended';
      }
      return 'Poll ended';
    }

    return '${difference.inSeconds}s remaining';
  }

  int getTotalVotes() {
    if (state == null) return 0;
    return state!.runningTally.counts.fold(0, (sum, count) => sum + count);
  }

  double getOptionPercentage(int index) {
    if (state == null || index >= state!.runningTally.counts.length) return 0;
    final total = getTotalVotes();
    if (total == 0) return 0;
    return (state!.runningTally.counts[index] / total) * 100;
  }
}

class WebSocketEventHandler {
  final Ref ref;

  WebSocketEventHandler(this.ref);

  void handlePollOpen(Map<String, dynamic> data) {
    final poll = PollObject.fromJson(data['poll']);
    ref.read(pollDataProvider.notifier).openPoll(poll);
  }

  void handlePollClose(Map<String, dynamic> data) {
    final poll = PollObject.fromJson(data['poll']);
    ref.read(pollDataProvider.notifier).closePoll(poll);
  }

  void handlePollUpdateTally(Map<String, dynamic> data) {
    final pollUpdate = TallyUpdateObject.fromJson(data);
    ref.read(pollDataProvider.notifier).updateTally(pollUpdate);
  }

  void handleRadioChatter(Map<String, dynamic> data) async {
    final radioChatter = ChatMessage.fromJson(data);
    bool notif = radioChatter.username == 'System';
    final parsedtext =
        ref.read(chatProvider.notifier).parseMessage(radioChatter);
    final message = ParsedChatMessage(text: parsedtext, notification: notif);
    ref.read(chatProvider.notifier).recieveMessage(message);
  }
}

class ChatMessage {
  final String id;
  final String? userGUID;
  final String username;
  final String channel;
  final String message;
  final String userType;
  final List<Emote>? emotes;
  final bool success;

  ChatMessage({
    required this.id,
    this.userGUID,
    required this.username,
    required this.channel,
    required this.message,
    required this.userType,
    this.emotes,
    required this.success,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      userGUID: json['userGUID'],
      username: json['username'],
      channel: json['channel'],
      message: json['message'],
      userType: json['userType'],
      emotes: json['emotes'] == null
          ? null
          : (json['emotes'] as List).map((e) => Emote.fromJson(e)).toList(),
      success: json['success'],
    );
  }
}

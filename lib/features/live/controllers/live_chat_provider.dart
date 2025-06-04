// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/features/api/repositories/fpwebsockets.dart';
import 'package:flutter/material.dart';
import 'package:floaty/features/api/utils/chat_utils.dart';
import 'package:floaty/features/router/views/root_layout.dart';
import 'package:floaty/features/api/models/ws_definitions.dart';
import 'package:floaty/settings.dart';

final webSocketEventHandlerProvider = Provider<WebSocketEventHandler>((ref) {
  return WebSocketEventHandler(ref);
});

final chatProvider =
    StateNotifierProvider<ChatManager, List<ParsedChatMessage>>((ref) {
  return ChatManager(ref);
});

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

class ChatManager extends StateNotifier<List<ParsedChatMessage>> {
  ChatManager(this.ref) : super([]);
  final dynamic ref;

  void addMessage(ParsedChatMessage message) {
    state = [
      ...state,
      message,
    ];
  }

  Future<List<InlineSpan>> parseMessage(
      ChatMessage message, TextEditingController controller) async {
    final emoteRegex = RegExp(r':([a-zA-Z0-9_-]+):');
    final pingRegex = RegExp(r'@(\w+)(?=:|[^:\w]|$)');

    bool showTimestamps =
        await settings.getBool('timestamp_messages', defaultValue: false);
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

    List<InlineSpan> spans = [];
    int lastIndex = 0;

    Color namecolor = message.username == 'System'
        ? Colors.white
        : await settings.getBool('show_username_colors', defaultValue: true)
            ? getColorForUsernameColor(message.username)
            : Theme.of(rootLayoutKey.currentState!.context).colorScheme.primary;

    bool isAdmin =
        message.userType == 'Moderator' || message.username == 'System';

    if (showTimestamps) {
      final localTime = message.sentAt.toLocal();
      spans.add(TextSpan(
          text:
              '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')} ',
          style: TextStyle(
              fontSize: fontSize,
              color: Theme.of(rootLayoutKey.currentState!.context)
                  .colorScheme
                  .tertiary)));
    }

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
                  fontSize: fontSize,
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
        spans.add(TextSpan(
            text: processedText, style: TextStyle(fontSize: fontSize)));
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
              height: emoteSize,
            ),
          ));
        } else {
          spans.add(TextSpan(text: emoteMatch.group(0)!));
        }
      } else if (matchData['type'] == 'ping') {
        var pingMatch = matchData['match'] as Match;
        String pingText = pingMatch.group(0)!;
        Color pingcolor = await settings.getBool('show_username_colors',
                defaultValue: true)
            ? getColorForUsernameColor(pingText.substring(1))
            : Theme.of(rootLayoutKey.currentState!.context).colorScheme.primary;

        bool highlightMentions =
            await settings.getBool('highlight_mentions', defaultValue: true);
        bool pingSound = await settings.getBool('play_sound_when_mentioned',
            defaultValue: false);

        if (pingText.substring(1) ==
                rootLayoutKey.currentState?.user!.username &&
            pingSound) {
          final player = AudioPlayer();
          await player.play(AssetSource('livechat/pop.wav'));
          player.onPlayerComplete.listen((event) {
            player.dispose();
          });
        }

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
                      return highlightMentions &&
                              pingText.substring(1) ==
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
                      color: highlightMentions &&
                              pingText.substring(1) ==
                                  rootLayoutKey.currentState?.user!.username
                          ? Colors.white
                          : pingcolor,
                      fontWeight: FontWeight.bold,
                      fontSize: pingSize,
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

  void reset() async {
    state = [];
  }

  void chatDisconnect() {
    state = [];
    ref.read(webSocketEventHandlerProvider).chatDisconnect();
  }

  void sendMessage(String username, String message, String id,
      {bool isModerator = false, bool isCreator = true}) {
    if (message.isNotEmpty) {
      ref.read(webSocketEventHandlerProvider).sendMessage(username, message, id,
          isModerator: isModerator, isCreator: isCreator);
    }
  }
}

final chatterlistprovider =
    StateNotifierProvider<ChatterListManager, Map<String, dynamic>>((ref) {
  return ChatterListManager(ref);
});

class ChatterListManager extends StateNotifier<Map<String, dynamic>> {
  ChatterListManager(this.ref) : super({});
  final dynamic ref;

  void updateUserList(Map<String, dynamic> userlist) {
    state = userlist;
  }

  void getChatterList(String creatorId) {
    fpWebsockets.getChatUserList(creatorId, (data) {
      ref.read(chatterlistprovider.notifier).updateUserList(data['data']);
    });
  }

  void reset() {
    state = {};
  }
}

class PollWrapper {
  final Poll poll;
  final bool isOpen;

  PollWrapper({required this.poll, required this.isOpen});
}

final pollprovider =
    StateNotifierProvider<PollManager, List<PollWrapper>>((ref) {
  return PollManager(ref);
});

class PollManager extends StateNotifier<List<PollWrapper>> {
  PollManager(this.ref) : super([]);
  final dynamic ref;

  void openPoll(Poll poll) {
    state = [
      ...state,
      PollWrapper(poll: poll, isOpen: true),
    ];
  }

  void closePoll(Poll poll) async {
    state = state.map((p) {
      if (p.poll.id == poll.id) {
        return PollWrapper(
          isOpen: false,
          poll: p.poll,
        );
      }
      return p;
    }).toList();

    Timer(const Duration(seconds: 30), () {
      if (mounted) {
        state = state.where((p) => p.poll.id != poll.id).toList();
      }
    });
  }

  void updateTally(TallyUpdate update) {
    state = state.map((p) {
      if (p.poll.id == update.pollId) {
        final updatedTally = RunningTally(
          tick: p.poll.runningTally.tick,
          counts: update.counts,
        );
        return PollWrapper(
          isOpen: p.isOpen,
          poll: Poll(
            id: p.poll.id,
            type: p.poll.type,
            creator: p.poll.creator,
            title: p.poll.title,
            options: p.poll.options,
            startDate: p.poll.startDate,
            endDate: p.poll.endDate,
            finalTallyApproximate: p.poll.finalTallyApproximate,
            finalTallyReal: p.poll.finalTallyReal,
            runningTally: updatedTally,
          ),
        );
      }
      return p;
    }).toList();
  }

  void reset() {
    state = [];
  }
}

final emotepickerProvider =
    StateNotifierProvider<EmotePickerManager, List<Emote>>((ref) {
  return EmotePickerManager(ref);
});

class EmotePickerManager extends StateNotifier<List<Emote>> {
  EmotePickerManager(this.ref) : super([]);
  final dynamic ref;

  void updateEmotes(Map<String, dynamic> emotes) {
    state = (emotes['emotes'] as List).map<Emote>((e) {
      return Emote.fromJson(e as Map<String, dynamic>);
    }).toList();
  }

  void reset() {
    state = [];
  }
}

final connectionProvider =
    StateNotifierProvider<ConnectionManager, Map<String, dynamic>>((ref) {
  return ConnectionManager(ref);
});

class ConnectionManager extends StateNotifier<Map<String, dynamic>> {
  ConnectionManager(this.ref) : super({});
  final dynamic ref;

  void updateConnectionState(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (data['color'] == 'success') {
        Future.delayed(const Duration(seconds: 7), () {
          ref.read(connectionProvider.notifier).reset();
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state = data;
    });
  }

  void reset() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state = {};
    });
  }
}

class WebSocketEventHandler {
  final Ref ref;
  WebSocketEventHandler(this.ref);
  TextEditingController? controller;

  void submitVote(String pollId, int optionIndex) {
    fpApiRequests.submitVote(pollId, optionIndex);
  }

  void sendMessage(String username, String message, String id,
      {bool isModerator = false, bool isCreator = true}) {
    if (message.isNotEmpty) {
      fpWebsockets.sendChatMessage(id, message, messagesHandler);
    }
  }

  void chatConnect(
      String liveId, String creatorId, TextEditingController controller) {
    this.controller = controller;
    fpWebsockets.chatConnect(liveId, messagesHandler, connectionHandler);
    fpWebsockets.pollConnect(creatorId, messagesHandler);
  }

  void chatDisconnect(String creatorId) {
    fpWebsockets.chatDisconnect(connectionHandler);
    fpWebsockets.pollDisconnect(
      creatorId,
      connectionHandler,
    );
  }

  void reset() {
    ref.read(emotepickerProvider.notifier).reset();
    ref.read(chatterlistprovider.notifier).reset();
    ref.read(chatProvider.notifier).reset();
    ref.read(pollprovider.notifier).reset();
  }

  void messagesHandler(Map<String, dynamic> data) async {
    if (data['socket'] == 'chat') {
      if (data['type'] == 'radioChatter') {
        final radioChatter = ChatMessage.fromJson(data['data']);
        bool notif = radioChatter.username == 'System';
        final parsedtext = await ref
            .read(chatProvider.notifier)
            .parseMessage(radioChatter, controller!);
        final message =
            ParsedChatMessage(text: parsedtext, notification: notif);
        ref.read(chatProvider.notifier).addMessage(message);
      } else if (data['type'] == 'getChatUserList') {
        ref.read(chatterlistprovider.notifier).updateUserList(data['data']);
      } else if (data['type'] == 'joinResponse') {
        ref.read(emotepickerProvider.notifier).updateEmotes(data['data']);
      }
    } else if (data['socket'] == 'poll') {
      if (data['type'] == 'open') {
        ref.read(pollprovider.notifier).openPoll(Poll.fromJson(data['data']));
      } else if (data['type'] == 'close') {
        ref.read(pollprovider.notifier).closePoll(Poll.fromJson(data['data']));
      } else if (data['type'] == 'updateTally') {
        ref
            .read(pollprovider.notifier)
            .updateTally(TallyUpdate.fromJson(data['data']));
      } else if (data['type'] == 'joinResponse') {
        ref.read(pollprovider.notifier).reset();
        for (var poll in data['data']['activePolls']) {
          ref.read(pollprovider.notifier).openPoll(Poll.fromJson(poll));
        }
      }
    }
  }

  void connectionHandler(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionProvider.notifier).updateConnectionState(data);
    });
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
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    this.userGUID,
    required this.username,
    required this.channel,
    required this.message,
    required this.userType,
    this.emotes,
    required this.success,
    required this.sentAt,
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
      sentAt: DateTime.parse(json['sentAt']),
    );
  }
}

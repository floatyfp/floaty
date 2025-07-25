import 'dart:async';
import 'package:floaty/features/api/utils/socket_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io_client;
import 'package:sails_io/sails_io.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

final FPWebsockets fpWebsockets = GetIt.I<FPWebsockets>();

class FPWebsockets {
  late final SailsIOClient io;
  late final SailsIOClient fpio;
  final String token;
  String? liveid;
  String userAgent;
  PackageInfo? packageInfo;
  Function(dynamic)? _radioChatterHandler;
  Function(dynamic)? _pollOpenHandler;
  Function(dynamic)? _pollCloseHandler;
  Function(dynamic)? _pollUpdateTallyHandler;

  @override
  FPWebsockets({required this.token, required this.userAgent}) {
    io = SailsIOClient(socket_io_client.io(
        'https://chat.floatplane.com?__sails_io_sdk_version=0.13.8&__sails_io_sdk_platform=node&__sails_io_sdk_language=javascript',
        socket_io_client.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({
              'User-Agent': userAgent,
              'Cookie': token,
              'Origin': 'https://www.floatplane.com'
            })
            .disableAutoConnect()
            .enableForceNew()
            .enableForceNewConnection()
            .build()));
    fpio = SailsIOClient(socket_io_client.io(
        'https://floatplane.com?__sails_io_sdk_version=1.2.1&__sails_io_sdk_platform=node&__sails_io_sdk_language=javascript&EIO=3&transport=websocket',
        socket_io_client.OptionBuilder()
            .setTransports(['websocket']).setExtraHeaders({
          'User-Agent': userAgent,
          'Cookie': token,
          'Origin': 'https://www.floatplane.com'
        }).build()));
  }

  // CHAT STUFF FROM HERE

  void chatConnect(
      String liveId,
      Function(Map<String, dynamic>) messagesHandler,
      Function(Map<String, dynamic>) connectionHandler) {
    io.socket.connect();

    joinLiveChatRoom(liveId, messagesHandler);

    unifiedConnectionListener(connectionHandler, io.socket);

    // Remove any existing handler first
    if (_radioChatterHandler != null) {
      io.socket.off('radioChatter', _radioChatterHandler!);
    }

    // Create and store the new handler
    _radioChatterHandler = (data) {
      messagesHandler({'socket': 'chat', 'type': 'radioChatter', 'data': data});
    };

    // Add the new handler
    io.socket.on('radioChatter', _radioChatterHandler!);
  }

  void chatDisconnect(Function(Map<String, dynamic>) connectionHandler) {
    io.socket.disconnect();
    io.socket.dispose();
    connectionHandler(
        {'connected': false, 'color': 'success', 'message': 'Disconnected'});
  }

  joinLiveChatRoom(
      String id, Function(Map<String, dynamic>) messagesHandler) async {
    liveid = id;
    io.get(
      url: '/RadioMessage/joinLivestreamRadioFrequency',
      data: {'channel': '/live/$id', 'message': null},
      cb: (data, jwr) {
        messagesHandler(
            {'socket': 'chat', 'type': 'joinResponse', 'data': data});
      },
    );
  }

  sendChatMessage(String id, String message,
      Function(Map<String, dynamic>) messagesHandler) async {
    io.post(
        url: '/RadioMessage/sendLivestreamRadioChatter',
        data: {'channel': '/live/$id', 'message': message},
        cb: (data, jwr) {
          messagesHandler(
              {'socket': 'chat', 'type': 'messageResponse', 'data': data});
        });
  }

  getChatUserList(
      String id, Function(Map<String, dynamic>) messagesHandler) async {
    io.get(
      url: '/RadioMessage/getChatUserList',
      data: {'channel': '/live/$id'},
      cb: (data, jwr) {
        messagesHandler(
            {'socket': 'chat', 'type': 'getChatUserList', 'data': data});
      },
    );
  }

  // POLL STUFF FROM HERE

  void pollConnect(
      String creatorId, Function(Map<String, dynamic>) messagesHandler) {
    joinPollRoom(creatorId, messagesHandler);

    // Remove any existing handler first
    if (_pollOpenHandler != null) {
      fpio.socket.off('pollOpen', _pollOpenHandler!);
    }

    // Create and store the new handler
    _pollOpenHandler = (data) {
      messagesHandler({'socket': 'poll', 'type': 'open', 'data': data});
    };

    // Add the new handler
    fpio.socket.on('pollOpen', _pollOpenHandler!);

    // Remove any existing handler first
    if (_pollCloseHandler != null) {
      fpio.socket.off('pollClose', _pollCloseHandler!);
    }

    // Create and store the new handler
    _pollCloseHandler = (data) {
      messagesHandler({'socket': 'poll', 'type': 'close', 'data': data});
    };

    // Add the new handler
    fpio.socket.on('pollClose', _pollCloseHandler!);

    // Remove any existing handler first
    if (_pollUpdateTallyHandler != null) {
      fpio.socket.off('pollUpdateTally', _pollUpdateTallyHandler!);
    }

    // Create and store the new handler
    _pollUpdateTallyHandler = (data) {
      messagesHandler({'socket': 'poll', 'type': 'updateTally', 'data': data});
    };

    // Add the new handler
    fpio.socket.on('pollUpdateTally', _pollUpdateTallyHandler!);
  }

  void pollDisconnect(
      String creatorId, Function(Map<String, dynamic>) messagesHandler) {
    leavePollRoom(creatorId, messagesHandler);
  }

  //if theres any floatplane devs reading this garbage code why isnt this on the chat endpoint?
  Future<void> joinPollRoom(
      String id, Function(Map<String, dynamic>) messagesHandler) async {
    fpio.post(
      url: '/api/v3/poll/live/joinroom',
      headers: {'Cookie': token},
      data: {'creatorId': id},
      cb: (data, jwr) {
        messagesHandler(
            {'socket': 'poll', 'type': 'joinResponse', 'data': data});
      },
    );
  }

  Future<void> leavePollRoom(
      String id, Function(Map<String, dynamic>) messagesHandler) async {
    fpio.post(
      url: '/api/v3/poll/live/leaveroom',
      headers: {'Cookie': token},
      data: {'creatorId': id},
      cb: (data, jwr) {
        messagesHandler(
            {'socket': 'poll', 'type': 'leaveResponse', 'data': data});
      },
    );
  }
}

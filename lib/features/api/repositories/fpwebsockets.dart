import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as socket_io_client;
import 'package:sails_io/sails_io.dart';
import 'package:get_it/get_it.dart';
import 'package:floaty/features/live/controllers/live_chat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final FPWebsockets fpWebsockets = GetIt.I<FPWebsockets>();

class FPWebsockets {
  late final SailsIOClient io;
  late final SailsIOClient fpio;
  final String token;
  late Ref cref;
  String? liveid;
  bool autoReconnect = false;

  bool get connected => io.socket.connected;
  bool get pollConnected => fpio.socket.connected;
  PackageInfo? packageInfo;
  String userAgent = 'FloatyClient/error, CFNetwork';

  @override
  FPWebsockets({required this.token}) {
    _init();
    io = SailsIOClient(socket_io_client.io(
        'https://chat.floatplane.com?__sails_io_sdk_version=0.13.8&__sails_io_sdk_platform=node&__sails_io_sdk_language=javascript',
        socket_io_client.OptionBuilder()
            .setTransports(['websocket']).setExtraHeaders({
          'User-Agent': userAgent,
          'Cookie': token,
          'Origin': 'https://www.floatplane.com'
        }).build()));
    fpio = SailsIOClient(socket_io_client.io(
        'https://chat.floatplane.com?__sails_io_sdk_version=0.13.8&__sails_io_sdk_platform=node&__sails_io_sdk_language=javascript',
        socket_io_client.OptionBuilder()
            .setTransports(['websocket']).setExtraHeaders({
          'User-Agent': userAgent,
          'Cookie': token,
          'Origin': 'https://www.floatplane.com'
        }).build()));

    fpio.socket.on('pollOpen', (data) {
      WebSocketEventHandler(cref).handlePollOpen(data);
    });

    fpio.socket.on('pollClose', (data) {
      WebSocketEventHandler(cref).handlePollClose(data);
    });

    fpio.socket.on('pollUpdateTally', (data) {
      WebSocketEventHandler(cref).handlePollUpdateTally(data);
    });

    io.socket.on('radioChatter', (data) {
      WebSocketEventHandler(cref).handleRadioChatter(data);
    });

    io.socket.onDisconnect((_) {
      if (autoReconnect && liveid != null) {
        io.socket.connect();
        joinLiveChat(liveid!);
      }
    });

    fpio.socket.onDisconnect((_) {
      if (autoReconnect && liveid != null) {
        fpio.socket.connect();
        joinpoll(liveid!);
      }
    });
  }

  Future<void> _init() async {
    packageInfo = await PackageInfo.fromPlatform();
    userAgent = 'FloatyClient/${packageInfo?.version}, CFNetwork';
  }

  Future<Map<String, dynamic>> joinLiveChat(String id) async {
    liveid = id;
    Map<String, dynamic> dedata = {};
    io.get(
        url: '/RadioMessage/joinLivestreamRadioFrequency',
        data: {'channel': '/live/$id', 'message': null},
        cb: (data, jwr) {
          dedata = data;
        });
    while (dedata.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (dedata['success'] == false || dedata.isEmpty) {
      return {'success': false};
    }
    return dedata;
  }

  Future<void> leaveLiveChat(String id) async {
    io.post(
        url: '/RadioMessage/leaveLivestreamRadioFrequency',
        data: {'channel': '/live/$id', 'message': 'bye!'},
        cb: (data, jwr) {});
  }

  Future<void> sendMessage(String id, String message) async {
    io.post(
        url: '/RadioMessage/sendLivestreamRadioChatter',
        data: {'channel': '/live/$id', 'message': message},
        cb: (data, jwr) {});
  }

  Future<Map<String, dynamic>> chatterlist(String id) async {
    Map<String, dynamic> dedata = {};
    io.get(
        url: '/RadioMessage/getChatUserList',
        data: {'channel': '/live/$id'},
        cb: (data, jwr) {
          dedata = data;
        });
    while (dedata.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (dedata['success'] == false || dedata.isEmpty) {
      return {'success': false};
    }
    return dedata;
  }

  //if theres any floatplane devs reading this garbage code why isnt this on the chat endpoint?
  Future<void> joinpoll(String id) async {
    fpio.post(
        url: '/api/v3/poll/live/joinroom',
        data: {'creatorid': id},
        cb: (data, jwr) {});
  }

  Future<void> leavepoll(String id) async {
    fpio.post(
        url: '/api/v3/poll/live/leaveroom',
        data: {'creatorid': id},
        cb: (data, jwr) {});
  }

  Future<void> connect(Ref ref) async {
    autoReconnect = true;
    cref = ref;
    // Create a Completer for the new connection attempt
    final Completer<void> completer = Completer<void>();

    // Flag to track if the completer has been completed
    bool isCompleted = false;

    // Callback for successful connection
    void onConnectCallback(_) {
      if (!isCompleted) {
        completer.complete(); // Complete the Future
        isCompleted = true; // Mark as completed
      }
    }

    // Callback for connection errors
    void onConnectErrorCallback(error) {
      if (!isCompleted) {
        completer.completeError(error); // Complete the Future with an error
        isCompleted = true; // Mark as completed
      }
    }

    // Callback for disconnection
    void onDisconnectCallback(_) {
      if (!isCompleted) {
        completer.completeError(
            'Disconnected unexpectedly'); // Handle unexpected disconnection
        isCompleted = true; // Mark as completed
      }
    }

    // Add listeners for socket events
    io.socket.onConnect(onConnectCallback);
    io.socket.onConnectError(onConnectErrorCallback);
    io.socket.onDisconnect(onDisconnectCallback);
    fpio.socket.onConnect(onConnectCallback);
    fpio.socket.onConnectError(onConnectErrorCallback);
    fpio.socket.onDisconnect(onDisconnectCallback);

    // Initiate the socket connection
    io.socket.connect();
    fpio.socket.connect();

    // Return the Future from the Completer
    return completer.future;
  }

  void disconnect() {
    autoReconnect = false;
    io.socket.disconnect();
    fpio.socket.disconnect();
  }
}

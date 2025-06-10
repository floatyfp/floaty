import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final StreamController<Uri> _linkStreamController =
      StreamController<Uri>.broadcast();
  final List<String> _ignoredPaths = ['/settings', '/account'];
  GoRouter? _router;

  factory DeepLinkService() {
    return _instance;
  }

  DeepLinkService._internal();

  void setRouter(GoRouter router) {
    _router = router;
  }

  Stream<Uri> get linkStream => _linkStreamController.stream;

  void initDeepLinks() {
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (Object error) {
      debugPrint('Deep link error: $error');
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Handling deep link: $uri');
    _linkStreamController.add(uri);

    if (_router == null) return;

    if (_ignoredPaths.any((path) => uri.path.startsWith(path))) {
      debugPrint('Ignoring deep link to ${uri.path}');
      return;
    }

    try {
      final path = uri.path;

      if (path.startsWith('/post/')) {
        final postId = path.split('/post/')[1];
        _router?.go('/post/$postId');
      } else if (path.startsWith('/channel/')) {
        final parts = path.split('/').where((part) => part.isNotEmpty).toList();
        if (parts.length >= 2) {
          final channelName = parts[1];
          final subName = parts.length >= 3 ? parts[2] : null;
          _router?.go(subName != null
              ? '/channel/$channelName/$subName'
              : '/channel/$channelName');
        }
      } else if (path == '/home' || path == '/') {
        _router?.go('/');
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkStreamController.close();
  }
}

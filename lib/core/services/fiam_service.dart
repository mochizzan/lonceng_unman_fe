import 'dart:async';

import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:lonceng_unman_fe/core/auth/auth_status.dart';

abstract class FiamDelegate {
  Future<void> setMessagesSuppressed(bool suppress);
  Future<void> setAutomaticDataCollectionEnabled(bool enabled);
}

class FirebaseInAppMessagingDelegate implements FiamDelegate {
  FirebaseInAppMessagingDelegate([FirebaseInAppMessaging? instance])
    : _instance = instance ?? FirebaseInAppMessaging.instance;

  final FirebaseInAppMessaging _instance;

  @override
  Future<void> setMessagesSuppressed(bool suppress) =>
      _instance.setMessagesSuppressed(suppress);

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) =>
      _instance.setAutomaticDataCollectionEnabled(enabled);
}

class FiamService {
  FiamService({FiamDelegate? delegate, FirebaseInAppMessaging? instance})
    : _fiam =
          delegate ??
          (instance != null
              ? FirebaseInAppMessagingDelegate(instance)
              : FirebaseInAppMessagingDelegate());

  final FiamDelegate _fiam;

  StreamSubscription<AuthStatus>? _sub;

  Future<void> bind(AuthStatusNotifier notifier) async {
    await _apply(notifier.currentStatus);
    await _sub?.cancel();
    _sub = notifier.status.listen((s) => _apply(s));
  }

  Future<void> _apply(AuthStatus s) async {
    final suppress = s != AuthStatus.authenticated;
    final enableCollection = !suppress;
    try {
      await _fiam.setMessagesSuppressed(suppress);
      debugPrint('[FIAM] suppressed=$suppress (status=$s)');
    } catch (e) {
      debugPrint('[FIAM] _apply setMessagesSuppressed FAILED: $e (status=$s)');
    }
    try {
      await _fiam.setAutomaticDataCollectionEnabled(enableCollection);
      debugPrint('[FIAM] dataCollection=$enableCollection (status=$s)');
    } catch (e) {
      debugPrint(
        '[FIAM] _apply setAutomaticDataCollectionEnabled FAILED: $e (status=$s)',
      );
    }
  }

  void dispose() => _sub?.cancel();
}

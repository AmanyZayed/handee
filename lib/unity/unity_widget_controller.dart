import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'unity_config.dart';

/// Same API as `flutter_unity_widget`'s [UnityWidgetController.postMessage].
class UnityWidgetController {
  UnityWidgetController._();

  static const _channel = MethodChannel('handee_unity');

  static UnityWidgetController? _instance;

  /// Set when the embedded Unity view is ready on Android.
  static UnityWidgetController? get instance => _instance;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static void register() {
    if (!isSupported) return;
    _instance = UnityWidgetController._();
  }

  static void unregister() {
    _instance = null;
  }

  /// Sends a message to a Unity GameObject method.
  Future<void> postMessage(
    String gameObject,
    String methodName,
    String message,
  ) async {
    if (!isSupported) return;

    await _channel.invokeMethod<void>('prepareUnity');
    await _channel.invokeMethod<void>('postMessage', {
      'gameObject': gameObject,
      'methodName': methodName,
      'message': message,
    });

    if (kDebugMode) {
      debugPrint(
        'Unity postMessage -> $gameObject.$methodName("$message")',
      );
    }
  }

  /// Primary sign API: AvatarController.PlaySign(word).
  Future<void> playSign(String word) {
    final trimmed = word.trim().toLowerCase();
    if (trimmed.isEmpty) return Future.value();

    return postMessage(
      UnityConfig.gameObject,
      UnityConfig.playMethod,
      trimmed,
    );
  }
}

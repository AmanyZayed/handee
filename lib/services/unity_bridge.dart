import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../unity/unity_config.dart';
import '../unity/unity_widget_controller.dart';

/// Sends words to Unity via [UnityWidgetController].
class UnityBridge {
  UnityBridge._();

  static const _channel = MethodChannel('handee_unity');

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static UnityWidgetController? get controller => UnityWidgetController.instance;

  static Future<bool> waitUntilReady({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!isSupported) return false;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (UnityWidgetController.instance != null) {
        try {
          final ready = await _channel.invokeMethod<bool>('isReady');
          if (ready == true) return true;
        } catch (_) {}
      }
      try {
        await _channel.invokeMethod<void>('prepareUnity');
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return UnityWidgetController.instance != null;
  }

  /// AvatarController.PlaySign(word) with retries.
  static Future<bool> playSign(String text) async {
    if (!isSupported) return false;
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return false;

    await waitUntilReady();

    final unity = UnityWidgetController.instance;
    if (unity == null) {
      debugPrint('Unity controller not ready');
      return false;
    }

    await unity.playSign(trimmed);
    for (var i = 1; i <= 8; i++) {
      await Future<void>.delayed(Duration(milliseconds: 400 * i));
      await unity.postMessage(
        UnityConfig.gameObject,
        UnityConfig.playMethod,
        trimmed,
      );
    }
    return true;
  }

  static Future<bool> openSignScreen(String text) async {
    if (!isSupported) return false;
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return false;

    try {
      final ok = await _channel.invokeMethod<bool>('openSign', {'word': trimmed});
      return ok == true;
    } catch (_) {
      return false;
    }
  }
}

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
    Duration timeout = const Duration(seconds: 10),
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
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return false;
  }

  static Future<void> prepare() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('prepareUnity');
    } catch (_) {}
  }

  /// Dispatch sign playback to every known Unity avatar object.
  static Future<bool> playSign(String text) async {
    if (!isSupported) return false;
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return false;

    final ready = await waitUntilReady();
    final unity = UnityWidgetController.instance;
    if (!ready || unity == null) {
      debugPrint('Unity controller not ready');
      return false;
    }

    await prepare();

    for (final target in UnityConfig.legacyGameObjects) {
      await unity.postMessage(target, UnityConfig.receiveMethod, trimmed);
      await unity.postMessage(target, UnityConfig.playTextMethod, trimmed);
      // Some Unity builds only animate after PlayText with an empty arg.
      await unity.postMessage(target, UnityConfig.playTextMethod, '');
    }

    await unity.postMessage(
      UnityConfig.gameObject,
      UnityConfig.playMethod,
      trimmed,
    );

    await Future<void>.delayed(const Duration(milliseconds: 400));
    await prepare();
    await unity.postMessage(UnityConfig.gameObject, UnityConfig.playMethod, trimmed);
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

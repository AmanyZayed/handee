import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../unity/unity_widget_controller.dart';

/// Sends words to Unity via [UnityWidgetController].
class UnityBridge {
  UnityBridge._();

  static const _channel = MethodChannel('handee_unity');

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static bool? _nativeRuntimeSupported;

  /// True on ARM phones; false on x86/x86_64 emulators (Unity libs are arm64-only).
  static Future<bool> isNativeRuntimeSupported() async {
    if (!isSupported) return false;
    if (_nativeRuntimeSupported != null) return _nativeRuntimeSupported!;
    try {
      final ok = await _channel.invokeMethod<bool>('isNativeSupported');
      _nativeRuntimeSupported = ok == true;
    } catch (_) {
      _nativeRuntimeSupported = false;
    }
    return _nativeRuntimeSupported!;
  }

  static UnityWidgetController? get controller => UnityWidgetController.instance;

  static Future<bool> waitUntilReady({
    Duration timeout = const Duration(seconds: 12),
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

  static Future<bool> playSign(String text) async {
    if (!isSupported) return false;
    if (!await isNativeRuntimeSupported()) return false;
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return false;

    final ready = await waitUntilReady();
    if (!ready || UnityWidgetController.instance == null) {
      debugPrint('Unity controller not ready');
      return false;
    }

    await prepare();

    // The scene object holding the ASLAnimator script is named "Hamada".
    // Its ReceiveTextFromFlutter handles full phrases and fingerspells
    // unknown words, so the whole text goes in one message.
    try {
      await _channel.invokeMethod<void>('playSign', {'word': trimmed});
      return true;
    } catch (e) {
      debugPrint('Unity playSign failed: $e');
      return false;
    }
  }

  static Future<bool> openSignScreen(String text) async {
    if (!isSupported) return false;
    if (!await isNativeRuntimeSupported()) return false;
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

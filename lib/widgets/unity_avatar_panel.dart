import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:handee/theme/app_fonts.dart';

import '../services/unity_bridge.dart';
import '../unity/handee_unity_registrar.dart';
import '../unity/unity_widget_controller.dart';

/// Embedded Unity avatar — registers [UnityWidgetController] when ready.
class UnityAvatarPanel extends StatefulWidget {
  const UnityAvatarPanel({super.key});

  @override
  State<UnityAvatarPanel> createState() => UnityAvatarPanelState();
}

class UnityAvatarPanelState extends State<UnityAvatarPanel> {
  static const _unityChannel = MethodChannel('handee_unity');

  bool _nativeUnity = true;
  bool _checkedNative = false;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    unawaited(_checkNativeUnity());
  }

  Future<void> _checkNativeUnity() async {
    final ok = await UnityBridge.isNativeRuntimeSupported();
    if (mounted) {
      setState(() {
        _nativeUnity = ok;
        _checkedNative = true;
      });
    }
  }

  Future<void> _warmUpUnity() async {
    for (var i = 0; i < 12; i++) {
      try {
        await _unityChannel.invokeMethod<void>('prepareUnity');
        final ready = await _unityChannel.invokeMethod<bool>('isReady');
        if (ready == true) return;
      } catch (e) {
        if (kDebugMode) debugPrint('Unity warm-up: $e');
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await UnityBridge.prepare();
  }

  void _onPlatformViewCreated(int id) {
    UnityWidgetController.register();
    unawaited(_warmUpUnity());
  }

  @override
  void dispose() {
    UnityWidgetController.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isSupported) {
      return Center(
        child: Text(
          'Avatar is available on Android only.',
          style: AppFonts.plusJakarta(
            color: Colors.white70,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_checkedNative && !_nativeUnity) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '3D avatar runs on a physical phone only.\n'
            'Use your Samsung device for signing — the emulator can test everything else.',
            style: AppFonts.plusJakarta(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Hybrid Composition: Unity draws through a SurfaceView, which freezes
    // after the first frame inside a virtual display (default AndroidView).
    return PlatformViewLink(
      viewType: HandeeUnityRegistrar.viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        final controller = PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: params.viewType,
          layoutDirection: TextDirection.ltr,
          creationParamsCodec: const StandardMessageCodec(),
        );
        controller
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
          ..create();
        return controller;
      },
    );
  }
}

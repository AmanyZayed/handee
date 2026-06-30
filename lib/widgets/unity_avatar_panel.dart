import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handee/theme/app_fonts.dart';

import '../services/unity_bridge.dart';
import '../theme/app_theme.dart';
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

  bool _warmingUp = true;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> _warmUpUnity() async {
    for (var i = 0; i < 12; i++) {
      try {
        await _unityChannel.invokeMethod<void>('prepareUnity');
        final ready = await _unityChannel.invokeMethod<bool>('isReady');
        if (ready == true) {
          if (mounted) setState(() => _warmingUp = false);
          return;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Unity warm-up: $e');
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (mounted) setState(() => _warmingUp = false);
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

    return Stack(
      fit: StackFit.expand,
      children: [
        AndroidView(
          viewType: HandeeUnityRegistrar.viewType,
          layoutDirection: TextDirection.ltr,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
        if (_warmingUp)
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.electric,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading avatar…',
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

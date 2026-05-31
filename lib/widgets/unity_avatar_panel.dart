import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  bool _sceneVisible = false;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> _waitForUnityReady() async {
    for (var i = 0; i < 50; i++) {
      try {
        final ready = await _unityChannel.invokeMethod<bool>('isReady');
        if (ready == true) {
          UnityWidgetController.register();
          if (mounted) setState(() => _sceneVisible = true);
          return;
        }
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    UnityWidgetController.register();
    if (mounted) setState(() => _sceneVisible = true);
  }

  void _onPlatformViewCreated(int id) {
    _waitForUnityReady();
  }

  @override
  void dispose() {
    UnityWidgetController.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isSupported) {
      return const SizedBox.shrink();
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
        AnimatedOpacity(
          opacity: _sceneVisible ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          child: Container(
            color: const Color.fromARGB(255, 238, 234, 239),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading avatar…',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

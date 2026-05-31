import 'package:flutter/material.dart';

import '../pages/sign_video_page.dart';
import 'sign_catalog.dart';
import 'unity_bridge.dart';

/// Green play: Unity avatar signs. Purple: sign video page.
class SignPlayer {
  SignPlayer._();

  static Future<void> play(BuildContext context, String text) async {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    final inUnityList = await SignCatalog.canUseUnityAvatar(trimmed);
    final hasVideo = await SignCatalog.hasSignVideo(trimmed);

    if (inUnityList && UnityBridge.isSupported) {
      final signed = await UnityBridge.playSign(trimmed);
      if (signed) return;

      final opened = await UnityBridge.openSignScreen(trimmed);
      if (opened) return;
    }

    if (!context.mounted) return;

    if (hasVideo) {
      await _openVideoPage(context, trimmed);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No sign found for "$trimmed"')),
    );
  }

  static Future<void> playVideo(BuildContext context, String text) async {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    if (!context.mounted) return;

    final hasVideo = await SignCatalog.hasSignVideo(trimmed);
    if (!context.mounted) return;

    if (hasVideo) {
      await _openVideoPage(context, trimmed);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No sign video for "$trimmed"')),
    );
  }

  static Future<void> _openVideoPage(BuildContext context, String word) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SignVideoPage(word: word),
      ),
    );
  }
}

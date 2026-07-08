import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';

import '../pages/fingerspell_page.dart';
import '../pages/sign_video_page.dart';
import '../theme/app_theme.dart';
import 'app_prefs.dart';
import 'sign_catalog.dart';
import 'unity_bridge.dart';

/// Play Sign: avatar → video → fingerspell.
/// Play Video: video → avatar → fingerspell.
class SignPlayer {
  SignPlayer._();

  static Future<void> play(
    BuildContext context,
    String text, {
    bool allowFingerspellFallback = true,
  }) async {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    await AppPrefs.instance.recordTranslation(trimmed);

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final hasVideo = words.length == 1 && await SignCatalog.hasSignVideo(trimmed);
    final label = _displayLabel(text);

    // The Unity animator handles known words and fingerspells the rest,
    // so any text can go straight to the avatar.
    if (UnityBridge.isSupported && await _tryAvatar(trimmed)) {
      return;
    }

    if (!context.mounted) return;

    if (hasVideo) {
      _notify(
        context,
        words.length > 1
            ? 'Playing each word in the video library.'
            : '$label isn\'t available in the 3D avatar. '
                'Showing the sign video instead.',
      );
      await _openVideoPage(context, trimmed);
      return;
    }

    if (!context.mounted) return;

    if (allowFingerspellFallback) {
      _notify(
        context,
        '$label isn\'t in our avatar or video library. '
        'Opening fingerspelling for each letter.',
      );
      await _openFingerspell(context, text.trim());
    } else {
      _notify(
        context,
        '$label isn\'t available in the avatar or as a sign video.',
      );
    }
  }

  static Future<void> playVideo(
    BuildContext context,
    String text, {
    bool allowFingerspellFallback = true,
  }) async {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    await AppPrefs.instance.recordTranslation(trimmed);

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final hasVideo = words.isNotEmpty &&
        (words.length == 1
            ? await SignCatalog.hasSignVideo(words.single)
            : await _allHaveVideo(words));
    final hasAvatar = UnityBridge.isSupported;
    final label = _displayLabel(text);

    if (!context.mounted) return;

    if (hasVideo) {
      await _openVideoPage(context, trimmed);
      return;
    }

    if (hasAvatar) {
      _notify(
        context,
        'No sign video for $label. Playing it with the 3D avatar instead.',
      );
      if (await _tryAvatar(trimmed)) return;
    }

    if (!context.mounted) return;

    if (allowFingerspellFallback) {
      _notify(
        context,
        '$label has no sign video or avatar. Opening fingerspelling instead.',
      );
      await _openFingerspell(context, text.trim());
    } else {
      _notify(
        context,
        'No sign video or avatar is available for $label.',
      );
    }
  }

  static Future<bool> _tryAvatar(String word) async {
    if (!UnityBridge.isSupported) return false;

    final started = await UnityBridge.playSign(word);
    if (!started) {
      return await UnityBridge.openSignScreen(word);
    }
    return true;
  }

  static Future<bool> _allHaveVideo(List<String> words) async {
    for (final word in words) {
      if (!await SignCatalog.hasSignVideo(word)) return false;
    }
    return true;
  }

  static String _displayLabel(String text) {
    final t = text.trim();
    return t.isEmpty ? 'This word' : '"$t"';
  }

  static void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFonts.plusJakarta(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        duration: const Duration(seconds: 4),
      ),
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

  static Future<void> _openFingerspell(BuildContext context, String text) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => FingerspellPage(initialText: text),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local app state: onboarding, stats, settings.
class AppPrefs {
  AppPrefs._();
  static final AppPrefs instance = AppPrefs._();

  /// Notifies when large-text preference changes (for [MaterialApp] rebuild).
  static final ValueNotifier<bool> largeTextNotifier = ValueNotifier(false);

  /// Bumps when translation history changes (home recent chips listen).
  static final ValueNotifier<int> historyRevision = ValueNotifier(0);

  static void _bumpHistory() => historyRevision.value++;

  static const _onboardingKey = 'onboarding_complete';
  static const _translationsKey = 'translations_count';
  static const _historyKey = 'translation_history_v1';
  static const _notificationsKey = 'notifications_enabled';
  static const _largeTextKey = 'large_text_enabled';
  static const _storeNotifyKey = 'store_notify_me';
  Future<bool> isOnboardingComplete() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_onboardingKey, true);
  }

  Future<void> clearOnboardingComplete() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_onboardingKey);
  }

  Future<int> translationsCount() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_translationsKey) ?? 0;
  }

  Future<void> recordTranslation([String? text]) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_translationsKey, (p.getInt(_translationsKey) ?? 0) + 1);
    if (text != null && text.trim().isNotEmpty) {
      await _appendHistory(p, text.trim());
      _bumpHistory();
    }
  }

  Future<void> _appendHistory(SharedPreferences p, String text) async {
    final raw = p.getStringList(_historyKey) ?? [];
    final lower = text.toLowerCase();
    raw.removeWhere((line) {
      final sep = line.indexOf('|');
      if (sep < 0) return false;
      return line.substring(sep + 1).toLowerCase() == lower;
    });
    raw.insert(0, '${DateTime.now().millisecondsSinceEpoch}|$text');
    while (raw.length > 100) {
      raw.removeLast();
    }
    await p.setStringList(_historyKey, raw);
  }

  /// Unique recent words for the home screen chips (newest first).
  Future<List<String>> recentWords({int limit = 8}) async {
    final items = await translationHistory();
    final seen = <String>{};
    final words = <String>[];
    for (final item in items) {
      final key = item.text.toLowerCase();
      if (seen.add(key)) {
        words.add(item.text);
        if (words.length >= limit) break;
      }
    }
    return words;
  }

  Future<List<TranslationHistoryItem>> translationHistory() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_historyKey) ?? [];
    final items = <TranslationHistoryItem>[];
    for (final line in raw) {
      final sep = line.indexOf('|');
      if (sep <= 0) continue;
      final ts = int.tryParse(line.substring(0, sep));
      if (ts == null) continue;
      items.add(TranslationHistoryItem(
        text: line.substring(sep + 1),
        at: DateTime.fromMillisecondsSinceEpoch(ts),
      ));
    }
    return items;
  }

  Future<void> removeTranslationHistoryItem(TranslationHistoryItem item) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_historyKey) ?? [];
    final target = '${item.at.millisecondsSinceEpoch}|${item.text}';
    raw.remove(target);
    await p.setStringList(_historyKey, raw);
    _bumpHistory();
  }

  Future<void> clearTranslationHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_historyKey);
    _bumpHistory();
  }

  Future<bool> storeNotifyEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_storeNotifyKey) ?? false;
  }

  Future<void> setStoreNotifyEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_storeNotifyKey, v);
  }

  Future<void> loadLargeTextNotifier() async {
    largeTextNotifier.value = await largeTextEnabled();
  }

  Future<bool> notificationsEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_notificationsKey, v);
  }

  Future<bool> largeTextEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_largeTextKey) ?? false;
  }

  Future<void> setLargeTextEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_largeTextKey, v);
    largeTextNotifier.value = v;
  }

}

class TranslationHistoryItem {
  const TranslationHistoryItem({required this.text, required this.at});

  final String text;
  final DateTime at;
}
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local app state: onboarding, stats, settings.
class AppPrefs {
  AppPrefs._();
  static final AppPrefs instance = AppPrefs._();

  /// Notifies when large-text preference changes (for [MaterialApp] rebuild).
  static final ValueNotifier<bool> largeTextNotifier = ValueNotifier(false);

  static const _onboardingKey = 'onboarding_complete';
  static const _signsLearnedKey = 'signs_learned';
  static const _dayStreakKey = 'day_streak';
  static const _translationsKey = 'translations_count';
  static const _lastActiveDayKey = 'last_active_day';
  static const _masteredSignsKey = 'mastered_signs';
  static const _dailySignsKey = 'daily_signs_today';
  static const _dailySignsDayKey = 'daily_signs_day';
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

  Future<int> signsLearned() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_signsLearnedKey) ?? 0;
  }

  Future<int> dayStreak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_dayStreakKey) ?? 0;
  }

  Future<int> translationsCount() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_translationsKey) ?? 0;
  }

  Future<void> recordTranslation([String? text]) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_translationsKey, (p.getInt(_translationsKey) ?? 0) + 1);
    await _touchStreak(p);
    if (text != null && text.trim().isNotEmpty) {
      await _appendHistory(p, text.trim());
    }
  }

  Future<void> _appendHistory(SharedPreferences p, String text) async {
    final raw = p.getStringList(_historyKey) ?? [];
    raw.insert(0, '${DateTime.now().millisecondsSinceEpoch}|$text');
    while (raw.length > 100) {
      raw.removeLast();
    }
    await p.setStringList(_historyKey, raw);
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

  Future<void> clearTranslationHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_historyKey);
  }

  Future<void> recordSignLearned(String sign) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_masteredSignsKey) ?? [];
    if (!raw.contains(sign)) {
      raw.add(sign);
      await p.setStringList(_masteredSignsKey, raw);
      await p.setInt(_signsLearnedKey, raw.length);
    }
    final today = _dayKey(DateTime.now());
    if (p.getString(_dailySignsDayKey) != today) {
      await p.setStringList(_dailySignsKey, []);
      await p.setString(_dailySignsDayKey, today);
    }
    final daily = p.getStringList(_dailySignsKey) ?? [];
    if (!daily.contains(sign)) {
      daily.add(sign);
      await p.setStringList(_dailySignsKey, daily);
    }
    await _touchStreak(p);
  }

  Future<int> dailyPracticeProgress() async {
    final p = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    if (p.getString(_dailySignsDayKey) != today) return 0;
    return (p.getStringList(_dailySignsKey) ?? []).length.clamp(0, 10);
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

  Future<void> _touchStreak(SharedPreferences p) async {
    final today = _dayKey(DateTime.now());
    final last = p.getString(_lastActiveDayKey);
    var streak = p.getInt(_dayStreakKey) ?? 0;
    if (last == today) return;
    if (last == _dayKey(DateTime.now().subtract(const Duration(days: 1)))) {
      streak += 1;
    } else {
      streak = 1;
    }
    await p.setString(_lastActiveDayKey, today);
    await p.setInt(_dayStreakKey, streak);
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class TranslationHistoryItem {
  const TranslationHistoryItem({required this.text, required this.at});

  final String text;
  final DateTime at;
}
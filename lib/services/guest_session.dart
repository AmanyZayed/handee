import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Guest session used while [kSkipAuth] is enabled.
Future<void> ensureGuestSession() async {
  if (!kSkipAuth) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
  if ((prefs.getString('username') ?? '').isEmpty) {
    await prefs.setString('username', 'Guest');
  }
}

/// Call before entering home when auth is bypassed.
Future<void> preparePostOnboardingSession() async {
  await ensureGuestSession();
}

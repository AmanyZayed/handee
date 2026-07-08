import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

const guestModeKey = 'isGuestMode';

/// Marks the app as using a local guest profile (no Firebase account).
Future<void> startGuestSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
  await prefs.setBool(guestModeKey, true);
  await prefs.setString('username', 'Guest');
  await prefs.remove('registeredEmail');
  await prefs.remove('mobile');
}

Future<bool> isGuestSession() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(guestModeKey) ?? false;
}

/// Guest session used when [kSkipAuth] is enabled at startup.
Future<void> ensureGuestSession() async {
  if (!kSkipAuth) return;
  await startGuestSession();
}

/// Call before entering home when auth is bypassed.
Future<void> preparePostOnboardingSession() async {
  await ensureGuestSession();
}

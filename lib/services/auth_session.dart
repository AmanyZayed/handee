import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/login_screen.dart';
import 'guest_session.dart';

/// Shared auth state + navigation helpers.
class AuthSession {
  AuthSession._();

  static const pendingLoginEmailKey = 'pendingLoginEmail';

  static Future<bool> isGuest() => isGuestSession();

  static Future<void> continueAsGuest(BuildContext context) async {
    await startGuestSession();
    if (!context.mounted) return;
    await goHome(context);
  }

  static Future<bool> isAuthenticated() async {
    if (kSkipAuth) return true;
    if (FirebaseAuth.instance.currentUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<void> persistUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool(guestModeKey, false);

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      await prefs.setString('registeredEmail', email);
    }

    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await prefs.setString('username', name);
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final phone = doc.data()?['phone'];
      if (phone is String && phone.trim().isNotEmpty) {
        await prefs.setString('mobile', phone.trim());
      }
    } catch (_) {}
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('registeredEmail');
    await prefs.remove('username');
    await prefs.remove('mobile');
    await prefs.remove(pendingLoginEmailKey);
    await prefs.remove(guestModeKey);
  }

  static Future<void> goHome(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  static Future<void> goLogin(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  /// Splash / onboarding destination after onboarding flag is known.
  static Future<Widget> resolveStartScreen({required bool onboardingDone}) async {
    if (!onboardingDone) return const OnboardingScreen();
    if (kSkipAuth) return const HomeScreen();
    if (await isAuthenticated()) return const HomeScreen();
    return const LoginScreen();
  }
}

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase + Google Sign-In helpers.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Web OAuth client (client_type 3) from Firebase / google-services.json.
  static const String defaultWebClientId =
      '845205637188-262evltkl2utmbp6aeuukiu9mjr0lp0h.apps.googleusercontent.com';

  GoogleSignIn? _googleSignIn;

  Future<String> _resolveWebClientId() async {
    try {
      final raw =
          await rootBundle.loadString('assets/config/google_auth.json');
      final id = (jsonDecode(raw) as Map<String, dynamic>)['webClientId'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
    } catch (_) {}

    try {
      final raw =
          await rootBundle.loadString('assets/config/google-services.json');
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final clients = root['client'] as List<dynamic>? ?? [];
      for (final client in clients) {
        final oauth = (client as Map<String, dynamic>)['oauth_client'];
        if (oauth is! List) continue;
        for (final entry in oauth) {
          final map = entry as Map<String, dynamic>;
          if (map['client_type'] == 3) {
            final id = map['client_id'];
            if (id is String && id.isNotEmpty) return id;
          }
        }
      }
    } catch (_) {}

    return defaultWebClientId;
  }

  GoogleSignIn _buildGoogleSignIn(String webClientId) {
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: webClientId,
    );
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('ApiException: 10') ||
        text.contains('DEVELOPER_ERROR') ||
        text.contains('12500')) {
      return 'Google Sign-In is misconfigured (SHA-1 / Firebase). '
          'Re-download google-services.json after adding SHA-1, then rebuild the app.';
    }
    if (text.contains('network') || text.contains('NETWORK_ERROR')) {
      return 'No internet connection. Connect to Wi‑Fi or mobile data and try again.';
    }
    if (text.contains('12501') || text.contains('sign_in_canceled')) {
      return 'Google sign-in was cancelled.';
    }
    if (text.contains('missing-google-config')) {
      return 'Google Sign-In is not configured in the app yet.';
    }
    if (text.contains('google-missing-id-token')) {
      return 'Google did not return a sign-in token. Rebuild the app after updating Firebase.';
    }
    return text.replaceFirst('Exception: ', '').trim();
  }

  Future<UserCredential> signInWithGoogle() async {
    final webClientId = await _resolveWebClientId();

    // Fresh client each attempt avoids stale cached config on device.
    _googleSignIn = _buildGoogleSignIn(webClientId);
    final googleSignIn = _googleSignIn!;

    try {
      await googleSignIn.signOut();

      final account = await googleSignIn.signIn();
      if (account == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'google-missing-id-token',
          message:
              'Google did not return an ID token. Run a full rebuild after updating google-services.json.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: _friendlyError(e),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: _friendlyError(e),
      );
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      FirebaseAuth.instance.signOut(),
      _googleSignIn?.signOut() ?? Future.value(),
    ]);
  }

  Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}

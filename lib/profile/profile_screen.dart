import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/guest_session.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_widget.dart';
import 'profile_details_widget.dart';
import 'sign_up_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  String _email = '';
  String _username = '';
  String _mobile = '';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (kSkipAuth) {
      await ensureGuestSession();
      if (!mounted) return;
      setState(() {
        _isLoggedIn = true;
        _email = prefs.getString('registeredEmail') ?? '';
        _username = prefs.getString('username') ?? 'Guest';
        _mobile = prefs.getString('mobile') ?? '';
      });
      return;
    }

    if (user != null) {
      await _persistUser(user, prefs: prefs);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _email = prefs.getString('registeredEmail') ?? '';
      _username = prefs.getString('username') ?? '';
      _mobile = prefs.getString('mobile') ?? '';
    });
  }

  Future<void> _persistUser(
    User user, {
    SharedPreferences? prefs,
  }) async {
    final storage = prefs ?? await SharedPreferences.getInstance();
    final email = user.email ?? storage.getString('registeredEmail') ?? '';
    final username = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (storage.getString('username') ?? email.split('@').first);

    await storage.setBool('isLoggedIn', true);
    if (email.isNotEmpty) await storage.setString('registeredEmail', email);
    if (username.isNotEmpty) await storage.setString('username', username);

    if (!mounted) return;
    setState(() {
      _isLoggedIn = true;
      _email = email;
      _username = username;
      _mobile = storage.getString('mobile') ?? '';
    });
  }

  Future<void> _onLogin(User user) => _persistUser(user);

  Future<void> _onLogout() async {
    if (kSkipAuth) {
      await ensureGuestSession();
      if (!mounted) return;
      setState(() {
        _isLoggedIn = true;
        _username = 'Guest';
      });
      return;
    }
    await AuthService.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = false;
      _email = '';
      _username = '';
      _mobile = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: _isLoggedIn
            ? ProfileDetailsWidget(
                email: _email,
                username: _username,
                mobile: _mobile,
                onLogout: _onLogout,
              )
            : LoginWidget(
                embedded: true,
                onLogin: _onLogin,
                onCreateAccount: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpWidget()),
                  );
                },
              ),
      ),
    );
  }
}

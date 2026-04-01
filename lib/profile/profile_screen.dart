import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_widget.dart';
import 'profile_details_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoggedIn = false;

  String email = '';
  String username = '';
  String mobile = '';

  @override
  void initState() {
    super.initState();
    _loadLoginState();
  }

  Future<void> _loadLoginState() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      email = prefs.getString('registeredEmail') ?? '';
      username = prefs.getString('username') ?? '';
      mobile = prefs.getString('mobile') ?? '';
    });
  }

  Future<void> _onLogin(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);

    setState(() {
      isLoggedIn = true;
      email = prefs.getString('registeredEmail') ?? '';
      username = prefs.getString('username') ?? '';
      mobile = prefs.getString('mobile') ?? '';
    });
  }

  Future<void> _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      isLoggedIn = false;
      email = '';
      username = '';
      mobile = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: isLoggedIn
          ? ProfileDetailsWidget(
              email: email,
              username: username,
              mobile: mobile,
              onLogout: _onLogout,
            )
          : LoginWidget(
              onLogin: _onLogin,
            ),
    );
  }
}
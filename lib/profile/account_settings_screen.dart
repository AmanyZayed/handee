import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'auth_widgets.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = p.getString('username') ?? '';
      _emailCtrl.text = p.getString('registeredEmail') ?? '';
      _phoneCtrl.text = p.getString('mobile') ?? '';
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final p = await SharedPreferences.getInstance();
    await p.setString('username', _nameCtrl.text.trim());
    await p.setString('registeredEmail', _emailCtrl.text.trim());
    await p.setString('mobile', _phoneCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account updated.')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 19, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account',
          style: AppFonts.spaceGrotesk(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthFieldLabel(label: 'Full name'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _nameCtrl,
                hint: 'Your name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel(label: 'Email'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _emailCtrl,
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel(label: 'Phone'),
              const SizedBox(height: 8),
              AuthStyledField(
                controller: _phoneCtrl,
                hint: '+1 555 000 0000',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),
              AuthGradientButton(
                label: 'Save changes',
                loading: _loading,
                onTap: _loading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

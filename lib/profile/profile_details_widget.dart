import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../pages/history_page.dart';
import '../pages/speech_to_text_page.dart';
import '../pages/text_to_speech_page.dart';
import '../services/app_prefs.dart';
import '../theme/app_theme.dart';
import 'account_settings_screen.dart';

class ProfileDetailsWidget extends StatefulWidget {
  final String username;
  final String email;
  final String mobile;
  final VoidCallback onLogout;

  const ProfileDetailsWidget({
    super.key,
    required this.username,
    required this.email,
    required this.mobile,
    required this.onLogout,
  });

  @override
  State<ProfileDetailsWidget> createState() => _ProfileDetailsWidgetState();
}

class _ProfileDetailsWidgetState extends State<ProfileDetailsWidget> {
  bool _notificationsEnabled = true;
  bool _largeText = false;

  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.username);
    _emailCtrl    = TextEditingController(text: widget.email);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = AppPrefs.instance;
    final n = await prefs.notificationsEnabled();
    final l = await prefs.largeTextEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = n;
      _largeText = l;
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final name  = _usernameCtrl.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Gradient cover header ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.royalNavy, AppColors.primaryMid],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Background orb
                  Positioned(
                    top: -40, right: -30,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                    child: Column(
                      children: [
                        // Avatar row
                        Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _initials,
                                  style: AppFonts.spaceGrotesk(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _usernameCtrl.text.isNotEmpty
                                        ? _usernameCtrl.text
                                        : 'HANDee User',
                                    style: AppFonts.plusJakarta(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _emailCtrl.text,
                                    style: AppFonts.plusJakarta(
                                      fontSize: 13,
                                      color: const Color(0xFFD6E1FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AccountSettingsScreen(),
                                  ),
                                );
                                if (!mounted) return;
                                final p =
                                    await SharedPreferences.getInstance();
                                setState(() {
                                  _usernameCtrl.text =
                                      p.getString('username') ?? '';
                                  _emailCtrl.text =
                                      p.getString('registeredEmail') ?? '';
                                });
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Settings list ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.history_rounded,
                    label: 'Translation history',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryPage()),
                    ),
                    isLast: false,
                  ),
                  _SettingsRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Account',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountSettingsScreen(),
                        ),
                      );
                      if (!mounted) return;
                      final p = await SharedPreferences.getInstance();
                      setState(() {
                        _usernameCtrl.text = p.getString('username') ?? '';
                        _emailCtrl.text = p.getString('registeredEmail') ?? '';
                      });
                    },
                    isLast: false,
                  ),
                  _SettingsRow(
                    icon: Icons.accessibility_outlined,
                    label: 'Accessibility',
                    trailing: Text(
                      _largeText ? 'Large text' : 'Default',
                      style: AppFonts.plusJakarta(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final next = !_largeText;
                      await AppPrefs.instance.setLargeTextEnabled(next);
                      setState(() => _largeText = next);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            next
                                ? 'Large text enabled across the app.'
                                : 'Default text size restored.',
                          ),
                        ),
                      );
                    },
                    isLast: false,
                  ),
                  _SettingsRow(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    trailing: Text(
                      'English',
                      style: AppFonts.plusJakarta(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('More languages are coming soon.'),
                        ),
                      );
                    },
                    isLast: false,
                  ),
                  _SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    trailing: _Toggle(
                      value: _notificationsEnabled,
                      onChanged: (v) async {
                        await AppPrefs.instance.setNotificationsEnabled(v);
                        setState(() => _notificationsEnabled = v);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              v
                                  ? 'Notifications preference saved.'
                                  : 'Notifications turned off in settings.',
                            ),
                          ),
                        );
                      },
                    ),
                    isLast: false,
                  ),
                  _SettingsRow(
                    icon: Icons.mic_none_rounded,
                    label: 'Speech to Text',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SpeechToTextPage(),
                      ),
                    ),
                    isLast: false,
                  ),
                  _SettingsRow(
                    icon: Icons.volume_up_outlined,
                    label: 'Text to Speech',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TextToSpeechPage(),
                      ),
                    ),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Log out ───────────────────────────────────────────────────────
          if (!kSkipAuth)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: GestureDetector(
                onTap: _confirmLogout,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                        color: const Color(0xFFFFD9D9), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        'Log out',
                        style: AppFonts.plusJakarta(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Log out',
            style: AppFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to log out?',
          style: AppFonts.plusJakarta(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings row
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    required this.isLast,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(20))
          : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF0F3FB))),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: AppFonts.plusJakarta(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFFC2CBE0)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle switch
// ─────────────────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 25,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            width: 21,
            height: 21,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';

import '../config/app_config.dart';
import '../home/home_screen.dart';
import '../profile/login_screen.dart';
import '../services/app_prefs.dart';
import '../services/guest_session.dart';
import '../theme/app_theme.dart';
import '../widgets/hd_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardData(
      title: 'Speak it. Sign it.',
      subtitle:
          'Turn your voice or text into clear sign language with a friendly 3D avatar.',
      icon: Icons.sign_language_rounded,
      bubbles: ['Hello', 'Thank you'],
      dark: false,
    ),
    _OnboardData(
      title: 'Point. Recognize.',
      subtitle:
          'Aim your camera and HANDee reads ASL signs into words in real time.',
      icon: Icons.camera_alt_outlined,
      badge: 'Reading sign…',
      dark: true,
    ),
    _OnboardData(
      title: 'Learn every day.',
      subtitle:
          'Master the alphabet, numbers and everyday signs — at your own pace.',
      icon: Icons.school_outlined,
      tiles: ['A', 'B', '7'],
      dark: false,
    ),
  ];

  Future<void> _finish() async {
    await AppPrefs.instance.setOnboardingComplete();
    if (!mounted) return;
    if (kSkipAuth) await preparePostOnboardingSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            kSkipAuth ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _OnboardPage(data: _pages[i]),
              ),
            ),
            _PageDots(count: _pages.length, index: _page),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 28),
              child: HdPrimaryButton(
                label: isLast ? 'Get Started' : 'Next',
                trailing: isLast
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardData {
  const _OnboardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.bubbles,
    this.badge,
    this.tiles,
    this.dark = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String>? bubbles;
  final String? badge;
  final List<String>? tiles;
  final bool dark;
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.data});
  final _OnboardData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _Visual(data: data),
          const Spacer(),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppFonts.plusJakarta(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _Visual extends StatelessWidget {
  const _Visual({required this.data});
  final _OnboardData data;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.62;

    if (data.dark) {
      return Container(
        width: size,
        height: size * 0.85,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF16204F), Color(0xFF0C1336)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          boxShadow: AppShadow.card,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(data.icon, size: 64, color: Colors.white.withValues(alpha: 0.85)),
            if (data.badge != null)
              Positioned(
                top: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    data.badge!,
                    style: AppFonts.plusJakarta(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (data.tiles != null) {
      return SizedBox(
        height: size * 0.7,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: data.tiles!.asMap().entries.map((e) {
            final offset = e.key == 1 ? -12.0 : 0.0;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: e.key == 1
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.electric],
                        )
                      : null,
                  color: e.key == 1 ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadow.sm,
                ),
                alignment: Alignment.center,
                child: Text(
                  e.value,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: e.key == 1 ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      children: [
        if (data.bubbles != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              data.bubbles!.first,
              style: AppFonts.plusJakarta(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          width: size * 0.55,
          height: size * 0.55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.electric],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadow.button,
          ),
          child: Icon(data.icon, size: 56, color: Colors.white),
        ),
        const SizedBox(height: 16),
        if (data.bubbles != null && data.bubbles!.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              data.bubbles!.last,
              style: AppFonts.plusJakarta(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

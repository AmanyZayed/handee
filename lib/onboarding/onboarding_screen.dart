import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';

import '../config/app_config.dart';
import '../services/app_prefs.dart';
import '../services/auth_session.dart';
import '../services/guest_session.dart';
import '../theme/app_theme.dart';
import '../widgets/hd_app_bar.dart';
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
      bubbles: ['Hello', 'Thank you'],
      dark: false,
    ),
    _OnboardData(
      title: 'Point. Recognize.',
      subtitle:
          'Aim your camera and HANDee reads ASL signs into words in real time.',
      badge: 'Reading sign…',
      dark: true,
    ),
  ];

  Future<void> _finish() async {
    await AppPrefs.instance.setOnboardingComplete();
    if (!mounted) return;
    if (kSkipAuth) await preparePostOnboardingSession();
    if (!mounted) return;
    final next = await AuthSession.resolveStartScreen(onboardingDone: true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 10, 0),
              child: Row(
                children: [
                  const HdLogoMark(size: 40, radius: 12, bare: true),
                  const Spacer(),
                  TextButton(
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
                ],
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
    this.bubbles,
    this.badge,
    this.dark = false,
  });

  final String title;
  final String subtitle;
  final List<String>? bubbles;
  final String? badge;
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
    final logoSize = size * 0.55;
    final logoRadius = logoSize * 0.22;

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
            HdLogoMark(size: logoSize, radius: logoRadius, bare: true),
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
        HdLogoMark(size: logoSize, radius: logoRadius, bare: true),
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

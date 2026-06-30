import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handee/theme/app_fonts.dart';
import '../config/app_config.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/login_screen.dart';
import '../services/app_prefs.dart';
import '../services/guest_session.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  late final AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _textCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 2400), () async {
      if (!mounted) return;
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
      final done = await AppPrefs.instance.isOnboardingComplete();
      if (!mounted) return;
      if (kSkipAuth && done) {
        await preparePostOnboardingSession();
        if (!mounted) return;
      }
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) {
            if (!done) return const OnboardingScreen();
            return kSkipAuth ? const HomeScreen() : const LoginScreen();
          },
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final logoSize = (size.shortestSide * 0.26).clamp(92.0, 132.0);
    final titleSize = (size.width * 0.105).clamp(32.0, 46.0);
    final taglineSize = (size.width * 0.038).clamp(13.0, 16.0);
    final bottomInset = padding.bottom > 0 ? padding.bottom : 24.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.75),
              radius: 1.55,
              colors: [Color(0xFF20307A), Color(0xFF0C1336), Color(0xFF070B22)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: size.height * -0.08,
                left: size.width * -0.18,
                child: _GlowOrb(
                  diameter: size.width * 0.72,
                  color: const Color(0xFF05347E).withValues(alpha: 0.33),
                ),
              ),
              Positioned(
                bottom: size.height * -0.05,
                right: size.width * -0.2,
                child: _GlowOrb(
                  diameter: size.width * 0.68,
                  color: AppColors.cyan.withValues(alpha: 0.20),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: padding.top,
                  left: 24,
                  right: 24,
                  bottom: bottomInset,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: _FloatingLogo(size: logoSize),
                            ),
                          ),
                          SizedBox(height: size.height * 0.035),
                          FadeTransition(
                            opacity: _textFade,
                            child: SlideTransition(
                              position: _textSlide,
                              child: Column(
                                children: [
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(children: [
                                      TextSpan(
                                        text: 'HAND',
                                        style: AppFonts.spaceGrotesk(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -1.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'ee',
                                        style: AppFonts.spaceGrotesk(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          letterSpacing: -1.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '.',
                                        style: AppFonts.spaceGrotesk(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.cyan,
                                          letterSpacing: -1.5,
                                        ),
                                      ),
                                    ]),
                                  ),
                                  SizedBox(height: size.height * 0.012),
                                  Text(
                                    'Say it with your hands.',
                                    textAlign: TextAlign.center,
                                    style: AppFonts.plusJakarta(
                                      fontSize: taglineSize,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF9DB0E8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FadeTransition(
                      opacity: _textFade,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: _LoadingDots(controller: _dotCtrl),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.diameter, required this.color});
  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _FloatingLogo extends StatefulWidget {
  const _FloatingLogo({required this.size});
  final double size;

  @override
  State<_FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<_FloatingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    _y = Tween<double>(begin: 0, end: -9).animate(
      CurvedAnimation(parent: _float, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size * 0.52;
    final radius = widget.size * 0.28;

    return AnimatedBuilder(
      animation: _y,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _y.value),
        child: child,
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.electric],
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D05347E),
              blurRadius: 60,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: Icon(
          Icons.sign_language_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final offset = i / 3;
        final anim = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 0.25, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 30,
          ),
          TweenSequenceItem(
            tween: Tween(begin: 1.0, end: 0.25)
                .chain(CurveTween(curve: Curves.easeIn)),
            weight: 30,
          ),
          TweenSequenceItem(
            tween: ConstantTween(0.25),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(offset, (offset + 0.6).clamp(0, 1)),
          ),
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: i == 1 ? 3.5 : 0),
          child: AnimatedBuilder(
            animation: anim,
            builder: (_, __) => Opacity(
              opacity: anim.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.electric,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

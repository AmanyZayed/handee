import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:handee/theme/app_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../asl/asl_camera_screen.dart';
import '../profile/profile_screen.dart';
import '../pages/history_page.dart';
import '../pages/fingerspell_page.dart';
import '../services/app_prefs.dart';
import '../services/sign_player.dart';
import '../services/unity_bridge.dart';
import '../theme/app_theme.dart';
import '../widgets/home_avatar_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App shell
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTap(int index) {
    setState(() => _currentIndex = index.clamp(0, 2));
    if (index == 0) {
      UnityBridge.prepare();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _currentIndex.clamp(0, 2);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: tabIndex,
        children: const [
          _TranslateTab(),
          AslCameraScreen(isTab: true),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _HdBottomNav(
        currentIndex: tabIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation — deep-navy dark pill style
// ─────────────────────────────────────────────────────────────────────────────

class _HdBottomNav extends StatelessWidget {
  const _HdBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(Icons.compare_arrows_rounded, 'Translate'),
    _NavItem(Icons.camera_alt_outlined, 'Recognize'),
    _NavItem(Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl)),
      ),
      padding: EdgeInsets.only(
        left: 26, right: 26, top: 12, bottom: bottom + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_items.length, (i) {
          final selected = i == currentIndex;
          final item = _items[i];
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2C66C2).withValues(alpha: 0.28)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Icon(
                    item.icon, size: 22,
                    color: selected ? Colors.white : const Color(0xFF7C8AC0),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.label,
                  style: AppFonts.plusJakarta(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF7C8AC0),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Translate tab
// ─────────────────────────────────────────────────────────────────────────────

class _TranslateTab extends StatefulWidget {
  const _TranslateTab();

  @override
  State<_TranslateTab> createState() => _TranslateTabState();
}

class _TranslateTabState extends State<_TranslateTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _textCtrl = TextEditingController();

  int _inputMode = 0; // 0 = type, 1 = speak

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  bool _busy = false;

  final List<String> _recent = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setCancelHandler(() => setState(() => _isSpeaking = false));
    _tts.setLanguage('en-US');
    _textCtrl.addListener(() => setState(() {}));
    AppPrefs.historyRevision.addListener(_onHistoryChanged);
    _loadRecent();
    UnityBridge.prepare();
  }

  void _onHistoryChanged() => _loadRecent();

  Future<void> _loadRecent() async {
    final words = await AppPrefs.instance.recentWords();
    if (!mounted) return;
    setState(() {
      _recent
        ..clear()
        ..addAll(words);
    });
  }

  Future<void> _openHistory() async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
    if (!mounted) return;
    await _loadRecent();
    if (selected != null && selected.isNotEmpty) {
      setState(() => _textCtrl.text = selected);
    }
  }

  @override
  void dispose() {
    AppPrefs.historyRevision.removeListener(_onHistoryChanged);
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  // ── STT ──────────────────────────────────────────────────────────────────

  Future<void> _toggleListen() async {
    if (_isListening) {
      await _speech.stop();
      _pulseCtrl..stop()..reset();
      setState(() => _isListening = false);
      return;
    }
    final available = await _speech.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone not available')),
        );
      }
      return;
    }
    setState(() => _isListening = true);
    _pulseCtrl.repeat(reverse: true);
    _speech.listen(
      onResult: (r) => setState(() => _textCtrl.text = r.recognizedWords),
      listenOptions: stt.SpeechListenOptions(localeId: 'en_US'),
    );
  }

  // ── TTS ──────────────────────────────────────────────────────────────────

  Future<void> _speak() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    if (_isSpeaking) {
      await _tts.stop();
    } else {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);
    }
  }

  // ── Sign playback ─────────────────────────────────────────────────────────

  Future<void> _runBusy(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPlayAvatar() {
    final word = _textCtrl.text.trim().toLowerCase();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a word first, then tap Play Sign.')),
      );
      return;
    }
    _runBusy(() => SignPlayer.play(context, word));
  }

  void _openFingerspell() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FingerspellPage(initialText: _textCtrl.text.trim()),
      ),
    );
  }

  void _onPlayVideo() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a word first, then tap Video.')),
      );
      return;
    }
    _runBusy(() => SignPlayer.playVideo(context, text));
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 🌙';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardInset > 0;

    return Column(
      children: [
        Container(
          color: AppColors.background,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
              child: _HomeTopBar(
                greeting: _greeting,
                onHistoryTap: _openHistory,
              ),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar — sits above the floating input card so hands stay visible.
              Positioned(
                top: 0,
                left: 18,
                right: 18,
                bottom: 28,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF16204F), Color(0xFF0C1336)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xxxl),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33152050),
                        blurRadius: 40,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 96),
                        child: HomeAvatarPanel(),
                      ),
                      ListenableBuilder(
                        listenable: _textCtrl,
                        builder: (_, __) {
                          if (!_busy && _textCtrl.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: _StatusBadge(
                              label: _busy
                                  ? 'Signing…'
                                  : 'Signing "${_textCtrl.text.trim()}"',
                              active: _busy,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Input — slides up above the keyboard only
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                bottom: keyboardInset,
                child: SingleChildScrollView(
                  physics: keyboardOpen
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_recent.isNotEmpty) ...[
                        SizedBox(
                          height: 32,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18),
                            itemCount: _recent.length,
                            itemBuilder: (_, i) => _RecentChip(
                              label: _recent[i],
                              onTap: () =>
                                  setState(() => _textCtrl.text = _recent[i]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _InputCard(
                        controller: _textCtrl,
                        inputMode: _inputMode,
                        isListening: _isListening,
                        isSpeaking: _isSpeaking,
                        busy: _busy,
                        pulseAnim: _pulseAnim,
                        onModeChanged: (m) {
                          if (_isListening) {
                            _speech.stop();
                            _pulseCtrl
                              ..stop()
                              ..reset();
                          }
                          setState(() {
                            _inputMode = m;
                            _isListening = false;
                          });
                        },
                        onToggleListen: _toggleListen,
                        onPlayAvatar: _onPlayAvatar,
                        onPlayVideo: _onPlayVideo,
                        onSpeak: _speak,
                        onFingerspell: _openFingerspell,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar — HANDee. wordmark row
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.greeting,
    required this.onHistoryTap,
  });

  final String greeting;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadow.button,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/logo_mark.png',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: AppFonts.plusJakarta(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'HAND',
                    style: AppFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: 'ee',
                    style: AppFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: '.',
                    style: AppFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.electric,
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onHistoryTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar stage status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppFonts.plusJakarta(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent chips
// ─────────────────────────────────────────────────────────────────────────────

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppFonts.plusJakarta(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input card
// ─────────────────────────────────────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.inputMode,
    required this.isListening,
    required this.isSpeaking,
    required this.busy,
    required this.pulseAnim,
    required this.onModeChanged,
    required this.onToggleListen,
    required this.onPlayAvatar,
    required this.onPlayVideo,
    required this.onSpeak,
    required this.onFingerspell,
  });

  final TextEditingController controller;
  final int inputMode;
  final bool isListening;
  final bool isSpeaking;
  final bool busy;
  final Animation<double> pulseAnim;
  final ValueChanged<int> onModeChanged;
  final VoidCallback onToggleListen;
  final VoidCallback onPlayAvatar;
  final VoidCallback onPlayVideo;
  final VoidCallback onSpeak;
  final VoidCallback onFingerspell;

  bool get _hasText => controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Mode tabs ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ModeChip(
                          label: 'Type',
                          icon: Icons.keyboard_rounded,
                          selected: inputMode == 0,
                          onTap: () => onModeChanged(0),
                        ),
                        const SizedBox(width: 8),
                        _ModeChip(
                          label: 'Speak',
                          icon: isListening
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          selected: inputMode == 1,
                          activeColor: isListening
                              ? AppColors.error
                              : AppColors.primary,
                          onTap: () => onModeChanged(1),
                        ),
                        const SizedBox(width: 8),
                        _ModeChip(
                          label: 'Fingerspell',
                          icon: Icons.back_hand_outlined,
                          selected: false,
                          onTap: onFingerspell,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Input ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: inputMode == 0 ? _typeField() : _speakField(),
          ),

          const SizedBox(height: 12),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _ActionBtn(
                    icon: Icons.accessibility_new_rounded,
                    label: 'Play Sign',
                    primary: true,
                    busy: busy,
                    onTap: onPlayAvatar,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _ActionBtn(
                    icon: Icons.play_circle_rounded,
                    label: 'Video',
                    primary: false,
                    busy: busy,
                    onTap: onPlayVideo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _ActionBtn(
                    icon: isSpeaking
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up_rounded,
                    label: isSpeaking ? 'Stop' : 'Speak',
                    primary: false,
                    busy: false,
                    color: isSpeaking ? AppColors.error : null,
                    onTap: onSpeak,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.start,
        textAlignVertical: TextAlignVertical.center,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.text,
        maxLines: 3,
        minLines: 1,
        style: AppFonts.plusJakarta(
          fontSize: 15,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Type a word or phrase…',
          hintStyle: AppFonts.plusJakarta(
            color: AppColors.textHint,
            fontSize: 15,
          ),
          filled: true,
          fillColor: AppColors.surface2,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _speakField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isListening ? AppColors.error : AppColors.border,
          width: isListening ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              controller.text.isEmpty
                  ? 'Tap the mic to speak…'
                  : controller.text,
              style: AppFonts.plusJakarta(
                fontSize: 15,
                color: controller.text.isEmpty
                    ? AppColors.textHint
                    : AppColors.textPrimary,
                fontWeight:
                    controller.text.isEmpty ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ScaleTransition(
            scale:
                isListening ? pulseAnim : const AlwaysStoppedAnimation(1.0),
            child: GestureDetector(
              onTap: onToggleListen,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isListening
                        ? [AppColors.error, const Color(0xFFDC2626)]
                        : [AppColors.primary, AppColors.primaryMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: AppShadow.colored(
                    isListening ? AppColors.error : AppColors.primary,
                  ),
                ),
                child: Icon(
                  isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode chip
// ─────────────────────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.activeColor,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final col = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [col, col == AppColors.primary ? AppColors.primaryMid : col])
              : null,
          color: selected ? null : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppFonts.plusJakarta(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.primary,
    required this.busy,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool primary;
  final bool busy;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isColored = primary || color != null;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        decoration: BoxDecoration(
          gradient: (primary && !busy && color == null)
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryMid],
                )
              : null,
          color: busy
              ? AppColors.surface2
              : (color ?? (primary ? AppColors.primary : AppColors.surface2)),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: (primary && !busy)
              ? AppShadow.colored(AppColors.primary, opacity: 0.16)
              : [],
        ),
        child: (busy && primary)
            ? const Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 15,
                        color: busy
                            ? AppColors.textHint
                            : (isColored ? Colors.white : AppColors.textSecondary)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppFonts.plusJakarta(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: busy
                              ? AppColors.textHint
                              : (isColored ? Colors.white : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

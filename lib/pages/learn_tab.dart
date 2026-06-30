import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';
import '../pages/store_page.dart';
import '../services/app_prefs.dart';
import '../theme/app_theme.dart';

class LearnTab extends StatefulWidget {
  const LearnTab({super.key});

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _practiceProgress = 0;
  int _dayStreak = 0;

  static const List<String> _letters = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
  ];
  static const List<String> _numbers = [
    '0','1','2','3','4','5','6','7','8','9',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.trim().toUpperCase()));
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = AppPrefs.instance;
    final p = await prefs.dailyPracticeProgress();
    final s = await prefs.dayStreak();
    if (mounted) {
      setState(() {
        _practiceProgress = p;
        _dayStreak = s;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filteredLetters => _query.isEmpty
      ? _letters
      : _letters.where((l) => l.contains(_query)).toList();

  List<String> get _filteredNumbers => _query.isEmpty
      ? _numbers
      : _numbers.where((n) => n.contains(_query)).toList();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Header ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn ASL',
                    style: AppFonts.spaceGrotesk(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap any sign to view the hand shape.',
                    style: AppFonts.plusJakarta(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Search bar
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 15),
                        const Icon(Icons.search_rounded,
                            size: 19, color: AppColors.textHint),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textCapitalization: TextCapitalization.characters,
                            style: AppFonts.plusJakarta(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search a letter or number…',
                              hintStyle: AppFonts.plusJakarta(
                                fontSize: 14,
                                color: AppColors.textHint,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: _searchCtrl.clear,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.textHint),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Progress / daily practice card ────────────────────────────────
        if (_query.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryMid],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppShadow.button,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily practice',
                            style: AppFonts.plusJakarta(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$_practiceProgress of 10 signs mastered today',
                            style: AppFonts.plusJakarta(
                              fontSize: 12.5,
                              color: const Color(0xFFD6E1FF),
                            ),
                          ),
                          const SizedBox(height: 11),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: _practiceProgress / 10,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_dayStreak',
                            style: AppFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'STREAK',
                            style: AppFonts.plusJakarta(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD6E1FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Alphabet section ──────────────────────────────────────────────
        if (_filteredLetters.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Text(
                'Alphabet',
                style: AppFonts.plusJakarta(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _SignTile(
                  char: _filteredLetters[i],
                  imagePath:
                      'assets/asl/${_filteredLetters[i].toLowerCase()}.png',
                  isNumber: false,
                  onTap: () =>
                      _showSignSheet(context, _filteredLetters[i]),
                ),
                childCount: _filteredLetters.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 0.86,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],

        // ── Numbers section ───────────────────────────────────────────────
        if (_filteredNumbers.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Text(
                'Numbers',
                style: AppFonts.plusJakarta(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _SignTile(
                  char: _filteredNumbers[i],
                  imagePath: 'assets/asl/${_filteredNumbers[i]}.png',
                  isNumber: true,
                  onTap: () =>
                      _showSignSheet(context, _filteredNumbers[i]),
                ),
                childCount: _filteredNumbers.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 0.86,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],

        // ── No results ────────────────────────────────────────────────────
        if (_filteredLetters.isEmpty && _filteredNumbers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.textHint.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'No results for "$_query"',
                    style: AppFonts.plusJakarta(
                        fontSize: 15, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

        // ── Premium section ───────────────────────────────────────────────
        if (_query.isEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
              child: Text(
                'Premium Features',
                style: AppFonts.plusJakarta(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              child: Column(
                children: [
                  _PremiumCard(
                    icon: Icons.library_books_rounded,
                    title: 'Extended Vocabulary',
                    subtitle: '500+ word signs with video',
                    badge: 'Popular',
                    badgeColor: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StorePage()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PremiumCard(
                    icon: Icons.wifi_off_rounded,
                    title: 'Offline Mode',
                    subtitle: 'Use HANDee without internet',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StorePage()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PremiumCard(
                    icon: Icons.insights_rounded,
                    title: 'Learning Analytics',
                    subtitle: 'Track your progress over time',
                    badge: 'New',
                    badgeColor: AppColors.success,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StorePage()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showSignSheet(BuildContext context, String char) {
    AppPrefs.instance.recordSignLearned(char);
    _loadProgress();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SignDetailSheet(char: char),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign tile (grid cell)
// ─────────────────────────────────────────────────────────────────────────────

class _SignTile extends StatelessWidget {
  const _SignTile({
    required this.char,
    required this.imagePath,
    required this.isNumber,
    required this.onTap,
  });

  final String char;
  final String imagePath;
  final bool isNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadow.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(
                char,
                style: AppFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isNumber ? AppColors.cyan : AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SignDetailSheet extends StatelessWidget {
  const _SignDetailSheet({required this.char});
  final String char;

  @override
  Widget build(BuildContext context) {
    final isNumber = int.tryParse(char) != null;
    final imagePath = 'assets/asl/${char.toLowerCase()}.png';
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            char,
            style: AppFonts.spaceGrotesk(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: isNumber ? AppColors.cyan : AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl - 1),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    char,
                    style: AppFonts.spaceGrotesk(
                      fontSize: 80,
                      fontWeight: FontWeight.w700,
                      color: isNumber ? AppColors.cyan : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ASL sign for "$char"',
            style: AppFonts.plusJakarta(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryMid],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadow.button,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Done',
                  style: AppFonts.plusJakarta(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
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
// Premium feature card
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppFonts.plusJakarta(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppColors.primary)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          badge!,
                          style: AppFonts.plusJakarta(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor ?? AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.plusJakarta(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: const Icon(Icons.lock_rounded,
                color: AppColors.primary, size: 16),
          ),
        ],
      ),
      ),
    );
  }
}

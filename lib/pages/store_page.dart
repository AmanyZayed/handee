import 'package:flutter/material.dart';
import 'package:handee/theme/app_fonts.dart';

import '../services/app_prefs.dart';
import '../theme/app_theme.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  bool _notifyMe = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await AppPrefs.instance.storeNotifyEnabled();
    if (mounted) setState(() => _notifyMe = v);
  }

  Future<void> _toggleNotify() async {
    final next = !_notifyMe;
    await AppPrefs.instance.setStoreNotifyEnabled(next);
    if (!mounted) return;
    setState(() => _notifyMe = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next
              ? "We'll notify you when Premium launches."
              : 'Notification preference cleared.',
        ),
      ),
    );
  }

  void _showPackInfo(_FeaturePack pack) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pack.title,
              style: AppFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pack.description,
              style: AppFonts.plusJakarta(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon — tap Get Notified above to hear when this launches.',
              style: AppFonts.plusJakarta(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 116,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Text(
                'Store',
                style: AppFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.royalNavy, AppColors.primaryMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.ink, Color(0xFF1A2350)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D0B1030),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          'Coming Soon',
                          style: AppFonts.plusJakarta(
                            color: AppColors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Premium Features\nUnlocked',
                        style: AppFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Get access to advanced sign recognition,\nmore vocabulary, and offline mode.',
                        style: AppFonts.plusJakarta(
                          color: const Color(0xFF9DB0E8),
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _toggleNotify,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 11),
                          decoration: BoxDecoration(
                            color: _notifyMe
                                ? AppColors.cyan.withValues(alpha: 0.25)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: _notifyMe
                                ? Border.all(color: AppColors.cyan)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_notifyMe)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.check_rounded,
                                      size: 16, color: AppColors.cyan),
                                ),
                              Text(
                                _notifyMe ? 'You\'re on the list' : 'Get Notified',
                                style: AppFonts.plusJakarta(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _notifyMe
                                      ? AppColors.cyan
                                      : AppColors.royalNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Feature Packs',
                  style: AppFonts.plusJakarta(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._featurePacks.map(
                  (pack) => _FeaturePackCard(
                    pack: pack,
                    onTap: () => _showPackInfo(pack),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static const _featurePacks = [
    _FeaturePack(
      icon: Icons.menu_book_rounded,
      title: 'Extended Vocabulary',
      description: '500+ additional signs including medical and legal terms',
      badge: 'Popular',
      badgeColor: AppColors.primary,
    ),
    _FeaturePack(
      icon: Icons.wifi_off_rounded,
      title: 'Offline Mode',
      description: 'Full recognition and translation without internet',
      badge: null,
      badgeColor: null,
    ),
    _FeaturePack(
      icon: Icons.analytics_rounded,
      title: 'Learning Analytics',
      description: 'Track progress, streaks, and mastered signs',
      badge: 'New',
      badgeColor: AppColors.success,
    ),
  ];
}

class _FeaturePack {
  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final Color? badgeColor;

  const _FeaturePack({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
  });
}

class _FeaturePackCard extends StatelessWidget {
  const _FeaturePackCard({required this.pack, required this.onTap});
  final _FeaturePack pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(pack.icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          pack.title,
                          style: AppFonts.plusJakarta(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (pack.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (pack.badgeColor ?? AppColors.primary)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            pack.badge!,
                            style: AppFonts.plusJakarta(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: pack.badgeColor ?? AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pack.description,
                    style: AppFonts.plusJakarta(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

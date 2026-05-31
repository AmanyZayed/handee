import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../asl/asl_camera_screen.dart';
import '../pages/history_page.dart';
import '../pages/store_page.dart';
import '../profile/profile_screen.dart';
import '../services/sign_player.dart';
import '../unity/unity_config.dart';
import '../unity/unity_widget_controller.dart';
import '../widgets/home_avatar_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 243, 244),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            _HomeMainContent(),
            StorePage(),
            HistoryPage(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 21, 38, 107),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(
              icon: Icons.translate,
              index: 0,
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
            _NavIcon(
              icon: Icons.shopping_cart,
              index: 1,
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
            _NavIcon(
              icon: Icons.history,
              index: 2,
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
            _NavIcon(
              icon: Icons.person,
              index: 3,
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

class _HomeMainContent extends StatefulWidget {
  const _HomeMainContent();

  @override
  State<_HomeMainContent> createState() => _HomeMainContentState();
}

class _HomeMainContentState extends State<_HomeMainContent> {
  final TextEditingController _textController = TextEditingController();
  UnityWidgetController? get unityWidgetController =>
      UnityWidgetController.instance;
  bool _busy = false;

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPlay() {
    final word = _textController.text.trim().toLowerCase();
    if (word.isEmpty) return;

    _runBusy(() async {
      final unity = unityWidgetController;
      if (unity != null) {
        await unity.postMessage(
          UnityConfig.gameObject,
          UnityConfig.playMethod,
          word,
        );
        if (kDebugMode) {
          debugPrint('Sent word to Unity: $word');
        }
        return;
      }

      if (!mounted) return;
      await SignPlayer.play(context, word);
    });
  }

  void _onPlayVideo() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _runBusy(() => SignPlayer.playVideo(context, text));
  }

  void _openAslCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AslCameraScreen()),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 70, 57, 187),
                  Color.fromARGB(255, 238, 234, 239),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(72, 12, 12, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      child: HomeAvatarPanel(),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 24,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _openAslCamera,
                        child: const _SideIcon(icon: Icons.videocam),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/asl-translator');
                        },
                        child: const _SideIcon(icon: Icons.language),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/speech-to-text');
                        },
                        child: const _SideIcon(icon: Icons.mic),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/text-to-speech');
                        },
                        child: const _SideIcon(icon: Icons.volume_up),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Green = avatar sign · Purple = sign video · Camera = ASL recognition',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.done,
                      enabled: !_busy,
                      onSubmitted: (_) => _onPlay(),
                      decoration: InputDecoration(
                        hintText: 'Type a word (e.g. hello, book)',
                        filled: true,
                        fillColor: const Color(0xFFF2F2F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _busy ? null : _onPlayVideo,
                    child: Container(
                      width: 48,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _busy
                            ? Colors.grey
                            : const Color.fromARGB(255, 70, 57, 187),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _busy ? null : _onPlay,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _busy ? Colors.grey : Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.play_arrow,
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
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isSelected ? 30 : 26,
        ),
      ),
    );
  }
}

class _SideIcon extends StatelessWidget {
  const _SideIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: const Color.fromARGB(255, 21, 38, 107),
      ),
    );
  }
}

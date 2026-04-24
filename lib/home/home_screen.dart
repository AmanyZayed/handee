import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../camera_screen.dart';
import '../pages/store_page.dart';
import '../pages/history_page.dart';
import '../profile/profile_screen.dart';
import '../video_test_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  int _currentIndex = 0;

  String aiResult = "No AI yet";

  Future<void> _openCamera() async {
    await _picker.pickImage(source: ImageSource.camera);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 243, 244),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const _HomeMainContent(),
            const StorePage(),
            const HistoryPage(),
            const ProfileScreen(),
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

// =========================
// Home Main Content
// =========================

class _HomeMainContent extends StatefulWidget {
  const _HomeMainContent({super.key});

  @override
  State<_HomeMainContent> createState() => _HomeMainContentState();
}

class _HomeMainContentState extends State<_HomeMainContent> {
  final TextEditingController _textController = TextEditingController();

  void _playTypedWord() {
    final word = _textController.text.toLowerCase().trim();

    if (word.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoTestPage(word: word),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
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
                Center(
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(66, 255, 253, 253),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 180,
                      color: Colors.white,
                    ),
                  ),
                ),

                // 🔥 SIDE ICONS
                Positioned(
                  left: 16,
                  bottom: 40,
                  child: Column(
                    children: [
                      // 🤖 AI Camera
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CameraScreen(),
                            ),
                          );
                        },
                        child: const _SideIcon(icon: Icons.smart_toy),
                      ),

                      const SizedBox(height: 12),

                      // 🌐 ASL Translator
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/asl-translator');
                        },
                        child: const _SideIcon(icon: Icons.language),
                      ),

                      const SizedBox(height: 12),

                      // 🎤 Speech to Text
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/speech-to-text');
                        },
                        child: const _SideIcon(icon: Icons.mic),
                      ),

                      const SizedBox(height: 12),

                      // 🔊 Text to Speech
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

        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _playTypedWord(),
                    decoration: InputDecoration(
                      hintText: 'Type word (e.g. hello)',
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 🎬 PLAY BUTTON (NEW)
                GestureDetector(
                  onTap: _playTypedWord,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 📷 CAMERA (UNCHANGED)
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CameraScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 21, 38, 107),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =========================
// Bottom Nav Icon
// =========================

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavIcon({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
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

// =========================
// Side Icon
// =========================

class _SideIcon extends StatelessWidget {
  final IconData icon;

  const _SideIcon({required this.icon});

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
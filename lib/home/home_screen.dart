import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../pages/store_page.dart';
import '../pages/history_page.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  int _currentIndex = 0;

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
            _HomeMainContent(openCamera: _openCamera),
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
                onTap: _onNavTap),
            _NavIcon(
                icon: Icons.shopping_cart,
                index: 1,
                currentIndex: _currentIndex,
                onTap: _onNavTap),
            _NavIcon(
                icon: Icons.history,
                index: 2,
                currentIndex: _currentIndex,
                onTap: _onNavTap),
            _NavIcon(
                icon: Icons.person,
                index: 3,
                currentIndex: _currentIndex,
                onTap: _onNavTap),
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

// =======================================================
// Home Main Content
// =======================================================

class _HomeMainContent extends StatelessWidget {
  final VoidCallback openCamera;

  const _HomeMainContent({required this.openCamera});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // =========================
        // 1️⃣ Character Area
        // =========================
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(66, 255, 253, 253),
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

                Positioned(
                  left: 16,
                  bottom: 40,
                  child: Column(
                    children: const [
                      _SideIcon(icon: Icons.refresh),
                      SizedBox(height: 12),
                      _SideIcon(icon: Icons.language),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // =========================
        // 2️⃣ Input Area
        // =========================
        Expanded(
          flex: 2,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                    decoration: InputDecoration(
                      hintText: 'Type to translate...',
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                GestureDetector(
                  onTap: openCamera,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color:  Color.fromARGB(255, 21, 38, 107),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:  Color.fromARGB(255, 21, 38, 107)
                              .withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
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
          color: isSelected
              ? Colors.white.withOpacity(0.2)
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

// =========================
// Side Small Icon
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
        color:  Color.fromARGB(255, 21, 38, 107),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class AslTranslatorPage extends StatefulWidget {
  const AslTranslatorPage({super.key});

  @override
  State<AslTranslatorPage> createState() => _AslTranslatorPageState();
}

class _AslTranslatorPageState extends State<AslTranslatorPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _signs = [];

  String? _getImageName(String char) {
    final c = char.toLowerCase();
    if (RegExp(r'^[a-z]$').hasMatch(c)) return '$c.png';
    if (RegExp(r'^[0-9]$').hasMatch(c)) return '$c.png';
    return null;
  }

  void _onTextChanged(String text) {
    setState(() {
      _signs = text.split('').where((ch) {
        return ch == ' ' || _getImageName(ch) != null;
      }).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Language Translator'),
        backgroundColor: const Color(0xFF3D7EF5),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFAFDE7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onTextChanged,
                    decoration: const InputDecoration(
                      hintText: 'Type text or numbers…',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _controller.clear();
                    _onTextChanged('');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _signs.isEmpty
                ? const Center(
                    child: Text(
                      'Signs will appear here as you type',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: _signs.map((ch) {
                          if (ch == ' ') return const SizedBox(width: 24);
                          final imgName = _getImageName(ch)!;
                          return _SignTile(
                            imagePath: 'assets/asl/$imgName',
                            label: ch.toUpperCase(),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SignTile extends StatelessWidget {
  final String imagePath;
  final String label;

  const _SignTile({required this.imagePath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imagePath,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade100,
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
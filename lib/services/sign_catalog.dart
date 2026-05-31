import 'package:flutter/services.dart';

/// Words the Unity avatar can animate (300-word list).
class SignCatalog {
  SignCatalog._();

  static Set<String>? _unityWords;
  static Set<String>? _assetPaths;

  static const _videoFolders = [
    'assets/signs_final_300',
    'assets/signs_cropped',
    'assets/signs',
    'assets/signs_cutout',
  ];

  static Future<Set<String>> unityWords() async {
    if (_unityWords != null) return _unityWords!;
    final raw = await rootBundle.loadString('assets/words/unity_words.txt');
    _unityWords = raw
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toSet();
    return _unityWords!;
  }

  static Future<Set<String>> _allAssetPaths() async {
    if (_assetPaths != null) return _assetPaths!;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _assetPaths = manifest.listAssets().toSet();
    return _assetPaths!;
  }

  static Future<bool> canUseUnityAvatar(String text) async {
    final words = _tokens(text);
    if (words.isEmpty) return false;
    final catalog = await unityWords();
    return words.every(catalog.contains);
  }

  static Future<bool> hasSignVideo(String text) async {
    final words = _tokens(text);
    if (words.isEmpty) return false;

    final assets = await _allAssetPaths();
    for (final word in words) {
      var found = false;
      for (final folder in _videoFolders) {
        if (assets.contains('$folder/$word.mp4')) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  static List<String> _tokens(String text) {
    return text
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }
}

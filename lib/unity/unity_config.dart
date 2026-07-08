/// Must match GameObject names in the Unity export (data.unity3d).
class UnityConfig {
  UnityConfig._();

  /// Root avatar object in the exported ASL scene.
  static const gameObject = 'HamadaAvatar';

  /// avatar_final4 uses PlayText (no PlaySign on ASLAnimator).
  static const playMethod = 'PlayText';
  static const receiveMethod = 'ReceiveTextFromFlutter';
  static const playTextMethod = 'PlayText';

  /// Alternate names seen in scene / at runtime.
  static const legacyGameObjects = [
    'HamadaAvatar',
    'Hamada',
    'Avatar',
    'ASLAnimator',
  ];
}

/// Must match the GameObject and method on the Unity avatar script.
class UnityConfig {
  UnityConfig._();

  static const gameObject = 'AvatarController';
  static const playMethod = 'PlaySign';

  /// Legacy names still present in some Unity exports.
  static const legacyGameObject = 'Hamada';
  static const legacyMethod = 'ReceiveTextFromFlutter';
}

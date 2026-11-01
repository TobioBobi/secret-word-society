import 'dart:math';

/// Session-only appearance, independent of display name and game randomness.
final class PlayerAvatar {
  const PlayerAvatar({required this.seed});

  factory PlayerAvatar.random() => PlayerAvatar(
    seed: List.generate(
      4,
      (_) => _random.nextInt(1 << 32).toRadixString(16),
    ).join('-'),
  );

  static final _random = Random.secure();
  static const style = 'cutouts';
  final String seed;
}

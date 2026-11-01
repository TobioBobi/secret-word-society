import 'player_avatar.dart';

/// Identity stays stable even when players have similar display names.
final class Player {
  Player({required String id, required String name, PlayerAvatar? avatar})
    : id = id.trim(),
      name = name.trim(),
      avatar = avatar ?? PlayerAvatar.random() {
    if (this.id.isEmpty || this.name.isEmpty) {
      throw ArgumentError('Player ID and name must not be empty.');
    }
  }

  final String id;
  final String name;
  final PlayerAvatar avatar;
}

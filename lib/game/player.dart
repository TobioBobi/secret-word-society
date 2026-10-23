/// Identity stays stable even when players have similar display names.
final class Player {
  Player({required String id, required String name})
    : id = id.trim(),
      name = name.trim() {
    if (this.id.isEmpty || this.name.isEmpty) {
      throw ArgumentError('Player ID and name must not be empty.');
    }
  }

  final String id;
  final String name;
}

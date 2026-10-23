import 'dart:math';

import 'game_round.dart';
import 'player.dart';
import 'word_catalog.dart';

enum NameProblem { empty, duplicate }

/// In-memory group and current round. A new app session always starts empty.
final class GameSession {
  final List<Player> _players = [];
  int _nextPlayerId = 0;
  GameRound? _round;

  List<Player> get players => List.unmodifiable(_players);
  GameRound? get round => _round;
  bool get canStart =>
      _round == null && _players.length >= GameRound.minimumPlayers;

  NameProblem? addPlayer(String input) {
    _requireSetup();
    final name = input.trim();
    if (name.isEmpty) return NameProblem.empty;
    if (_players.any(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    )) {
      return NameProblem.duplicate;
    }
    _players.add(Player(id: 'player-${_nextPlayerId++}', name: name));
    return null;
  }

  void removePlayer(String id) {
    _requireSetup();
    _players.removeWhere((player) => player.id == id);
  }

  void startRound(WordCatalog catalog, {Random? random}) {
    _requireSetup();
    _round = GameRound.start(
      players: _players,
      catalog: catalog,
      random: random,
    );
  }

  void revealSecret() => _round = _requireRound().revealSecret();

  void hideAndAdvance() => _round = _requireRound().hideAndAdvance();

  void concealSecret() => _round = _round?.concealSecret();

  GameRound _requireRound() =>
      _round ?? (throw StateError('Start a round first.'));

  /// Editing the group discards the round, never the names.
  void returnToGroup() => _round = null;

  void _requireSetup() {
    if (_round != null) throw StateError('Return to the group before editing.');
  }
}

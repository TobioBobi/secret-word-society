import 'dart:math';

import 'game_round.dart';
import 'player.dart';
import 'player_avatar.dart';
import 'word_catalog.dart';
import 'word_deck.dart';

enum NameProblem { empty, duplicate }

/// In-memory group and current round. A new app session always starts empty.
final class GameSession {
  final List<Player> _players = [];
  int _nextPlayerId = 0;
  GameRound? _round;
  WordDeck? _deck;

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

  NameProblem? renamePlayer(String id, String input) {
    _requireSetup();
    final index = _players.indexWhere((player) => player.id == id);
    if (index < 0) throw ArgumentError('Unknown player.');
    final name = input.trim();
    if (name.isEmpty) return NameProblem.empty;
    if (_players.any(
      (player) =>
          player.id != id && player.name.toLowerCase() == name.toLowerCase(),
    )) {
      return NameProblem.duplicate;
    }
    final player = _players[index];
    _players[index] = Player(id: id, name: name, avatar: player.avatar);
    return null;
  }

  void rerollAvatar(String id) {
    _requireSetup();
    final index = _players.indexWhere((player) => player.id == id);
    if (index < 0) throw ArgumentError('Unknown player.');
    final player = _players[index];
    _players[index] = Player(
      id: id,
      name: player.name,
      avatar: PlayerAvatar.random(),
    );
  }

  void removePlayer(String id) {
    _requireSetup();
    _players.removeWhere((player) => player.id == id);
  }

  void startRound(WordCatalog catalog, {Random? random}) {
    _requireSetup();
    final deck = _deck?.matches(catalog) == true ? _deck! : WordDeck(catalog);
    _round = GameRound.fromDeck(players: _players, deck: deck, random: random);
    _deck = deck;
  }

  void revealSecret({bool markAsViewed = true}) =>
      _round = _requireRound().revealSecret(markAsViewed: markAsViewed);

  void markSecretViewed() => _round = _requireRound().markSecretViewed();

  void hideAndAdvance() => _round = _requireRound().hideAndAdvance();

  void concealSecret() => _round = _round?.concealSecret();

  void startDiscussion(DateTime now) =>
      _round = _requireRound().startDiscussion(now);

  void advanceTime(DateTime now) => _round = _requireRound().advanceTime(now);

  void selectSuspect(String playerId) =>
      _round = _requireRound().selectSuspect(playerId);

  void confirmSuspect(DateTime now) =>
      _round = _requireRound().confirmSuspect(now);

  void pauseReveal(DateTime now) => _round = _round?.pauseReveal(now);

  void resumeReveal(DateTime now) => _round = _round?.resumeReveal(now);

  void newRound() => _round = _requireRound().newRound();

  GameRound _requireRound() =>
      _round ?? (throw StateError('Start a round first.'));

  /// Editing the group discards the round, never the names.
  void returnToGroup() => _round = null;

  void _requireSetup() {
    if (_round != null) throw StateError('Return to the group before editing.');
  }
}

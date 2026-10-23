import 'dart:math';

import 'player.dart';
import 'word_catalog.dart';

enum GamePhase { handoff, secret, ready, discussion, voting, result }

enum PlayerRole { group, imposter }

enum Winner { group, imposter }

/// Contains exactly the information the current player may see.
final class PlayerSecret {
  const PlayerSecret({required this.role, required this.text});

  final PlayerRole role;
  final String text;
}

final class RoundResult {
  const RoundResult({
    required this.imposter,
    required this.suspect,
    required this.word,
  });

  final Player imposter;
  final Player suspect;
  final String word;

  Winner get winner =>
      suspect.id == imposter.id ? Winner.group : Winner.imposter;
}

/// Immutable round state. UI callers replace their snapshot after each action.
///
/// The selected pair and role assignment stay private until their intended
/// phase. Do not retain old, revealed snapshots in navigation or restoration.
final class GameRound {
  GameRound._({
    required this.players,
    required this._catalog,
    required this._random,
    required this._pair,
    required this._imposterIndex,
    this.phase = GamePhase.handoff,
    this._handoffIndex = 0,
    this.discussionEndsAt,
    this.suspect,
  });

  factory GameRound.start({
    required Iterable<Player> players,
    required WordCatalog catalog,
    Random? random,
  }) {
    final group = List<Player>.unmodifiable(players);
    if (group.length < minimumPlayers) {
      throw ArgumentError('At least three players are required.');
    }
    if (group.map((player) => player.id).toSet().length != group.length ||
        group.map((player) => player.name.toLowerCase()).toSet().length !=
            group.length) {
      throw ArgumentError('Player IDs and names must be unique.');
    }
    final source = random ?? Random();
    return GameRound._(
      players: group,
      catalog: catalog,
      random: source,
      pair: catalog.choose(source),
      imposterIndex: source.nextInt(group.length),
    );
  }

  static const minimumPlayers = 3;
  static const discussionDuration = Duration(minutes: 2);

  final List<Player> players;
  final GamePhase phase;
  final DateTime? discussionEndsAt;
  final Player? suspect;
  final WordCatalog _catalog;
  final Random _random;
  final WordPair _pair;
  final int _imposterIndex;
  final int _handoffIndex;

  String get languageCode => _catalog.languageCode;

  Player? get currentPlayer =>
      phase == GamePhase.handoff || phase == GamePhase.secret
      ? players[_handoffIndex]
      : null;

  /// One-based progress while handing out secrets, absent afterwards.
  int? get currentPlayerNumber =>
      currentPlayer == null ? null : _handoffIndex + 1;

  PlayerSecret? get currentSecret {
    if (phase != GamePhase.secret) return null;
    final isImposter = _handoffIndex == _imposterIndex;
    return PlayerSecret(
      role: isImposter ? PlayerRole.imposter : PlayerRole.group,
      text: isImposter ? _pair.hint : _pair.word,
    );
  }

  RoundResult? get result => phase == GamePhase.result
      ? RoundResult(
          imposter: players[_imposterIndex],
          suspect: suspect!,
          word: _pair.word,
        )
      : null;

  GameRound revealSecret() {
    _requirePhase(GamePhase.handoff);
    return _copy(phase: GamePhase.secret);
  }

  /// Conceals on interruption without advancing to another person.
  GameRound concealSecret() =>
      phase == GamePhase.secret ? _copy(phase: GamePhase.handoff) : this;

  /// Concealment and advancing happen in a single state change.
  GameRound hideAndAdvance() {
    _requirePhase(GamePhase.secret);
    final isLast = _handoffIndex == players.length - 1;
    return _copy(
      phase: isLast ? GamePhase.ready : GamePhase.handoff,
      handoffIndex: isLast ? _handoffIndex : _handoffIndex + 1,
    );
  }

  GameRound startDiscussion(DateTime now) {
    _requirePhase(GamePhase.ready);
    return _copy(
      phase: GamePhase.discussion,
      discussionEndsAt: now.add(discussionDuration),
    );
  }

  /// Derives remaining time from a deadline, including time spent off screen.
  Duration remainingDiscussionTime(DateTime now) {
    if (phase == GamePhase.voting || phase == GamePhase.result) {
      return Duration.zero;
    }
    if (discussionEndsAt == null) return discussionDuration;
    final remaining = discussionEndsAt!.difference(now);
    if (remaining.isNegative) return Duration.zero;
    return remaining > discussionDuration ? discussionDuration : remaining;
  }

  /// Called by UI timer ticks and when resuming the app.
  GameRound advanceTime(DateTime now) {
    _requirePhase(GamePhase.discussion);
    return now.isBefore(discussionEndsAt!)
        ? this
        : _copy(phase: GamePhase.voting);
  }

  GameRound selectSuspect(String playerId) {
    _requirePhase(GamePhase.voting);
    final index = players.indexWhere((player) => player.id == playerId);
    if (index == -1) throw ArgumentError('Suspect must belong to this round.');
    return _copy(phase: phase, suspect: players[index]);
  }

  GameRound confirmSuspect() {
    _requirePhase(GamePhase.voting);
    if (suspect == null) throw StateError('Select a suspect first.');
    return _copy(phase: GamePhase.result);
  }

  /// Retains the group; every round draws a word and an imposter anew.
  /// Random repeats are allowed. No persistence or repeat avoidance yet.
  GameRound newRound() {
    _requirePhase(GamePhase.result);
    return GameRound.start(
      players: players,
      catalog: _catalog,
      random: _random,
    );
  }

  void _requirePhase(GamePhase expected) {
    if (phase != expected) {
      throw StateError('Action is not available in the current phase.');
    }
  }

  GameRound _copy({
    required GamePhase phase,
    int? handoffIndex,
    DateTime? discussionEndsAt,
    Player? suspect,
  }) => GameRound._(
    players: players,
    catalog: _catalog,
    random: _random,
    pair: _pair,
    imposterIndex: _imposterIndex,
    phase: phase,
    handoffIndex: handoffIndex ?? _handoffIndex,
    discussionEndsAt: discussionEndsAt ?? this.discussionEndsAt,
    suspect: suspect ?? this.suspect,
  );
}

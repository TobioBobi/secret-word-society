import 'dart:math';

import 'player.dart';
import 'round_rules.dart';
import 'word_catalog.dart';
import 'word_deck.dart';

enum GamePhase { handoff, secret, ready, discussion, voting, reveal, result }

enum PlayerRole { group, imposter }

enum Winner { group, imposter }

/// Contains exactly the information the current player may see.
final class PlayerSecret {
  const PlayerSecret({required this.role, required this.text});

  final PlayerRole role;
  final String text;
}

final class RoundResult {
  RoundResult({
    required Iterable<Player> imposters,
    required Iterable<Player> suspects,
    required this.word,
  }) : imposters = List.unmodifiable(imposters),
       suspects = List.unmodifiable(suspects);

  final List<Player> imposters;
  final List<Player> suspects;
  final String word;

  Winner get winner =>
      suspects.length == imposters.length &&
          suspects.every(
            (suspect) => imposters.any((imposter) => imposter.id == suspect.id),
          )
      ? Winner.group
      : Winner.imposter;
}

/// Immutable round state. UI callers replace their snapshot after each action.
///
/// The selected pair and role assignment stay private until their intended
/// phase. Do not retain old, revealed snapshots in navigation or restoration.
final class GameRound {
  GameRound._({
    required this.players,
    required this._deck,
    required this._random,
    required this._pair,
    required this._imposterHints,
    this.phase = GamePhase.handoff,
    this._handoffIndex = 0,
    this.hasViewedSecret = false,
    this.discussionEndsAt,
    this.suspects = const [],
    this.revealEndsAt,
    this.revealRemaining = revealDuration,
  });

  factory GameRound.start({
    required Iterable<Player> players,
    required WordCatalog catalog,
    Random? random,
  }) => GameRound.fromDeck(
    players: players,
    deck: WordDeck(catalog),
    random: random,
  );

  /// Reuses a session's draw source; only starting a round consumes a word.
  factory GameRound.fromDeck({
    required Iterable<Player> players,
    required WordDeck deck,
    Random? random,
  }) {
    final group = List<Player>.unmodifiable(players);
    RoundRules.validate(group.length);
    if (group.map((player) => player.id).toSet().length != group.length ||
        group.map((player) => player.name.toLowerCase()).toSet().length !=
            group.length) {
      throw ArgumentError('Player IDs and names must be unique.');
    }
    final source = random ?? Random();
    if (deck.catalog.pairs.any(
      (pair) => pair.hints.length < RoundRules.maximumImposters(group.length),
    )) {
      throw ArgumentError('This group needs more distinct hints per word.');
    }
    final pair = deck.draw(source);
    final count = RoundRules.drawImposterCount(group.length, source);
    // Partial Fisher–Yates: unique, uniformly selected players without retries.
    final indices = List.generate(group.length, (index) => index);
    final hints = pair.hints.toList()..shuffle(source);
    final assignments = <int, String>{};
    for (var index = 0; index < count; index++) {
      final chosen = index + source.nextInt(group.length - index);
      final value = indices[chosen];
      indices[chosen] = indices[index];
      indices[index] = value;
      assignments[value] = hints[index];
    }
    return GameRound._(
      players: group,
      deck: deck,
      random: source,
      pair: pair,
      imposterHints: Map.unmodifiable(assignments),
    );
  }

  static const minimumPlayers = RoundRules.minimumPlayers;
  Duration get discussionDuration =>
      RoundRules.discussionDuration(players.length);
  bool get allowsMultipleSuspects =>
      RoundRules.maximumImposters(players.length) > 1;
  int get maximumSuspects => RoundRules.maximumImposters(players.length);

  /// The public group-size limit never depends on the secret role draw.
  bool canSelectSuspect(String playerId) =>
      !allowsMultipleSuspects ||
      suspects.length < maximumSuspects ||
      suspects.any((player) => player.id == playerId);
  static const revealDuration = Duration(seconds: 3);

  final List<Player> players;
  final GamePhase phase;
  final bool hasViewedSecret;

  bool get canAdvanceCard =>
      phase == GamePhase.handoff || phase == GamePhase.secret;
  final DateTime? discussionEndsAt;
  final List<Player> suspects;
  final DateTime? revealEndsAt;
  final Duration revealRemaining;
  final WordDeck _deck;
  final Random _random;
  final WordPair _pair;
  final Map<int, String> _imposterHints;
  final int _handoffIndex;

  String get languageCode => _deck.catalog.languageCode;

  Player? get currentPlayer =>
      phase == GamePhase.handoff || phase == GamePhase.secret
      ? players[_handoffIndex]
      : null;

  /// One-based progress while handing out secrets, absent afterwards.
  int? get currentPlayerNumber =>
      currentPlayer == null ? null : _handoffIndex + 1;

  PlayerSecret? get currentSecret {
    if (phase != GamePhase.secret) return null;
    final hint = _imposterHints[_handoffIndex];
    final isImposter = hint != null;
    return PlayerSecret(
      role: isImposter ? PlayerRole.imposter : PlayerRole.group,
      text: hint ?? _pair.word,
    );
  }

  RoundResult? get result => phase == GamePhase.result
      ? RoundResult(
          imposters: [
            for (var i = 0; i < players.length; i++)
              if (_imposterHints.containsKey(i)) players[i],
          ],
          suspects: suspects,
          word: _pair.word,
        )
      : null;

  GameRound revealSecret({bool markAsViewed = true}) {
    _requirePhase(GamePhase.handoff);
    return _copy(
      phase: GamePhase.secret,
      hasViewedSecret: hasViewedSecret || markAsViewed,
    );
  }

  /// Records a complete viewing independently of the always-available handoff.
  GameRound markSecretViewed() {
    _requirePhase(GamePhase.secret);
    return hasViewedSecret ? this : _copy(phase: phase, hasViewedSecret: true);
  }

  /// Conceals on interruption without advancing to another person.
  GameRound concealSecret() =>
      phase == GamePhase.secret ? _copy(phase: GamePhase.handoff) : this;

  /// Concealment and advancing happen in a single state change.
  GameRound hideAndAdvance() {
    if (!canAdvanceCard) {
      throw StateError('Cards can only advance during handoff.');
    }
    final isLast = _handoffIndex == players.length - 1;
    return _copy(
      phase: isLast ? GamePhase.ready : GamePhase.handoff,
      handoffIndex: isLast ? _handoffIndex : _handoffIndex + 1,
      hasViewedSecret: false,
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
    if (phase == GamePhase.voting ||
        phase == GamePhase.reveal ||
        phase == GamePhase.result) {
      return Duration.zero;
    }
    if (discussionEndsAt == null) return discussionDuration;
    final remaining = discussionEndsAt!.difference(now);
    if (remaining.isNegative) return Duration.zero;
    return remaining > discussionDuration ? discussionDuration : remaining;
  }

  /// Called by UI timer ticks and when resuming the app.
  GameRound advanceTime(DateTime now) {
    if (phase == GamePhase.reveal) {
      return revealEndsAt != null && remainingRevealTime(now) == Duration.zero
          ? _copy(phase: GamePhase.result)
          : this;
    }
    _requirePhase(GamePhase.discussion);
    return now.isBefore(discussionEndsAt!)
        ? this
        : _copy(phase: GamePhase.voting);
  }

  GameRound selectSuspect(String playerId) {
    _requirePhase(GamePhase.voting);
    final index = players.indexWhere((player) => player.id == playerId);
    if (index == -1) throw ArgumentError('Suspect must belong to this round.');
    if (!canSelectSuspect(playerId)) return this;
    final selected = allowsMultipleSuspects
        ? (suspects.any((player) => player.id == playerId)
              ? suspects.where((player) => player.id != playerId).toList()
              : [...suspects, players[index]])
        : [players[index]];
    return _copy(phase: phase, suspects: List.unmodifiable(selected));
  }

  GameRound confirmSuspect(DateTime now) {
    _requirePhase(GamePhase.voting);
    if (suspects.isEmpty) throw StateError('Select a suspect first.');
    return _copy(
      phase: GamePhase.reveal,
      revealEndsAt: now.add(revealDuration),
    );
  }

  Duration remainingRevealTime(DateTime now) {
    if (phase == GamePhase.result) return Duration.zero;
    if (revealEndsAt == null) return revealRemaining;
    final remaining = revealEndsAt!.difference(now);
    if (remaining.isNegative) return Duration.zero;
    return remaining > revealRemaining ? revealRemaining : remaining;
  }

  /// Freeze suspense while the app or a confirmation dialog covers the round.
  GameRound pauseReveal(DateTime now) => phase != GamePhase.reveal
      ? this
      : _copy(
          phase: phase,
          pauseReveal: true,
          revealRemaining: remainingRevealTime(now),
        );

  GameRound resumeReveal(DateTime now) =>
      phase != GamePhase.reveal || revealEndsAt != null
      ? this
      : _copy(phase: phase, revealEndsAt: now.add(revealRemaining));

  /// Retains the group and word deck; the imposter is drawn independently anew.
  GameRound newRound() {
    _requirePhase(GamePhase.result);
    return GameRound.fromDeck(players: players, deck: _deck, random: _random);
  }

  void _requirePhase(GamePhase expected) {
    if (phase != expected) {
      throw StateError('Action is not available in the current phase.');
    }
  }

  GameRound _copy({
    required GamePhase phase,
    int? handoffIndex,
    bool? hasViewedSecret,
    DateTime? discussionEndsAt,
    List<Player>? suspects,
    DateTime? revealEndsAt,
    Duration? revealRemaining,
    bool pauseReveal = false,
  }) => GameRound._(
    players: players,
    deck: _deck,
    random: _random,
    pair: _pair,
    imposterHints: _imposterHints,
    phase: phase,
    handoffIndex: handoffIndex ?? _handoffIndex,
    hasViewedSecret: hasViewedSecret ?? this.hasViewedSecret,
    discussionEndsAt: discussionEndsAt ?? this.discussionEndsAt,
    suspects: suspects ?? this.suspects,
    revealEndsAt: pauseReveal ? null : revealEndsAt ?? this.revealEndsAt,
    revealRemaining: revealRemaining ?? this.revealRemaining,
  );
}

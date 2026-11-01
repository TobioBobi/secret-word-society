import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/game_round.dart';
import 'package:secret_word_society/game/player.dart';
import 'package:secret_word_society/game/word_catalog.dart';

final _players = [
  Player(id: 'a', name: 'Ada'),
  Player(id: 'b', name: 'Ben'),
  Player(id: 'c', name: 'Cem'),
  Player(id: 'd', name: 'Dora'),
];
final _catalog = WordCatalog(
  languageCode: 'de',
  pairs: [
    WordPair(id: '1', word: 'Pizza', hint: 'Gesellige Runde'),
    WordPair(id: '2', word: 'Kino', hint: 'Dunkler Raum'),
  ],
);
final _now = DateTime.utc(2026, 10, 23, 12);

GameRound _start({int seed = 0, List<Player>? players}) => GameRound.start(
  players: players ?? _players,
  catalog: _catalog,
  random: Random(seed),
);

GameRound _ready(GameRound round) {
  while (round.phase == GamePhase.handoff) {
    round = round.revealSecret().hideAndAdvance();
  }
  expect(round.phase, GamePhase.ready);
  return round;
}

GameRound _voting(GameRound round) =>
    _ready(round)
        .startDiscussion(_now)
        .advanceTime(_now.add(round.discussionDuration));

String _imposterId(GameRound round) {
  String? id;
  while (round.phase == GamePhase.handoff) {
    round = round.revealSecret();
    if (round.currentSecret!.role == PlayerRole.imposter) {
      id = round.currentPlayer!.id;
    }
    round = round.hideAndAdvance();
  }
  return id!;
}

void main() {
  test('reveal hides the result until the deadline and freezes exact remaining time', () {
    final reveal = _voting(_start()).selectSuspect('a').confirmSuspect(_now);
    expect(reveal.phase, GamePhase.reveal);
    expect(reveal.result, isNull);
    expect(reveal.currentSecret, isNull);
    expect(reveal.currentPlayer, isNull);
    expect(reveal.remainingDiscussionTime(_now), Duration.zero);
    expect(
      reveal.remainingRevealTime(_now.subtract(const Duration(seconds: 1))),
      GameRound.revealDuration,
    );
    expect(
      reveal.advanceTime(_now.add(const Duration(milliseconds: 2999))),
      same(reveal),
    );
    expect(() => reveal.confirmSuspect(_now), throwsStateError);
    expect(() => reveal.selectSuspect('b'), throwsStateError);
    expect(reveal.newRound, throwsStateError);
    final paused = reveal.pauseReveal(
      _now.add(const Duration(milliseconds: 1250)),
    );
    final later = _now.add(const Duration(hours: 1));
    expect(paused.revealEndsAt, isNull);
    expect(
      paused.remainingRevealTime(later),
      const Duration(milliseconds: 1750),
    );
    expect(paused.advanceTime(later), same(paused));
    expect(
      paused.pauseReveal(later).remainingRevealTime(later),
      const Duration(milliseconds: 1750),
    );
    final resumed = paused.resumeReveal(later);
    expect(
      resumed.resumeReveal(later.add(const Duration(seconds: 1))),
      same(resumed),
    );
    expect(
      resumed.advanceTime(later.add(const Duration(milliseconds: 1749))).result,
      isNull,
    );
    final result = resumed.advanceTime(
      later.add(const Duration(milliseconds: 1750)),
    );
    expect(result.phase, GamePhase.result);
    expect(result.result!.suspects.single.id, 'a');
    expect(result.newRound().revealRemaining, GameRound.revealDuration);
    expect(result.newRound().revealEndsAt, isNull);
  });

  test('requires three players, unique IDs and case-insensitive names', () {
    for (var count = 0; count < 3; count++) {
      expect(
        () => _start(players: _players.take(count).toList()),
        throwsArgumentError,
      );
    }
    expect(_start(players: _players.take(3).toList()).players, hasLength(3));
    expect(
      () => _start(
        players: [
          ..._players,
          Player(id: 'a', name: 'Eva'),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => _start(
        players: [
          ..._players,
          Player(id: 'e', name: ' ADA '),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('trims player fields and rejects blank identity or name', () {
    final player = Player(id: ' a ', name: ' Ada ');
    expect(player.id, 'a');
    expect(player.name, 'Ada');
    expect(() => Player(id: ' ', name: 'Ada'), throwsArgumentError);
    expect(() => Player(id: 'a', name: '\n'), throwsArgumentError);
  });

  test(
    'takes an immutable roster snapshot and rejects groups above fourteen',
    () {
      final input = List.of(_players);
      final round = _start(players: input);
      input.clear();
      expect(round.players, hasLength(4));
      expect(() => round.players.clear(), throwsUnsupportedError);
      final largeGroup = List.generate(
        100,
        (i) => Player(id: '$i', name: 'Person $i'),
      );
      expect(() => _start(players: largeGroup), throwsArgumentError);
    },
  );

  test('every group gets one imposter and one consistent word/hint pair', () {
    final selectedImposters = <String>{};
    final selectedWords = <String>{};
    for (final groupSize in [3, 4, 5]) {
      for (var seed = 0; seed < 40; seed++) {
        final group = List.generate(
          groupSize,
          (i) => Player(id: '$i', name: 'Person $i'),
        );
        var round = _start(seed: seed, players: group);
        final groupWords = <String>[];
        final imposterHints = <String>[];
        for (var i = 0; i < groupSize; i++) {
          expect(round.currentPlayer, same(group[i]));
          expect(round.currentPlayerNumber, i + 1);
          expect(round.currentSecret, isNull);
          expect(round.result, isNull);
          round = round.revealSecret();
          final secret = round.currentSecret!;
          if (secret.role == PlayerRole.imposter) {
            imposterHints.add(secret.text);
            selectedImposters.add(round.currentPlayer!.id);
          } else {
            groupWords.add(secret.text);
          }
          round = round.hideAndAdvance();
          expect(round.currentSecret, isNull);
        }
        expect(imposterHints, hasLength(1));
        expect(groupWords, hasLength(groupSize - 1));
        expect(groupWords.toSet(), hasLength(1));
        final pair = _catalog.pairs.singleWhere(
          (p) => p.word == groupWords.first,
        );
        expect(imposterHints.single, pair.hint);
        selectedWords.add(pair.word);
        expect(round.phase, GamePhase.ready);
        expect(round.currentPlayer, isNull);
        expect(round.currentPlayerNumber, isNull);
        expect(round.discussionEndsAt, isNull);
      }
    }
    expect(selectedWords, containsAll(['Pizza', 'Kino']));
    expect(selectedImposters, containsAll(['0', '1', '2']));
  });

  test('seeded randomness makes role and word distribution reproducible', () {
    var first = _start(seed: 42);
    var second = _start(seed: 42);
    for (var i = 0; i < _players.length; i++) {
      first = first.revealSecret();
      second = second.revealSecret();
      expect(first.currentSecret!.role, second.currentSecret!.role);
      expect(first.currentSecret!.text, second.currentSecret!.text);
      first = first.hideAndAdvance();
      second = second.hideAndAdvance();
    }
  });

  test('interruption conceals the card without losing the current person', () {
    final initial = _start();
    expect(initial.concealSecret(), same(initial));
    final revealed = initial.revealSecret();
    final hidden = revealed.concealSecret();
    expect(hidden.phase, GamePhase.handoff);
    expect(hidden.currentPlayer, same(revealed.currentPlayer));
    expect(hidden.currentSecret, isNull);
    expect(
      hidden.revealSecret().currentSecret!.text,
      revealed.currentSecret!.text,
    );
    final next = hidden.revealSecret().hideAndAdvance();
    expect(next.currentPlayer, same(_players[1]));
    expect(next.currentSecret, isNull);
  });

  test(
    'deadline starts only on ready and accounts for a long interruption',
    () {
      final ready = _ready(_start());
      expect(ready.remainingDiscussionTime(_now), const Duration(seconds: 120));
      expect(ready.discussionEndsAt, isNull);
      final running = ready.startDiscussion(_now);
      expect(running.discussionEndsAt, _now.add(const Duration(seconds: 120)));
      expect(
        running.remainingDiscussionTime(_now.add(const Duration(seconds: 3))),
        const Duration(seconds: 117),
      );
      expect(
        running.advanceTime(_now.add(const Duration(seconds: 119))),
        same(running),
      );
      expect(
        running.advanceTime(_now.add(const Duration(seconds: 120))).phase,
        GamePhase.voting,
      );
      final resumed = running.advanceTime(_now.add(const Duration(hours: 1)));
      expect(resumed.phase, GamePhase.voting);
      expect(resumed.remainingDiscussionTime(_now), Duration.zero);
      expect(resumed.currentSecret, isNull);
      expect(resumed.result, isNull);
      expect(
        running.remainingDiscussionTime(
          _now.subtract(const Duration(seconds: 1)),
        ),
        ready.discussionDuration,
      );
      expect(
        running.remainingDiscussionTime(_now.add(const Duration(hours: 1))),
        Duration.zero,
      );
    },
  );

  test('only a round member can be selected; selection can change before confirmation', () {
    final voting = _voting(_start());
    expect(voting.suspects, isEmpty);
    expect(() => voting.confirmSuspect(_now), throwsStateError);
    expect(() => voting.selectSuspect('outsider'), throwsArgumentError);
    final selected = voting.selectSuspect('a').selectSuspect('b');
    expect(selected.suspects.single, same(_players[1]));
    expect(selected.result, isNull);
    expect(
      selected
          .confirmSuspect(_now)
          .advanceTime(_now.add(GameRound.revealDuration))
          .result!
          .suspects
          .single,
      same(_players[1]),
    );
  });

  test('correct suspicion wins for the group; every wrong suspicion wins for the imposter', () {
    final initial = _start(seed: 7);
    final imposterId = _imposterId(initial);
    final voting = _voting(initial);
    for (final suspect in _players) {
      final finished = voting
          .selectSuspect(suspect.id)
          .confirmSuspect(_now)
          .advanceTime(_now.add(GameRound.revealDuration));
      expect(finished.phase, GamePhase.result);
      expect(finished.result!.imposters.single.id, imposterId);
      expect(
        finished.result!.winner,
        suspect.id == imposterId ? Winner.group : Winner.imposter,
      );
      expect(
        _catalog.pairs.map((pair) => pair.word),
        contains(finished.result!.word),
      );
      expect(finished.currentSecret, isNull);
      expect(finished.currentPlayer, isNull);
    }
  });

  test(
    'new rounds retain the group and word history, resetting round state',
    () {
      // Draw sequence: first remaining pair / imposter 0, then sole pair / 3.
      final random = _SequenceRandom([0, 0, 0, 3]);
      final first = GameRound.start(
        players: _players,
        catalog: _catalog,
        random: random,
      );
      final finished = _voting(first)
          .selectSuspect('a')
          .confirmSuspect(_now)
          .advanceTime(_now.add(GameRound.revealDuration));
      expect(finished.result!.word, 'Pizza');
      expect(finished.result!.imposters.single.id, 'a');
      final next = finished.newRound();
      expect(next.players, orderedEquals(_players));
      expect(next.languageCode, 'de');
      expect(next.phase, GamePhase.handoff);
      expect(next.currentPlayerNumber, 1);
      expect(next.currentPlayer, same(_players.first));
      expect(next.currentSecret, isNull);
      expect(next.suspects, isEmpty);
      expect(next.result, isNull);
      expect(next.discussionEndsAt, isNull);
      expect(next.remainingDiscussionTime(_now), next.discussionDuration);
      expect(_imposterId(next), 'd');
      expect(next.revealSecret().currentSecret!.text, 'Kino');
    },
  );

  test('imposter repeats remain possible while word repeats are avoided', () {
    final first = GameRound.start(
      players: _players,
      catalog: _catalog,
      random: _SequenceRandom([0, 0, 0, 0]),
    );
    final finished = _voting(first)
        .selectSuspect('a')
        .confirmSuspect(_now)
        .advanceTime(_now.add(GameRound.revealDuration));
    final next = finished.newRound();
    final nextResult = _voting(next)
        .selectSuspect('a')
        .confirmSuspect(_now)
        .advanceTime(_now.add(GameRound.revealDuration))
        .result!;
    expect(
      nextResult.imposters.single.id,
      finished.result!.imposters.single.id,
    );
    expect(nextResult.word, isNot(finished.result!.word));
  });

  test('every card may be skipped without viewing and stays concealed', () {
    var round = _start();
    for (var i = 1; i <= round.players.length; i++) {
      expect(round.currentPlayerNumber, i);
      expect(round.currentSecret, isNull);
      expect(round.hasViewedSecret, isFalse);
      expect(round.canAdvanceCard, isTrue);
      round = round.hideAndAdvance();
      expect(round.currentSecret, isNull);
    }
    expect(round.phase, GamePhase.ready);
    expect(round.canAdvanceCard, isFalse);
    expect(round.hideAndAdvance, throwsStateError);
  });

  test('partial, complete and concealed views may all advance', () {
    var round = _start();
    expect(round.markSecretViewed, throwsStateError);
    round = round.revealSecret(markAsViewed: false);
    expect(round.hasViewedSecret, isFalse);
    expect(round.canAdvanceCard, isTrue);
    round = round.hideAndAdvance();
    expect(round.currentSecret, isNull);
    expect(round.canAdvanceCard, isTrue);
    round = round.revealSecret().concealSecret();
    expect(round.hasViewedSecret, isTrue);
    expect(round.canAdvanceCard, isTrue);
    round = round.hideAndAdvance();
    expect(round.hasViewedSecret, isFalse);
    expect(round.canAdvanceCard, isTrue);
  });

  test('out-of-order actions are rejected in every phase', () {
    final handoff = _start();
    final secret = handoff.revealSecret();
    final ready = _ready(handoff);
    final discussion = ready.startDiscussion(_now);
    final voting = discussion.advanceTime(_now.add(const Duration(minutes: 2)));
    final reveal = voting.selectSuspect('a').confirmSuspect(_now);
    final result = reveal.advanceTime(_now.add(GameRound.revealDuration));
    for (final round in [
      handoff,
      secret,
      ready,
      discussion,
      voting,
      reveal,
      result,
    ]) {
      if (round.phase != GamePhase.discussion &&
          round.phase != GamePhase.reveal) {
        expect(() => round.advanceTime(_now), throwsStateError);
      }
      if (!round.canAdvanceCard) {
        expect(round.hideAndAdvance, throwsStateError);
      }
      final actions = <GamePhase, List<void Function()>>{
        GamePhase.handoff: [round.revealSecret],
        GamePhase.ready: [() => round.startDiscussion(_now)],

        GamePhase.voting: [
          () => round.selectSuspect('a'),
          () => round.confirmSuspect(_now),
        ],
        GamePhase.result: [round.newRound],
      };
      for (final entry in actions.entries) {
        if (entry.key != round.phase) {
          for (final action in entry.value) {
            expect(
              action,
              throwsStateError,
              reason: '${round.phase} -> ${entry.key}',
            );
          }
        }
      }
    }
  });
}

final class _SequenceRandom implements Random {
  _SequenceRandom(this.values);
  final List<int> values;
  var index = 0;

  @override
  int nextInt(int max) {
    final value = values[index++];
    if (value < 0 || value >= max) throw StateError('Invalid test draw.');
    return value;
  }

  @override
  bool nextBool() => throw UnsupportedError('Not used.');

  @override
  double nextDouble() => throw UnsupportedError('Not used.');
}

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
        .advanceTime(_now.add(GameRound.discussionDuration));

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
    'takes an immutable roster snapshot and has no arbitrary player cap',
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
      expect(_start(players: largeGroup).players, hasLength(100));
    },
  );

  test('every group gets one imposter and one consistent word/hint pair', () {
    final selectedImposters = <String>{};
    final selectedWords = <String>{};
    for (final groupSize in [3, 4, 20]) {
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
      expect(ready.remainingDiscussionTime(_now), const Duration(minutes: 2));
      expect(ready.discussionEndsAt, isNull);
      final running = ready.startDiscussion(_now);
      expect(running.discussionEndsAt, _now.add(const Duration(minutes: 2)));
      expect(
        running.remainingDiscussionTime(_now.add(const Duration(seconds: 37))),
        const Duration(seconds: 83),
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
        GameRound.discussionDuration,
      );
      expect(
        running.remainingDiscussionTime(_now.add(const Duration(hours: 1))),
        Duration.zero,
      );
    },
  );

  test('only a round member can be selected; selection can change before confirmation', () {
    final voting = _voting(_start());
    expect(voting.suspect, isNull);
    expect(voting.confirmSuspect, throwsStateError);
    expect(() => voting.selectSuspect('outsider'), throwsArgumentError);
    final selected = voting.selectSuspect('a').selectSuspect('b');
    expect(selected.suspect, same(_players[1]));
    expect(selected.result, isNull);
    expect(selected.confirmSuspect().result!.suspect, same(_players[1]));
  });

  test('correct suspicion wins for the group; every wrong suspicion wins for the imposter', () {
    final initial = _start(seed: 7);
    final imposterId = _imposterId(initial);
    final voting = _voting(initial);
    for (final suspect in _players) {
      final finished = voting.selectSuspect(suspect.id).confirmSuspect();
      expect(finished.phase, GamePhase.result);
      expect(finished.result!.imposter.id, imposterId);
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
    'new rounds retain only the group and catalog, resetting all round state',
    () {
      // Draw sequence: pair 0 / imposter 0, then pair 1 / imposter 3.
      final random = _SequenceRandom([0, 0, 1, 3]);
      final first = GameRound.start(
        players: _players,
        catalog: _catalog,
        random: random,
      );
      final finished = _voting(first).selectSuspect('a').confirmSuspect();
      expect(finished.result!.word, 'Pizza');
      expect(finished.result!.imposter.id, 'a');
      final next = finished.newRound();
      expect(next.players, orderedEquals(_players));
      expect(next.languageCode, 'de');
      expect(next.phase, GamePhase.handoff);
      expect(next.currentPlayerNumber, 1);
      expect(next.currentPlayer, same(_players.first));
      expect(next.currentSecret, isNull);
      expect(next.suspect, isNull);
      expect(next.result, isNull);
      expect(next.discussionEndsAt, isNull);
      expect(next.remainingDiscussionTime(_now), GameRound.discussionDuration);
      expect(_imposterId(next), 'd');
      expect(next.revealSecret().currentSecret!.text, 'Kino');
    },
  );

  test('random repeats across rounds are permitted', () {
    final first = GameRound.start(
      players: _players,
      catalog: _catalog,
      random: _SequenceRandom([0, 0, 0, 0]),
    );
    final finished = _voting(first).selectSuspect('a').confirmSuspect();
    final next = finished.newRound();
    final nextResult = _voting(next)
        .selectSuspect('a')
        .confirmSuspect()
        .result!;
    expect(nextResult.imposter.id, finished.result!.imposter.id);
    expect(nextResult.word, finished.result!.word);
  });

  test('out-of-order actions are rejected in every phase', () {
    final handoff = _start();
    final secret = handoff.revealSecret();
    final ready = _ready(handoff);
    final discussion = ready.startDiscussion(_now);
    final voting = discussion.advanceTime(_now.add(const Duration(minutes: 2)));
    final result = voting.selectSuspect('a').confirmSuspect();
    for (final round in [handoff, secret, ready, discussion, voting, result]) {
      final actions = <GamePhase, List<void Function()>>{
        GamePhase.handoff: [round.revealSecret],
        GamePhase.secret: [round.hideAndAdvance],
        GamePhase.ready: [() => round.startDiscussion(_now)],
        GamePhase.discussion: [() => round.advanceTime(_now)],
        GamePhase.voting: [
          () => round.selectSuspect('a'),
          round.confirmSuspect,
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

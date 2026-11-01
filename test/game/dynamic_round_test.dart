import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/game_round.dart';
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/game/player.dart';
import 'package:secret_word_society/game/round_rules.dart';
import 'package:secret_word_society/game/word_catalog.dart';

final _catalog = WordCatalog(
  languageCode: 'de',
  pairs: [
    WordPair(
      id: '1',
      word: 'Pizza',
      hint: 'Gesellige Runde',
      additionalHints: ['Teigduft', 'Geteiltes Abendessen'],
    ),
    WordPair(
      id: '2',
      word: 'Kino',
      hint: 'Dunkler Raum',
      additionalHints: ['Große Leinwand', 'Rascheltüten'],
    ),
  ],
);
final _now = DateTime.utc(2026, 11, 1);
List<Player> _players(int count) =>
    List.generate(count, (i) => Player(id: '$i', name: 'Person $i'));

(GameRound, Set<String>, Set<String>) _distribute(GameRound round) {
  final ids = <String>{};
  final hints = <String>{};
  final words = <String>{};
  while (round.currentPlayer != null) {
    expect(round.currentSecret, isNull);
    expect(round.result, isNull);
    round = round.revealSecret();
    final secret = round.currentSecret!;
    if (secret.role == PlayerRole.imposter) {
      ids.add(round.currentPlayer!.id);
      expect(hints.add(secret.text), isTrue);
    } else {
      words.add(secret.text);
    }
    // Reopening always shows the same hint and never the other assignments.
    expect(
      round.concealSecret().revealSecret().currentSecret!.text,
      secret.text,
    );
    round = round.hideAndAdvance();
  }
  expect(words, hasLength(1));
  final pair = _catalog.pairs.singleWhere((p) => p.word == words.single);
  expect(pair.hints, containsAll(hints));
  return (round, ids, words);
}

void main() {
  test('selection cap follows the public maximum, never the secret count', () {
    for (var size = 6; size <= 14; size++) {
      for (var seed = 0; seed < 20; seed++) {
        final (ready, _, _) = _distribute(
          GameRound.start(
            players: _players(size),
            catalog: _catalog,
            random: Random(seed),
          ),
        );
        var voting = ready
            .startDiscussion(_now)
            .advanceTime(_now.add(ready.discussionDuration));
        final maximum = size <= 10 ? 2 : 3;
        expect(voting.maximumSuspects, maximum);
        for (final player in voting.players.take(maximum)) {
          expect(voting.canSelectSuspect(player.id), isTrue);
          voting = voting.selectSuspect(player.id);
        }
        final extra = voting.players[maximum];
        expect(voting.canSelectSuspect(extra.id), isFalse);
        expect(voting.selectSuspect(extra.id), same(voting));
        expect(voting.suspects, hasLength(maximum));
        final first = voting.players.first;
        expect(voting.canSelectSuspect(first.id), isTrue);
        voting = voting.selectSuspect(first.id);
        expect(voting.suspects, hasLength(maximum - 1));
        expect(voting.canSelectSuspect(extra.id), isTrue);
        voting = voting.selectSuspect(extra.id);
        expect(voting.suspects, hasLength(maximum));
        expect(voting.suspects, contains(extra));
        expect(voting.suspects, isNot(contains(first)));
      }
    }
  });

  test('all group sizes, deadlines and random assignment boundaries', () {
    for (var size = 3; size <= 14; size++) {
      final observedCounts = <int>{};
      final observedPlayers = <String>{};
      for (var seed = 0; seed < 80; seed++) {
        final initial = GameRound.start(
          players: _players(size),
          catalog: _catalog,
          random: Random(seed),
        );
        final (ready, ids, _) = _distribute(initial);
        expect(ready.discussionDuration, Duration(seconds: size * 30));
        final minimum = size >= 11 ? 2 : 1;
        final maximum = size >= 11 ? 3 : (size >= 6 ? 2 : 1);
        expect(ids.length, inInclusiveRange(minimum, maximum));
        observedCounts.add(ids.length);
        observedPlayers.addAll(ids);
        final running = ready.startDiscussion(_now);
        final deadline = _now.add(Duration(seconds: size * 30));
        expect(running.discussionEndsAt, deadline);
        expect(
          running.advanceTime(
            deadline.subtract(const Duration(microseconds: 1)),
          ),
          same(running),
        );
        expect(
          running.remainingDiscussionTime(
            _now.subtract(const Duration(days: 1)),
          ),
          running.discussionDuration,
        );
        final voting = running.advanceTime(deadline);
        expect(voting.phase, GamePhase.voting);
        expect(voting.remainingDiscussionTime(deadline), Duration.zero);
        expect(
          running.advanceTime(deadline.add(const Duration(hours: 1))).phase,
          GamePhase.voting,
        );
        expect(voting.result, isNull);
      }
      expect(observedCounts, size < 6 ? {1} : (size < 11 ? {1, 2} : {2, 3}));
      expect(observedPlayers, _players(size).map((p) => p.id).toSet());
    }
    for (final invalid in [0, 2, 15, 100]) {
      expect(
        () => GameRound.start(players: _players(invalid), catalog: _catalog),
        throwsArgumentError,
      );
      expect(() => RoundRules.discussionDuration(invalid), throwsArgumentError);
    }
  });

  test(
    'only the exact set wins; toggling, immutable results and next round',
    () {
      for (var seed = 0; seed < 30; seed++) {
        final (ready, ids, words) = _distribute(
          GameRound.start(
            players: _players(14),
            catalog: _catalog,
            random: Random(seed),
          ),
        );
        final voting = ready
            .startDiscussion(_now)
            .advanceTime(_now.add(ready.discussionDuration));
        expect(() => voting.confirmSuspect(_now), throwsStateError);
        expect(() => voting.selectSuspect('outsider'), throwsArgumentError);
        final innocent = voting.players
            .firstWhere((p) => !ids.contains(p.id))
            .id;
        for (final selection in [
          ids,
          ids.skip(1).toSet(),
          {...ids.skip(1), innocent},
          if (ids.length < voting.maximumSuspects) {...ids, innocent},
          {innocent},
        ]) {
          var selected = voting;
          for (final id in selection) {
            selected = selected.selectSuspect(id);
          }
          expect(
            selected.selectSuspect(selection.first).suspects.length,
            selection.length - 1,
          );
          final reveal = selected.confirmSuspect(_now);
          expect(reveal.result, isNull);
          expect(reveal.currentSecret, isNull);
          final finished = reveal.advanceTime(
            _now.add(GameRound.revealDuration),
          );
          expect(
            finished.result!.winner,
            selection.length == ids.length && selection.containsAll(ids)
                ? Winner.group
                : Winner.imposter,
          );
          expect(finished.result!.imposters.map((p) => p.id).toSet(), ids);
          expect(finished.result!.suspects.map((p) => p.id).toSet(), selection);
          expect(
            () => finished.result!.imposters.clear(),
            throwsUnsupportedError,
          );
          expect(
            () => finished.result!.suspects.clear(),
            throwsUnsupportedError,
          );
          expect(() => selected.suspects.clear(), throwsUnsupportedError);
          if (identical(selection, ids)) {
            final next = finished.newRound();
            expect(next.suspects, isEmpty);
            expect(next.discussionEndsAt, isNull);
            final (_, _, nextWords) = _distribute(next);
            expect(nextWords.single, isNot(words.single));
          }
        }
      }
    },
  );

  test(
    'group limit and edited group recalculate rules without losing identities',
    () {
      final session = GameSession();
      for (var i = 0; i < 14; i++) {
        expect(session.addPlayer('Person $i'), isNull);
      }
      expect(session.addPlayer('Too many'), NameProblem.groupFull);
      expect(session.players.length, 14);
      final first = session.players.first;
      session.startRound(_catalog, random: Random(1));
      expect(session.round!.discussionDuration, const Duration(minutes: 7));
      session.returnToGroup();
      for (final player in session.players.skip(4)) {
        session.removePlayer(player.id);
      }
      session.startRound(_catalog, random: Random(1));
      expect(session.round!.discussionDuration, const Duration(minutes: 2));
      expect(session.round!.allowsMultipleSuspects, isFalse);
      expect(session.round!.players.first, same(first));
    },
  );

  test('bad or duplicate hints fail explicitly instead of repeating hints', () {
    expect(
      () => WordPair(
        id: '1',
        word: 'Word',
        hint: 'Hint',
        additionalHints: [' hint '],
      ),
      throwsArgumentError,
    );
    expect(
      () =>
          WordPair(id: '1', word: 'Word', hint: 'Hint', additionalHints: [' ']),
      throwsArgumentError,
    );
    final insufficient = WordCatalog(
      languageCode: 'de',
      pairs: [WordPair(id: '1', word: 'Word', hint: 'Hint')],
    );
    expect(
      () => GameRound.start(players: _players(6), catalog: insufficient),
      throwsArgumentError,
    );
    expect(
      () => WordCatalog.fromJson(
        '{"languageCode":"de","pairs":[{"id":"1","word":"Word","hint":"Hint","additionalHints":[1]}]}',
      ),
      throwsFormatException,
    );
  });
}

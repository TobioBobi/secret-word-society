import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/game_round.dart';
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/game/word_catalog.dart';

void main() {
  final catalog = WordCatalog(
    languageCode: 'de',
    pairs: [WordPair(id: 'test', word: 'Popcorn', hint: 'Kino')],
  );

  GameSession group() => GameSession()
    ..addPlayer('Anna')
    ..addPlayer('Ben')
    ..addPlayer('Cem');

  test('trims names and rejects blank and case-insensitive duplicates', () {
    final session = GameSession();
    expect(session.addPlayer(' \n\t '), NameProblem.empty);
    expect(session.addPlayer('  Änne  '), isNull);
    expect(session.addPlayer(' änNE '), NameProblem.duplicate);
    expect(session.players.single.name, 'Änne');
    expect(() => session.players.clear(), throwsUnsupportedError);
    expect(session.round, isNull);
    expect(session.canStart, isFalse);
  });

  test('removal retains order and identities; re-adding uses a fresh ID', () {
    final session = group();
    final original = session.players;
    session.removePlayer(original[1].id);
    expect(session.players.map((p) => p.name), ['Anna', 'Cem']);
    expect(session.canStart, isFalse);
    expect(session.addPlayer('Ben'), isNull);
    expect(session.players.map((p) => p.name), ['Anna', 'Cem', 'Ben']);
    expect(session.players.last.id, isNot(original[1].id));
    expect(session.players.first, same(original.first));
    expect(original, hasLength(3));
    expect(session.players.map((p) => p.id).toSet(), hasLength(3));
    expect(session.canStart, isTrue);
  });

  test(
    'start requires three people and creates a concealed, untimed round',
    () {
      final session = GameSession()
        ..addPlayer('Anna')
        ..addPlayer('Ben');
      expect(() => session.startRound(catalog), throwsArgumentError);
      expect(session.round, isNull);
      session.addPlayer('Cem');
      session.startRound(catalog, random: Random(3));
      final round = session.round!;
      expect(round.players.map((p) => p.name), ['Anna', 'Ben', 'Cem']);
      expect(round.phase, GamePhase.handoff);
      expect(round.currentPlayer!.name, 'Anna');
      expect(round.currentPlayerNumber, 1);
      expect(round.currentSecret, isNull);
      expect(round.result, isNull);
      expect(round.discussionEndsAt, isNull);
      expect(session.canStart, isFalse);
      expect(() => session.startRound(catalog), throwsStateError);
      expect(() => session.addPlayer('Dora'), throwsStateError);
      expect(
        () => session.removePlayer(round.players.first.id),
        throwsStateError,
      );
    },
  );

  test('returning discards round, retains group and allows a fresh round', () {
    final session = group()..startRound(catalog);
    final previous = session.round!;
    session.returnToGroup();
    expect(session.round, isNull);
    expect(session.players, orderedEquals(previous.players));
    session.removePlayer(session.players.first.id);
    session.addPlayer('Dora');
    session.startRound(catalog);
    expect(session.round, isNot(same(previous)));
    expect(session.round!.currentPlayer!.name, 'Ben');
    expect(previous.players.map((p) => p.name), ['Anna', 'Ben', 'Cem']);
    expect(GameSession().players, isEmpty);
  });

  test('does not impose an arbitrary player limit', () {
    final session = GameSession();
    for (var index = 0; index < 60; index++) {
      expect(session.addPlayer('Person $index'), isNull);
    }
    session.startRound(catalog);
    expect(session.round!.players, hasLength(60));
  });

  test('session actions preserve secrets on concealment and finish without a timer', () {
    final session = group();
    expect(session.revealSecret, throwsStateError);
    expect(session.hideAndAdvance, throwsStateError);
    session.concealSecret();
    session.startRound(catalog);
    var words = 0;
    var hints = 0;
    for (var i = 1; i <= 3; i++) {
      expect(session.hideAndAdvance, throwsStateError);
      session.revealSecret();
      final secret = session.round!.currentSecret!;
      session.concealSecret();
      expect(session.round!.currentPlayerNumber, i);
      expect(session.round!.currentSecret, isNull);
      session.revealSecret();
      expect(session.round!.currentSecret!.role, secret.role);
      expect(session.round!.currentSecret!.text, secret.text);
      if (secret.role == PlayerRole.imposter) {
        hints++;
        expect(secret.text, 'Kino');
      } else {
        words++;
        expect(secret.text, 'Popcorn');
      }
      session.hideAndAdvance();
      expect(session.round!.currentSecret, isNull);
      expect(session.round!.discussionEndsAt, isNull);
    }
    expect(words, 2);
    expect(hints, 1);
    expect(session.round!.phase, GamePhase.ready);
    session.concealSecret();
    expect(session.round!.phase, GamePhase.ready);
    expect(session.revealSecret, throwsStateError);
    session.returnToGroup();
    expect(session.players, hasLength(3));
    expect(session.round, isNull);
  });
}

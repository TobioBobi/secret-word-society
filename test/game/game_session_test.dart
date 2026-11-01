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

  String finish(GameSession session) {
    final words = <String>{};
    while (session.round!.phase == GamePhase.handoff) {
      session.revealSecret();
      if (session.round!.currentSecret!.role == PlayerRole.group) {
        words.add(session.round!.currentSecret!.text);
      }
      session.hideAndAdvance();
    }
    final now = DateTime.utc(2026, 10, 25);
    session.startDiscussion(now);
    session.advanceTime(now.add(session.round!.discussionDuration));
    session.selectSuspect(session.players.first.id);
    session.confirmSuspect(now);
    session.advanceTime(now.add(GameRound.revealDuration));
    expect(session.round!.result!.word, words.single);
    return words.single;
  }

  const source =
      '{"languageCode":"de","pairs":['
      '{"id":"1","word":"Pizza","hint":"Gesellige Runde"},'
      '{"id":"2","word":"Kino","hint":"Dunkler Raum"},'
      '{"id":"3","word":"Zelt","hint":"Nachts draußen"}]}';

  test('word history survives follow-ups, group edits and reloaded assets', () {
    final session = group();
    session.startRound(WordCatalog.fromJson(source), random: Random(42));
    String? previous;
    for (var cycle = 0; cycle < 3; cycle++) {
      final seen = <String>{};
      for (var draw = 0; draw < 3; draw++) {
        final word = finish(session);
        expect(word, isNot(previous));
        expect(seen.add(word), isTrue);
        previous = word;
        if (draw.isEven) {
          session.newRound();
        } else {
          session.returnToGroup();
          final player = session.players.last;
          session.removePlayer(player.id);
          session.addPlayer(player.name);
          session.startRound(
            WordCatalog.fromJson(source),
            random: Random(cycle),
          );
        }
        expect(session.round!.currentSecret, isNull);
        expect(session.round!.phase, GamePhase.handoff);
      }
      expect(seen, {'Pizza', 'Kino', 'Zelt'});
    }
  });

  test('abandoned rounds consume a word; invalid starts consume none', () {
    final session = GameSession()
      ..addPlayer('Anna')
      ..addPlayer('Ben');
    expect(
      () =>
          session.startRound(WordCatalog.fromJson(source), random: Random(42)),
      throwsArgumentError,
    );
    session.addPlayer('Cem');
    session.startRound(WordCatalog.fromJson(source), random: Random(42));
    final first = session.round!;
    expect(
      () => session.startRound(WordCatalog.fromJson(source)),
      throwsStateError,
    );
    session.returnToGroup(); // Not a single card needs to have been revealed.
    session.startRound(WordCatalog.fromJson(source), random: Random(42));
    final second = finish(session);
    // Read the abandoned snapshot only for this assertion, never in the UI.
    var abandoned = first;
    final groupWords = <String>{};
    while (abandoned.phase == GamePhase.handoff) {
      abandoned = abandoned.revealSecret();
      if (abandoned.currentSecret!.role == PlayerRole.group) {
        groupWords.add(abandoned.currentSecret!.text);
      }
      abandoned = abandoned.hideAndAdvance();
    }
    expect(second, isNot(groupWords.single));
    final fresh = group();
    fresh.startRound(WordCatalog.fromJson(source), random: Random(42));
    expect(finish(fresh), groupWords.single);
  });

  test('a changed catalog starts its own word supply', () {
    final session = group();
    session.startRound(WordCatalog.fromJson(source), random: Random(1));
    finish(session);
    session.returnToGroup();
    session.startRound(catalog);
    expect(finish(session), 'Popcorn');
  });

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

  test('enforces fourteen players and allows starting after removing one', () {
    final session = GameSession();
    for (var index = 0; index < 14; index++) {
      expect(session.addPlayer('Person $index'), isNull);
    }
    expect(session.addPlayer('Overflow'), NameProblem.groupFull);
    session.removePlayer(session.players.last.id);
    expect(session.addPlayer('Replacement'), isNull);
    expect(session.players, hasLength(14));
    expect(session.canStart, isTrue);
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
      expect(session.round!.canAdvanceCard, isTrue);
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

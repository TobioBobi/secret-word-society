import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/game_round.dart';
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/game/player.dart';
import 'package:secret_word_society/game/round_rules.dart';
import 'package:secret_word_society/game/word_catalog.dart';

final catalog = WordCatalog(
  languageCode: 'de',
  pairs: [
    WordPair(
      id: '1',
      word: 'Pizza',
      hint: 'Teig',
      additionalHints: ['Ofen', 'Käse'],
    ),
  ],
);
final now = DateTime.utc(2026);

class BinaryRandom implements Random {
  BinaryRandom(this.value);
  final int value;
  @override
  int nextInt(int max) {
    expect(max, 2); // Exactly two equally likely outcomes, no weighted mapping.
    return value;
  }

  @override
  bool nextBool() => throw UnimplementedError();
  @override
  double nextDouble() => throw UnimplementedError();
}

void main() {
  test(
    'ranges use both uniform binary outcomes; fixed choices do not draw',
    () {
      for (var n = 1; n < 14; n++) {
        expect(ImposterChoice(n, n + 1).draw(BinaryRandom(0)), n);
        expect(ImposterChoice(n, n + 1).draw(BinaryRandom(1)), n + 1);
        expect(ImposterChoice(n, n).draw(BinaryRandom(100)), n);
      }
      expect(() => ImposterChoice.fromStep(-1), throwsArgumentError);
    },
  );
  test('every fixed count and range, balanced hints, voting and follow-up', () {
    for (var size = 3; size <= 14; size++) {
      for (final invalid in [
        ImposterChoice(size, size),
        ImposterChoice(size - 1, size),
      ]) {
        expect(
          () => GameRound.start(
            players: List.generate(size, (i) => Player(id: '$i', name: 'P$i')),
            catalog: catalog,
            imposterChoice: invalid,
          ),
          throwsArgumentError,
        );
      }
      for (var step = 0; step <= (size - 2) * 2; step++) {
        final choice = ImposterChoice.fromStep(step);
        final observed = <int>{};
        for (var seed = 0; seed < 20; seed++) {
          var round = GameRound.start(
            players: List.generate(size, (i) => Player(id: '$i', name: 'P$i')),
            catalog: catalog,
            random: Random(seed),
            imposterChoice: choice,
          );
          final ids = <String>[];
          final hints = <String, int>{};
          while (round.currentPlayer != null) {
            expect(round.currentSecret, isNull);
            round = round.revealSecret();
            if (round.currentSecret!.role == PlayerRole.imposter) {
              ids.add(round.currentPlayer!.id);
              hints.update(
                round.currentSecret!.text,
                (n) => n + 1,
                ifAbsent: () => 1,
              );
            }
            round = round.hideAndAdvance();
          }
          observed.add(ids.length);
          expect(ids.toSet().length, ids.length);
          expect(ids.length, inInclusiveRange(choice.minimum, choice.maximum));
          expect(hints.length, min(ids.length, 3));
          expect(
            hints.values.reduce(max) - hints.values.reduce(min),
            lessThanOrEqualTo(1),
          );
          round = round
              .startDiscussion(now)
              .advanceTime(now.add(round.discussionDuration));
          expect(round.maximumSuspects, choice.maximum);
          for (final id in ids) {
            round = round.selectSuspect(id);
          }
          if (choice.maximum > 1 &&
              ids.length == choice.maximum &&
              ids.length < size) {
            final extra = round.players.firstWhere((p) => !ids.contains(p.id));
            expect(round.selectSuspect(extra.id), same(round));
            round = round.selectSuspect(ids.first);
            expect(round.canSelectSuspect(extra.id), isTrue);
            round = round.selectSuspect(ids.first);
          }
          round = round
              .confirmSuspect(now)
              .advanceTime(now.add(GameRound.revealDuration));
          expect(round.result!.winner, Winner.group);
          expect(round.newRound().imposterChoice.label, choice.label);
        }
        expect(observed, {choice.minimum, choice.maximum});
      }
    }
  });

  test('session default, retention, reduction and fresh session', () {
    final session = GameSession();
    for (var i = 0; i < 14; i++) {
      session.addPlayer('P$i');
    }
    expect(session.imposterChoice.label, '2–3');
    session.removePlayer(session.players.last.id);
    session.setImposterChoice(ImposterChoice(11, 12));
    session.startRound(catalog);
    expect(
      () => session.setImposterChoice(ImposterChoice(1, 1)),
      throwsStateError,
    );
    session.returnToGroup();
    session.removePlayer(session.players.last.id);
    expect(session.imposterChoice.label, '11');
    session.removePlayer(session.players.last.id);
    expect(session.imposterChoice.label, '10');
    session.addPlayer('New');
    expect(session.imposterChoice.label, '10');
    final fresh = GameSession();
    for (var i = 0; i < 6; i++) {
      fresh.addPlayer('P$i');
    }
    expect(fresh.imposterChoice.label, '1–2');
    expect(
      () => fresh.setImposterChoice(ImposterChoice(6, 6)),
      throwsArgumentError,
    );
    expect(() => ImposterChoice(1, 3), throwsArgumentError);
    expect(() => ImposterChoice(0, 1), throwsArgumentError);
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/game_round.dart';
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/game/word_catalog.dart';
import 'package:secret_word_society/game/word_deck.dart';

final catalog = WordCatalog(
  languageCode: 'de',
  pairs: [WordPair(id: '1', word: 'Popcorn', hint: 'Kino')],
);

GameSession group() => GameSession()
  ..addPlayer('Anna')
  ..addPlayer('Ben')
  ..addPlayer('Cem');

List<String> distribute(GameSession session) {
  final ids = <String>[];
  while (session.round!.canAdvanceCard) {
    ids.add(session.round!.currentPlayer!.id);
    session.hideAndAdvance();
  }
  return ids;
}

void main() {
  test('every allowed order is equally likely and independent of roles', () {
    final players = group().players;
    for (final previous in [null, players.first.id, 'removed']) {
      final outcomes = <String, int>{};
      // Exhaust every equally probable draw for a three-person, one-word round.
      for (var role = 0; role < 3; role++) {
        for (
          var start = 0;
          start < (previous == players.first.id ? 2 : 3);
          start++
        ) {
          for (var tail = 0; tail < 2; tail++) {
            var round = GameRound.fromDeck(
              players: players,
              deck: WordDeck(catalog),
              previousStartPlayerId: previous,
              random: Draws([0, role, start, tail]),
            );
            final order = <String>[];
            String? imposter;
            while (round.canAdvanceCard) {
              final player = round.currentPlayer!;
              order.add(player.id);
              round = round.revealSecret();
              if (round.currentSecret!.role == PlayerRole.imposter) {
                imposter = player.id;
              }
              round = round.hideAndAdvance();
            }
            expect(imposter, players[role].id);
            if (previous == players.first.id) {
              expect(order.first, isNot(previous));
            }
            final key = '${order.join(',')}:$imposter';
            outcomes.update(key, (count) => count + 1, ifAbsent: () => 1);
          }
        }
      }
      expect(outcomes, hasLength(previous == players.first.id ? 12 : 18));
      expect(outcomes.values, everyElement(1));
    }
  });

  test(
    'follow-ups exclude the last start and group edits retain only identity',
    () {
      final session = group()..startRound(catalog, random: Random(9));
      final initialStart = session.round!.currentPlayer!.id;
      for (var cycle = 0; cycle < 10; cycle++) {
        final start = session.round!.currentPlayer!;
        distribute(session);
        final now = DateTime.utc(2026);
        session.startDiscussion(now);
        session.advanceTime(now.add(session.round!.discussionDuration));
        session.selectSuspect(session.players.first.id);
        session.confirmSuspect(now);
        session.advanceTime(now.add(GameRound.revealDuration));
        session.newRound();
        expect(session.round!.currentPlayer!.id, isNot(start.id));
      }
      final previous = session.round!.currentPlayer!;
      session.returnToGroup();
      session.removePlayer(previous.id);
      session.addPlayer(previous.name);
      final orders = <String>{};
      for (var seed = 0; seed < 100; seed++) {
        var round = GameRound.fromDeck(
          players: session.players,
          deck: WordDeck(catalog),
          previousStartPlayerId: previous.id,
          random: Random(seed),
        );
        final order = <String>[];
        while (round.canAdvanceCard) {
          order.add(round.currentPlayer!.id);
          round = round.hideAndAdvance();
        }
        expect(order, isNot(contains(previous.id)));
        orders.add(order.join(','));
      }
      expect(orders, hasLength(6));
      final fresh = group()..startRound(catalog, random: Random(9));
      expect(fresh.round!.currentPlayer!.id, initialStart);
    },
  );

  test('aborted rounds exclude their startperson even after renaming', () {
    final session = group()..startRound(catalog, random: Random(7));
    final first = session.round!.currentPlayer!;
    session.returnToGroup();
    session.renamePlayer(first.id, 'Neuer Name');
    session.startRound(catalog, random: Random(7));
    expect(session.round!.currentPlayer!.id, isNot(first.id));
    expect(
      distribute(session).toSet(),
      session.players.map((p) => p.id).toSet(),
    );
  });

  test('every supported group receives each identity once with stable secret views', () {
    for (var size = 3; size <= 14; size++) {
      final session = GameSession();
      for (var i = 0; i < size; i++) {
        session.addPlayer('Person $i');
      }
      session.startRound(catalog, random: Random(size));
      final seen = <String>{};
      for (var i = 0; i < size; i++) {
        final player = session.round!.currentPlayer!;
        expect(seen.add(player.id), isTrue);
        session.revealSecret();
        final secret = session.round!.currentSecret!;
        session.concealSecret();
        expect(session.round!.currentPlayer, same(player));
        session.revealSecret();
        expect(session.round!.currentSecret!.role, secret.role);
        expect(session.round!.currentSecret!.text, secret.text);
        session.hideAndAdvance();
      }
      expect(seen, session.players.map((p) => p.id).toSet());
      expect(session.round!.phase, GamePhase.ready);
    }
  });

  test('first rounds can use every complete order, not just rotations', () {
    final orders = <String>{};
    for (var seed = 0; seed < 100; seed++) {
      final session = group()..startRound(catalog, random: Random(seed));
      final original = session.players;
      final order = distribute(session);
      expect(order.toSet(), original.map((p) => p.id).toSet());
      expect(order, hasLength(3));
      expect(session.players, orderedEquals(original));
      orders.add(order.join(','));
    }
    expect(orders, hasLength(6));
  });
}

final class Draws implements Random {
  Draws(this.values);
  final List<int> values;
  int index = 0;
  @override
  int nextInt(int max) {
    final value = values[index++];
    expect(value, inInclusiveRange(0, max - 1));
    return value;
  }

  @override
  bool nextBool() => throw UnsupportedError('Unused');
  @override
  double nextDouble() => throw UnsupportedError('Unused');
}

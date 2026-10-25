import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/word_catalog.dart';
import 'package:secret_word_society/game/word_deck.dart';

WordCatalog _catalog(int size) => WordCatalog(
  languageCode: 'de',
  pairs: List.generate(
    size,
    (index) =>
        WordPair(id: '$index', word: 'Wort $index', hint: 'Hinweis $index'),
  ),
);

void main() {
  test('every cycle covers the catalog once and boundaries never repeat', () {
    for (final size in [2, 3, 16, 100]) {
      final catalog = _catalog(size);
      for (var seed = 0; seed < 30; seed++) {
        final random = Random(seed);
        final deck = WordDeck(catalog);
        WordPair? previous;
        for (var cycle = 0; cycle < 5; cycle++) {
          final seen = <String>{};
          for (var draw = 0; draw < size; draw++) {
            final pair = deck.draw(random);
            expect(catalog.pairs, contains(same(pair)));
            expect(seen.add(pair.id), isTrue);
            expect(pair, isNot(same(previous)));
            previous = pair;
          }
          expect(seen, catalog.pairs.map((pair) => pair.id).toSet());
        }
      }
    }
  });

  test('one-word catalogs remain playable across refills', () {
    final catalog = _catalog(1);
    final deck = WordDeck(catalog);
    final random = Random(1);
    for (var draw = 0; draw < 5; draw++) {
      expect(deck.draw(random), same(catalog.pairs.single));
    }
  });

  test('seeds reproduce the sequence and different seeds vary it', () {
    final catalog = _catalog(16);
    final orders = <String>{};
    for (var seed = 0; seed < 10; seed++) {
      final first = WordDeck(catalog);
      final second = WordDeck(catalog);
      final firstRandom = Random(seed);
      final secondRandom = Random(seed);
      final order = <String>[];
      for (var draw = 0; draw < 48; draw++) {
        final pair = first.draw(firstRandom);
        expect(second.draw(secondRandom), same(pair));
        order.add(pair.id);
      }
      orders.add(order.join(','));
    }
    expect(orders.length, greaterThan(1));
  });

  test('matches reloaded content but rejects changed catalogs', () {
    final catalog = _catalog(3);
    final deck = WordDeck(catalog);
    expect(deck.matches(_catalog(3)), isTrue);
    expect(deck.matches(_catalog(2)), isFalse);
    for (final field in ['language', 'id', 'word', 'hint', 'order']) {
      var pairs = catalog.pairs.toList();
      final pair = pairs.first;
      pairs[0] = WordPair(
        id: field == 'id' ? 'new' : pair.id,
        word: field == 'word' ? 'Neu' : pair.word,
        hint: field == 'hint' ? 'Anders' : pair.hint,
      );
      if (field == 'order') pairs = pairs.reversed.toList();
      expect(
        deck.matches(
          WordCatalog(
            languageCode: field == 'language' ? 'en' : 'de',
            pairs: pairs,
          ),
        ),
        isFalse,
        reason: field,
      );
    }
  });
}

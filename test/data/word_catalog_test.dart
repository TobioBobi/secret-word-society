import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/data/word_catalog_loader.dart';
import 'package:secret_word_society/game/game_round.dart';
import 'package:secret_word_society/game/player.dart';
import 'package:secret_word_society/game/word_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled German catalog has 100 distinct offline word/hint pairs',
    () async {
      final catalog = await loadWordCatalog();
      expect(catalog.languageCode, 'de');
      expect(catalog.pairs, hasLength(100));
      expect(
        catalog.pairs.map((pair) => pair.id).toSet(),
        hasLength(catalog.pairs.length),
      );
      expect(
        catalog.pairs.map((pair) => pair.word.toLowerCase()).toSet(),
        hasLength(catalog.pairs.length),
      );
      for (final pair in catalog.pairs) {
        expect(pair.word, isNotEmpty);
        expect(pair.hint, isNotEmpty);
        expect(
          pair.hint.toLowerCase(),
          isNot(contains(pair.word.toLowerCase())),
        );
      }
      expect(catalog.pairs.map((pair) => pair.word), contains('Zahnbürste'));
      expect(() => catalog.pairs.clear(), throwsUnsupportedError);
    },
  );

  test(
    'catalog copies input and preserves language independently of game rules',
    () {
      final input = [WordPair(id: '1', word: ' Word ', hint: ' Hint ')];
      final catalog = WordCatalog(languageCode: 'xx', pairs: input);
      input.clear();
      expect(catalog.languageCode, 'xx');
      expect(catalog.pairs.single.word, 'Word');
      expect(catalog.pairs.single.hint, 'Hint');
    },
  );

  test(
    'every bundled pair supports a complete round with consistent secrets',
    () async {
      final catalog = await loadWordCatalog();
      var round = GameRound.start(
        players: List.generate(3, (i) => Player(id: '$i', name: 'Person $i')),
        catalog: catalog,
        random: Random(42),
      );
      final seen = <String>{};
      for (var index = 0; index < catalog.pairs.length; index++) {
        String? imposterId;
        final words = <String>[];
        final hints = <String>[];
        while (round.phase == GamePhase.handoff) {
          expect(round.currentSecret, isNull);
          expect(round.result, isNull);
          round = round.revealSecret();
          final secret = round.currentSecret!;
          if (secret.role == PlayerRole.imposter) {
            imposterId = round.currentPlayer!.id;
            hints.add(secret.text);
          } else {
            words.add(secret.text);
          }
          round = round.hideAndAdvance();
        }
        expect(hints, hasLength(1));
        expect(words, hasLength(2));
        final word = words.toSet().single;
        expect(seen.add(word), isTrue);
        expect(
          catalog.pairs.singleWhere((pair) => pair.word == word).hint,
          hints.single,
        );
        final now = DateTime.utc(2026, 10, 25);
        final correct = index.isEven;
        final suspect = correct
            ? imposterId!
            : round.players.firstWhere((player) => player.id != imposterId).id;
        round = round
            .startDiscussion(now)
            .advanceTime(now.add(GameRound.discussionDuration))
            .selectSuspect(suspect)
            .confirmSuspect();
        expect(round.result!.word, word);
        expect(round.result!.winner, correct ? Winner.group : Winner.imposter);
        round = round.newRound();
        expect(round.currentSecret, isNull);
        expect(round.discussionEndsAt, isNull);
        expect(
          round.remainingDiscussionTime(now),
          GameRound.discussionDuration,
        );
      }
      expect(seen, catalog.pairs.map((pair) => pair.word).toSet());
    },
  );

  test(
    'loader rejects unavailable languages without silently substituting German',
    () {
      expect(loadWordCatalog(languageCode: 'en'), throwsUnsupportedError);
    },
  );

  test(
    'loader rejects a mismatched language and propagates missing assets',
    () {
      expect(
        loadWordCatalog(
          bundle: _TestBundle(
            '{"languageCode":"xx",'
            '"pairs":[{"id":"1","word":"Word","hint":"Hint"}]}',
          ),
        ),
        throwsFormatException,
      );
      expect(
        loadWordCatalog(bundle: _TestBundle(null)),
        throwsA(isA<FlutterError>()),
      );
    },
  );

  test('malformed or unusable catalogs fail at the content boundary', () {
    final invalidSources = <Object?>[
      null,
      [],
      {},
      {'languageCode': 5, 'pairs': []},
      {'languageCode': 'de', 'pairs': 'invalid'},
      {'languageCode': 'de', 'pairs': []},
      {
        'languageCode': ' ',
        'pairs': [
          {'id': '1', 'word': 'Wort', 'hint': 'Hinweis'},
        ],
      },
      {
        'languageCode': 'de',
        'pairs': [null],
      },
      {
        'languageCode': 'de',
        'pairs': [
          {'id': '1', 'word': 42, 'hint': 'Hinweis'},
        ],
      },
      {
        'languageCode': 'de',
        'pairs': [
          {'id': '1', 'word': 'Wort'},
        ],
      },
      for (final field in ['id', 'word', 'hint'])
        {
          'languageCode': 'de',
          'pairs': [
            {'id': '1', 'word': 'Wort', 'hint': 'Hinweis', field: ' '},
          ],
        },
      {
        'languageCode': 'de',
        'pairs': [
          {'id': '1', 'word': 'Wort', 'hint': ' WORT '},
        ],
      },
      {
        'languageCode': 'de',
        'pairs': [
          {'id': '1', 'word': 'Wort', 'hint': 'Hinweis'},
          {'id': '1', 'word': 'Anderes', 'hint': 'Weiteres'},
        ],
      },
      {
        'languageCode': 'de',
        'pairs': [
          {'id': '1', 'word': 'Wort', 'hint': 'Hinweis'},
          {'id': '2', 'word': ' WORT ', 'hint': 'Weiteres'},
        ],
      },
    ];
    for (final source in invalidSources) {
      expect(
        () => WordCatalog.fromJson(jsonEncode(source)),
        throwsFormatException,
      );
    }
    expect(() => WordCatalog.fromJson('{'), throwsFormatException);
  });
}

final class _TestBundle extends CachingAssetBundle {
  _TestBundle(this.source);
  final String? source;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (source == null) throw FlutterError('Missing asset.');
    return source!;
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

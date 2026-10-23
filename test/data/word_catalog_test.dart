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

  test('bundled German starter catalog loads offline and has distinct useful fields', () async {
    final catalog = await loadWordCatalog();
    expect(catalog.languageCode, 'de');
    expect(catalog.pairs.length, inInclusiveRange(10, 20));
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
      expect(pair.hint.toLowerCase(), isNot(contains(pair.word.toLowerCase())));
    }
    expect(catalog.pairs.map((pair) => pair.word), contains('Zahnbürste'));
    expect(catalog.pairs, contains(same(catalog.choose(Random(42)))));
    expect(() => catalog.pairs.clear(), throwsUnsupportedError);
  });

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
    'a bundled word supports a complete round and a fresh follow-up',
    () async {
      final catalog = await loadWordCatalog();
      var round = GameRound.start(
        players: List.generate(3, (i) => Player(id: '$i', name: 'Person $i')),
        catalog: catalog,
        random: Random(42),
      );
      String? imposterId;
      final words = <String>{};
      String? hint;
      while (round.phase == GamePhase.handoff) {
        round = round.revealSecret();
        final secret = round.currentSecret!;
        if (secret.role == PlayerRole.imposter) {
          imposterId = round.currentPlayer!.id;
          hint = secret.text;
        } else {
          words.add(secret.text);
        }
        round = round.hideAndAdvance();
      }
      final word = words.single;
      expect(catalog.pairs.singleWhere((pair) => pair.word == word).hint, hint);
      final now = DateTime.utc(2026, 10, 23);
      round = round
          .startDiscussion(now)
          .advanceTime(now.add(const Duration(minutes: 2)))
          .selectSuspect(imposterId!)
          .confirmSuspect();
      expect(round.result!.word, word);
      expect(round.result!.winner, Winner.group);
      expect(round.newRound().currentSecret, isNull);
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

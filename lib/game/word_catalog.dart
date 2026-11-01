import 'dart:convert';

final class WordPair {
  WordPair({
    required String id,
    required String word,
    required String hint,
    Iterable<String> additionalHints = const [],
  }) : id = id.trim(),
       word = word.trim(),
       hints = List.unmodifiable(
         [hint, ...additionalHints].map((s) => s.trim()),
       ) {
    if (this.id.isEmpty || this.word.isEmpty || this.hint.isEmpty) {
      throw ArgumentError('Word pair fields must not be empty.');
    }
    if (hints.any(
          (hint) =>
              hint.isEmpty || this.word.toLowerCase() == hint.toLowerCase(),
        ) ||
        hints.map((hint) => hint.toLowerCase()).toSet().length !=
            hints.length) {
      throw ArgumentError(
        'Hints must be nonempty, distinct and differ from the word.',
      );
    }
  }

  final String id;
  final String word;
  final List<String> hints;
  String get hint => hints.first;
}

/// Localized content, independent of Flutter and UI translations.
final class WordCatalog {
  WordCatalog({required String languageCode, required Iterable<WordPair> pairs})
    : languageCode = languageCode.trim(),
      pairs = List.unmodifiable(pairs) {
    if (this.languageCode.isEmpty || this.pairs.isEmpty) {
      throw ArgumentError('A catalog needs a language and at least one pair.');
    }
    if (this.pairs.map((pair) => pair.id).toSet().length != this.pairs.length) {
      throw ArgumentError('Word pair IDs must be unique within a catalog.');
    }
    if (this.pairs.map((pair) => pair.word.toLowerCase()).toSet().length !=
        this.pairs.length) {
      throw ArgumentError('Words must be unique within a catalog.');
    }
  }

  factory WordCatalog.fromJson(String source) {
    final data = jsonDecode(source);
    if (data is! Map<String, dynamic> ||
        data['languageCode'] is! String ||
        data['pairs'] is! List) {
      throw const FormatException('Expected a languageCode and a pairs list.');
    }
    try {
      return WordCatalog(
        languageCode: data['languageCode'] as String,
        pairs: (data['pairs'] as List).map((entry) {
          if (entry is! Map<String, dynamic> ||
              entry['id'] is! String ||
              entry['word'] is! String ||
              entry['hint'] is! String) {
            throw const FormatException('Expected id, word and hint strings.');
          }
          return WordPair(
            id: entry['id'] as String,
            word: entry['word'] as String,
            hint: entry['hint'] as String,
            additionalHints: switch (entry['additionalHints']) {
              null => const <String>[],
              List<dynamic> hints when hints.every((hint) => hint is String) =>
                hints.cast<String>(),
              _ => throw const FormatException(
                'Expected additional hint strings.',
              ),
            },
          );
        }),
      );
    } on ArgumentError {
      throw const FormatException('Invalid word catalog content.');
    }
  }

  final String languageCode;
  final List<WordPair> pairs;
}

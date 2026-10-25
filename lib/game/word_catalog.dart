import 'dart:convert';

final class WordPair {
  WordPair({required String id, required String word, required String hint})
    : id = id.trim(),
      word = word.trim(),
      hint = hint.trim() {
    if (this.id.isEmpty || this.word.isEmpty || this.hint.isEmpty) {
      throw ArgumentError('Word pair fields must not be empty.');
    }
    if (this.word.toLowerCase() == this.hint.toLowerCase()) {
      throw ArgumentError('A hint must differ from its word.');
    }
  }

  final String id;
  final String word;
  final String hint;
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

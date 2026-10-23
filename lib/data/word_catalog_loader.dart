import 'package:flutter/services.dart';

import '../game/word_catalog.dart';

/// Only installed languages can be loaded; there is no network fallback.
Future<WordCatalog> loadWordCatalog({
  String languageCode = 'de',
  AssetBundle? bundle,
}) async {
  final path = switch (languageCode) {
    'de' => 'assets/words/de.json',
    _ => throw UnsupportedError('No word catalog for this language.'),
  };
  final catalog = WordCatalog.fromJson(
    await (bundle ?? rootBundle).loadString(path),
  );
  if (catalog.languageCode != languageCode) {
    throw const FormatException('Word catalog language does not match.');
  }
  return catalog;
}

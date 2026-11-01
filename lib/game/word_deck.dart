import 'dart:math';

import 'word_catalog.dart';

/// Session-only draw source, shared by rounds, never by separate sessions.
/// Drawing randomly from the remaining pairs is equivalent to shuffling a deck.
final class WordDeck {
  WordDeck(this.catalog);

  final WordCatalog catalog;
  final List<WordPair> _remaining = [];
  WordPair? _previous;

  /// Reloading identical assets must not reset the session's word history.
  bool matches(WordCatalog other) {
    if (catalog.languageCode != other.languageCode ||
        catalog.pairs.length != other.pairs.length) {
      return false;
    }
    for (var index = 0; index < catalog.pairs.length; index++) {
      final first = catalog.pairs[index];
      final second = other.pairs[index];
      if (first.id != second.id ||
          first.word != second.word ||
          first.hints.length != second.hints.length) {
        return false;
      }
      for (var hint = 0; hint < first.hints.length; hint++) {
        if (first.hints[hint] != second.hints[hint]) return false;
      }
    }
    return true;
  }

  WordPair draw(Random random) {
    final refilling = _remaining.isEmpty;
    if (refilling) _remaining.addAll(catalog.pairs);

    // At a cycle boundary, choose uniformly among all but the previous word.
    // A one-word catalog necessarily repeats, but must still remain playable.
    final avoidPrevious =
        refilling && _previous != null && _remaining.length > 1;
    var index = random.nextInt(_remaining.length - (avoidPrevious ? 1 : 0));
    if (avoidPrevious && index >= _remaining.indexOf(_previous!)) index++;
    final pair = _remaining.removeAt(index);
    _previous = pair;
    return pair;
  }
}

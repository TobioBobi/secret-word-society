import 'dart:math';

enum HandoffEntrance { left, right, bottom, grow }

/// A visual shuffle, independent of the round's roles and player order.
class HandoffEntrances {
  HandoffEntrances({Random? random}) : _random = random ?? Random();

  final Random _random;
  final _remaining = <HandoffEntrance>[];
  HandoffEntrance? _previous;

  HandoffEntrance next() {
    if (_remaining.isEmpty) {
      _remaining.addAll(HandoffEntrance.values);
      do {
        _remaining.shuffle(_random);
      } while (_remaining.last == _previous);
    }
    return _previous = _remaining.removeLast();
  }
}

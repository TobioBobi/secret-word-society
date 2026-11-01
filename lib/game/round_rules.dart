import 'dart:math';

/// Public configuration depends only on group size, never on the secret draw.
abstract final class RoundRules {
  static const minimumPlayers = 3;
  static const maximumPlayers = 14;

  static void validate(int count) {
    if (count < minimumPlayers || count > maximumPlayers) {
      throw ArgumentError.value(count, 'count', 'Expected 3–14 players.');
    }
  }

  static Duration discussionDuration(int count) {
    validate(count);
    return Duration(seconds: 30 * count);
  }

  static int minimumImposters(int count) {
    validate(count);
    return count >= 11 ? 2 : 1;
  }

  static int maximumImposters(int count) {
    validate(count);
    return count >= 11 ? 3 : (count >= 6 ? 2 : 1);
  }

  static int drawImposterCount(int count, Random random) {
    final minimum = minimumImposters(count);
    final maximum = maximumImposters(count);
    return minimum == maximum
        ? minimum
        : minimum + random.nextInt(maximum - minimum + 1);
  }
}

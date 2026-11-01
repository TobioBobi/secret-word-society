import 'dart:math';

/// Public choice; never contains the secretly drawn count.
final class ImposterChoice {
  ImposterChoice(this.minimum, this.maximum) {
    if (minimum < 1 || maximum < minimum || maximum > minimum + 1) {
      throw ArgumentError('Expected a positive count or adjacent pair.');
    }
  }

  final int minimum;
  final int maximum;
  int get step => minimum + maximum - 2;
  String get label => minimum == maximum ? '$minimum' : '$minimum–$maximum';

  factory ImposterChoice.fromStep(int step) {
    if (step < 0) throw ArgumentError.value(step, 'step');
    return ImposterChoice(step ~/ 2 + 1, (step + 1) ~/ 2 + 1);
  }

  factory ImposterChoice.automatic(int players) => ImposterChoice(
    RoundRules.minimumImposters(players),
    RoundRules.maximumImposters(players),
  );

  void validateFor(int players) {
    RoundRules.validate(players);
    if (maximum >= players) throw ArgumentError('Too many imposters.');
  }

  int draw(Random random) =>
      minimum == maximum ? minimum : minimum + random.nextInt(2);
}

/// Public configuration depends only on group size, never on the secret draw.
abstract final class RoundRules {
  static const minimumPlayers = 3;
  static const maximumPlayers = 14;
  static const durationStep = Duration(seconds: 30);
  static const minimumDuration = durationStep;
  static const maximumDuration = Duration(minutes: 15);

  static void validateDuration(Duration duration) {
    if (duration < minimumDuration ||
        duration > maximumDuration ||
        duration.inMicroseconds % durationStep.inMicroseconds != 0) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Expected 30s–15m in 30s steps.',
      );
    }
  }

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
    return ImposterChoice.automatic(count).draw(random);
  }
}

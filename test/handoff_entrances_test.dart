import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/ui/handoff_entrances.dart';

void main() {
  test(
    'each shuffled cycle uses all four entrances without adjacent repeats',
    () {
      for (var seed = 0; seed < 100; seed++) {
        final entrances = HandoffEntrances(random: Random(seed));
        HandoffEntrance? previous;
        for (var cycle = 0; cycle < 30; cycle++) {
          final seen = <HandoffEntrance>{};
          for (var draw = 0; draw < 4; draw++) {
            final entrance = entrances.next();
            expect(entrance, isNot(previous));
            seen.add(entrance);
            previous = entrance;
          }
          expect(seen, HandoffEntrance.values.toSet());
        }
      }
    },
  );
}

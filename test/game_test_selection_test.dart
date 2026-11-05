import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/game_test_selection.dart';

void main() {
  test('each declared game test runs in exactly one of two groups', () {
    const assignments = {'first': 1, 'second': 2, 'third': 1};
    final first = GameTestSelection('1', assignments);
    final second = GameTestSelection('2', assignments);
    expect(assignments.keys.where(first.includes).toList(), ['first', 'third']);
    expect(assignments.keys.where(second.includes).toList(), ['second']);
    first.validate();
    second.validate();
  });

  test('a test assigned outside the two CI groups cannot disappear', () {
    final selection = GameTestSelection('1', {
      'first': 1,
      'second': 2,
      'lost': 3,
    });
    expect(() => selection.includes('lost'), throwsStateError);
  });

  test('local default runs all tests without filtering', () {
    final selection = GameTestSelection('all', {'first': 1, 'second': 2});
    expect(selection.includes('first'), isTrue);
    expect(selection.includes('second'), isTrue);
    selection.validate();
  });

  test('new and duplicate tests fail registration', () {
    final selection = GameTestSelection('1', {'first': 1, 'second': 2});
    expect(() => selection.includes('new'), throwsStateError);
    selection.includes('first');
    expect(() => selection.includes('first'), throwsStateError);
  });

  test('missing tests and empty groups fail validation', () {
    final incomplete = GameTestSelection('1', {'first': 1, 'second': 2});
    incomplete.includes('first');
    expect(incomplete.validate, throwsStateError);
    final empty = GameTestSelection('2', {'first': 1});
    empty.includes('first');
    expect(empty.validate, throwsStateError);
    expect(GameTestSelection('1', {}).validate, throwsStateError);
  });

  test(
    'unknown or empty group argument fails instead of selecting nothing',
    () {
      for (final group in ['', '0', '3', 'typo']) {
        expect(
          () => GameTestSelection(group, gameTestGroups),
          throwsArgumentError,
        );
      }
    },
  );
}

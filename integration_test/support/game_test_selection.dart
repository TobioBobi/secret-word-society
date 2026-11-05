/// Explicit, measured assignment of the complete Android game suite.
/// Unknown, renamed or removed tests fail registration instead of disappearing
/// from CI. Keep both groups nonempty when updating this list.
const gameTestGroups = <String, int>{
  'skip timer: confirmation, expiry and normal resolution': 1,
  'manual imposters: range or fixed=false, hints and reduced group': 2,
  'manual imposters: range or fixed=true, hints and reduced group': 2,
  'manual timer: real 30-second expiry and retained follow-up': 1,
  'real assets: complete round, correct=true, then start next round': 1,
  'real assets: complete round, correct=false, then start next round': 2,
  'unseen and partial cards stay with their person until fully viewed': 2,
  'leave dialog conceals cards, retains group and allows restart': 1,
  '6 players: distinct offline hints, capped multi-vote and edited group': 2,
  '14 players: distinct offline hints, capped multi-vote and edited group': 1,
};

class GameTestSelection {
  GameTestSelection(this.group, this.assignments) {
    if (group != 'all' && group != '1' && group != '2') {
      throw ArgumentError.value(
        group,
        'GAME_TEST_GROUP',
        'Expected all, 1 or 2',
      );
    }
  }

  final String group;
  final Map<String, int> assignments;
  final _registered = <String>{};

  bool includes(String name) {
    final assigned = assignments[name];
    if (assigned == null) {
      throw StateError('Assign new game test to a CI group: $name');
    }
    if (assigned != 1 && assigned != 2) {
      throw StateError('Invalid game test group $assigned for $name');
    }
    if (!_registered.add(name)) {
      throw StateError('Duplicate game test: $name');
    }
    return group == 'all' || group == '$assigned';
  }

  void validate() {
    final missing = assignments.keys.toSet().difference(_registered);
    if (missing.isNotEmpty) {
      throw StateError('Game tests not registered: $missing');
    }
    for (final requiredGroup in [1, 2]) {
      if (!assignments.values.contains(requiredGroup)) {
        throw StateError('Empty game test group: $requiredGroup');
      }
    }
  }
}

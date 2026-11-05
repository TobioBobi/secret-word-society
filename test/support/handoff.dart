import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/game/player_avatar.dart';
import 'package:secret_word_society/ui/player_avatar.dart';

String handoffName(
  WidgetTester tester, [
  Iterable<String> names = const ['Anna', 'Ben', 'Cem'],
]) => names.singleWhere((name) => find.text(name).evaluate().isNotEmpty);

Future<Map<String, PlayerAvatar>> groupAvatars(
  WidgetTester tester,
  List<String> names,
) async {
  final avatars = <String, PlayerAvatar>{};
  for (final (index, name) in names.indexed) {
    final row = find.byKey(ValueKey('player-$index'));
    await tester.scrollUntilVisible(
      row,
      index == 0 ? -180 : 180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    avatars[name] = tester
        .widget<PlayerAvatarView>(
          find.descendant(of: row, matching: find.byType(PlayerAvatarView)),
        )
        .avatar;
  }
  return avatars;
}

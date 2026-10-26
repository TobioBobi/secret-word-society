import 'package:flutter_test/flutter_test.dart';

/// Reacquires lazy children after scrolling and delayed platform metrics.
/// Only the search is retried: the action itself is dispatched exactly once.
Future<void> tapWhenStable(
  WidgetTester tester,
  Finder target, {
  required Finder scrollable,
}) async {
  final hitTarget = target.hitTestable();
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (hitTarget.evaluate().length == 1) {
      final before = tester.getRect(hitTarget);
      await tester.pump(const Duration(milliseconds: 100));
      if (hitTarget.evaluate().length == 1 &&
          tester.getRect(hitTarget) == before) {
        await tester.tap(hitTarget);
        return;
      }
    } else if (target.evaluate().length == 1) {
      await tester.ensureVisible(target);
    } else {
      await tester.drag(scrollable, const Offset(0, -160));
    }
  }
  fail('Target did not become visible and stable: $target');
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Visible underlay, calculated from the actual rendered cover shape.
Rect openingBounds(WidgetTester tester) {
  final panel = tester.getRect(
    find.byKey(const ValueKey('secret-curtain-panel')),
  );
  final cover = find
      .descendant(
        of: find.byKey(const ValueKey('secret-curtain-cover')),
        matching: find.byType(PhysicalShape),
      )
      .first;
  final shape = tester
      .widget<PhysicalShape>(cover)
      .clipper
      .getClip(tester.getSize(cover));
  final covered = shape.shift(tester.getTopLeft(cover) - panel.topLeft);
  return Path.combine(
    PathOperation.difference,
    Path()..addRect(Offset.zero & panel.size),
    covered,
  ).getBounds();
}

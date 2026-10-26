import 'dart:ui' show SemanticsAction, SemanticsActionEvent;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart'
    show startTestRound, tapVisible, expectConcealed, semanticsTree;

Finder get _curtain => find.byKey(const ValueKey('secret-curtain-gesture'));

Future<TestGesture> _hold(WidgetTester tester) async {
  await tester.ensureVisible(_curtain);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(_curtain));
  final panel = tester.getRect(
    find.byKey(const ValueKey('secret-curtain-panel')),
  );
  await gesture.moveBy(const Offset(0, -30));
  await tester.pump();
  await gesture.moveTo(Offset(panel.center.dx, panel.top + 32));
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets(
    'cover follows the finger without acceleration and keeps its grip',
    (tester) async {
      await startTestRound(tester);
      await tester.ensureVisible(_curtain);
      await tester.pumpAndSettle();
      final start = tester.getCenter(_curtain);
      final panel = tester.getRect(
        find.byKey(const ValueKey('secret-curtain-panel')),
      );
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy - 60, 0.1));
      expectConcealed(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy - 60, 0.1));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy - 40, 0.1));
      await gesture.moveTo(Offset(start.dx, panel.top + 32));
      await tester.pump();
      expect(tester.getCenter(_curtain).dy, closeTo(panel.top + 32, 0.1));
      expect(
        find.text('Popcorn').evaluate().isNotEmpty ||
            find.text('Kino').evaluate().isNotEmpty,
        isTrue,
      );
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      expect(tester.getCenter(_curtain).dy, closeTo(panel.top + 32, 0.1));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(tester.getCenter(_curtain).dy, closeTo(panel.top + 62, 0.1));
      expectConcealed(tester);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy, 0.1));
      final flick = await tester.startGesture(start);
      await flick.moveBy(const Offset(0, -60));
      await tester.pump();
      final releasedAt = tester.getCenter(_curtain).dy;
      await flick.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getCenter(_curtain).dy, greaterThanOrEqualTo(releasedAt));
      expectConcealed(tester);
      await tester.pumpAndSettle();
      expect(tester.getCenter(_curtain).dy, closeTo(start.dy, 0.1));
    },
  );

  testWidgets('hold, release, repeat, cancel and separate concealed handoff', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await startTestRound(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.ensureVisible(_curtain);
    await tester.tap(_curtain);
    await tester.pump();
    expectConcealed(tester);
    for (var i = 0; i < 3; i++) {
      final gesture = await _hold(tester);
      final secret = find.text('Popcorn').evaluate().isNotEmpty
          ? 'Popcorn'
          : 'Kino';
      expect(find.text(secret), findsOneWidget);
      expect(semanticsTree(tester), contains(secret));
      expect(find.text('Person 1 von 3'), findsOneWidget);
      if (i == 1) {
        await gesture.cancel();
      } else {
        await gesture.up();
      }
      await tester.pump();
      expectConcealed(tester);
      await tester.pumpAndSettle();
    }
    await tapVisible(tester, 'Weiter');
    expect(find.text('Handy an Ben.'), findsOneWidget);
    expectConcealed(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    semantics.dispose();
  });

  testWidgets(
    'interrupted held and partial drags stay closed until a new gesture',
    (tester) async {
      await startTestRound(tester);
      for (final full in [false, true]) {
        TestGesture gesture;
        if (full) {
          gesture = await _hold(tester);
        } else {
          await tester.ensureVisible(_curtain);
          await tester.pumpAndSettle();
          gesture = await tester.startGesture(tester.getCenter(_curtain));
          await gesture.moveBy(const Offset(0, -30));
          await tester.pump();
        }
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        // An old pointer can deliver another move before the resume frame.
        await gesture.moveBy(const Offset(0, -150));
        await tester.pump();
        expectConcealed(tester);
        await gesture.moveBy(const Offset(0, -150));
        await tester.pump();
        expectConcealed(tester);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('Person 1 von 3'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'same-frame release and advancing while held cannot leak secrets',
    (tester) async {
      await startTestRound(tester);
      final gesture = await _hold(tester);
      final advance = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      advance();
      advance();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Handy an Ben.'), findsOneWidget);
      expectConcealed(tester);
      await tester.ensureVisible(_curtain);
      await tester.pumpAndSettle();
      final quick = await tester.startGesture(tester.getCenter(_curtain));
      await quick.moveBy(const Offset(0, -30));
      await quick.moveBy(const Offset(0, -260));
      await quick.up();
      await tester.pump();
      expectConcealed(tester);
    },
  );

  testWidgets(
    'semantics and keyboard peek expire and interruptions cancel expiry',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await startTestRound(tester);
      await tester.ensureVisible(_curtain);
      await tester.pumpAndSettle();
      final node = tester.getSemantics(
        find.bySemanticsLabel('Geheimnis kurz ansehen'),
      );
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: node.id,
        ),
      );
      await tester.pump();
      expect(
        find.text('Popcorn').evaluate().isNotEmpty ||
            find.text('Kino').evaluate().isNotEmpty,
        isTrue,
      );
      await tester.pump(const Duration(seconds: 8));
      expectConcealed(tester);
      await tester.pumpAndSettle();
      Focus.of(tester.element(_curtain)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        find.text('Popcorn').evaluate().isNotEmpty ||
            find.text('Kino').evaluate().isNotEmpty,
        isTrue,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expectConcealed(tester);
      await tester.pump(const Duration(seconds: 9));
      expectConcealed(tester);
      semantics.dispose();
    },
  );
}

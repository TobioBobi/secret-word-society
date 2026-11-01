import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart'
    show
        leaveRound,
        readyGroup,
        showStart,
        tapVisible,
        expectConcealed,
        testCatalog;

final class _Clock {
  DateTime value = DateTime.utc(2026, 10, 23, 12);
  DateTime now() => value;
  void advance(Duration elapsed) => value = value.add(elapsed);
}

Future<void> _ready(WidgetTester tester, _Clock clock) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    MyApp(catalogLoader: () async => testCatalog, now: clock.now),
  );
  await readyGroup(tester);
  await showStart(tester);
  await tapVisible(tester, 'Runde starten');
  await _distribute(tester);
}

Future<void> _distribute(WidgetTester tester) async {
  for (var index = 0; index < 3; index++) {
    await tapVisible(tester, 'Geheimnis kurz ansehen');
    await tapVisible(tester, 'Weiter');
  }
}

Future<void> _tick(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 250));

void main() {
  testWidgets('explicit guarded start; deadline, rounding and hidden secrets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final clock = _Clock();
    await _ready(tester, clock);
    clock.advance(const Duration(minutes: 3));
    await tester.pump(const Duration(minutes: 3));
    expect(find.text('Alle eingeweiht?'), findsOneWidget);
    expect(find.text('01:30'), findsNothing);

    await tester.ensureVisible(find.text('01:30 starten'));
    final start = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .onPressed!;
    start();
    start();
    await tester.pumpAndSettle();
    expect(find.text('Jetzt wird geblufft.'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
    expectConcealed(tester);
    expect(find.byType(FilledButton), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Noch 90 Sekunden')).label,
      'Noch 90 Sekunden',
    );
    final timerSemantics = tester.widget<Semantics>(
      find
          .ancestor(of: find.text('01:30'), matching: find.byType(Semantics))
          .first,
    );
    expect(timerSemantics.properties.liveRegion, isNot(true));

    clock.advance(const Duration(milliseconds: 500));
    await _tick(tester);
    expect(find.text('01:30'), findsOneWidget);
    clock.advance(const Duration(milliseconds: 500));
    await _tick(tester);
    expect(find.text('01:29'), findsOneWidget);
    // A single UI tick must account for all elapsed time, not decrement by one.
    clock.advance(const Duration(seconds: 88, microseconds: 999999));
    await _tick(tester);
    expect(find.text('00:01'), findsOneWidget);
    start(); // The old ready callback must not reset the deadline.
    clock.advance(const Duration(microseconds: 1));
    await _tick(tester);
    await tester.pumpAndSettle();
    expect(find.text('Wem vertraut ihr nicht?'), findsOneWidget);
    expect(
      find.text('Die Zeit ist um. Einigt euch auf eine Person.'),
      findsOneWidget,
    );
    expect(find.text('00:00'), findsNothing);
    expectConcealed(tester);
    final heading = tester.widget<Focus>(
      find.byKey(const ValueKey('GamePhase.voting-null')),
    );
    expect(heading.focusNode!.hasFocus, isTrue);
    await tester.pump(const Duration(minutes: 3));
    expect(find.text('Wem vertraut ihr nicht?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('all interruptions reconcile time before the resumed frame', (
    tester,
  ) async {
    final clock = _Clock();
    await _ready(tester, clock);
    await tapVisible(tester, '01:30 starten');
    var elapsed = 0;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      clock.advance(const Duration(seconds: 1));
      elapsed += 1;
      // No background pump: Flutter may not produce frames while suspended.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      final remaining = 90 - elapsed;
      expect(
        find.text(
          '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}'
              .padLeft(5, '0'),
        ),
        findsOneWidget,
      );
      expectConcealed(tester);
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.advance(const Duration(minutes: 5));
    // The window may first become visible while still inactive on Android.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(find.text('Wem vertraut ihr nicht?'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Jetzt wird geblufft.'), findsNothing);
    expectConcealed(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leave dialog does not pause time or obscure the next phase on cancel',
    (tester) async {
      final clock = _Clock();
      await _ready(tester, clock);
      await tapVisible(tester, '01:30 starten');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      clock.advance(const Duration(seconds: 90));
      await _tick(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tapVisible(tester, 'Weiterspielen');
      expect(find.text('Wem vertraut ihr nicht?'), findsOneWidget);
      expectConcealed(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'leaving cancels the timer; fresh round and disposal stay clean',
    (tester) async {
      final clock = _Clock();
      await _ready(tester, clock);
      final oldStart = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      await tapVisible(tester, '01:30 starten');
      clock.advance(const Duration(seconds: 3));
      await _tick(tester);
      await leaveRound(tester);
      await tapVisible(tester, 'Runde verlassen');
      clock.advance(const Duration(minutes: 3));
      await tester.pump(const Duration(minutes: 3));
      expect(find.text('Wer ist dabei?'), findsOneWidget);
      expect(find.text('3 Personen'), findsOneWidget);
      await showStart(tester);
      await tapVisible(tester, 'Runde starten');
      await _distribute(tester);
      oldStart();
      await tester.pumpAndSettle();
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      await tapVisible(tester, '01:30 starten');
      expect(find.text('01:30'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      clock.advance(const Duration(minutes: 3));
      await tester.pump(const Duration(minutes: 3));
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Personen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('start ignores interruptions and an open leave dialog', (
    tester,
  ) async {
    final clock = _Clock();
    await _ready(tester, clock);
    final start = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .onPressed!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    start();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Alle eingeweiht?'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    start();
    await tapVisible(tester, 'Weiterspielen');
    expect(find.text('Alle eingeweiht?'), findsOneWidget);
  });

  testWidgets('ready, countdown and voting fit 320px at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final clock = _Clock();
    await _ready(tester, clock);
    await tapVisible(tester, '01:30 starten');
    expect(find.text('01:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await leaveRound(tester);
    await tapVisible(tester, 'Weiterspielen');
    clock.advance(const Duration(seconds: 90));
    await _tick(tester);
    await tester.pumpAndSettle();
    expect(find.text('Wem vertraut ihr nicht?'), findsOneWidget);
    await leaveRound(tester);
    await tapVisible(tester, 'Runde verlassen');
    expect(find.text('3 Personen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

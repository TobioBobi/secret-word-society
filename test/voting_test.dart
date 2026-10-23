import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart'
    show
        addName,
        readyGroup,
        showStart,
        tapVisible,
        expectConcealed,
        testCatalog;

const _names = ['Anna', 'Ben', 'Cem'];

final class _Clock {
  DateTime value = DateTime.utc(2026, 10, 24, 12);
  DateTime now() => value;
}

Future<String> _distribute(WidgetTester tester, List<String> names) async {
  String? imposter;
  for (final (index, name) in names.indexed) {
    await tapVisible(tester, 'Geheimnis aufdecken');
    if (find.text('Du bist der Imposter').evaluate().isNotEmpty) {
      imposter = name;
    }
    await tapVisible(
      tester,
      index == names.length - 1
          ? 'Verbergen & weiter'
          : 'Verbergen & weitergeben',
    );
  }
  return imposter!;
}

Future<void> _reachVoting(WidgetTester tester, _Clock clock) async {
  await tapVisible(tester, '2 Minuten starten');
  expect(find.text('02:00'), findsOneWidget);
  clock.value = clock.value.add(const Duration(minutes: 2));
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pumpAndSettle();
  expect(find.text('Wem vertraut ihr nicht?'), findsOneWidget);
  expectConcealed(tester);
}

Future<String> _voting(WidgetTester tester, _Clock clock) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    MyApp(catalogLoader: () async => testCatalog, now: clock.now),
  );
  await readyGroup(tester);
  await showStart(tester);
  await tapVisible(tester, 'Runde starten');
  final imposter = await _distribute(tester, _names);
  await _reachVoting(tester, clock);
  return imposter;
}

Future<FilledButton> _action(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byType(FilledButton),
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.byType(FilledButton));
  await tester.pumpAndSettle();
  return tester.widget<FilledButton>(find.byType(FilledButton));
}

void main() {
  for (final correct in [true, false]) {
    testWidgets('vote, reveal and fresh complete round: correct=$correct', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final clock = _Clock();
      final imposter = await _voting(tester, clock);
      final suspect = correct
          ? imposter
          : _names.firstWhere((name) => name != imposter);
      expect((await _action(tester)).onPressed, isNull);
      await tapVisible(tester, suspect);
      await _action(tester);
      expect(find.text('$suspect verdächtigen'), findsOneWidget);
      expectConcealed(tester);
      final selectedTile = find.widgetWithText(RadioListTile<String>, suspect);
      await tester.ensureVisible(selectedTile);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(suspect))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      final confirm = (await _action(tester)).onPressed!;
      confirm();
      confirm(); // The same frame must not confirm twice.
      await tester.pumpAndSettle();
      expect(
        find.text(correct ? 'Erwischt!' : 'Gut geblufft!'),
        findsOneWidget,
      );
      expect(
        find.text(correct ? 'Die Gruppe gewinnt.' : 'Der Imposter gewinnt.'),
        findsOneWidget,
      );
      expect(find.text('Popcorn'), findsOneWidget);
      expect(find.text('Kino'), findsNothing);
      expect(find.text(imposter), correct ? findsNWidgets(2) : findsOneWidget);
      expect(find.text('Euer Verdacht'), findsOneWidget);
      expect(find.text('Der Imposter war'), findsOneWidget);
      expect(find.text('Das geheime Wort'), findsOneWidget);
      expect(find.byType(RadioListTile<String>), findsNothing);
      expect(
        tester
            .widget<Focus>(find.byKey(const ValueKey('GamePhase.result-null')))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      final next = (await _action(tester)).onPressed!;
      next();
      next();
      confirm(); // Previous-round callbacks must not reveal the new round.
      await tester.pumpAndSettle();
      expect(find.text('Handy an Anna.'), findsOneWidget);
      expect(find.text('Person 1 von 3'), findsOneWidget);
      expectConcealed(tester);
      expect(find.text('Euer Verdacht'), findsNothing);
      clock.value = clock.value.add(const Duration(minutes: 5));
      await tester.pump(const Duration(minutes: 5));
      expect(find.text('Handy an Anna.'), findsOneWidget);
      final secondImposter = await _distribute(tester, _names);
      await _reachVoting(tester, clock);
      expect((await _action(tester)).onPressed, isNull);
      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        isNull,
      );
      await tapVisible(tester, secondImposter);
      await tapVisible(tester, '$secondImposter verdächtigen');
      expect(find.text('Erwischt!'), findsOneWidget);
      await tapVisible(tester, 'Gruppe bearbeiten');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('3 Personen'), findsOneWidget);
      expectConcealed(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Personen'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets(
    'selection changes, survives cancellation and guards stale actions',
    (tester) async {
      final clock = _Clock();
      await _voting(tester, clock);
      await tapVisible(tester, 'Anna');
      final oldConfirm = (await _action(tester)).onPressed!;
      await tapVisible(tester, 'Ben');
      oldConfirm();
      await tester.pumpAndSettle();
      await _action(tester);
      expect(find.text('Ben verdächtigen'), findsOneWidget);
      expectConcealed(tester);
      final confirm = (await _action(tester)).onPressed!;
      final select = tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .onChanged;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      confirm();
      select('player-2');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Ben verdächtigen'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      confirm();
      select('player-2');
      await tapVisible(tester, 'Weiterspielen');
      await _action(tester);
      expect(find.text('Ben verdächtigen'), findsOneWidget);
      expectConcealed(tester);
      await tapVisible(tester, 'Ben verdächtigen');
      expect(find.text('Die Auflösung'), findsOneWidget);
      final next = (await _action(tester)).onPressed!;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      next();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Die Auflösung'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Wer ist dabei?'), findsOneWidget);
      expect(find.text('3 Personen'), findsOneWidget);
      next();
      confirm();
      select('player-2');
      await tester.pumpAndSettle();
      expect(find.text('Wer ist dabei?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('voting can be abandoned without revealing the result', (
    tester,
  ) async {
    final clock = _Clock();
    await _voting(tester, clock);
    await tapVisible(tester, 'Cem');
    await tapVisible(tester, 'Gruppe bearbeiten');
    await tapVisible(tester, 'Runde verlassen');
    expect(find.text('3 Personen'), findsOneWidget);
    expectConcealed(tester);
    await showStart(tester);
    await tapVisible(tester, 'Runde starten');
    expect(find.text('Handy an Anna.'), findsOneWidget);
    expectConcealed(tester);
  });

  testWidgets('large group, long names and result fit 320px at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final clock = _Clock();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MyApp(catalogLoader: () async => testCatalog, now: clock.now),
    );
    const longName = 'AlexandramitbesonderslangemNamen';
    final names = [for (var i = 1; i < 12; i++) 'Person $i', longName];
    for (final name in names) {
      await addName(tester, name);
    }
    await showStart(tester);
    await tapVisible(tester, 'Runde starten');
    await _distribute(tester, names);
    await _reachVoting(tester, clock);
    await tapVisible(tester, longName);
    await tapVisible(tester, '$longName verdächtigen');
    await tapVisible(tester, 'Noch eine Runde');
    expect(find.text('Handy an Person 1.'), findsOneWidget);
    expect(find.text('Person 1 von 12'), findsOneWidget);
    expectConcealed(tester);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';
import 'package:secret_word_society/platform/round_signal.dart';

import 'widget_test.dart'
    show
        addName,
        readyGroup,
        showStart,
        tapVisible,
        expectConcealed,
        semanticsTree,
        testCatalog;

const _names = ['Anna', 'Ben', 'Cem'];
final _soundCalls = <MethodCall>[];
Iterable<MethodCall> get _reveals =>
    _soundCalls.where((call) => call.method == 'reveal');

final class _Clock {
  DateTime value = DateTime.utc(2026, 10, 24, 12);
  DateTime now() => value;
}

Future<String> _distribute(WidgetTester tester, List<String> names) async {
  String? imposter;
  for (final name in names) {
    await tapVisible(tester, 'Geheimnis kurz ansehen');
    if (find.text('Du bist der Imposter').evaluate().isNotEmpty) {
      imposter = name;
    }
    await tapVisible(tester, 'Weiter');
  }
  return imposter!;
}

Future<void> _reachVoting(WidgetTester tester, _Clock clock) async {
  await tapVisible(tester, '10 Sekunden starten');
  expect(find.text('00:10'), findsOneWidget);
  clock.value = clock.value.add(const Duration(seconds: 10));
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

Future<void> _finishReveal(WidgetTester tester, _Clock clock) async {
  final previousReveals = _reveals.length;
  expect(find.text('Wer hat geblufft?'), findsOneWidget);
  expect(find.text('3'), findsOneWidget);
  expectConcealed(tester);
  expect(find.text('Erwischt!'), findsNothing);
  expect(find.text('Gut geblufft!'), findsNothing);
  for (final label in [
    'Der Imposter war',
    'Das geheime Wort',
    'Die Gruppe gewinnt.',
    'Der Imposter gewinnt.',
  ]) {
    expect(semanticsTree(tester), isNot(contains(label)));
  }
  for (final seconds in [2, 1]) {
    clock.value = clock.value.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('$seconds'), findsOneWidget);
    expectConcealed(tester);
    expect(find.text('Die Auflösung'), findsNothing);
    expect(_reveals, hasLength(previousReveals));
  }
  clock.value = clock.value.add(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _soundCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RoundSignal.channel, (call) async {
          _soundCalls.add(call);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(RoundSignal.channel, null);
  });
  testWidgets(
    'countdown freezes across background and leave dialog without restarting',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final clock = _Clock();
      await _voting(tester, clock);
      await tapVisible(tester, 'Anna');
      await tapVisible(tester, 'Anna verdächtigen');
      clock.value = clock.value.add(const Duration(milliseconds: 1250));
      await tester.pump(const Duration(milliseconds: 1250));
      expect(find.text('2'), findsOneWidget);
      expect(find.bySemanticsLabel('Enthüllung in 2 Sekunden'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock.value = clock.value.add(const Duration(minutes: 5));
      await tester.pump(const Duration(minutes: 5));
      expectConcealed(tester);
      expect(find.text('2'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      clock.value = clock.value.add(const Duration(minutes: 5));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(minutes: 5));
      expectConcealed(tester);
      await tapVisible(tester, 'Weiterspielen');
      expect(find.text('2'), findsOneWidget);
      clock.value = clock.value.add(const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.text('1'), findsOneWidget);
      expectConcealed(tester);
      clock.value = clock.value.add(const Duration(milliseconds: 999));
      await tester.pump(const Duration(milliseconds: 999));
      expectConcealed(tester);
      clock.value = clock.value.add(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 251));
      await tester.pumpAndSettle();
      expect(find.text('Die Auflösung'), findsOneWidget);
      expect(_reveals, hasLength(1));
      expect(_reveals.single.arguments['audible'], isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    },
  );

  testWidgets('abandoning or disposing a countdown cannot reveal later', (
    tester,
  ) async {
    final clock = _Clock();
    await _voting(tester, clock);
    await tapVisible(tester, 'Ben');
    final confirm = (await _action(tester)).onPressed!;
    confirm();
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Gruppe bearbeiten');
    await tapVisible(tester, 'Runde verlassen');
    clock.value = clock.value.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    confirm();
    await showStart(tester);
    await tapVisible(tester, 'Runde starten');
    await _distribute(tester, _names);
    await _reachVoting(tester, clock);
    await tapVisible(tester, 'Cem');
    await tapVisible(tester, 'Cem verdächtigen');
    expect(find.text('3'), findsOneWidget);
    expectConcealed(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    clock.value = clock.value.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(tester.takeException(), isNull);
    expect(_reveals, isEmpty);
  });

  testWidgets('late reveal consumes the sound without replay on return', (
    tester,
  ) async {
    final clock = _Clock();
    await _voting(tester, clock);
    await tapVisible(tester, 'Anna');
    await tapVisible(tester, 'Anna verdächtigen');
    expect(_reveals, isEmpty);
    clock.value = clock.value.add(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.text('Die Auflösung'), findsOneWidget);
    expect(_reveals.single.arguments['audible'], isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(_reveals, hasLength(1));
  });

  testWidgets('interruption before reveal frame completes consumes sound', (
    tester,
  ) async {
    final clock = _Clock();
    await _voting(tester, clock);
    await tapVisible(tester, 'Anna');
    await tapVisible(tester, 'Anna verdächtigen');
    var interrupted = false;
    tester.binding.addPersistentFrameCallback((_) {
      if (interrupted || find.text('Die Auflösung').evaluate().isEmpty) return;
      interrupted = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    clock.value = clock.value.add(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(interrupted, isTrue);
    expect(_reveals.single.arguments['audible'], isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(_reveals, hasLength(1));
  });

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
      await _finishReveal(tester, clock);
      final sound = _reveals.single;
      expect(sound.arguments['winner'], correct ? 'group' : 'imposter');
      expect(sound.arguments['audible'], isTrue);
      expect(
        sound.arguments['token'],
        _soundCalls
            .singleWhere((c) => c.method == 'prepareReveal')
            .arguments['token'],
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      expect(_reveals, hasLength(1));
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
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Person 1 von 3'), findsOneWidget);
      expectConcealed(tester);
      expect(find.text('Euer Verdacht'), findsNothing);
      clock.value = clock.value.add(const Duration(minutes: 5));
      await tester.pump(const Duration(minutes: 5));
      expect(find.text('Anna'), findsOneWidget);
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
      await _finishReveal(tester, clock);
      expect(find.text('Erwischt!'), findsOneWidget);
      expect(_reveals, hasLength(2));
      expect(_reveals.last.arguments['winner'], 'group');
      expect(_reveals.last.arguments['token'], isNot(sound.arguments['token']));
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
      await _finishReveal(tester, clock);
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
    expect(find.text('Anna'), findsOneWidget);
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
    await _finishReveal(tester, clock);
    await tapVisible(tester, 'Noch eine Runde');
    expect(find.text('Person 1'), findsOneWidget);
    expect(find.text('Person 1 von 12'), findsOneWidget);
    expectConcealed(tester);
    expect(tester.takeException(), isNull);
  });
}

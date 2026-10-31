import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secret_word_society/data/word_catalog_loader.dart';
import 'package:secret_word_society/game/word_catalog.dart';
import 'package:secret_word_society/main.dart' as app;

import '../test/support/tap_when_stable.dart';

const _players = ['Anna', 'Ben', 'Cem'];

Finder get _pageScroll => find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 15),
);

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tapWhenStable(tester, target, scrollable: _pageScroll);
  await _settle(tester);
}

TestGesture? _peekGesture;

Future<void> _tapText(WidgetTester tester, String text) async {
  if (_peekGesture != null) {
    await _peekGesture!.up();
    _peekGesture = null;
    await _settle(tester);
  }
  if (text == 'Geheimnis kurz ansehen') {
    final target = find.byKey(const ValueKey('secret-curtain-gesture'));
    await tester.ensureVisible(target);
    await _settle(tester);
    _peekGesture = await tester.startGesture(tester.getCenter(target));
    final panel = tester.getRect(
      find.byKey(const ValueKey('secret-curtain-panel')),
    );
    await _peekGesture!.moveBy(const Offset(0, -30));
    await tester.pump();
    final preview = find.byKey(const ValueKey('secret-curtain-opening'));
    expect(preview, findsOneWidget);
    expect(
      find.descendant(of: preview, matching: find.byType(Text)),
      findsWidgets,
    );
    await _peekGesture!.moveBy(const Offset(0, -60));
    await tester.pump();
    final clip = tester
        .widget<ClipRect>(preview)
        .clipper!
        .getClip(tester.getSize(preview));
    expect(clip.top, greaterThan(0));
    expect(clip.height, greaterThan(0));
    await _peekGesture!.moveTo(Offset(panel.center.dx, panel.top + 32));
    await _settle(tester);
    return;
  }
  await _tap(tester, find.text(text));
}

Future<void> _launchAndCreateGroup(WidgetTester tester) async {
  // Remove the previous app's State even when tests run in one process.
  await tester.pumpWidget(const SizedBox.shrink());
  app.main();
  await _settle(tester);
  expect(find.text('Noch keine Personen'), findsOneWidget);

  for (final name in _players) {
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), name);
    await _tap(tester, find.byTooltip('Name hinzufügen'));
  }
  // Native keyboard metrics can arrive after pumpAndSettle has returned.
  // Wait for the viewport to expand before scrolling to the start button.
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  final keyboardWait = Stopwatch()..start();
  while (tester.view.viewInsets.bottom > 0 &&
      keyboardWait.elapsed < const Duration(seconds: 15)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(
    tester.view.viewInsets.bottom,
    0,
    reason: 'Android keyboard is hidden',
  );
  await _settle(tester);
  await _tapText(tester, 'Runde starten');
  expect(find.text('Handy an Anna.'), findsOneWidget);
  expect(find.text('Person 1 von 3'), findsOneWidget);
}

void _expectConcealed(WordCatalog catalog) {
  for (final pair in catalog.pairs) {
    expect(find.text(pair.word), findsNothing);
    expect(find.text(pair.hint), findsNothing);
  }
  expect(find.text('Du bist der Imposter'), findsNothing);
}

String _visibleSecret(WordCatalog catalog) {
  final secrets = {
    for (final pair in catalog.pairs) ...[pair.word, pair.hint],
  };
  final cards = find.byWidgetPredicate(
    (widget) => widget is Text && secrets.contains(widget.data),
  );
  expect(cards, findsOneWidget);
  return (cards.evaluate().single.widget as Text).data!;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  for (final correct in [true, false]) {
    testWidgets(
      'real assets: complete round, correct=$correct, then start next round',
      (tester) async {
        await _launchAndCreateGroup(tester);
        final catalog = await loadWordCatalog();
        final words = <String>[];
        final hints = <String>[];
        String? imposter;

        for (final (index, name) in _players.indexed) {
          expect(find.text('Handy an $name.'), findsOneWidget);
          expect(find.text('Person ${index + 1} von 3'), findsOneWidget);
          _expectConcealed(catalog);
          await _tapText(tester, 'Geheimnis kurz ansehen');
          expect(find.text('Handy an $name.'), findsOneWidget);
          final secret = _visibleSecret(catalog);
          if (find.text('Du bist der Imposter').evaluate().isNotEmpty) {
            expect(find.text('Dein Hinweis'), findsOneWidget);
            expect(find.text('Dein geheimes Wort'), findsNothing);
            hints.add(secret);
            imposter = name;
          } else {
            expect(find.text('Dein geheimes Wort'), findsOneWidget);
            expect(find.text('Dein Hinweis'), findsNothing);
            words.add(secret);
          }
          await _tapText(tester, 'Weiter');
          _expectConcealed(catalog);
          expect(find.text('Handy an $name.'), findsNothing);
        }

        expect(words, hasLength(2));
        expect(words.toSet(), hasLength(1));
        expect(hints, hasLength(1));
        final pair = catalog.pairs.singleWhere(
          (pair) => pair.word == words.first,
        );
        expect(hints.single, pair.hint);
        expect(find.text('Alle eingeweiht?'), findsOneWidget);
        expect(find.text('Alle Geheimnisse sind verteilt.'), findsOneWidget);
        expect(find.text('Geheimnis kurz ansehen'), findsNothing);

        await _tapText(tester, '10 Sekunden starten');
        expect(find.text('Jetzt wird geblufft.'), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        _expectConcealed(catalog);
        // Use the real production clock on Android, with the configured round duration.
        // pump(Duration) waits real time with the integration-test binding.
        await tester.pump(const Duration(seconds: 2));
        final countdown = tester.widget<Text>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data ?? ''),
          ),
        );
        final digits = countdown.data!.split(':').map(int.parse).toList();
        expect(digits[0] * 60 + digits[1], inInclusiveRange(5, 8));
        await tester.pump(const Duration(seconds: 9));
        await _settle(tester);
        expect(
          find.text('Wem vertraut ihr nicht?'),
          findsOneWidget,
          reason:
              'Lifecycle: ${tester.binding.lifecycleState}, '
              'device time: ${DateTime.now()}',
        );
        expect(
          find.text('Die Zeit ist um. Einigt euch auf eine Person.'),
          findsOneWidget,
        );
        expect(find.text('Zeit ist um!'), findsOneWidget);
        expect(find.text('Jetzt wird geblufft.'), findsNothing);
        _expectConcealed(catalog);
        final confirmButton = find.byType(FilledButton);
        await tester.scrollUntilVisible(
          confirmButton,
          160,
          scrollable: _pageScroll,
        );
        expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);
        final suspect = correct
            ? imposter!
            : _players.firstWhere((name) => name != imposter);
        await _tapText(tester, suspect);
        _expectConcealed(catalog);
        await _tapText(tester, '$suspect verdächtigen');
        expect(find.text('Wer hat geblufft?'), findsOneWidget);
        _expectConcealed(catalog);
        expect(find.text('Die Auflösung'), findsNothing);
        await tester.pump(const Duration(seconds: 1));
        _expectConcealed(catalog);
        expect(find.text('Die Auflösung'), findsNothing);
        await tester.pump(const Duration(seconds: 3));
        await _settle(tester);
        expect(
          find.text(correct ? 'Erwischt!' : 'Gut geblufft!'),
          findsOneWidget,
        );
        expect(
          find.text(correct ? 'Die Gruppe gewinnt.' : 'Der Imposter gewinnt.'),
          findsOneWidget,
        );
        expect(find.text(words.first), findsOneWidget);
        expect(
          find.text(imposter!),
          correct ? findsNWidgets(2) : findsOneWidget,
        );
        expect(find.text(suspect), correct ? findsNWidgets(2) : findsOneWidget);
        expect(find.text('Euer Verdacht'), findsOneWidget);
        expect(find.text('Der Imposter war'), findsOneWidget);
        expect(find.text('Das geheime Wort'), findsOneWidget);
        await _tapText(tester, 'Noch eine Runde');
        expect(find.text('Handy an Anna.'), findsOneWidget);
        expect(find.text('Person 1 von 3'), findsOneWidget);
        _expectConcealed(catalog);
        final nextWords = <String>{};
        final nextHints = <String>[];
        for (var index = 0; index < _players.length; index++) {
          await _tapText(tester, 'Geheimnis kurz ansehen');
          final secret = _visibleSecret(catalog);
          if (find.text('Du bist der Imposter').evaluate().isNotEmpty) {
            nextHints.add(secret);
          } else {
            nextWords.add(secret);
          }
          await _tapText(tester, 'Weiter');
        }
        expect(nextWords, hasLength(1));
        expect(nextWords.single, isNot(words.first));
        expect(nextHints, hasLength(1));
        expect(
          catalog.pairs
              .singleWhere((pair) => pair.word == nextWords.single)
              .hint,
          nextHints.single,
        );
        expect(find.text('Alle eingeweiht?'), findsOneWidget);
        _expectConcealed(catalog);
        await _tapText(tester, '10 Sekunden starten');
        expect(find.text('00:10'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('leave dialog conceals cards, retains group and allows restart', (
    tester,
  ) async {
    await _launchAndCreateGroup(tester);
    final catalog = await loadWordCatalog();
    await _tapText(tester, 'Geheimnis kurz ansehen');
    final firstSecret = _visibleSecret(catalog);

    await _tapText(tester, 'Gruppe bearbeiten');
    expect(find.text('Runde verlassen?'), findsOneWidget);
    _expectConcealed(catalog);
    await _tapText(tester, 'Weiterspielen');
    expect(find.text('Handy an Anna.'), findsOneWidget);
    _expectConcealed(catalog);
    await _tapText(tester, 'Geheimnis kurz ansehen');
    expect(_visibleSecret(catalog), firstSecret);

    await _tapText(tester, 'Weiter');
    expect(find.text('Handy an Ben.'), findsOneWidget);
    await _tapText(tester, 'Geheimnis kurz ansehen');
    final secondSecret = _visibleSecret(catalog);
    // At least one of the first two people belongs to the group.
    final previousWord = catalog.pairs
        .singleWhere(
          (pair) => pair.word == firstSecret || pair.word == secondSecret,
        )
        .word;
    await _tapText(tester, 'Gruppe bearbeiten');
    expect(find.text('Runde verlassen?'), findsOneWidget);
    _expectConcealed(catalog);
    await _tapText(tester, 'Runde verlassen');
    expect(find.text('Wer ist dabei?'), findsOneWidget);
    expect(find.text('3 Personen'), findsOneWidget);
    _expectConcealed(catalog);
    for (final name in _players) {
      await tester.scrollUntilVisible(
        find.text(name),
        160,
        scrollable: _pageScroll,
      );
      expect(find.text(name), findsOneWidget);
    }

    await _tapText(tester, 'Runde starten');
    expect(find.text('Handy an Anna.'), findsOneWidget);
    expect(find.text('Person 1 von 3'), findsOneWidget);
    _expectConcealed(catalog);
    await _tapText(tester, 'Geheimnis kurz ansehen');
    final restartedWords = <String>{};
    for (var index = 0; index < _players.length; index++) {
      if (index > 0) await _tapText(tester, 'Geheimnis kurz ansehen');
      final secret = _visibleSecret(catalog);
      if (find.text('Du bist der Imposter').evaluate().isEmpty) {
        restartedWords.add(secret);
      }
      await _tapText(tester, 'Weiter');
    }
    expect(restartedWords, hasLength(1));
    expect(restartedWords.single, isNot(previousWord));
    expect(tester.takeException(), isNull);
  });
}

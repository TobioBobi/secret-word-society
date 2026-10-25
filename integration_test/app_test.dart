import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secret_word_society/data/word_catalog_loader.dart';
import 'package:secret_word_society/game/word_catalog.dart';
import 'package:secret_word_society/main.dart' as app;

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
  await tester.scrollUntilVisible(target, 160, scrollable: _pageScroll);
  await _settle(tester);
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _tapText(WidgetTester tester, String text) =>
    _tap(tester, find.text(text));

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
  // Dismiss the real keyboard through the scroll view's on-drag behavior.
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
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
          await _tapText(tester, 'Geheimnis aufdecken');
          expect(find.text('Nur für $name.'), findsOneWidget);
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
          await _tapText(
            tester,
            index == _players.length - 1
                ? 'Verbergen & weiter'
                : 'Verbergen & weitergeben',
          );
          _expectConcealed(catalog);
          expect(find.text('Nur für $name.'), findsNothing);
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
        expect(find.text('Geheimnis aufdecken'), findsNothing);

        await _tapText(tester, '2 Minuten starten');
        expect(find.text('Jetzt wird geblufft.'), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        _expectConcealed(catalog);
        // Use the real production clock on Android, without shortening the round.
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
        expect(digits[0] * 60 + digits[1], inInclusiveRange(115, 118));
        await tester.pump(const Duration(seconds: 119));
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
          await _tapText(tester, 'Geheimnis aufdecken');
          final secret = _visibleSecret(catalog);
          if (find.text('Du bist der Imposter').evaluate().isNotEmpty) {
            nextHints.add(secret);
          } else {
            nextWords.add(secret);
          }
          await _tapText(
            tester,
            index == _players.length - 1
                ? 'Verbergen & weiter'
                : 'Verbergen & weitergeben',
          );
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
        await _tapText(tester, '2 Minuten starten');
        expect(find.text('02:00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('leave dialog conceals cards, retains group and allows restart', (
    tester,
  ) async {
    await _launchAndCreateGroup(tester);
    final catalog = await loadWordCatalog();
    await _tapText(tester, 'Geheimnis aufdecken');
    final firstSecret = _visibleSecret(catalog);

    await _tapText(tester, 'Gruppe bearbeiten');
    expect(find.text('Runde verlassen?'), findsOneWidget);
    _expectConcealed(catalog);
    await _tapText(tester, 'Weiterspielen');
    expect(find.text('Handy an Anna.'), findsOneWidget);
    _expectConcealed(catalog);
    await _tapText(tester, 'Geheimnis aufdecken');
    expect(_visibleSecret(catalog), firstSecret);

    await _tapText(tester, 'Verbergen & weitergeben');
    expect(find.text('Handy an Ben.'), findsOneWidget);
    await _tapText(tester, 'Geheimnis aufdecken');
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
    await _tapText(tester, 'Geheimnis aufdecken');
    final restartedWords = <String>{};
    for (var index = 0; index < _players.length; index++) {
      if (index > 0) await _tapText(tester, 'Geheimnis aufdecken');
      final secret = _visibleSecret(catalog);
      if (find.text('Du bist der Imposter').evaluate().isEmpty) {
        restartedWords.add(secret);
      }
      await _tapText(
        tester,
        index == _players.length - 1
            ? 'Verbergen & weiter'
            : 'Verbergen & weitergeben',
      );
    }
    expect(restartedWords, hasLength(1));
    expect(restartedWords.single, isNot(previousWord));
    expect(tester.takeException(), isNull);
  });
}

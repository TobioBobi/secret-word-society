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
  // Remove the previous app's State even when both tests run in one process.
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real assets: distribute three private cards and reach ready', (
    tester,
  ) async {
    await _launchAndCreateGroup(tester);
    final catalog = await loadWordCatalog();
    final words = <String>[];
    final hints = <String>[];

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
    final pair = catalog.pairs.singleWhere((pair) => pair.word == words.first);
    expect(hints.single, pair.hint);
    expect(find.text('Alle eingeweiht?'), findsOneWidget);
    expect(find.text('Alle Geheimnisse sind verteilt.'), findsOneWidget);
    expect(find.text('Geheimnis aufdecken'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
    _visibleSecret(catalog);
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
    _visibleSecret(catalog);
    expect(tester.takeException(), isNull);
  });
}

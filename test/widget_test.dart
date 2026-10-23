import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/data/word_catalog_loader.dart';
import 'package:secret_word_society/game/word_catalog.dart';
import 'package:secret_word_society/main.dart';

final testCatalog = WordCatalog(
  languageCode: 'de',
  pairs: [WordPair(id: 'test', word: 'Popcorn', hint: 'Kino')],
);

Future<void> addName(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.byType(TextField));
  await tester.enterText(find.byType(TextField), name);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Future<void> readyGroup(WidgetTester tester) async {
  await addName(tester, 'Anna');
  await addName(tester, 'Ben');
  await addName(tester, 'Cem');
}

Future<void> showStart(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Runde starten'),
    180,
    scrollable: find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts empty and validates names through button and keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Wer ist dabei?'), findsOneWidget);
    expect(find.text('Noch keine Personen'), findsOneWidget);
    expect(find.text('Noch 3 Personen bis zum Start.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Name hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.text('Bitte gib einen Namen ein.'), findsOneWidget);
    await addName(tester, '   Anna   ');
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('1 Person'), findsOneWidget);
    expect(find.text('Bitte gib einen Namen ein.'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await addName(tester, ' aNNa ');
    expect(find.textContaining('Dieser Name ist schon dabei.'), findsOneWidget);
    expect(find.text('1 Person'), findsOneWidget);
    await addName(tester, 'Ben');
    await showStart(tester);
    expect(find.text('Noch 1 Person bis zum Start.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await addName(tester, 'Cem');
    await showStart(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.ensureVisible(find.byTooltip('Ben entfernen'));
    await tester.tap(find.byTooltip('Ben entfernen'));
    await tester.pumpAndSettle();
    expect(find.text('Ben'), findsNothing);
    await showStart(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Ben');
    await tester.tap(find.byTooltip('Name hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.text('3 Personen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('starts with real offline assets; back/edit retain the group', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MyApp());
    await readyGroup(tester);
    await showStart(tester);
    await tester.tap(find.text('Runde starten'));
    await tester.pumpAndSettle();
    expect(find.text('Handy an Anna.'), findsOneWidget);
    expect(find.text('Person 1 von 3'), findsOneWidget);
    expect(find.text('Dein Geheimnis bleibt verdeckt.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final tree = StringBuffer();
    tester.binding.rootPipelineOwner.visitChildren((owner) {
      tree.writeln(owner.semanticsOwner?.rootSemanticsNode?.toStringDeep());
    });
    semantics.dispose();
    expect(tree.toString(), contains('Dein Geheimnis bleibt verdeckt.'));
    final catalog = await loadWordCatalog();
    for (final pair in catalog.pairs) {
      expect(tree.toString(), isNot(contains(pair.word)));
      expect(tree.toString(), isNot(contains(pair.hint)));
    }

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Wer ist dabei?'), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('3 Personen'), findsOneWidget);
    await showStart(tester);
    await tester.tap(find.text('Runde starten'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gruppe bearbeiten'));
    await tester.tap(find.text('Gruppe bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Wer ist dabei?'), findsOneWidget);
    expect(find.text('3 Personen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Personen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed catalog load preserves group and supports a guarded retry',
    (tester) async {
      var calls = 0;
      final pending = Completer<WordCatalog>();
      await tester.pumpWidget(
        MyApp(
          catalogLoader: () {
            calls++;
            return calls == 1
                ? Future.error(const FormatException('broken'))
                : pending.future;
          },
        ),
      );
      await readyGroup(tester);
      await showStart(tester);
      await tester.tap(find.text('Runde starten'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Die Wörter konnten nicht geladen werden.'),
        findsOneWidget,
      );
      expect(find.text('3 Personen'), findsOneWidget);
      await showStart(tester);
      await tester.tap(find.text('Runde starten'));
      await tester.pump();
      expect(find.text('Runde wird vorbereitet …'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await tester.tap(find.text('Runde wird vorbereitet …'));
      await tester.pump();
      expect(calls, 2);
      pending.complete(testCatalog);
      await tester.pumpAndSettle();
      expect(find.text('Handy an Anna.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposing while loading does not update a removed screen', (
    tester,
  ) async {
    final pending = Completer<WordCatalog>();
    await tester.pumpWidget(MyApp(catalogLoader: () => pending.future));
    await readyGroup(tester);
    await showStart(tester);
    await tester.tap(find.text('Runde starten'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(testCatalog);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'small display, 200% text, keyboard and long group remain usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(MyApp(catalogLoader: () async => testCatalog));
      const longName = 'AlexandramitbesonderslangemNamen';
      await addName(tester, longName);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await addName(tester, 'Ben');
      await addName(tester, 'Cem');
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      for (var index = 4; index <= 12; index++) {
        await addName(tester, 'Person $index');
      }
      await showStart(tester);
      await tester.tap(find.text('Runde starten'));
      await tester.pumpAndSettle();
      expect(find.text('Handy an $longName.'), findsOneWidget);
      expect(find.text('Person 1 von 12'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Gruppe bearbeiten'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gruppe bearbeiten'));
      await tester.pumpAndSettle();
      expect(find.text('12 Personen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

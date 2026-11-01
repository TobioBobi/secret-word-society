import 'dart:async';

import 'package:flutter/material.dart';
import 'package:secret_word_society/ui/secret_curtain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/data/word_catalog_loader.dart';
import 'package:secret_word_society/game/word_catalog.dart';
import 'package:secret_word_society/main.dart';

final testCatalog = WordCatalog(
  languageCode: 'de',
  pairs: [WordPair(id: 'test', word: 'Popcorn', hint: 'Kino')],
);

final multiHintCatalog = WordCatalog(
  languageCode: 'de',
  pairs: [
    WordPair(
      id: 'test',
      word: 'Popcorn',
      hint: 'Kino',
      additionalHints: ['Filmabend', 'Knallender Mais'],
    ),
  ],
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

Future<void> tapVisible(WidgetTester tester, String label) async {
  if (label == 'Geheimnis kurz ansehen') {
    final curtain = find.byType(SecretCurtain);
    await tester.ensureVisible(curtain);
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('secret-peek-action'));
    tester.widget<Semantics>(action).properties.onTap!();
    await tester.pumpAndSettle();
    return;
  }
  for (
    var attempt = 0;
    find.text(label).evaluate().isEmpty && attempt < 40;
    attempt++
  ) {
    // Scroll beside the curtain's grip, as a user can on a short viewport.
    final viewport = tester.getRect(find.byType(CustomScrollView));
    await tester.dragFrom(
      Offset(viewport.left + 8, viewport.center.dy),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> leaveRound(WidgetTester tester) async {
  if (find.text('Die Auflösung').evaluate().isEmpty) {
    expect(find.text('Gruppe bearbeiten'), findsNothing);
  }
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> startTestRound(WidgetTester tester) async {
  await tester.pumpWidget(MyApp(catalogLoader: () async => testCatalog));
  await readyGroup(tester);
  await showStart(tester);
  await tapVisible(tester, 'Runde starten');
}

String semanticsTree(WidgetTester tester) {
  final tree = StringBuffer();
  tester.binding.rootPipelineOwner.visitChildren((owner) {
    tree.writeln(owner.semanticsOwner?.rootSemanticsNode?.toStringDeep());
  });
  return tree.toString();
}

void expectConcealed(WidgetTester tester) {
  for (final secret in ['Popcorn', 'Kino', 'Du bist der Imposter']) {
    expect(find.text(secret), findsNothing);
    expect(semanticsTree(tester), isNot(contains(secret)));
  }
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
    await tester.ensureVisible(find.byTooltip('Ben entfernen'));
    await tester.pumpAndSettle();
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
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Person 1 von 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Geheimnis kurz ansehen'), findsOneWidget);
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
    await tapVisible(tester, 'Runde verlassen');
    expect(find.text('Wer ist dabei?'), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('3 Personen'), findsOneWidget);
    await showStart(tester);
    await tester.tap(find.text('Runde starten'));
    await tester.pumpAndSettle();
    await leaveRound(tester);
    await tapVisible(tester, 'Runde verlassen');
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
      await tester.scrollUntilVisible(find.text('3 Personen'), -180);
      await tester.pumpAndSettle();
      expect(find.text('3 Personen'), findsOneWidget);
      await showStart(tester);
      await tester.tap(find.text('Runde starten'));
      await tester.pump();
      expect(find.text('Runde wird vorbereitet …'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.scrollUntilVisible(find.byType(TextField), -180);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await tester.scrollUntilVisible(
        find.text('Runde wird vorbereitet …'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Runde wird vorbereitet …'));
      await tester.pump();
      expect(calls, 2);
      pending.complete(testCatalog);
      await tester.pumpAndSettle();
      expect(find.text('Anna'), findsOneWidget);
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
      await tester.pumpWidget(
        MyApp(catalogLoader: () async => multiHintCatalog),
      );
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
      expect(find.text(longName), findsOneWidget);
      expect(find.text('Person 1 von 12'), findsOneWidget);
      await leaveRound(tester);
      await tapVisible(tester, 'Runde verlassen');
      expect(find.text('12 Personen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'distributes exactly one hint, conceals every handoff and ends ready',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await startTestRound(tester);
      var words = 0;
      var hints = 0;
      for (final (index, name) in ['Anna', 'Ben', 'Cem'].indexed) {
        expect(find.text(name), findsOneWidget);
        expect(find.text('Person ${index + 1} von 3'), findsOneWidget);
        expectConcealed(tester);
        await tapVisible(tester, 'Geheimnis kurz ansehen');
        expect(find.text(name), findsOneWidget);
        if (find.text('Du bist der Imposter').evaluate().isNotEmpty) {
          hints++;
          expect(find.text('Dein Hinweis'), findsOneWidget);
          expect(find.text('Kino'), findsOneWidget);
          expect(find.text('Popcorn'), findsNothing);
          expect(semanticsTree(tester), isNot(contains('Popcorn')));
        } else {
          words++;
          expect(find.text('Dein geheimes Wort'), findsOneWidget);
          expect(find.text('Popcorn'), findsOneWidget);
          expect(find.text('Kino'), findsNothing);
        }
        await tapVisible(tester, 'Weiter');
        expectConcealed(tester);
        expect(find.text(name), findsNothing);
      }
      expect(words, 2);
      expect(hints, 1);
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      expect(find.text('Alle Geheimnisse sind verteilt.'), findsOneWidget);
      expect(find.text('Geheimnis kurz ansehen'), findsNothing);
      await tester.pump(const Duration(minutes: 3));
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Weiterspielen');
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'interruptions hide a card and preserve the current person and secret',
    (tester) async {
      final semantics = tester.ensureSemantics();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await startTestRound(tester);
      await tapVisible(tester, 'Geheimnis kurz ansehen');
      await tapVisible(tester, 'Weiter');
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
      ]) {
        await tapVisible(tester, 'Geheimnis kurz ansehen');
        final secret = find.text('Popcorn').evaluate().isNotEmpty
            ? 'Popcorn'
            : 'Kino';
        final staleAction = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .onPressed!;
        tester.binding.handleAppLifecycleStateChanged(state);
        // Background states suspend frames. Verify the next rendered frame on resume.
        staleAction();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(find.text('Ben'), findsOneWidget);
        expectConcealed(tester);
        await tapVisible(tester, 'Geheimnis kurz ansehen');
        expect(find.text(secret), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expectConcealed(tester);
        await tapVisible(tester, 'Weiterspielen');
      }
      expect(find.text('Person 2 von 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'back conceals before dialog; cancellation never restores secrets',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await startTestRound(tester);
      for (final dismissWithBack in [false, true]) {
        await tapVisible(tester, 'Geheimnis kurz ansehen');
        await leaveRound(tester);
        expect(find.text('Runde verlassen?'), findsOneWidget);
        expectConcealed(tester);
        if (dismissWithBack) {
          // System back dismisses only the dialog, not the concealed round.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        } else {
          await tapVisible(tester, 'Weiterspielen');
        }
        expect(find.text('Anna'), findsOneWidget);
        expectConcealed(tester);
      }
      await tapVisible(tester, 'Geheimnis kurz ansehen');
      await leaveRound(tester);
      await tapVisible(tester, 'Runde verlassen');
      expect(find.text('3 Personen'), findsOneWidget);
      await showStart(tester);
      await tapVisible(tester, 'Runde starten');
      expect(find.text('Person 1 von 3'), findsOneWidget);
      expectConcealed(tester);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('stale card actions cannot reveal or skip the next person', (
    tester,
  ) async {
    await startTestRound(tester);
    await tapVisible(tester, 'Geheimnis kurz ansehen');
    final advance = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .onPressed!;
    advance();
    advance();
    await tester.pumpAndSettle();
    expect(find.text('Ben'), findsOneWidget);
    expectConcealed(tester);
    await tester.binding.handlePopRoute();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tapVisible(tester, 'Weiterspielen');
    expect(find.text('Ben'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'private cards, ready and leave dialog fit small screens at 200% text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final catalog = WordCatalog(
        languageCode: 'de',
        pairs: [
          WordPair(
            id: 'long',
            word: 'Donaudampfschifffahrtsgesellschaft',
            hint: 'Eine besonders lange Fahrt auf dem Wasser',
          ),
        ],
      );
      await tester.pumpWidget(MyApp(catalogLoader: () async => catalog));
      await addName(tester, 'AlexandramitbesonderslangemNamen');
      await addName(tester, 'Ben');
      await addName(tester, 'Cem');
      await showStart(tester);
      await tapVisible(tester, 'Runde starten');
      for (var i = 0; i < 3; i++) {
        await tapVisible(tester, 'Geheimnis kurz ansehen');
        expect(tester.takeException(), isNull);
        await tapVisible(tester, 'Weiter');
        expect(tester.takeException(), isNull);
      }
      await leaveRound(tester);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, 'Weiterspielen');
      expect(find.text('Alle eingeweiht?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

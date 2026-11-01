import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart'
    show addName, showStart, tapVisible, semanticsTree, multiHintCatalog;

void main() {
  for (final size in [6, 14]) {
    testWidgets(
      'hidden draw, exact multi-selection and follow-up for $size players',
      (tester) async {
        final semantics = tester.ensureSemantics();
        if (size == 14) {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        var now = DateTime.utc(2026, 11, 1);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpWidget(
          MyApp(catalogLoader: () async => multiHintCatalog, now: () => now),
        );
        final names = List.generate(size, (i) => 'Person ${i + 1}');
        for (final name in names) {
          await addName(tester, name);
        }
        if (size == 14) {
          expect(
            tester.widget<TextField>(find.byType(TextField)).enabled,
            isFalse,
          );
          expect(
            find.text('Eure Gruppe ist mit 14 Personen vollständig.'),
            findsOneWidget,
          );
        }
        await showStart(tester);
        expect(
          find.text(
            size == 6
                ? '1–2 Imposter · 03:00 Minuten'
                : '2–3 Imposter · 07:00 Minuten',
          ),
          findsOneWidget,
        );
        await tapVisible(tester, 'Runde starten');
        final imposters = <String>[];
        final hints = <String>{};
        for (final name in names) {
          expect(find.text(name), findsOneWidget);
          await tapVisible(tester, 'Geheimnis kurz ansehen');
          if (find.text('Du bist ein Imposter').evaluate().isNotEmpty) {
            imposters.add(name);
            final hint = multiHintCatalog.pairs.single.hints.singleWhere(
              (hint) => find.text(hint).evaluate().isNotEmpty,
            );
            expect(hints.add(hint), isTrue);
            for (final other in multiHintCatalog.pairs.single.hints.where(
              (other) => other != hint,
            )) {
              expect(semanticsTree(tester), isNot(contains(other)));
            }
          }
          await tapVisible(tester, 'Weiter');
          for (final secret in [
            'Popcorn',
            ...multiHintCatalog.pairs.single.hints,
            'Du bist ein Imposter',
          ]) {
            expect(semanticsTree(tester), isNot(contains(secret)));
          }
        }
        expect(
          imposters.length,
          size == 6 ? inInclusiveRange(1, 2) : inInclusiveRange(2, 3),
        );
        final time = size == 6 ? '03:00' : '07:00';
        await tapVisible(tester, '$time starten');
        expect(find.text(time), findsOneWidget);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        now = now.add(Duration(seconds: size * 30));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(find.byType(RadioGroup<String>), findsNothing);
        expect(find.text('Wem vertraut ihr nicht?'), findsOneWidget);
        expect(
          find.text(
            'Die Zeit ist um. Für den Gruppensieg müsst ihr alle Imposter und keine andere Person auswählen.',
          ),
          findsOneWidget,
        );

        Future<void> select(String name) async {
          tester
              .widget<CustomScrollView>(find.byType(CustomScrollView))
              .controller!
              .jumpTo(0);
          await tester.pumpAndSettle();
          await tapVisible(tester, name);
        }

        final maximum = size == 6 ? 2 : 3;
        for (final name in names.take(maximum)) {
          await select(name);
        }
        expect(
          tester
              .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, names[maximum - 1]),
              )
              .onChanged,
          isNotNull,
        );
        // A disabled extra person cannot be added, even by tapping their row.
        await select(names[maximum]);
        expect(
          tester
              .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, names[maximum]),
              )
              .onChanged,
          isNull,
        );
        await select(names.first);
        await tester.scrollUntilVisible(
          find.widgetWithText(CheckboxListTile, names[maximum]),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, names[maximum]),
              )
              .onChanged,
          isNotNull,
        );
        for (final name in names.skip(1).take(maximum - 1)) {
          await select(name);
        }

        final innocent = names.firstWhere((name) => !imposters.contains(name));
        await select(innocent);
        final stale = tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, innocent),
            )
            .onChanged!;
        await select(innocent);
        for (final name in imposters) {
          await select(name);
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        stale(
          true,
        ); // An old selection must not change the round under its dialog.
        await tapVisible(tester, 'Weiterspielen');
        final label = imposters.length == 1
            ? '${imposters.single} verdächtigen'
            : '${imposters.length} Personen verdächtigen';
        await tapVisible(tester, label);
        expect(semanticsTree(tester), isNot(contains('Die Imposter waren')));
        expect(semanticsTree(tester), isNot(contains('Popcorn')));
        now = now.add(const Duration(seconds: 3));
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(find.text('Die Gruppe gewinnt.'), findsOneWidget);
        await tapVisible(tester, 'Noch eine Runde');
        expect(find.text('Person 1'), findsOneWidget);
        expect(semanticsTree(tester), isNot(contains('Popcorn')));
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}

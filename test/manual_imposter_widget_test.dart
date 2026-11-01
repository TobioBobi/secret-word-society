import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'widget_test.dart'
    show readyGroup, showStart, tapVisible, testCatalog, semanticsTree;

void main() {
  testWidgets('manual count on small display, semantics and all-imposter win', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();

    var now = DateTime.utc(2026);
    await tester.pumpWidget(
      MyApp(catalogLoader: () async => testCatalog, now: () => now),
    );
    await readyGroup(tester);
    await showStart(tester);
    for (final label in ['1–2', '2', '2–3', '3']) {
      final plus = find.byTooltip('Mehr Imposter');
      await tester.scrollUntilVisible(plus, -140);
      await tester.ensureVisible(plus);
      await tester.pumpAndSettle();
      await tester.tap(plus);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('imposter-count'))).data,
        label,
      );
      expect(semanticsTree(tester), contains('Imposter-Anzahl: $label'));
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(find.text('Automatisch'), findsNothing);
    await tapVisible(tester, 'Runde starten');
    expect(find.byTooltip('Mehr Imposter'), findsNothing);
    for (var i = 0; i < 3; i++) {
      await tapVisible(tester, 'Weiter');
    }
    await tapVisible(tester, '01:30 starten');
    now = now.add(const Duration(seconds: 90));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    for (final name in ['Anna', 'Ben', 'Cem']) {
      await tapVisible(tester, name);
    }
    await tapVisible(tester, '3 Personen verdächtigen');
    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Ihr habt alle Imposter entlarvt.'), findsOneWidget);
    await tapVisible(tester, 'Gruppe bearbeiten');
    await showStart(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('imposter-count')),
      -140,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('imposter-count'))).data,
      '3',
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

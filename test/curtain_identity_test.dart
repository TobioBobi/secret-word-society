import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

import 'support/handoff.dart';
import 'widget_test.dart'
    show addName, showStart, tapVisible, testCatalog, expectConcealed;

void main() {
  for (final large in [false, true]) {
    for (final accessible in [false, true]) {
      testWidgets(
        'central identity stays large and moves with the curtain, large=$large, accessible=$accessible',
        (tester) async {
          tester.view.physicalSize = large
              ? const Size(320, 568)
              : const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = large ? 2 : 1;
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(accessibleNavigation: accessible);
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            MyApp(catalogLoader: () async => testCatalog),
          );
          const names = [
            'Alexandra Maximiliane',
            'Benjamin Konstantin',
            'Charlotte Friederike',
          ];
          for (final name in names) {
            await addName(tester, name);
          }
          await showStart(tester);
          await tapVisible(tester, 'Runde starten');
          final name = handoffName(tester, names);
          final avatar = find.byKey(const ValueKey('curtain-avatar'));
          final panel = tester.getRect(
            find.byKey(const ValueKey('secret-curtain-panel')),
          );
          final image = tester.getRect(avatar);
          final heading = tester.getRect(find.text(name));
          expect(image.center.dx, closeTo(panel.center.dx, 1));
          expect(heading.center.dx, closeTo(panel.center.dx, 1));
          expect(heading.top, greaterThan(image.bottom));
          if (!large) expect(image.width, closeTo(200, 1));
          await tapVisible(tester, 'Geheimnis kurz ansehen');
          final openAvatar = tester.getRect(avatar);
          final openHeading = tester.getRect(find.text(name));
          final button = tester.getRect(find.byType(FilledButton));
          expect(openHeading.bottom, lessThanOrEqualTo(button.top));
          final openPanel = tester.getRect(
            find.byKey(const ValueKey('secret-curtain-panel')),
          );
          expect(button.top, greaterThanOrEqualTo(openPanel.top));
          expect(
            find.text('Verdecken und weitergeben').hitTestable(),
            findsOneWidget,
          );
          expect(
            button.bottom,
            lessThan(
              tester
                  .getRect(
                    find.text('Kino').evaluate().isEmpty
                        ? find.text('Popcorn')
                        : find.text('Kino'),
                  )
                  .top,
            ),
          );
          await tester.pump(const Duration(seconds: 8));
          await tester.pumpAndSettle();
          expectConcealed(tester);
          final closedAvatar = tester.getRect(avatar);
          final closedHeading = tester.getRect(find.text(name));
          expect(closedAvatar.top, greaterThan(openAvatar.top));
          expect(
            closedHeading.top - openHeading.top,
            closeTo(closedAvatar.top - openAvatar.top, 1),
          );
          expect(closedHeading.size, openHeading.size);
          expect(closedHeading.top, greaterThan(closedAvatar.bottom));
          await tapVisible(tester, 'Verdecken und weitergeben');
          expect(handoffName(tester, names), isNot(name));
          semantics.dispose();
        },
      );
    }
  }
}

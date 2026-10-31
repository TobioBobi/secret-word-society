import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/l10n/app_localizations.dart';
import 'package:secret_word_society/ui/party_theme.dart';
import 'package:secret_word_society/ui/secret_curtain.dart';

void main() {
  testWidgets('the painted opening follows the curve across white content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var revealed = false;
    const capture = ValueKey('paint-capture');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPartyTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              height: 400,
              child: StatefulBuilder(
                builder: (context, update) => RepaintBoundary(
                  key: capture,
                  child: SecretCurtain(
                    title: 'Handy an Anna.',
                    name: 'Anna',
                    headingFocus: focus,
                    advanceAction: TextButton(
                      onPressed: () {},
                      child: const Text('Weiter'),
                    ),
                    revealed: revealed,
                    concealRevision: 0,
                    onReveal: (_) => update(() => revealed = true),
                    onConceal: () => update(() => revealed = false),
                    secretBuilder: (_) => const SizedBox(
                      key: ValueKey('white-secret'),
                      height: 120,
                      child: ColoredBox(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<List<List<int>>> samples() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(capture),
      );
      return (await tester.runAsync(() async {
        final bitmap = await boundary.toImage();
        final data = (await bitmap.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final colors = [
          for (final x in [30, 160])
            [
              for (var channel = 0; channel < 4; channel++)
                data.getUint8((320 * 320 + x) * 4 + channel),
            ],
        ];
        bitmap.dispose();
        return colors;
      }))!;
    }

    final grip = find.byKey(const ValueKey('secret-curtain-gesture'));
    final gesture = await tester.startGesture(tester.getCenter(grip));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    final partial = await samples();
    // The higher side already exposes the white underlay while the lower
    // middle of the same curved edge still covers it. A flat clip fails here.
    void expectExposedWhite(List<int> pixel) {
      // The real cover shadow can darken white, but keeps it neutral gray.
      expect(pixel[0], greaterThan(80));
      expect(pixel[1], pixel[0]);
      expect(pixel[2], pixel[0]);
      expect(pixel[3], 255);
    }

    expectExposedWhite(partial[0]);
    expect(partial[1][0], isNot(partial[1][2]));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    expectExposedWhite((await samples())[1]);
    await gesture.up();
    await tester.pump();
    expect(find.byKey(const ValueKey('white-secret')), findsNothing);
    await tester.pumpAndSettle();
  });
}

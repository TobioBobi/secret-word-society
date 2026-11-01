import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secret_word_society/data/word_catalog_loader.dart';
import 'package:secret_word_society/game/word_catalog.dart';
import 'package:secret_word_society/main.dart' as app;
import 'package:secret_word_society/ui/player_avatar.dart';

import '../test/support/tap_when_stable.dart';
import '../test/support/curtain_geometry.dart';

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
int _peekStart = 0;

Future<void> _releasePeek(WidgetTester tester) async {
  final opening = find.byKey(const ValueKey('secret-curtain-opening'));
  final content = find
      .descendant(of: opening, matching: find.byType(Text))
      .last;
  final position = tester.getRect(content);
  final reducedMotion = MediaQuery.disableAnimationsOf(tester.element(opening));
  await _peekGesture!.up();
  _peekGesture = null;
  await tester.pump();
  if (reducedMotion) {
    // CI disables Android animations, so there is intentionally no return frame.
    expect(opening, findsNothing);
  } else {
    expect(opening, findsOneWidget);
    expect(tester.getRect(content), position);
  }
  await _settle(tester);
  expect(opening, findsNothing);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  if (_peekGesture != null) {
    await _releasePeek(tester);
  }
  if (text == 'Geheimnis kurz ansehen') {
    final target = find.byKey(const ValueKey('secret-curtain-gesture'));
    await tester.ensureVisible(target);
    await _settle(tester);
    final area = _peekStart++ % 3;
    final originTarget = switch (area) {
      0 => find.byKey(const ValueKey('curtain-avatar')),
      1 => target,
      _ => find.byKey(const ValueKey('secret-curtain-panel')),
    };
    // The full-height cover can scroll on small viewports. Bring the actual
    // origin into view, not just the lower grip, before starting the pointer.
    await tester.ensureVisible(originTarget);
    await _settle(tester);
    final origin = area == 2
        ? tester.getRect(originTarget).topLeft + const Offset(12, 24)
        : tester.getCenter(originTarget);
    var gripStart = tester.getCenter(target);
    _peekGesture = await tester.startGesture(origin);
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
    final clip = openingBounds(tester);
    expect(clip.top, greaterThan(0));
    expect(clip.height, greaterThan(0));
    if (area != 1) {
      // Starting near the top can demonstrate a partial opening, but cannot
      // reach the stop without leaving the physical screen. Release and
      // re-grab the lower grip rather than injecting off-screen pointers.
      await _releasePeek(tester);
      expect(preview, findsNothing);
      await tester.ensureVisible(target);
      await _settle(tester);
      gripStart = tester.getCenter(target);
      _peekGesture = await tester.startGesture(gripStart);
      await _peekGesture!.moveBy(const Offset(0, -30));
      await tester.pump();
    }
    await _peekGesture!.moveTo(
      Offset(panel.center.dx, panel.top.clamp(0.0, double.infinity) + 32),
    );
    await _settle(tester);
    expect(
      gripStart.dy - tester.getCenter(target).dy,
      lessThan(panel.height * .6),
    );
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
  final reroll = find.byKey(const ValueKey('reroll-player-0'));
  await tester.scrollUntilVisible(reroll, -180, scrollable: _pageScroll);
  await _settle(tester);
  final original = tester
      .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
      .avatar;
  await _tap(tester, reroll);
  final changed = tester
      .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
      .avatar;
  expect(changed.seed, isNot(original.seed));
  await _tap(tester, reroll);
  final selected = tester
      .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
      .avatar;
  expect(selected.seed, isNot(changed.seed));
  await _tapText(tester, 'Runde starten');
  expect(
    tester.widget<PlayerAvatarView>(find.byType(PlayerAvatarView)).avatar,
    same(selected),
  );
  expect(find.text('Anna'), findsOneWidget);
  expect(find.text('Person 1 von 3'), findsOneWidget);
}

Future<void> _leaveRound(WidgetTester tester) async {
  expect(find.text('Gruppe bearbeiten'), findsNothing);
  await tester.binding.handlePopRoute();
  await _settle(tester);
  await _peekGesture?.up();
  _peekGesture = null;
  await _settle(tester);
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
        final firstAvatar = tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView))
            .avatar;
        final catalog = await loadWordCatalog();
        final words = <String>[];
        final hints = <String>[];
        String? imposter;

        for (final (index, name) in _players.indexed) {
          expect(find.text(name), findsOneWidget);
          expect(find.text('Person ${index + 1} von 3'), findsOneWidget);
          _expectConcealed(catalog);
          await _tapText(tester, 'Geheimnis kurz ansehen');
          expect(find.text(name), findsOneWidget);
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
          expect(find.text(name), findsNothing);
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
        await tester.scrollUntilVisible(
          find.text('Gruppe bearbeiten'),
          180,
          scrollable: _pageScroll,
        );
        await tester.ensureVisible(find.text('Gruppe bearbeiten'));
        await _settle(tester);
        expect(find.text('Gruppe bearbeiten').hitTestable(), findsOneWidget);
        if (correct) {
          await _tapText(tester, 'Gruppe bearbeiten');
          expect(find.text('3 Personen'), findsOneWidget);
          await _tapText(tester, 'Ben');
          await tester.enterText(find.byType(TextField).last, 'Benny');
          await _tapText(tester, 'Übernehmen');
          await _tap(tester, find.byTooltip('Cem entfernen'));
          await tester.scrollUntilVisible(
            find.byType(TextField),
            -180,
            scrollable: _pageScroll,
          );
          await tester.ensureVisible(find.byType(TextField));
          await tester.enterText(find.byType(TextField), 'Dora');
          await _tap(tester, find.byTooltip('Name hinzufügen'));
          FocusManager.instance.primaryFocus?.unfocus();
          await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          final keyboardWait = Stopwatch()..start();
          while (tester.view.viewInsets.bottom > 0 &&
              keyboardWait.elapsed < const Duration(seconds: 15)) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(tester.view.viewInsets.bottom, 0);
          await _tapText(tester, 'Runde starten');
        } else {
          await _tapText(tester, 'Noch eine Runde');
        }
        expect(
          tester.widget<PlayerAvatarView>(find.byType(PlayerAvatarView)).avatar,
          same(firstAvatar),
        );
        expect(find.text('Anna'), findsOneWidget);
        expect(find.text('Person 1 von 3'), findsOneWidget);
        _expectConcealed(catalog);
        final nextWords = <String>{};
        final nextHints = <String>[];
        for (var index = 0; index < _players.length; index++) {
          expect(
            find.text((correct ? ['Anna', 'Benny', 'Dora'] : _players)[index]),
            findsOneWidget,
          );
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

  testWidgets('unseen cards can all be skipped without exposing secrets', (
    tester,
  ) async {
    await _launchAndCreateGroup(tester);
    final catalog = await loadWordCatalog();
    for (final name in _players) {
      expect(find.text(name), findsOneWidget);
      expect(find.text('Gruppe bearbeiten'), findsNothing);
      _expectConcealed(catalog);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await _tapText(tester, 'Weiter');
      _expectConcealed(catalog);
    }
    expect(find.text('Alle eingeweiht?'), findsOneWidget);
    expect(find.text('Gruppe bearbeiten'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leave dialog conceals cards, retains group and allows restart', (
    tester,
  ) async {
    await _launchAndCreateGroup(tester);
    final catalog = await loadWordCatalog();
    await _tapText(tester, 'Geheimnis kurz ansehen');
    final firstSecret = _visibleSecret(catalog);

    await _leaveRound(tester);
    expect(find.text('Runde verlassen?'), findsOneWidget);
    _expectConcealed(catalog);
    await _tapText(tester, 'Weiterspielen');
    expect(find.text('Anna'), findsOneWidget);
    _expectConcealed(catalog);
    await _tapText(tester, 'Geheimnis kurz ansehen');
    expect(_visibleSecret(catalog), firstSecret);

    await _tapText(tester, 'Weiter');
    expect(find.text('Ben'), findsOneWidget);
    await _tapText(tester, 'Geheimnis kurz ansehen');
    final secondSecret = _visibleSecret(catalog);
    // At least one of the first two people belongs to the group.
    final previousWord = catalog.pairs
        .singleWhere(
          (pair) => pair.word == firstSecret || pair.word == secondSecret,
        )
        .word;
    await _leaveRound(tester);
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
    expect(find.text('Anna'), findsOneWidget);
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

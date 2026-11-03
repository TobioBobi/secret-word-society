import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:image/image.dart' as img;
import 'package:secret_word_society/game/game_session.dart';
import 'package:secret_word_society/game/player_photo.dart';
import 'package:secret_word_society/l10n/app_localizations.dart';
import 'package:secret_word_society/platform/photo_processing.dart';
import 'package:secret_word_society/ui/photo_editor.dart';
import 'package:secret_word_society/ui/party_theme.dart';
import 'package:secret_word_society/main.dart';
import 'package:secret_word_society/ui/player_avatar.dart';

import 'widget_test.dart' show testCatalog, readyGroup, tapVisible, showStart;

PhotoSource source() {
  final image = img.Image(width: 240, height: 320);
  for (final p in image) {
    p.r = p.x;
    p.g = p.y % 256;
    p.b = (p.x + p.y) % 256;
  }
  return PhotoSource(img.encodeJpg(image), [50, 65, 140, 160], [120, 145], [
    [85, 110],
    [155, 110],
  ]);
}

class DeferredProcessing extends PhotoProcessing {
  final result = Completer<PlayerPhoto>();
  PhotoSource? input;
  PhotoEffect? effect;
  @override
  Future<PlayerPhoto> render(PhotoSource source, PhotoEffect effect) {
    input = source;
    this.effect = effect;
    return result.future;
  }
}

class UnavailableCamera extends CameraPlatform {
  UnavailableCamera(this.denied);
  final bool denied;
  @override
  Future<List<CameraDescription>> availableCameras() async {
    if (denied) throw CameraException('CameraAccessDenied', 'Denied');
    return [];
  }
}

void main() {
  testWidgets(
    'group photo dice immediately creates a preview from the original',
    (tester) async {
      final original = source();
      final photo = PlayerPhoto(
        original,
        renderPhoto((original, PhotoEffect.nose)),
        PhotoEffect.nose,
      );
      final processing = DeferredProcessing();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoEditor(
            name: 'Anna',
            initial: photo,
            processing: processing,
            rerollInitially: true,
          ),
        ),
      );
      expect(processing.input, same(original));
      expect(processing.effect, isNot(photo.effect));
      processing.result.complete(
        PlayerPhoto(original, photo.bytes, processing.effect!),
      );
      await tester.pumpAndSettle();
      expect(find.text('Übernehmen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'accepted photo appears through voting, result and follow-up; removal restores Cutouts',
    (tester) async {
      var now = DateTime.utc(2026);
      final original = source();
      final photo = PlayerPhoto(
        original,
        renderPhoto((original, PhotoEffect.eyes)),
        PhotoEffect.eyes,
      );
      var cancel = false;
      await tester.pumpWidget(
        MyApp(
          catalogLoader: () async => testCatalog,
          now: () => now,
          photoEditorLauncher: (_, _) async => cancel ? null : photo,
        ),
      );
      await readyGroup(tester);
      final button = find.byTooltip('Foto für Anna');
      await tester.scrollUntilVisible(
        button,
        -150,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      final avatar = tester
          .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
          .avatar;
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      cancel = true;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      await showStart(tester);
      await tapVisible(tester, 'Runde starten');
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      for (var i = 0; i < 3; i++) {
        await tapVisible(tester, 'Weiter');
      }
      await tapVisible(tester, '01:30 starten');
      now = now.add(const Duration(seconds: 90));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      await tapVisible(tester, 'Anna');
      await tapVisible(tester, 'Anna verdächtigen');
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is PlayerAvatarView && identical(w.photo, photo),
        ),
        findsWidgets,
      );
      await tapVisible(tester, 'Noch eine Runde');
      expect(
        tester
            .widget<PlayerAvatarView>(find.byType(PlayerAvatarView).first)
            .photo,
        same(photo),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Runde verlassen');
      await tester.scrollUntilVisible(
        find.byTooltip('Foto entfernen'),
        -150,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byTooltip('Foto entfernen'));
      await tester.pumpAndSettle();
      final restored = tester.widget<PlayerAvatarView>(
        find.byType(PlayerAvatarView).first,
      );
      expect(restored.photo, isNull);
      expect(restored.avatar, same(avatar));
      expect(tester.takeException(), isNull);
    },
  );
  for (final denied in [false, true]) {
    testWidgets(
      'missing camera or denied permission remains cancellable: $denied',
      (tester) async {
        final platform = CameraPlatform.instance;
        CameraPlatform.instance = UnavailableCamera(denied);
        addTearDown(() => CameraPlatform.instance = platform);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PhotoEditor(name: 'Anna'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            denied ? 'Kein Kamerazugriff' : 'Keine Frontkamera',
          ),
          findsOneWidget,
        );
        expect(find.text('Abbrechen'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Foto aufnehmen'),
              )
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  test('effects always sample original, are distinct and bounded', () {
    final original = source();
    final before = Uint8List.fromList(original.bytes);
    final results = <String>{};
    for (final effect in PhotoEffect.values) {
      final bytes = renderPhoto((original, effect));
      final image = img.decodeJpg(bytes)!;
      expect((image.width, image.height), (384, 384));
      expect(bytes.length, lessThan(100000));
      expect(renderPhoto((original, effect)), bytes);
      expect(original.bytes, before);
      results.add(bytes.toString());
    }
    expect(results, hasLength(4));
  });

  test('EXIF orientation is baked, mirrored once, metadata removed', () {
    final image = img.Image(width: 100, height: 200);
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: 49,
      y2: 199,
      color: img.ColorRgb8(255, 0, 0),
    );
    img.fillRect(
      image,
      x1: 50,
      y1: 0,
      x2: 99,
      y2: 199,
      color: img.ColorRgb8(0, 0, 255),
    );
    final normal = img.decodeJpg(normalizePhoto(img.encodeJpg(image)))!;
    expect(normal.getPixel(10, 100).b, greaterThan(200));
    image.exif.imageIfd.orientation = 6;
    final rotated = img.decodeJpg(normalizePhoto(img.encodeJpg(image)))!;
    expect((rotated.width, rotated.height), (768, 384));
    expect(rotated.exif.imageIfd.hasOrientation, isFalse);
  });

  test('photo preserves identity and Cutouts through rename and rounds', () {
    final session = GameSession()
      ..addPlayer('Anna')
      ..addPlayer('Ben')
      ..addPlayer('Cem');
    final player = session.players.first;
    final original = source();
    final photo = PlayerPhoto(
      original,
      renderPhoto((original, PhotoEffect.nose)),
      PhotoEffect.nose,
    );
    session.setPhoto(player.id, photo);
    session.renamePlayer(player.id, 'Anni');
    expect(session.players.first.photo, same(photo));
    expect(session.players.first.avatar, same(player.avatar));
    session.startRound(testCatalog);
    expect(session.round!.currentPlayer!.photo, same(photo));
    expect(() => session.setPhoto(player.id, null), throwsStateError);
    while (session.round!.canAdvanceCard) {
      session.hideAndAdvance();
    }
    final now = DateTime.utc(2026);
    session.startDiscussion(now);
    session.advanceTime(now.add(const Duration(minutes: 2)));
    session.selectSuspect(player.id);
    session.confirmSuspect(now);
    session.advanceTime(now.add(const Duration(seconds: 3)));
    expect(session.round!.result!.suspects.single.photo, same(photo));
    session.newRound();
    expect(session.round!.currentPlayer!.photo, same(photo));
    session.returnToGroup();
    session.setPhoto(player.id, null);
    expect(session.players.first.photo, isNull);
    expect(session.players.first.avatar, same(player.avatar));
    session.setPhoto(player.id, photo);
    session.removePlayer(player.id);
    session.addPlayer('Anni');
    expect(session.players.last.photo, isNull);
    expect(GameSession().players, isEmpty);
  });

  for (final interrupt in [false, true]) {
    testWidgets(
      'preview uses original, cancel/interrupt discards pending effect: $interrupt',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final original = source();
        final photo = PlayerPhoto(
          original,
          renderPhoto((original, PhotoEffect.nose)),
          PhotoEffect.nose,
        );
        final processing = DeferredProcessing();
        PlayerPhoto? accepted;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildPartyTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    accepted = await Navigator.push<PlayerPhoto>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoEditor(
                          name: 'Anna',
                          initial: photo,
                          processing: processing,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Effekt würfeln'), 150);
        await tester.tap(find.text('Effekt würfeln'));
        await tester.pump();
        expect(processing.input, same(original));
        expect(processing.effect, isNot(photo.effect));
        if (interrupt) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        } else {
          await tester.scrollUntilVisible(find.text('Abbrechen'), 150);
          await tester.tap(find.text('Abbrechen'));
          await tester.pumpAndSettle();
        }
        processing.result.complete(
          PlayerPhoto(original, photo.bytes, processing.effect!),
        );
        await tester.pumpAndSettle();
        if (interrupt) {
          await tester.scrollUntilVisible(find.text('Große Nase'), -120);
          expect(find.text('Große Nase'), findsOneWidget);
          await tester.scrollUntilVisible(find.text('Übernehmen'), -120);
          await tester.tap(find.text('Übernehmen'));
          await tester.pumpAndSettle();
          expect(accepted, same(photo));
        } else {
          expect(accepted, isNull);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

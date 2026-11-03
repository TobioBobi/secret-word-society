// Standalone release-mode acceptance harness; not a production entrypoint.
// Unlike integration_test, this runs with AOT compilation and R8 enabled.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:secret_word_society/game/player_photo.dart';
import 'package:secret_word_society/platform/photo_processing.dart';

import 'photo_fixture.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: Scaffold(body: Text('Photo release probe'))));
  _probe();
}

Future<void> _probe() async {
  final directory = await Directory.systemTemp.createTemp('photo-release-');
  try {
    if (!kReleaseMode) throw StateError('Probe must run in release mode');
    final input = await File('${directory.path}/capture.jpg')
        .writeAsBytes(base64Decode(photoFixture));
    final processing = PhotoProcessing();
    final source = await processing.prepare(input.path);
    if (await input.exists()) throw StateError('Capture not cleaned');
    for (final effect in PhotoEffect.values) {
      final result = await processing.render(source, effect);
      final image = img.decodeJpg(result.bytes);
      if (image == null || image.width != 384 || image.height != 384) {
        throw StateError('Invalid ${effect.name} output');
      }
    }
    // ignore: avoid_print
    print('PHOTO_RELEASE_PROBE:PASS');
  } catch (error, stack) {
    // ignore: avoid_print
    print('PHOTO_RELEASE_PROBE:FAIL $error\n$stack');
  } finally {
    await directory.delete(recursive: true);
  }
}

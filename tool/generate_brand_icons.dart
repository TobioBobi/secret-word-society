// Run from the repository root: dart run tool/generate_brand_icons.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void save(img.Image image, String path) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
}

void main() {
  final source = img.decodePng(
    File('assets/branding/psst-source.png').readAsBytesSync(),
  )!;
  // The source includes transparent margins. At 90% scale its complete
  // silhouette stays inside Android's central 66/108 safe zone.
  final foreground = img.Image(width: 432, height: 432, numChannels: 4);
  final character = img.copyResize(
    source,
    width: 389,
    height: 389,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(foreground, character, dstX: 21, dstY: 21);
  save(
    foreground,
    'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png',
  );

  // Legacy launchers have no adaptive viewport: use the visible 72/108 area.
  final legacyForeground = img.copyCrop(
    foreground,
    x: 72,
    y: 72,
    width: 288,
    height: 288,
  );
  final legacy = img.Image(width: 288, height: 288, numChannels: 4);
  img.fill(legacy, color: img.ColorRgba8(255, 240, 219, 255));
  img.compositeImage(legacy, legacyForeground);
  for (final entry in {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  }.entries) {
    save(
      img.copyResize(
        legacy,
        width: entry.value,
        height: entry.value,
        interpolation: img.Interpolation.cubic,
      ),
      'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
    );
  }
  save(
    img.copyResize(
      legacy,
      width: 512,
      height: 512,
      interpolation: img.Interpolation.cubic,
    ),
    'assets/branding/app-icon.png',
  );
}

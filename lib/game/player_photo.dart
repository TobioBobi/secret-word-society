import 'dart:typed_data';
import 'dart:math';

enum PhotoEffect {
  nose,
  eyes,
  wide,
  swirl,
  alien,
  cheeks,
  grin,
  egghead,
  squashed,
  asymmetric,
  mini,
  mirror,
  jelly,
  fisheye,
}

/// Drawn once per suggestion, then retained with its rendered image.
final class PhotoVariation {
  const PhotoVariation({this.strength = 1, this.mirrorRight = false});
  factory PhotoVariation.random(Random random) => PhotoVariation(
    strength:
        minimumStrength +
        random.nextDouble() * (maximumStrength - minimumStrength),
    mirrorRight: random.nextBool(),
  );
  static const minimumStrength = .75;
  static const maximumStrength = 1.25;
  final double strength;
  final bool mirrorRight;
}

/// Session-only normalized source and landmark coordinates, in source pixels.
final class PhotoSource {
  const PhotoSource(this.bytes, this.face, this.nose, this.eyes, {this.mouth});
  final Uint8List bytes;
  final List<double> face; // left, top, width, height
  final List<double> nose;
  final List<List<double>> eyes;
  final List<double>? mouth;
  List<double> get mouthCenter => mouth ?? [nose[0], face[1] + face[3] * .76];
}

final class PlayerPhoto {
  const PlayerPhoto(
    this.source,
    this.bytes,
    this.effect, {
    this.variation = const PhotoVariation(),
  });
  final PhotoSource source;
  final Uint8List bytes;
  final PhotoEffect effect;
  final PhotoVariation variation;
}

class PhotoProblem implements Exception {
  const PhotoProblem(this.code);
  final String code;
}

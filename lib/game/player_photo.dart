import 'dart:typed_data';

enum PhotoEffect { nose, eyes, wide, swirl }

/// Session-only normalized source and landmark coordinates, in source pixels.
final class PhotoSource {
  const PhotoSource(this.bytes, this.face, this.nose, this.eyes);
  final Uint8List bytes;
  final List<double> face; // left, top, width, height
  final List<double> nose;
  final List<List<double>> eyes;
}

final class PlayerPhoto {
  const PlayerPhoto(this.source, this.bytes, this.effect);
  final PhotoSource source;
  final Uint8List bytes;
  final PhotoEffect effect;
}

class PhotoProblem implements Exception {
  const PhotoProblem(this.code);
  final String code;
}

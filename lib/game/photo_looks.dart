import 'dart:math';

import 'package:image/image.dart' as img;

import 'player_photo.dart';

// Original procedural artwork: no external graphics, fonts, models or downloads.
// All decorations use one eye-aligned coordinate system AFTER source warping.
void applyPhotoLook(
  img.Image image,
  PhotoSource source,
  PhotoEffect effect,
  PhotoVariation variation,
  int cropX,
  int cropY,
  int cropSide,
) {
  final strength = variation.strength;
  final look = effect == PhotoEffect.discoAlien ? PhotoEffect.green : effect;
  if (look.index >= PhotoEffect.green.index &&
      look.index <= PhotoEffect.comic.index) {
    for (final p in image) {
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      final l = .299 * r + .587 * g + .114 * b;
      final target = switch (look) {
        PhotoEffect.green => [l * .48, l * 1.22 + 20, l * .56],
        PhotoEffect.ice => [l * .65, l * 1.04 + 12, l * 1.24 + 24],
        PhotoEffect.pink => [l * 1.20 + 25, l * .57, l * 1.05 + 15],
        PhotoEffect.mono => List.filled(
          3,
          (l - 128) * (.8 + .2 * strength) + 128,
        ),
        PhotoEffect.sepia => [l * 1.18 + 12, l * .97 + 4, l * .72],
        PhotoEffect.retro => [r * .86 + 30, g * .90 + 15, b * .74 + 26],
        PhotoEffect.sunset => [r * 1.12 + 20, g * .83 + 8, b * .65 + 12],
        _ => [
          ((r / 64).floor() * 64 + 24).toDouble(),
          ((g / 64).floor() * 64 + 24).toDouble(),
          ((b / 64).floor() * 64 + 24).toDouble(),
        ],
      };
      final mix = look == PhotoEffect.mono
          ? 1.0
          : (.8 * strength).clamp(0.0, 1.0);
      p.setRgb(
        (r + (target[0] - r) * mix).clamp(0, 255),
        (g + (target[1] - g) * mix).clamp(0, 255),
        (b + (target[2] - b) * mix).clamp(0, 255),
      );
    }
    if (effect != PhotoEffect.discoAlien) {
      return;
    }
  }

  final art = _FaceArt(image, source, cropX, cropY, cropSide, strength);
  switch (effect) {
    case PhotoEffect.sunglasses:
      art.glasses();
    case PhotoEffect.moustache:
      art.moustache();
    case PhotoEffect.clown:
      art.clown();
    case PhotoEffect.patch:
      art.patch();
    case PhotoEffect.crown:
      art.crown();
    case PhotoEffect.partyHat:
      art.partyHat();
    case PhotoEffect.catEars:
      art.ears(false);
    case PhotoEffect.bunnyEars:
      art.ears(true);
    case PhotoEffect.wizardHat:
      art.wizardHat();
    case PhotoEffect.flower:
      art.flower();
    case PhotoEffect.stars:
      art.frame(0);
    case PhotoEffect.confetti:
      art.frame(1);
    case PhotoEffect.burst:
      art.frame(2);
    case PhotoEffect.pirate:
      art.pirate();
      art.patch();
      art.collar(art.red);
    case PhotoEffect.wizard:
      art.wizardHat();
      art.collar(art.purple);
      art.frame(0);
    case PhotoEffect.astronaut:
      art.astronaut();
    case PhotoEffect.royal:
      art.crown();
      art.collar(art.purple);
    case PhotoEffect.discoAlien:
      art.glasses();
      art.frame(1);
    default:
      break;
  }
}

class _FaceArt {
  _FaceArt(
    this.image,
    PhotoSource source,
    int cropX,
    int cropY,
    int cropSide,
    double strength,
  ) {
    final eyes = [...source.eyes]..sort((a, b) => a[0].compareTo(b[0]));
    angle = atan2(eyes[1][1] - eyes[0][1], eyes[1][0] - eyes[0][0]);
    scale = 384 / cropSide;
    ox = ((eyes[0][0] + eyes[1][0]) / 2 - cropX) * scale;
    oy = ((eyes[0][1] + eyes[1][1]) / 2 - cropY) * scale;
    unit = source.face[2] * scale;
    size = .92 + .08 * strength;
    // Fit tall headwear into the existing photo crop, without zooming the photo
    // out. Only the portion above the forehead is compressed; facial anchors
    // and the rest of the artwork keep their original scale and position.
    headScale =
        ((oy - unit * .30 * cos(angle) - 10 - unit * .65 * sin(angle).abs()) /
                (unit * 1.02 * cos(angle)))
            .clamp(.15, 1.0);
    offsetX = cropX * scale;
    offsetY = cropY * scale;
    nose = local(source.nose);
    mouth = local(source.mouthCenter);
    // Actual eye spacing, including mild perspective, anchors glasses/patch.
    eyeDistance =
        sqrt(
          pow(eyes[1][0] - eyes[0][0], 2) + pow(eyes[1][1] - eyes[0][1], 2),
        ) /
        source.face[2];
  }
  final img.Image image;
  late final double angle, scale, ox, oy, unit, size, eyeDistance, headScale;
  late final List<double> nose, mouth;
  final ink = img.ColorRgb8(37, 21, 53),
      white = img.ColorRgb8(255, 248, 229),
      pink = img.ColorRgb8(255, 88, 168),
      yellow = img.ColorRgb8(255, 218, 63),
      cyan = img.ColorRgb8(65, 226, 233),
      purple = img.ColorRgb8(139, 83, 239),
      red = img.ColorRgb8(242, 65, 78);
  List<double> local(List<double> p) {
    final x = p[0] * scale - (ox), y = p[1] * scale - oy;
    // ox/oy have crop offsets; use differences from the eye midpoint instead.
    return [
      (x - offsetX) * cos(angle) / unit + (y - offsetY) * sin(angle) / unit,
      -(x - offsetX) * sin(angle) / unit + (y - offsetY) * cos(angle) / unit,
    ];
  }

  double offsetX = 0, offsetY = 0;
  img.Point point(double x, double y) {
    final fittedY = y < -.30 ? -.30 + (y + .30) * headScale : y;
    return img.Point(
      (ox + unit * (x * cos(angle) - fittedY * sin(angle))).round(),
      (oy + unit * (x * sin(angle) + fittedY * cos(angle))).round(),
    );
  }

  void polygon(
    List<List<double>> points,
    img.Color color, {
    bool outline = true,
  }) {
    final vertices = points.map((p) => point(p[0], p[1])).toList();
    img.fillPolygon(image, vertices: vertices, color: color);
    if (outline) {
      img.drawPolygon(
        image,
        vertices: vertices,
        color: ink,
        thickness: 3,
        antialias: true,
      );
    }
  }

  void oval(
    double x,
    double y,
    double rx,
    double ry,
    img.Color color, {
    bool outline = true,
  }) => polygon(
    [
      for (var i = 0; i < 48; i++)
        [x + rx * cos(i * pi / 24), y + ry * sin(i * pi / 24)],
    ],
    color,
    outline: outline,
  );
  void line(
    double x,
    double y,
    double xx,
    double yy,
    img.Color color,
    double thickness,
  ) {
    final a = point(x, y), b = point(xx, yy);
    img.drawLine(
      image,
      x1: a.x.toInt(),
      y1: a.y.toInt(),
      x2: b.x.toInt(),
      y2: b.y.toInt(),
      color: color,
      thickness: max(2, unit * thickness),
      antialias: true,
    );
  }

  void star(double x, double y, double radius, img.Color color) => polygon([
    for (var i = 0; i < 10; i++)
      [
        x + sin(i * pi / 5) * radius * (i.isEven ? 1 : .44),
        y - cos(i * pi / 5) * radius * (i.isEven ? 1 : .44),
      ],
  ], color);
  void glasses() {
    final d = eyeDistance / 2;
    line(-d, 0, d, 0, pink, .065);
    for (final x in [-d, d]) {
      oval(x, 0, .23 * size, .17 * size, pink);
      oval(x, 0, .185 * size, .125 * size, ink, outline: false);
      line(x - .1, -.06, x + .04, -.095, cyan, .035);
    }
  }

  void moustache() {
    final x = mouth[0], y = (nose[1] + mouth[1]) / 2;
    for (final side in [-1.0, 1.0]) {
      polygon([
        [x, y],
        [x + side * .12, y - .07],
        [x + side * .27 * size, y - .01],
        [x + side * .39 * size, y - .08],
        [x + side * .31, y + .10],
        [x + side * .12, y + .12],
      ], ink);
    }
  }

  void clown() {
    oval(nose[0], nose[1], .15 * size, .13 * size, red);
    oval(nose[0] - .045, nose[1] - .04, .035, .025, white, outline: false);
  }

  void patch() {
    line(-.53, -.14, .52, .14, ink, .055);
    oval(-eyeDistance / 2, 0, .19 * size, .15 * size, ink);
    star(-eyeDistance / 2, -.01, .065, white);
  }

  void crown() {
    polygon([
      [-.47, -.35],
      [-.52, -.76],
      [-.25, -.58],
      [0, -.91 * size],
      [.25, -.58],
      [.52, -.76],
      [.47, -.35],
    ], yellow);
    line(-.45, -.43, .45, -.43, pink, .05);
    for (final x in [-.28, 0.0, .28]) {
      oval(x, -.52, .045, .06, x == 0 ? cyan : red);
    }
  }

  void partyHat() {
    polygon([
      [-.44, -.35],
      [0, -1.10 * size],
      [.44, -.35],
    ], purple);
    line(-.25, -.65, .25, -.65, pink, .08);
    oval(0, -1.10 * size, .095, .095, yellow);
    for (final x in [-.20, 0.0, .20]) {
      star(x, -.47, .055, cyan);
    }
  }

  void ears(bool bunny) {
    for (final side in [-1.0, 1.0]) {
      if (bunny) {
        oval(side * .35, -.75, .14, .44 * size, white);
        oval(side * .35, -.78, .065, .28 * size, pink, outline: false);
      } else {
        polygon([
          [side * .19, -.38],
          [side * .42, -.95 * size],
          [side * .61, -.31],
        ], purple);
        polygon(
          [
            [side * .30, -.42],
            [side * .42, -.77],
            [side * .51, -.38],
          ],
          pink,
          outline: false,
        );
      }
    }
  }

  void wizardHat() {
    polygon([
      [-.43, -.40],
      [-.10, -1.12 * size],
      [.25, -1.02],
      [.08, -.93],
      [.43, -.40],
    ], purple);
    oval(0, -.39, .60, .09, purple);
    star(-.05, -.72, .12, yellow);
  }

  void flower() {
    final x = .40, y = -.38;
    for (var i = 0; i < 6; i++) {
      oval(
        x + cos(i * pi / 3) * .14,
        y + sin(i * pi / 3) * .14,
        .115 * size,
        .115 * size,
        pink,
      );
    }
    oval(x, y, .095, .095, yellow);
  }

  void pirate() {
    polygon([
      [-.65, -.34],
      [-.60, -.71],
      [-.32, -.65],
      [0, -.94 * size],
      [.32, -.65],
      [.60, -.71],
      [.65, -.34],
    ], ink);
    line(-.61, -.36, .61, -.36, yellow, .045);
    oval(0, -.63, .12, .11, white);
    for (final x in [-.04, .04]) {
      oval(x, -.64, .025, .035, ink, outline: false);
    }
    line(-.16, -.48, .16, -.55, white, .025);
    line(-.16, -.55, .16, -.48, white, .025);
  }

  void collar(img.Color color) {
    final y = mouth[1] + .28;
    polygon([
      [-.74, y + .40],
      [-.48, y],
      [0, y + .20],
      [.48, y],
      [.74, y + .40],
    ], color);
    line(-.48, y, 0, y + .20, yellow, .055);
    line(0, y + .20, .48, y, yellow, .055);
  }

  void astronaut() {
    // Open helmet preserves the actual face and photo background; no segmentation.
    for (var i = 0; i < 100; i++) {
      final t = i * 2 * pi / 100;
      oval(
        cos(t) * .67,
        sin(t) * .81 + .10,
        .055 * size,
        .055 * size,
        white,
        outline: false,
      );
    }
    for (final x in [-.69, .69]) {
      oval(x, .12, .13, .20, cyan);
      oval(x, .12, .055, .11, purple);
    }
    collar(white);
    star(.35, mouth[1] + .52, .09, cyan);
  }

  void frame(int style) {
    // Canvas coordinates keep decorations outside the face and circular avatar.
    final colors = [pink, yellow, cyan, purple];
    for (var i = 0; i < 20; i++) {
      final t = i * pi / 10;
      final x = 192 + cos(t) * 171, y = 192 + sin(t) * 171;
      final color = colors[i % 4];
      final radius =
          (style == 2
              ? 24.0
              : style == 0
              ? 12.0
              : 6.0) *
          size;
      final vertices = [
        for (var j = 0; j < (style == 1 ? 4 : 10); j++)
          img.Point(
            (x +
                    sin(j * 2 * pi / (style == 1 ? 4 : 10)) *
                        radius *
                        (j.isEven || style == 1 ? 1 : .45))
                .round(),
            (y -
                    cos(j * 2 * pi / (style == 1 ? 4 : 10)) *
                        radius *
                        (j.isEven || style == 1 ? 1 : .45))
                .round(),
          ),
      ];
      img.fillPolygon(image, vertices: vertices, color: color);
      if (style != 1) {
        img.drawPolygon(image, vertices: vertices, color: ink, thickness: 2);
      }
    }
  }
}

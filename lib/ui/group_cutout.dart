import 'package:flutter/material.dart';

import 'cutout.dart';
import 'party_theme.dart';

ButtonStyle groupIconStyle({bool primary = false}) =>
    IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      backgroundColor: primary ? PartyColors.lime : PartyColors.background,
      foregroundColor: primary ? PartyColors.background : PartyColors.text,
      disabledBackgroundColor: PartyColors.surface,
      disabledForegroundColor: PartyColors.muted,
      shape: const PaperBorder(),
    ).copyWith(
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused)
              ? (primary ? PartyColors.background : PartyColors.lime)
              : PartyColors.outline,
          width: states.contains(WidgetState.focused) ? 3 : 1,
        ),
      ),
    );

/// Retains InputDecorator's floating-label gap and native error/focus behavior.
class PaperInputBorder extends OutlineInputBorder {
  const PaperInputBorder({super.borderSide});

  @override
  PaperInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) => PaperInputBorder(borderSide: borderSide ?? this.borderSide);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is PaperInputBorder
      ? PaperInputBorder(
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is PaperInputBorder
      ? PaperInputBorder(
          borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        )
      : super.lerpTo(b, t);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      const PaperBorder().getOuterPath(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(borderSide.width));

  @override
  PaperInputBorder scale(double t) =>
      PaperInputBorder(borderSide: borderSide.scale(t));

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) => canvas.drawPath(getOuterPath(rect), paint);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    canvas.save();
    if (gapStart != null && gapExtent > 0 && gapPercentage > 0) {
      final extent = (gapExtent + gapPadding * 2) * gapPercentage;
      final start = textDirection == TextDirection.rtl
          ? rect.width - gapStart - extent + gapPadding
          : gapStart - gapPadding;
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(rect.inflate(borderSide.width)),
          Path()..addRect(
            Rect.fromLTWH(
              start,
              rect.top - borderSide.width,
              extent,
              borderSide.width * 2 + 2,
            ),
          ),
        ),
      );
    }
    PaperBorder(side: borderSide).paint(canvas, rect);
    canvas.restore();
  }
}

/// Scoped to preparation, so the remaining theme tickets keep their own scope.
ThemeData buildGroupCutoutTheme(ThemeData base) => base.copyWith(
  appBarTheme: base.appBarTheme.copyWith(
    backgroundColor: PartyColors.background,
    foregroundColor: PartyColors.text,
    surfaceTintColor: Colors.transparent,
  ),
  inputDecorationTheme: base.inputDecorationTheme.copyWith(
    border: const PaperInputBorder(),
    enabledBorder: const PaperInputBorder(
      borderSide: BorderSide(color: PartyColors.outline),
    ),
    disabledBorder: const PaperInputBorder(
      borderSide: BorderSide(color: PartyColors.outline),
    ),
    focusedBorder: const PaperInputBorder(
      borderSide: BorderSide(color: PartyColors.lime, width: 2),
    ),
    errorBorder: const PaperInputBorder(
      borderSide: BorderSide(color: PartyColors.coral, width: 2),
    ),
    focusedErrorBorder: const PaperInputBorder(
      borderSide: BorderSide(color: PartyColors.coral, width: 3),
    ),
    errorMaxLines: 5,
  ),
  iconButtonTheme: IconButtonThemeData(style: groupIconStyle()),
  textButtonTheme: TextButtonThemeData(
    style: base.textButtonTheme.style?.copyWith(
      shape: const WidgetStatePropertyAll(PaperBorder()),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: base.filledButtonTheme.style?.copyWith(
      shape: const WidgetStatePropertyAll(PaperBorder()),
    ),
  ),
  dialogTheme: base.dialogTheme.copyWith(
    shape: const PaperBorder(side: BorderSide(color: PartyColors.outline)),
    shadowColor: PartyColors.purple,
  ),
);

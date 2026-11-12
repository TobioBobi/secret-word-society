import 'package:flutter/material.dart';

import 'party_theme.dart';

/// Shared paper geometry. Insets leave text clear of every clipped corner.
abstract final class Cutout {
  static const gap = 16.0;
  static const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const shadowOffset = Offset(4, 6);
}

/// A slightly irregular, straight-edged sheet, shared by fills and outlines.
class PaperBorder extends OutlinedBorder {
  const PaperBorder({super.side});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  PaperBorder copyWith({BorderSide? side}) =>
      PaperBorder(side: side ?? this.side);

  @override
  ShapeBorder scale(double t) => PaperBorder(side: side.scale(t));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final corner = (rect.shortestSide * .23).clamp(0.0, 14.0);
    return Path()
      ..moveTo(rect.left + corner, rect.top)
      ..lineTo(rect.right - corner * 1.2, rect.top + 1)
      ..lineTo(rect.right, rect.top + corner)
      ..lineTo(rect.right - 2, rect.bottom - corner)
      ..lineTo(rect.right - corner, rect.bottom - 1)
      ..lineTo(rect.left + corner * .8, rect.bottom)
      ..lineTo(rect.left, rect.bottom - corner)
      ..lineTo(rect.left + 1, rect.top + corner)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(getOuterPath(rect.deflate(side.width / 2)), side.toPaint());
  }
}

enum CutoutActionStyle { primary, secondary, outlined }

/// Native Material buttons retain focus, keyboard and screenreader behavior.
/// Only the paper moves; its hit target and its shadow stay in place.
class CutoutAction extends StatefulWidget {
  const CutoutAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.style = CutoutActionStyle.primary,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final CutoutActionStyle style;

  @override
  State<CutoutAction> createState() => _CutoutActionState();
}

class _CutoutActionState extends State<CutoutAction> {
  final _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outlined = widget.style == CutoutActionStyle.outlined;
    final primary = widget.style == CutoutActionStyle.primary;
    final color = primary ? PartyColors.lime : PartyColors.purple;
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 6),
      child: ValueListenableBuilder<Set<WidgetState>>(
        valueListenable: _states,
        builder: (context, states, _) {
          final pressed = states.contains(WidgetState.pressed);
          final focused = states.contains(WidgetState.focused);
          final disabled = widget.onPressed == null;
          final style = ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(56, 64)),
            padding: const WidgetStatePropertyAll(Cutout.padding),
            textStyle: WidgetStatePropertyAll(
              primary
                  ? PartyTypography.action.copyWith(fontSize: 32)
                  : PartyTypography.action,
            ),
            shape: const WidgetStatePropertyAll(PaperBorder()),
            side: WidgetStatePropertyAll(
              BorderSide(
                color: focused
                    ? (primary ? PartyColors.background : PartyColors.lime)
                    : PartyColors.text,
                width: focused ? 3 : (outlined ? 2 : 0),
                style: focused || outlined
                    ? BorderStyle.solid
                    : BorderStyle.none,
              ),
            ),
            backgroundColor: WidgetStatePropertyAll(
              disabled
                  ? PartyColors.surface
                  : (outlined ? PartyColors.background : color),
            ),
            foregroundColor: WidgetStatePropertyAll(
              disabled
                  ? PartyColors.muted
                  : (primary ? PartyColors.background : PartyColors.text),
            ),
            elevation: const WidgetStatePropertyAll(0),
          );
          final button = primary
              ? FilledButton(
                  onPressed: widget.onPressed,
                  statesController: _states,
                  style: style,
                  child: widget.child,
                )
              : OutlinedButton(
                  onPressed: widget.onPressed,
                  statesController: _states,
                  style: style,
                  child: widget.child,
                );
          return Stack(
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: Cutout.shadowOffset,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: disabled
                          ? PartyColors.outline
                          : (primary
                                ? PartyColors.purple
                                : PartyColors.paperShadow),
                      shape: const PaperBorder(),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: pressed && !MediaQuery.disableAnimationsOf(context)
                    ? Cutout.shadowOffset
                    : Offset.zero,
                transformHitTests: false,
                child: SizedBox(width: double.infinity, child: button),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Silent decorative paper slivers; no image assets or text announcements.
class PaperConfetti extends StatelessWidget {
  const PaperConfetti({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 64,
      height: 44,
      child: Stack(
        children: [
          Transform.rotate(
            angle: -.45,
            child: const SizedBox(
              width: 58,
              height: 12,
              child: ColoredBox(color: PartyColors.lime),
            ),
          ),
          Positioned(
            top: 24,
            left: 12,
            child: Transform.rotate(
              angle: -.2,
              child: const SizedBox(
                width: 48,
                height: 10,
                child: ColoredBox(color: PartyColors.purple),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

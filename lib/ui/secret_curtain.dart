import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'cutout.dart';
import 'handoff_avatar.dart';
import 'handoff_entrances.dart';
import 'party_theme.dart';

/// Keeps gesture and cover progress locally. Private content belongs to the round
/// and stays behind the cover during a normal return. Interruptions and
/// cancellation still remove it immediately.
class SecretCurtain extends StatefulWidget {
  const SecretCurtain({
    super.key,
    required this.title,
    required this.name,
    this.avatar,
    this.recipientPrompt,
    this.entrances,
    this.animateAvatar = false,
    this.hintActive = true,
    required this.onHandoff,
    required this.onInterrupt,
    required this.canAdvance,
    required this.headingFocus,
    required this.revealed,
    required this.concealRevision,
    required this.onReveal,
    required this.onConceal,
    required this.secretBuilder,
  });

  final String title;
  final String name;
  final Widget? avatar;
  final String? recipientPrompt;
  final HandoffEntrances? entrances;
  final bool animateAvatar;
  final bool hintActive;
  final VoidCallback onHandoff;
  final VoidCallback onInterrupt;
  final bool canAdvance;
  final FocusNode headingFocus;
  final bool revealed;
  final int concealRevision;
  // False prepares a visual preview; true confirms enough text was visible.
  final ValueChanged<bool> onReveal;
  final VoidCallback onConceal;
  // Attach the supplied key to the actual word/hint, excluding role and labels.
  final Widget Function(BuildContext context, Key textKey) secretBuilder;

  @override
  State<SecretCurtain> createState() => _SecretCurtainState();
}

class _SecretCurtainState extends State<SecretCurtain>
    with TickerProviderStateMixin {
  late final _cover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  static const _fullyOpenAt = 0.95;
  final _secretTextKey = GlobalKey();
  final _panelKey = GlobalKey();
  late final _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late bool _avatarReady = !widget.animateAvatar || widget.entrances == null;
  bool _hintDismissed = false;
  Timer? _hintTimer;
  // Keep the entrance when concealRevision replaces the gesture subtree.
  final _avatarEntranceKey = GlobalKey();

  Timer? _accessibleTimer;
  double? _lastDragY;
  bool _dragging = false;
  bool _requestedViewed = false;
  bool _returning = false;
  bool _viewed = false;
  bool _accessibleMode = false;
  int? _activePointer;
  int _returnRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHint();
  }

  void _syncHint() {
    final eligible =
        widget.hintActive &&
        _avatarReady &&
        !_hintDismissed &&
        !widget.revealed &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!eligible) {
      _hintTimer?.cancel();
      _hintTimer = null;
      _hint.reset();
    } else {
      _hintTimer ??= Timer(const Duration(seconds: 2), () {
        _hint.forward(from: 0);
        _hintTimer = Timer.periodic(const Duration(seconds: 4), (_) {
          _hint.forward(from: 0);
        });
      });
    }
  }

  void _dismissHint() {
    _hintDismissed = true;
    _syncHint();
  }

  void _avatarCompleted() {
    _avatarReady = true;
    _syncHint();
  }

  @override
  void didUpdateWidget(SecretCurtain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.concealRevision != widget.concealRevision) {
      _returnRevision++;
      _returning = false;
      _accessibleTimer?.cancel();
      _dragging = false;
      _lastDragY = null;
      _requestedViewed = false;
      _viewed = false;
      _activePointer = null;
      _cover.value = 0;
    }
    _syncHint();
  }

  @override
  void dispose() {
    _accessibleTimer?.cancel();
    _hintTimer?.cancel();
    _hint.dispose();
    _cover.dispose();
    super.dispose();
  }

  Future<void> _close({
    bool keepSecretDuringReturn = false,
    bool handoff = false,
  }) async {
    _accessibleTimer?.cancel();
    _dragging = false;
    _lastDragY = null;
    _requestedViewed = false;
    final revision = ++_returnRevision;
    final concealRevision = widget.concealRevision;
    final immediate = MediaQuery.disableAnimationsOf(context);
    final retain =
        keepSecretDuringReturn &&
        !immediate &&
        widget.revealed &&
        _cover.value > 0;
    setState(() => _returning = retain);
    if (!retain) widget.onConceal();
    if (immediate) {
      _cover.value = 0;
      if (handoff) widget.onHandoff();
      return;
    }
    try {
      await _cover.animateBack(0, curve: Curves.easeInOutCubic).orCancel;
    } on TickerCanceled {
      // Re-grabbing, interruption and disposal invalidate this return.
      return;
    }
    if (!mounted ||
        revision != _returnRevision ||
        concealRevision != widget.concealRevision) {
      return;
    }
    if (retain) {
      setState(() => _returning = false);
    }
    if (handoff) {
      widget.onHandoff();
    } else if (retain) {
      widget.onConceal();
    }
  }

  void _accessiblePeek() {
    if (_dragging || _returning) return;
    _dismissHint();
    setState(() => _accessibleMode = true);
    _returnRevision++;
    _returning = false;
    _requestedViewed = true;
    _viewed = true;
    widget.onReveal(true);
    _cover.value = 1;
    _accessibleTimer?.cancel();
    // Allows the role and even a long word to be read, without latching open.
    _accessibleTimer = Timer(
      const Duration(seconds: 8),
      () => unawaited(_close()),
    );
  }

  void _interrupt() {
    _returnRevision++;
    _accessibleTimer?.cancel();
    _dragging = false;
    _returning = false;
    _viewed = false;
    _activePointer = null;
    _cover.value = 0;
    widget.onInterrupt();
  }

  void _startDrag(DragStartDetails details) {
    _dismissHint();
    _returnRevision++;
    setState(() => _returning = false);
    _accessibleTimer?.cancel();
    _cover.stop();
    _dragging = true;
    _lastDragY = details.globalPosition.dy;
    _requestedViewed = false;
    widget.onReveal(false);
  }

  void _updateDrag(DragUpdateDetails details, double travel) {
    if (!_dragging) return;
    final y = details.globalPosition.dy;
    final movement = _lastDragY! - y;
    _lastDragY = y;
    // Global coordinates keep movement 1:1 even while the surface moves.
    _cover.value = (_cover.value + movement / travel).clamp(0.0, 1.0);
    _confirmVisibleText(travel);
    // The first drag frame creates and lays out the private content.
    if (_secretTextKey.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confirmVisibleText(travel);
      });
    }
  }

  void _confirmVisibleText(double travel) {
    if (!_dragging || _requestedViewed) return;
    final text = _secretTextKey.currentContext?.findRenderObject();
    final panel = _panelKey.currentContext?.findRenderObject();
    if (text is! RenderBox || panel is! RenderBox || !text.hasSize) return;
    // Include FittedBox scaling and the paper edge at the rendered text's center,
    // which can sit off-center when a long secret is scaled down.
    final middle = text.localToGlobal(text.size.center(Offset.zero));
    final edgeY = _PaperEdgeClipper.edgeY(
      panel.size,
      panel.globalToLocal(middle).dx,
    );
    final edge =
        panel.localToGlobal(Offset(0, edgeY)).dy - travel * _cover.value;
    if (edge <= middle.dy) {
      _requestedViewed = true;
      _viewed = true;
      widget.onReveal(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final accessible =
            _accessibleMode || MediaQuery.accessibleNavigationOf(context);
        // A little covered space below the secret protects it against a
        // small accidental drag while passing the phone.
        const secretLift = 40.0;
        // Keep the established stop and reachable grip.
        var travel = math.min(
          height * .55,
          160 * MediaQuery.textScalerOf(context).scale(1) + 32,
        );
        if (accessible) {
          // Even a heavily wrapped action must fit on the raised cover.
          final style = FilledButtonTheme.of(context).style;
          final padding =
              (style?.padding?.resolve({}) ?? const EdgeInsets.all(16)).resolve(
                Directionality.of(context),
              );
          final textStyle =
              style?.textStyle?.resolve({}) ?? const TextStyle(fontSize: 17);
          final actionHeight = math.max(
            style?.minimumSize?.resolve({})?.height ?? 56,
            _textSize(
                  context,
                  strings.concealAndHandoff,
                  textStyle,
                  constraints.maxWidth - 48 - padding.horizontal,
                ).height +
                padding.vertical,
          );
          travel = math.min(travel, math.max(0, height - actionHeight - 56));
        }
        final contentTop = height - travel * _fullyOpenAt + 8;
        return Listener(
          key: _panelKey,
          onPointerDown: (event) {
            if (_activePointer != null) return;
            _activePointer = event.pointer;
            if (_returning) {
              _returnRevision++;
              _cover.stop();
              setState(() => _returning = false);
              _dragging = true;
              _lastDragY = event.position.dy;
            }
          },
          onPointerUp: (event) {
            if (_activePointer != event.pointer) return;
            _activePointer = null;
            if (_dragging) {
              unawaited(_close(keepSecretDuringReturn: true, handoff: _viewed));
            }
          },
          onPointerCancel: (_) {
            // Flutter reports cancellation of an accepted drag through onEnd.
            // Conceal here first so it cannot be treated as normal release.
            if (_dragging || _returning) _interrupt();
          },
          child: FocusableActionDetector(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  _accessiblePeek();
                  return null;
                },
              ),
            },
            child: Semantics(
              key: const ValueKey('secret-peek-action'),
              explicitChildNodes: true,
              button: true,
              label: strings.peekSecret,
              value: widget.revealed
                  ? strings.curtainRelease
                  : strings.secretConcealed,
              hint: strings.peekAccessibilityHint,
              onTap: _accessiblePeek,
              child: ClipRect(
                child: SizedBox(
                  key: const ValueKey('secret-curtain-panel'),
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: PartyColors.purple,
                        padding: EdgeInsets.fromLTRB(
                          24,
                          contentTop,
                          24,
                          16 + secretLift,
                        ),
                        child: AnimatedBuilder(
                          animation: _cover,
                          builder: (context, _) =>
                              widget.revealed && _cover.value > 0
                              ? LayoutBuilder(
                                  // The paper cover is the visual mask. A second,
                                  // rectangular clip would hide the text beyond
                                  // the cut edge and conceal otherwise visible text.
                                  builder: (context, space) => ExcludeSemantics(
                                    key: const ValueKey(
                                      'secret-curtain-opening',
                                    ),
                                    excluding:
                                        _returning ||
                                        _cover.value < _fullyOpenAt,
                                    child: Semantics(
                                      liveRegion: true,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.bottomLeft,
                                        child: SizedBox(
                                          // Preserve enlarged type when it fits;
                                          // only actual overflow needs scaling.
                                          width: space.maxWidth,
                                          child: widget.secretBuilder(
                                            context,
                                            _secretTextKey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.expand(),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: Listenable.merge([_cover, _hint]),
                        builder: (context, child) => Transform.translate(
                          key: const ValueKey('secret-curtain-cover'),
                          // Hint motion never changes opening progress or builds
                          // private content; the purple backing stays empty.
                          offset: Offset(
                            0,
                            -travel * _cover.value -
                                12 * math.sin(math.pi * _hint.value),
                          ),
                          child: child,
                        ),
                        child: GestureDetector(
                          // Discard recognizer pointer tracking as well as the visual drag
                          // when a dialog or interruption invalidates the gesture.
                          key: ValueKey(
                            'secret-curtain-drag-surface-${widget.concealRevision}',
                          ),
                          excludeFromSemantics: true,
                          behavior: HitTestBehavior.opaque,
                          dragStartBehavior: DragStartBehavior.down,
                          onVerticalDragStart: _startDrag,
                          onVerticalDragUpdate: (details) =>
                              _updateDrag(details, travel),
                          onVerticalDragEnd: (_) {
                            if (_dragging) {
                              unawaited(
                                _close(
                                  keepSecretDuringReturn: true,
                                  handoff: _viewed,
                                ),
                              );
                            }
                          },
                          onVerticalDragCancel: () {
                            // Losing before a drag starts is not a canceled viewing.
                            if (_dragging) _interrupt();
                          },
                          child: _PaperCover(
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                color: PartyColors.surface,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      24,
                                      16,
                                      24,
                                      accessible ? 40 : 120,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: _identity(
                                            context,
                                            strings,
                                            showPrompt:
                                                widget.recipientPrompt !=
                                                    null ||
                                                !accessible,
                                          ),
                                        ),
                                        if (accessible) ...[
                                          const SizedBox(height: 16),
                                          FilledButton(
                                            style:
                                                FilledButton.styleFrom(
                                                  shape: const PaperBorder(),
                                                  elevation: 0,
                                                ).copyWith(
                                                  side:
                                                      WidgetStateProperty.resolveWith(
                                                        (states) => BorderSide(
                                                          color: PartyColors
                                                              .background,
                                                          width:
                                                              states.contains(
                                                                WidgetState
                                                                    .focused,
                                                              )
                                                              ? 3
                                                              : 0,
                                                        ),
                                                      ),
                                                ),
                                            onPressed:
                                                widget.canAdvance && !_returning
                                                ? () => unawaited(
                                                    _close(
                                                      keepSecretDuringReturn:
                                                          true,
                                                      handoff: true,
                                                    ),
                                                  )
                                                : null,
                                            child: Text(
                                              strings.concealAndHandoff,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!accessible)
                                    Positioned(
                                      key: const ValueKey(
                                        'secret-curtain-gesture',
                                      ),
                                      bottom: 8,
                                      left: 24,
                                      right: 24,
                                      height: 92,
                                      child: ExcludeSemantics(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons
                                                  .keyboard_double_arrow_up_rounded,
                                              size: 24,
                                              color: PartyColors.lime,
                                            ),
                                            const SizedBox(height: 4),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                strings.curtainInstruction,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                      fontSize: 14,
                                                      color: PartyColors.muted,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const DecoratedBox(
                                              decoration: ShapeDecoration(
                                                color: PartyColors.lime,
                                                shape: PaperBorder(),
                                              ),
                                              child: SizedBox(
                                                width: 88,
                                                height: 5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _identity(
    BuildContext context,
    AppLocalizations strings, {
    required bool showPrompt,
  }) => LayoutBuilder(
    builder: (context, space) {
      final promptStyle = Theme.of(context).textTheme.bodyMedium!
          .copyWith(color: PartyColors.muted);
      final promptHeight = showPrompt
          ? 12 +
                _textSize(
                  context,
                  widget.recipientPrompt ?? strings.curtainYourTurn,
                  promptStyle,
                  space.maxWidth,
                ).height
          : 0.0;
      final nameStyle = Theme.of(context).textTheme.headlineLarge!;
      double nameHeight(double size) => _textSize(
        context,
        widget.name,
        nameStyle.copyWith(fontSize: size),
        space.maxWidth,
      ).height;
      // Reserve room for the full name before choosing the avatar size.
      // Keep whole words together when a name has several parts.
      final nameBudget = math.max(
        1.0,
        space.maxHeight - 64 - 16 - promptHeight,
      );
      final words = widget.name.split(RegExp(r'\s+'));
      bool fits(double size) =>
          nameHeight(size) <= nameBudget &&
          (words.length < 2 ||
              words.every(
                (word) =>
                    _textSize(
                      context,
                      word,
                      nameStyle.copyWith(fontSize: size),
                      double.infinity,
                    ).width <=
                    space.maxWidth,
              ));
      var fontSize = 44.0;
      if (!fits(fontSize)) {
        var lower = 1.0;
        var upper = fontSize;
        for (var step = 0; step < 12; step++) {
          final candidate = (lower + upper) / 2;
          if (fits(candidate)) {
            lower = candidate;
          } else {
            upper = candidate;
          }
        }
        fontSize = lower;
      }
      final avatarSize = math.min(
        200.0,
        math.max(
          0.0,
          space.maxHeight - nameHeight(fontSize) - 16 - promptHeight,
        ),
      );
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: space.maxWidth,
              height: avatarSize,
              child: widget.entrances == null
                  ? Center(child: _avatar(avatarSize))
                  : HandoffAvatar(
                      key: _avatarEntranceKey,
                      entrances: widget.entrances!,
                      animate: widget.animateAvatar,
                      onCompleted: _avatarCompleted,
                      child: _avatar(avatarSize),
                    ),
            ),
            if (showPrompt) ...[
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: Text(
                  widget.recipientPrompt ?? strings.curtainYourTurn,
                  textAlign: TextAlign.center,
                  style: promptStyle,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: space.maxWidth,
              child: _heading(context, fontSize: fontSize),
            ),
          ],
        ),
      );
    },
  );

  Widget _avatar(double avatarSize) => Container(
    key: const ValueKey('curtain-avatar'),
    width: avatarSize,
    height: avatarSize,
    decoration: const ShapeDecoration(
      shape: PaperBorder(),
      color: PartyColors.purple,
      shadows: [
        BoxShadow(color: PartyColors.paperShadow, offset: Cutout.shadowOffset),
      ],
    ),
    padding: EdgeInsets.all(avatarSize * .045),
    child:
        widget.avatar ??
        const ExcludeSemantics(
          child: Icon(
            Icons.person_outline_rounded,
            size: 32,
            color: PartyColors.text,
          ),
        ),
  );

  Size _textSize(
    BuildContext context,
    String text,
    TextStyle style,
    double width,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
      locale: Localizations.localeOf(context),
    )..layout(maxWidth: width);
    final size = painter.size;
    painter.dispose();
    return size;
  }

  Widget _heading(BuildContext context, {double fontSize = 44}) => Focus(
    focusNode: widget.headingFocus,
    skipTraversal: true,
    child: Semantics(
      header: true,
      liveRegion: true,
      label: widget.title,
      excludeSemantics: true,
      child: Text(
        widget.name,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge!
            .copyWith(fontSize: fontSize),
      ),
    ),
  );
}

class _PaperCover extends StatelessWidget {
  const _PaperCover({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PhysicalShape(
    clipper: const _PaperEdgeClipper(),
    clipBehavior: Clip.antiAlias,
    color: PartyColors.surface,
    child: CustomPaint(
      foregroundPainter: const _PaperEdgePainter(),
      child: child,
    ),
  );
}

/// The purple paper lip stays inside the mask, so it cannot hide extra text.
class _PaperEdgePainter extends CustomPainter {
  const _PaperEdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (final (index, point) in _PaperEdgeClipper._edge.indexed) {
      if (index == 0) {
        path.moveTo(size.width * point.dx, size.height + point.dy);
      } else {
        path.lineTo(size.width * point.dx, size.height + point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = PartyColors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
  }

  @override
  bool shouldRepaint(_PaperEdgePainter oldDelegate) => false;
}

class _PaperEdgeClipper extends CustomClipper<Path> {
  const _PaperEdgeClipper();

  // A shallow cut-paper edge. Rendering and text eligibility share this line.
  static const _edge = [
    Offset(0, -32),
    Offset(.2, -18),
    Offset(.5, -8),
    Offset(.8, -17),
    Offset(1, -32),
  ];

  static double edgeY(Size size, double x) {
    final t = (x / size.width).clamp(0.0, 1.0);
    for (var i = 1; i < _edge.length; i++) {
      final left = _edge[i - 1];
      final right = _edge[i];
      if (t <= right.dx) {
        final fraction = (t - left.dx) / (right.dx - left.dx);
        return size.height + left.dy + (right.dy - left.dy) * fraction;
      }
    }
    return size.height + _edge.last.dy;
  }

  @override
  Path getClip(Size size) {
    final path = Path();
    for (final point in _edge) {
      path.lineTo(size.width * point.dx, size.height + point.dy);
    }
    return path
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_PaperEdgeClipper oldClipper) => false;
}

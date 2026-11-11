import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
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
  final VoidCallback onHandoff;
  final VoidCallback onInterrupt;
  final bool canAdvance;
  final FocusNode headingFocus;
  final bool revealed;
  final int concealRevision;
  // False prepares a visual preview; true confirms a complete viewing.
  final ValueChanged<bool> onReveal;
  final VoidCallback onConceal;
  final WidgetBuilder secretBuilder;

  @override
  State<SecretCurtain> createState() => _SecretCurtainState();
}

class _SecretCurtainState extends State<SecretCurtain>
    with SingleTickerProviderStateMixin {
  late final _cover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  static const _fullyOpenAt = 0.95;

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
  }

  @override
  void dispose() {
    _accessibleTimer?.cancel();
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
    if (_cover.value >= _fullyOpenAt && !_requestedViewed) {
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
                                  // The curved cover is the visual mask. A second,
                                  // rectangular clip would hide the text beyond
                                  // that curve and make the moving edge look flat.
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
                                          width: space.maxWidth,
                                          child: widget.secretBuilder(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.expand(),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _cover,
                        builder: (context, child) => Transform.translate(
                          key: const ValueKey('secret-curtain-cover'),
                          offset: Offset(0, -travel * _cover.value),
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
                          child: PhysicalShape(
                            clipper: const _SoftEdgeClipper(),
                            clipBehavior: Clip.antiAlias,
                            color: PartyColors.surface,
                            elevation: 8,
                            shadowColor: Colors.black54,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF2D2042),
                                    Color(0xFF231A34),
                                    PartyColors.background,
                                  ],
                                ),
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
                                              decoration: BoxDecoration(
                                                color: PartyColors.lime,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(4),
                                                ),
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
                      entrances: widget.entrances!,
                      animate: widget.animateAvatar,
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
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: PartyColors.purple,
      border: Border.all(
        color: const Color(0xFF423068),
        width: avatarSize * .045,
      ),
    ),
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

class _SoftEdgeClipper extends CustomClipper<Path> {
  const _SoftEdgeClipper();

  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 32)
    ..quadraticBezierTo(
      size.width * .5,
      size.height + 16,
      size.width,
      size.height - 32,
    )
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(_SoftEdgeClipper oldClipper) => false;
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'party_theme.dart';

/// Keeps only the cover animation locally. Private content belongs to the round
/// and is removed immediately on release, cancellation or interruption.
class SecretCurtain extends StatefulWidget {
  const SecretCurtain({
    super.key,
    required this.title,
    required this.name,
    required this.advanceAction,
    required this.headingFocus,
    required this.revealed,
    required this.concealRevision,
    required this.onReveal,
    required this.onConceal,
    required this.secretBuilder,
  });

  final String title;
  final String name;
  final Widget advanceAction;
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

  @override
  void didUpdateWidget(SecretCurtain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.concealRevision != widget.concealRevision) {
      _accessibleTimer?.cancel();
      _dragging = false;
      _lastDragY = null;
      _requestedViewed = false;
      _cover.value = 0;
    }
  }

  @override
  void dispose() {
    _accessibleTimer?.cancel();
    _cover.dispose();
    super.dispose();
  }

  void _close() {
    _accessibleTimer?.cancel();
    _dragging = false;
    _lastDragY = null;
    _requestedViewed = false;
    widget.onConceal();
    if (MediaQuery.disableAnimationsOf(context)) {
      _cover.value = 0;
    } else {
      _cover.animateBack(0, curve: Curves.easeInOutCubic);
    }
  }

  void _accessiblePeek() {
    _requestedViewed = true;
    widget.onReveal(true);
    _cover.value = 1;
    _accessibleTimer?.cancel();
    // Allows the role and even a long word to be read, without latching open.
    _accessibleTimer = Timer(const Duration(seconds: 8), _close);
  }

  void _startDrag(DragStartDetails details) {
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
      widget.onReveal(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        // Only uncover the reading area. Use the same travel for both roles.
        final travel = math.min(
          height * .55,
          160 * MediaQuery.textScalerOf(context).scale(1) + 32,
        );
        final contentTop = height - travel * _fullyOpenAt + 8;
        return FocusableActionDetector(
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
                      padding: EdgeInsets.fromLTRB(24, contentTop, 24, 16),
                      child: AnimatedBuilder(
                        animation: _cover,
                        builder: (context, _) =>
                            widget.revealed && _cover.value > 0
                            ? LayoutBuilder(
                                // The curved cover is the visual mask. A second,
                                // rectangular clip would hide the text beyond
                                // that curve and make the moving edge look flat.
                                builder: (context, space) => ExcludeSemantics(
                                  key: const ValueKey('secret-curtain-opening'),
                                  excluding: _cover.value < _fullyOpenAt,
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
                        onVerticalDragEnd: (_) => _close(),
                        onVerticalDragCancel: () {
                          // A tap on the nested handoff button can win before
                          // a drag starts. Do not invalidate that button's round.
                          if (_dragging) _close();
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
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    16,
                                    24,
                                    120,
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: SizedBox(
                                              width: constraints.maxWidth - 48,
                                              child: _identity(
                                                context,
                                                strings,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: math.min(
                                          constraints.maxWidth - 48,
                                          200 *
                                              MediaQuery.textScalerOf(context)
                                                  .scale(1),
                                        ),
                                        child: widget.advanceAction,
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  key: const ValueKey('secret-curtain-gesture'),
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
                                          child: SizedBox(width: 88, height: 5),
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
        );
      },
    );
  }

  Widget _identity(BuildContext context, AppLocalizations strings) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        key: const ValueKey('curtain-avatar'),
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: PartyColors.purple,
          border: Border.all(color: const Color(0xFF423068), width: 9),
        ),
        child: const ExcludeSemantics(
          child: Icon(
            Icons.person_outline_rounded,
            size: 32,
            color: PartyColors.text,
          ),
        ),
      ),
      const SizedBox(height: 24),
      Focus(
        focusNode: widget.headingFocus,
        skipTraversal: true,
        child: Semantics(
          header: true,
          label: widget.title,
          excludeSemantics: true,
          child: Text(
            widget.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge!
                .copyWith(fontSize: 44),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        strings.curtainYourTurn,
        textAlign: TextAlign.center,
        style: const TextStyle(color: PartyColors.muted),
      ),
    ],
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

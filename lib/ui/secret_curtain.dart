import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'party_card.dart';
import 'party_theme.dart';

/// Keeps only the cover animation locally. Private content belongs to the round
/// and is removed immediately on release, cancellation or interruption.
class SecretCurtain extends StatefulWidget {
  const SecretCurtain({
    super.key,
    required this.revealed,
    required this.concealRevision,
    required this.onReveal,
    required this.onConceal,
    required this.secretBuilder,
  });

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
  static const _handleHeight = 64.0;
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final height = math.min(
      240 * MediaQuery.textScalerOf(context).scale(1),
      math.max(160.0, MediaQuery.sizeOf(context).height / 2),
    );
    final travel = height - _handleHeight;
    final contentTop = height - travel * _fullyOpenAt + 8;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusableActionDetector(
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
            button: true,
            label: strings.peekSecret,
            value: widget.revealed
                ? strings.curtainRelease
                : strings.secretConcealed,
            hint: strings.peekAccessibilityHint,
            onTap: _accessiblePeek,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                key: const ValueKey('secret-curtain-panel'),
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PartyCard(
                      color: PartyColors.purple,
                      outlined: false,
                      padding: EdgeInsets.fromLTRB(24, contentTop, 24, 16),
                      child: AnimatedBuilder(
                        animation: _cover,
                        builder: (context, _) =>
                            widget.revealed && _cover.value > 0
                            ? LayoutBuilder(
                                builder: (context, constraints) => ClipRect(
                                  key: const ValueKey('secret-curtain-opening'),
                                  clipper: _OpeningClipper(
                                    height - travel * _cover.value - contentTop,
                                  ),
                                  child: ExcludeSemantics(
                                    excluding: _cover.value < _fullyOpenAt,
                                    child: Semantics(
                                      liveRegion: true,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          width: constraints.maxWidth,
                                          child: widget.secretBuilder(context),
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
                      animation: _cover,
                      builder: (context, child) => Transform.translate(
                        key: const ValueKey('secret-curtain-cover'),
                        offset: Offset(0, -travel * _cover.value),
                        child: child,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ExcludeSemantics(
                            child: PartyCard(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                16,
                                24,
                                64,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) => FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SizedBox(
                                    width: constraints.maxWidth,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons
                                              .keyboard_double_arrow_up_rounded,
                                          size: 40,
                                          color: PartyColors.lime,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          strings.curtainInstruction,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          strings.curtainRelease,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: PartyColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: _handleHeight,
                            child: GestureDetector(
                              key: const ValueKey('secret-curtain-gesture'),
                              excludeFromSemantics: true,
                              behavior: HitTestBehavior.opaque,
                              dragStartBehavior: DragStartBehavior.down,
                              onVerticalDragStart: (details) {
                                _accessibleTimer?.cancel();
                                _cover.stop();
                                _dragging = true;
                                _lastDragY = details.globalPosition.dy;
                                _requestedViewed = false;
                                widget.onReveal(false);
                              },
                              onVerticalDragUpdate: (details) {
                                if (!_dragging) return;
                                final y = details.globalPosition.dy;
                                final movement = _lastDragY! - y;
                                _lastDragY = y;
                                // A pixel of finger travel moves the cover one pixel.
                                // Global coordinates stay stable as the grip moves.
                                _cover.value =
                                    (_cover.value + movement / travel).clamp(
                                      0.0,
                                      1.0,
                                    );
                                if (_cover.value >= _fullyOpenAt &&
                                    !_requestedViewed) {
                                  _requestedViewed = true;
                                  widget.onReveal(true);
                                }
                              },
                              onVerticalDragEnd: (_) => _close(),
                              onVerticalDragCancel: _close,
                              child: const Center(
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  size: 40,
                                  color: PartyColors.lime,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paint only the portion below the moving cover; fully covered previews are
/// also excluded from semantics independently of their paint clipping.
class _OpeningClipper extends CustomClipper<Rect> {
  const _OpeningClipper(this.top);

  final double top;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, top.clamp(0.0, size.height), size.width, size.height);

  @override
  bool shouldReclip(_OpeningClipper oldClipper) => top != oldClipper.top;
}

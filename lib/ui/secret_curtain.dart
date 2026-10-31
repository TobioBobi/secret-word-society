import 'dart:async';

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
    required this.headingFocus,
    required this.revealed,
    required this.concealRevision,
    required this.onReveal,
    required this.onConceal,
    required this.secretBuilder,
  });

  final String title;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final travel = height - _handleHeight;
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
                                        alignment: Alignment.bottomLeft,
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
                          PhysicalShape(
                            clipper: const _SoftEdgeClipper(),
                            clipBehavior: Clip.antiAlias,
                            color: PartyColors.surface,
                            elevation: 8,
                            shadowColor: Colors.black54,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF38274E),
                                    PartyColors.surface,
                                    Color(0xFF42305C),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  16,
                                  24,
                                  80,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, space) => Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: SizedBox(
                                        width: space.maxWidth,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              key: const ValueKey(
                                                'curtain-avatar',
                                              ),
                                              width: 104,
                                              height: 104,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: PartyColors.purple
                                                    .withValues(alpha: 0.22),
                                                border: Border.all(
                                                  color: PartyColors.outline,
                                                ),
                                              ),
                                              child: const ExcludeSemantics(
                                                child: Icon(
                                                  Icons.person_outline_rounded,
                                                  size: 64,
                                                  color: PartyColors.muted,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Focus(
                                              focusNode: widget.headingFocus,
                                              skipTraversal: true,
                                              child: Semantics(
                                                header: true,
                                                child: Text(
                                                  widget.title,
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineLarge,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              strings.curtainYourTurn,
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
                              child: const ExcludeSemantics(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.keyboard_double_arrow_up_rounded,
                                      size: 24,
                                      color: PartyColors.lime,
                                    ),
                                    SizedBox(height: 2),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: PartyColors.lime,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(4),
                                        ),
                                      ),
                                      child: SizedBox(width: 64, height: 6),
                                    ),
                                  ],
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
        );
      },
    );
  }
}

class _SoftEdgeClipper extends CustomClipper<Path> {
  const _SoftEdgeClipper();

  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 18)
    ..cubicTo(
      size.width * .28,
      size.height - 36,
      size.width * .62,
      size.height + 8,
      size.width,
      size.height - 12,
    )
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(_SoftEdgeClipper oldClipper) => false;
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

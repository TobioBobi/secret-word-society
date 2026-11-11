import 'package:flutter/material.dart';

import 'handoff_entrances.dart';

/// Moves only the picture; its layout slot and the recipient text stay still.
class HandoffAvatar extends StatefulWidget {
  const HandoffAvatar({
    super.key,
    required this.entrances,
    required this.animate,
    required this.child,
  });

  final HandoffEntrances entrances;
  final bool animate;
  final Widget child;

  @override
  State<HandoffAvatar> createState() => _HandoffAvatarState();
}

class _HandoffAvatarState extends State<HandoffAvatar>
    with SingleTickerProviderStateMixin {
  late final _entrance = widget.animate ? widget.entrances.next() : null;
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      if (_entrance != null) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, space) => ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        child: Center(child: widget.child),
        builder: (context, child) {
          final remaining =
              1 - Curves.easeOutCubic.transform(_controller.value);
          final offset = switch (_entrance) {
            HandoffEntrance.left => Offset(-space.maxWidth * remaining, 0),
            HandoffEntrance.right => Offset(space.maxWidth * remaining, 0),
            HandoffEntrance.bottom => Offset(0, space.maxHeight * remaining),
            _ => Offset.zero,
          };
          return Transform.translate(
            offset: offset,
            child: Transform.scale(
              scale: _entrance == HandoffEntrance.grow ? 1 - .8 * remaining : 1,
              child: child,
            ),
          );
        },
      ),
    ),
  );
}

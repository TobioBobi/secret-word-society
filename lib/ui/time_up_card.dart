import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'party_card.dart';
import 'party_theme.dart';

/// A single finite burst, with the same readable card when motion is disabled.
class TimeUpCard extends StatefulWidget {
  const TimeUpCard({super.key, required this.animate});

  final bool animate;

  @override
  State<TimeUpCard> createState() => _TimeUpCardState();
}

class _TimeUpCardState extends State<TimeUpCard>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    value: 1,
  );
  bool _started = false;

  @override
  void didUpdateWidget(TimeUpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate) _controller.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      if (widget.animate) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final burst = math.sin(_controller.value * math.pi).clamp(0.0, 1.0);
        return Transform.scale(
          scale: 1 - 0.04 * burst,
          child: PartyCard(
            color: PartyColors.lime,
            foregroundColor: PartyColors.background,
            outlined: false,
            child: Column(
              children: [
                ExcludeSemantics(
                  child: Transform.rotate(
                    angle:
                        math.sin(_controller.value * math.pi * 4) *
                        0.18 *
                        burst,
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.timeUpTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(strings.votingCard, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import 'party_theme.dart';

/// Shared card surface; content can grow with names and Android's text size.
class PartyCard extends StatelessWidget {
  const PartyCard({
    super.key,
    required this.child,
    this.color = PartyColors.surface,
    this.foregroundColor = PartyColors.text,
    this.outlined = true,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final Color color;
  final Color foregroundColor;
  final bool outlined;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: outlined ? Border.all(color: PartyColors.outline) : null,
    ),
    child: Padding(
      padding: padding,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foregroundColor),
        child: IconTheme.merge(
          data: IconThemeData(color: foregroundColor),
          child: child,
        ),
      ),
    ),
  );
}

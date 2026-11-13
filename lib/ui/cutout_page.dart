import 'package:flutter/material.dart';

import 'party_theme.dart';
import 'group_cutout.dart';

/// Long route titles scroll with the content instead of truncating in a toolbar.
class CutoutPage extends StatelessWidget {
  const CutoutPage({
    super.key,
    required this.title,
    required this.children,
    this.sliverBody,
  });

  final String title;
  final List<Widget> children;
  final Widget? sliverBody;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: PartyColors.background,
      scrolledUnderElevation: 0,
      leading: IconButtonTheme(
        data: IconButtonThemeData(style: groupIconStyle()),
        child: const BackButton(),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        namesRoute: true,
                        child: Text(title, style: PartyTypography.heading),
                      ),
                      const SizedBox(height: 24),
                      ...children,
                    ],
                  ),
                ),
              ),
              if (sliverBody != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: sliverBody!,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

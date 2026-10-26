import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/tap_when_stable.dart';

void main() {
  testWidgets('reacquires a button removed after scrolling and taps once', (
    tester,
  ) async {
    var visible = true;
    var taps = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: [
                        const Spacer(),
                        if (visible)
                          FilledButton(
                            onPressed: () => taps++,
                            child: const Text('Runde starten'),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final remove = Timer(const Duration(milliseconds: 100), () {
      rebuild(() => visible = false);
    });
    final restore = Timer(const Duration(milliseconds: 500), () {
      rebuild(() => visible = true);
    });
    addTearDown(remove.cancel);
    addTearDown(restore.cancel);
    await tapWhenStable(
      tester,
      find.text('Runde starten'),
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}

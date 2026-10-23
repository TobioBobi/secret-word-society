import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

void main() {
  testWidgets('Shows Hello World', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hello, world!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

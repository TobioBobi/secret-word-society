import 'package:flutter_test/flutter_test.dart';
import 'package:secret_word_society/main.dart';

void main() {
  testWidgets('Shows the German placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Hallo, Welt!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

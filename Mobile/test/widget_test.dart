import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  testWidgets('Lumina app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const LuminaApp());

    expect(find.text('LUMINA'), findsOneWidget);
    expect(find.text('Your learning, without the signal.'), findsOneWidget);
  });
}

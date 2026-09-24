import 'package:flutter_test/flutter_test.dart';
import 'package:nutrigrow/main.dart';

void main() {
  testWidgets(
    'App starts successfully',
    (WidgetTester tester) async {

      await tester.pumpWidget(
        const NutriGrowApp(),
      );

      expect(
        find.text('NutriGrow'),
        findsNothing,
      );
    },
  );
}
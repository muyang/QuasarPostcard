import 'package:flutter_test/flutter_test.dart';
import 'package:card_designer/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CardDesignerApp());
    expect(find.byType(CardDesignerApp), findsOneWidget);
  });
}

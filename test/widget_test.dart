import 'package:flutter_test/flutter_test.dart';
import 'package:tavrix_browser/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const TavrixApp());
    expect(find.text('Tavrix Browser'), findsOneWidget);
  });
}

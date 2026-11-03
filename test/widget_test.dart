import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavrix_browser/widgets/address_bar.dart';

void main() {
  testWidgets('address bar shows its placeholder and handles submit',
      (WidgetTester tester) async {
    String? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AddressBar(
          tab: null,
          isBookmarked: false,
          onSubmit: (value) => submitted = value,
          onShowPageInfo: () {},
          onSwipeNext: () {},
          onSwipePrevious: () {},
          onCopy: () {},
          onPasteAndGo: (value) => submitted = value,
          onShare: () {},
          onToggleBookmark: () {},
        ),
      ),
    ));

    expect(find.text('Search or type URL'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'example.com');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();

    expect(submitted, 'example.com');
  });
}

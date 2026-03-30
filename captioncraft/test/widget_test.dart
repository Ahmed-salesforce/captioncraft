import 'package:flutter_test/flutter_test.dart';

import 'package:captioncraft/app.dart';

void main() {
  testWidgets('App boots and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CaptionCraftApp());
    expect(find.text('CaptionCraft'), findsOneWidget);
  });
}

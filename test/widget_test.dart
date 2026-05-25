import 'package:flutter_test/flutter_test.dart';

import 'package:snapdate/main.dart';

void main() {
  testWidgets('SnapDate welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SnapDate'), findsOneWidget);
    expect(find.text('Welcome to SnapDate!'), findsOneWidget);
    expect(find.text('Get Start'), findsOneWidget);
  });
}

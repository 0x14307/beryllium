// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'package:beryllium/main.dart';

void main() {
  testWidgets('Main app renders a device dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Main());

    expect(find.text('Devices'), findsOneWidget);
    expect(find.text('Add device'), findsOneWidget);
    expect(find.byType(FScaffold), findsOneWidget);
    expect(find.byType(FTabs), findsOneWidget);
  });
}

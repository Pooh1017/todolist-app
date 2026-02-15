import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_dolist/settings/settings_page.dart';

void main() {
  testWidgets('SettingsPage shows title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );

    expect(find.text('การตั้งค่า'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/login.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Login(),
    ));
    expect(find.byType(Login), findsOneWidget);
  });
}

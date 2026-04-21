import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_parking_project/frontend/main.dart'; // ✅ SmartParkingApp is here

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const SmartParkingApp());

    // Verify login page loads with key Arabic text
    expect(find.text('مرحبا بك'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
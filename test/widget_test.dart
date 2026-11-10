import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymate/app/moneymate_app.dart';
import 'package:moneymate/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('app shows the themed Hello screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyMateApp()));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('MoneyMate'), findsOneWidget);
    expect(find.text('₹0.00'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('home screen renders at 200% text scale without overflow',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

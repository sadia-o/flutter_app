import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/features/dashboard/widgets/dashboard_alert_card.dart';
import 'package:baitguard/domain/models/dashboard/dashboard_alert_item.dart';
import 'package:baitguard/domain/models/alert_type.dart';
import 'package:baitguard/domain/models/alert_severity.dart';
import 'package:baitguard/domain/models/alert_status.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('DashboardAlertCard', () {
    final testAlerts = [
      DashboardAlertItem(
        id: 'alert_123',
        title: 'Rat detected',
        location: 'Warehouse A',
        timestamp: DateTime.now(),
        type: AlertType.rodent,
        severity: AlertSeverity.critical,
        status: AlertStatus.open,
      ),
    ];

    testWidgets('tapping row calls onAlertTap with stable alert id', (
      WidgetTester tester,
    ) async {
      String? tappedId;

      await tester.pumpWidget(
        buildTestableWidget(
          DashboardAlertCard(
            alerts: testAlerts,
            onSeeAll: () {},
            onAlertTap: (id) => tappedId = id,
          ),
        ),
      );

      // Find the row by text or semantics and tap it
      await tester.tap(find.text('Rat detected'));
      await tester.pumpAndSettle();

      expect(tappedId, 'alert_123');
    });

    testWidgets('row semantics contain useful data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DashboardAlertCard(
            alerts: testAlerts,
            onSeeAll: () {},
            onAlertTap: (id) {},
          ),
        ),
      );

      final semanticsFinder = find.bySemanticsLabel(
        RegExp(r'.*Alert: Rat detected, at Warehouse A.*'),
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });
}

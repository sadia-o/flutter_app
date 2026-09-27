import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/features/dashboard/widgets/activity_chart_card.dart';
import 'package:baitguard/domain/models/dashboard/activity_data_point.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ActivityChartCard', () {
    final testSeries = [
      ActivityDataPoint(
        time: DateTime.now().subtract(const Duration(hours: 24)),
        count: 10,
      ),
      ActivityDataPoint(
        time: DateTime.now().subtract(const Duration(hours: 12)),
        count: 20,
      ),
      ActivityDataPoint(time: DateTime.now(), count: 5),
    ];

    testWidgets('renders chart and detections total correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ActivityChartCard(
            series: testSeries,
            detectionsToday: 42,
            activityChangePercentage: 15.0,
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.text('+15% vs yesterday'), findsOneWidget);
      expect(find.text('0h'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);
    });
  });
}

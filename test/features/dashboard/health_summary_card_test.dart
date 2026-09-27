import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/features/dashboard/widgets/health_summary_card.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('HealthSummaryCard', () {
    testWidgets('displays the supplied score and clamps visually', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const HealthSummaryCard(
            score: 87,
            scoreChange: 3,
            statusMessage: 'ALL SYSTEMS NOMINAL',
            activeStations: 118,
            totalStations: 120,
            attentionStations: 2,
          ),
        ),
      );

      expect(find.text('87'), findsOneWidget);
      expect(find.text('ALL SYSTEMS NOMINAL'), findsOneWidget);
      expect(find.text('+3 pts this week'), findsOneWidget);
      expect(
        find.text('118 of 120 stations online\n2 need attention'),
        findsOneWidget,
      );
    });

    testWidgets(
      'different scores produce different semantics and no hardcoded 87',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const HealthSummaryCard(
              score: 95,
              scoreChange: -1,
              statusMessage: 'SYSTEM DEGRADED',
              activeStations: 100,
              totalStations: 120,
              attentionStations: 20,
            ),
          ),
        );

        expect(find.text('95'), findsOneWidget);
        expect(find.text('87'), findsNothing);
        expect(find.text('SYSTEM DEGRADED'), findsOneWidget);

        final semanticsFinder = find.bySemanticsLabel(
          RegExp(r'System health score: 95.*SYSTEM DEGRADED.*'),
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets('score is clamped between 0 and 100', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const HealthSummaryCard(
            score: 150,
            scoreChange: 0,
            statusMessage: 'OVER 9000',
            activeStations: 1,
            totalStations: 1,
            attentionStations: 0,
          ),
        ),
      );

      expect(find.text('150'), findsNothing);
      expect(find.text('100'), findsOneWidget); // Visually clamped

      final semanticsFinder = find.bySemanticsLabel(
        RegExp(r'System health score: 100.*'),
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });
}

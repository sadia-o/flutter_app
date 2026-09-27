import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/features/dashboard/widgets/facility_map_card.dart';
import 'package:baitguard/domain/models/dashboard/station_map_marker.dart';
import 'package:baitguard/domain/models/dashboard/facility_map_zone.dart';
import 'package:baitguard/domain/models/station_status.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('FacilityMapCard', () {
    final zones = [
      const FacilityMapZone(
        id: 'z1',
        label: 'Zone 1',
        left: 0.1,
        top: 0.1,
        width: 0.4,
        height: 0.4,
        labelX: 0.2,
        labelY: 0.2,
      ),
    ];

    final markers = [
      const StationMapMarker(
        stationId: 'st_1',
        name: 'Station 1',
        normalizedX: 0.5,
        normalizedY: 0.5,
        status: StationStatus.online,
      ),
    ];

    testWidgets(
      'renders map card with markers and labels structurally separate',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(FacilityMapCard(markers: markers, zones: zones)),
        );

        expect(find.text('Live facility map'), findsOneWidget);
        // Semantics for the marker short id
        expect(find.text('1'), findsOneWidget);
      },
    );

    testWidgets('tapping marker triggers onMarkerTap with stationId', (
      WidgetTester tester,
    ) async {
      String? tappedId;

      await tester.pumpWidget(
        buildTestableWidget(
          FacilityMapCard(
            markers: markers,
            zones: zones,
            onMarkerTap: (id) => tappedId = id,
          ),
        ),
      );

      // Find the marker's text or semantics and tap it
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(tappedId, 'st_1');
    });

    testWidgets('marker semantics are descriptive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(FacilityMapCard(markers: markers, zones: zones)),
      );

      final semanticsFinder = find.bySemanticsLabel(
        RegExp(r'.*Station st_1.*online.*'),
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });
}

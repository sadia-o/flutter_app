import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/data/repositories/mock/mock_report_repository.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/features/reports/view_models/reports_view_model.dart';
import 'package:baitguard/app/state/active_facility_controller.dart';
import 'package:baitguard/features/reports/views/reports_screen.dart';

import 'package:baitguard/features/reports/views/widgets/report_ready_modal.dart';

void main() {
  group('ReportsScreen UI', () {
    late MockBaitGuardDataSource dataSource;
    late MockReportRepository repository;
    late ActiveFacilityController facilityController;

    setUp(() {
      dataSource = MockBaitGuardDataSource.seeded();
      repository = MockReportRepository(dataSource);
      facilityController = ActiveFacilityController(
        permittedSiteIds: ['site-1', 'site-2'],
        initialSiteId: 'site-1',
      );
    });

    Widget createWidgetUnderTest(UserRole role) {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: role,
        currentUserId: 'user-1',
      );

      return MaterialApp(
        home: ChangeNotifierProvider<ReportsViewModel>.value(
          value: vm,
          child: const Scaffold(body: ReportsScreen()),
        ),
      );
    }

    testWidgets('15. Report Ready modal uses generated export', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(createWidgetUnderTest(UserRole.admin));
      await tester.pumpAndSettle(); // Wait for data to load

      // Tap generate report
      final generateButtons = find.byIcon(Icons.file_download_outlined);
      expect(generateButtons, findsWidgets);
      await tester.tap(generateButtons.first);
      await tester.pump(); // Start generation
      await tester.pumpAndSettle(); // Finish generation and show modal

      // Verify modal is shown
      expect(find.byType(ReportReadyModal), findsOneWidget);
      expect(find.text('Report Ready'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportReadyModal), findsNothing);
    });

    testWidgets(
      '16. Download action invokes shared toast behavior & 17. Share action invokes shared toast behavior',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(createWidgetUnderTest(UserRole.admin));
        await tester.pumpAndSettle();

        final generateButtons = find.byIcon(Icons.file_download_outlined);
        await tester.tap(generateButtons.first);
        await tester.pumpAndSettle();

        expect(find.byType(ReportReadyModal), findsOneWidget);

        // Tap Download
        await tester.tap(find.text('Download'));
        await tester.pumpAndSettle();

        // Check toast message
        expect(
          find.text(
            'Report download will be available after Firebase integration.',
          ),
          findsOneWidget,
        );

        // Tap Share
        await tester.tap(find.text('Share'));
        await tester.pumpAndSettle();

        // Check toast message
        expect(
          find.text(
            'Report sharing will be available after Firebase integration.',
          ),
          findsWidgets,
        );

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets('18. No Reports SnackBar usage exists', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(createWidgetUnderTest(UserRole.admin));
      await tester.pumpAndSettle();

      final generateButtons = find.byIcon(Icons.file_download_outlined);
      await tester.tap(generateButtons.first);
      await tester.pumpAndSettle();

      // Tap Download to trigger toast
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      // Ensure no standard SnackBar is shown
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}

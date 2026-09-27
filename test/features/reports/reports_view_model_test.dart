import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/domain/models/report_models.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:baitguard/data/repositories/mock/mock_report_repository.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/features/reports/view_models/reports_view_model.dart';
import 'package:baitguard/app/state/active_facility_controller.dart';

void main() {
  group('ReportsViewModel', () {
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

    Future<void> waitForLoad(ReportsViewModel vm) async {
      while (vm.isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    test(
      '1. Provider creates ReportsViewModel correctly & 2. Month data loads',
      () async {
        final vm = ReportsViewModel(
          repository: repository,
          activeFacilityController: facilityController,
          userRole: UserRole.admin,
          currentUserId: 'admin-1',
        );

        expect(vm.isLoading, isTrue);
        await waitForLoad(vm);
        expect(vm.isLoading, isFalse);

        expect(vm.dashboardData, isNotNull);
        expect(vm.selectedPeriod.type, ReportPeriodType.month);
      },
    );

    test('3. Week data loads', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm);

      vm.changePeriodType(ReportPeriodType.week);
      expect(vm.selectedPeriod.type, ReportPeriodType.week);

      await waitForLoad(vm);
      expect(vm.dashboardData, isNotNull);
    });

    test('4. Quarter data loads', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm);

      vm.changePeriodType(ReportPeriodType.quarter);
      expect(vm.selectedPeriod.type, ReportPeriodType.quarter);

      await waitForLoad(vm);
      expect(vm.dashboardData, isNotNull);
    });

    test('5. Year data loads', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm);

      vm.changePeriodType(ReportPeriodType.year);
      expect(vm.selectedPeriod.type, ReportPeriodType.year);

      await waitForLoad(vm);
      expect(vm.dashboardData, isNotNull);
    });

    test('6. Active facility change reloads scoped data', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm);

      // Simulate facility change
      facilityController.selectSite('site-2');
      expect(vm.isLoading, isTrue);

      await waitForLoad(vm);
      expect(vm.isLoading, isFalse);
      expect(vm.dashboardData, isNotNull);
    });

    test('7. Admin can generate all three templates', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm);

      expect(
        vm.permissions.canGenerateTemplate(ReportTemplateType.monthlyActivity),
        isTrue,
      );
      expect(
        vm.permissions.canGenerateTemplate(ReportTemplateType.baitConsumption),
        isTrue,
      );
      expect(
        vm.permissions.canGenerateTemplate(ReportTemplateType.complianceAudit),
        isTrue,
      );
    });

    test('8. Technician cannot generate Compliance Audit', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.technician,
        currentUserId: 'tech-1',
      );
      await waitForLoad(vm);

      expect(
        vm.permissions.canGenerateTemplate(ReportTemplateType.monthlyActivity),
        isTrue,
      );
      expect(
        vm.permissions.canGenerateTemplate(ReportTemplateType.baitConsumption),
        isTrue,
      );
      expect(
        vm.permissions.canGenerateTemplate(ReportTemplateType.complianceAudit),
        isFalse,
      );
    });

    test('9. Viewer cannot generate reports', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.viewer,
        currentUserId: 'viewer-1',
      );
      await waitForLoad(vm);

      expect(
        vm.permissions.canGenerateTemplate(ReportTemplateType.monthlyActivity),
        isFalse,
      );
      expect(
        vm.permissions.canGenerateTemplate(ReportTemplateType.baitConsumption),
        isFalse,
      );
      expect(
        vm.permissions.canGenerateTemplate(ReportTemplateType.complianceAudit),
        isFalse,
      );
    });

    test('10. Duplicate generation requests are blocked', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm);

      // Fire first request
      final future1 = vm.generateReport(ReportTemplateType.monthlyActivity);
      expect(vm.isGenerating, isTrue);

      // Fire second request
      await vm.generateReport(ReportTemplateType.monthlyActivity);

      // Wait for both
      await future1;

      // Wait for background reloads
      await waitForLoad(vm);

      expect(vm.actionSuccessEventId, 1);
    });

    test('11. Successful generation inserts export first', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm);

      final initialCount = vm.dashboardData!.recentExports.length;

      await vm.generateReport(ReportTemplateType.monthlyActivity);
      await waitForLoad(vm);

      expect(vm.dashboardData!.recentExports.length, initialCount + 1);
      expect(
        vm.dashboardData!.recentExports.first.templateType,
        ReportTemplateType.monthlyActivity,
      );
    });

    test(
      '12. Generated exports persist in the shared mock repository',
      () async {
        final vm1 = ReportsViewModel(
          repository: repository,
          activeFacilityController: facilityController,
          userRole: UserRole.admin,
          currentUserId: 'admin-1',
        );
        await waitForLoad(vm1);
        await vm1.generateReport(ReportTemplateType.monthlyActivity);
        await waitForLoad(vm1);

        final vm2 = ReportsViewModel(
          repository: repository,
          activeFacilityController: facilityController,
          userRole: UserRole.admin,
          currentUserId: 'admin-1',
        );
        await waitForLoad(vm2);

        expect(
          vm2.dashboardData!.recentExports.any(
            (e) => e.templateType == ReportTemplateType.monthlyActivity,
          ),
          isTrue,
        );
      },
    );

    test('13. Facility exports remain isolated', () async {
      final vm1 = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm1);

      final initialCount = vm1.dashboardData!.recentExports.length;
      await vm1.generateReport(ReportTemplateType.monthlyActivity);
      await waitForLoad(vm1);

      expect(vm1.dashboardData!.recentExports.length, initialCount + 1);

      facilityController.selectSite('site-2');

      final vm2 = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm2);

      expect(
        vm2.dashboardData!.recentExports.length,
        0, // Assuming site-2 has 0 exports in the seed
      );
    });

    test('14. Dynamic filename is correct', () async {
      final vm = ReportsViewModel(
        repository: repository,
        activeFacilityController: facilityController,
        userRole: UserRole.admin,
        currentUserId: 'admin-1',
      );
      await waitForLoad(vm);

      await vm.generateReport(ReportTemplateType.monthlyActivity);
      await waitForLoad(vm);

      final export = vm.generatedExport!;
      expect(export.fileName, contains('Monthly_Activity_'));
    });
  });
}

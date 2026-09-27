import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/app/state/active_facility_controller.dart';

void main() {
  group('ActiveFacilityController', () {
    test('1. exposes immutable permitted site IDs', () {
      final controller = ActiveFacilityController(
        permittedSiteIds: ['site_1', 'site_2'],
      );
      expect(controller.permittedSiteIds, ['site_1', 'site_2']);
      expect(
        () => (controller.permittedSiteIds as dynamic).add('site_3'),
        throwsUnsupportedError,
      );
    });

    test('2. selects the first permitted site by default', () {
      final controller = ActiveFacilityController(
        permittedSiteIds: ['site_1', 'site_2'],
      );
      expect(controller.selectedSiteId, 'site_1');
      expect(controller.hasSelectedSite, isTrue);
    });

    test('2b. uses provided initialSiteId when permitted', () {
      final controller = ActiveFacilityController(
        permittedSiteIds: ['site_1', 'site_2'],
        initialSiteId: 'site_2',
      );
      expect(controller.selectedSiteId, 'site_2');
    });

    test('2c. ignores initialSiteId when not permitted', () {
      final controller = ActiveFacilityController(
        permittedSiteIds: ['site_1', 'site_2'],
        initialSiteId: 'site_9',
      );
      expect(controller.selectedSiteId, 'site_1');
    });

    test('2d. selectedSiteId is null when no permitted sites', () {
      final controller = ActiveFacilityController(permittedSiteIds: []);
      expect(controller.selectedSiteId, isNull);
      expect(controller.hasSelectedSite, isFalse);
    });

    test('3. rejects unauthorized site IDs', () {
      final controller = ActiveFacilityController(permittedSiteIds: ['site_1']);
      final result = controller.selectSite('site_99');
      expect(result, isFalse);
      expect(controller.selectedSiteId, 'site_1');
    });

    test('4. same-site selection does not notify listeners', () {
      final controller = ActiveFacilityController(
        permittedSiteIds: ['site_1', 'site_2'],
      );
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      final result = controller.selectSite('site_1'); // Already selected
      expect(result, isFalse);
      expect(notifyCount, 0);
    });

    test('5. valid selection notifies listeners exactly once', () {
      final controller = ActiveFacilityController(
        permittedSiteIds: ['site_1', 'site_2'],
      );
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      final result = controller.selectSite('site_2');
      expect(result, isTrue);
      expect(controller.selectedSiteId, 'site_2');
      expect(notifyCount, 1);
    });

    test('isPermitted returns correct values', () {
      final controller = ActiveFacilityController(
        permittedSiteIds: ['site_1', 'site_2'],
      );
      expect(controller.isPermitted('site_1'), isTrue);
      expect(controller.isPermitted('site_99'), isFalse);
    });
  });
}

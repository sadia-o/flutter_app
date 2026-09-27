import 'package:flutter_test/flutter_test.dart';
import 'package:baitguard/data/repositories/mock/mock_baitguard_data_source.dart';
import 'package:baitguard/domain/models/access_request.dart';
import 'package:baitguard/data/repositories/mock/mock_deployment_snapshot.dart';

void main() {
  group('MockBaitGuardDataSource', () {
    test('consecutive access requests receive different deterministic IDs', () {
      final dataSource = MockBaitGuardDataSource(
        deploymentSnapshot: MockDeploymentSnapshot.seeded(),
      );

      final request1 = AccessRequest(
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        company: 'Example Corp',
        phone: '555-0100',
        department: null,
        message: null,
        submittedAt: DateTime.now(),
      );

      final request2 = AccessRequest(
        fullName: 'John Smith',
        email: 'john@example.com',
        company: 'Another Corp',
        phone: '555-0200',
        department: null,
        message: null,
        submittedAt: DateTime.now(),
      );

      dataSource.addAccessRequest(request1);
      dataSource.addAccessRequest(request2);

      final requests = dataSource.accessRequests;
      expect(requests.length, 2);
      expect(requests[0].id, 'req_0001');
      expect(requests[1].id, 'req_0002');
      expect(requests[0].id, isNot(equals(requests[1].id)));
    });

    test('collections are immutable', () {
      final dataSource = MockBaitGuardDataSource.seeded();

      expect(
        () => dataSource.users.add(dataSource.users.first),
        throwsUnsupportedError,
      );
      expect(
        () => dataSource.stations.add(dataSource.stations.first),
        throwsUnsupportedError,
      );
      expect(
        () => dataSource.alerts.add(dataSource.alerts.first),
        throwsUnsupportedError,
      );
      expect(() => dataSource.accessRequests.clear(), throwsUnsupportedError);
    });
  });
}

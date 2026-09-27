import 'package:baitguard/data/repositories/firebase/firestore_access_request_repository.dart';
import 'package:baitguard/domain/models/access_request.dart';
import 'package:baitguard/domain/models/access_request_failure.dart';
import 'package:baitguard/domain/models/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _DocumentWriterFake {
  int calls = 0;
  Map<String, Object?>? document;
  Object? failure;

  Future<void> call(Map<String, Object?> data) async {
    calls++;
    document = data;
    if (failure != null) throw failure!;
  }
}

class _ReviewTransactionFake {
  int calls = 0;
  String? requestId;
  String? reviewerUid;
  Map<String, Object?>? updates;
  Object? failure;

  Future<void> call(
    String requestId,
    String reviewerUid,
    Map<String, Object?> updates,
  ) async {
    calls++;
    this.requestId = requestId;
    this.reviewerUid = reviewerUid;
    this.updates = updates;
    if (failure != null) throw failure!;
  }
}

AccessRequest _request() => AccessRequest(
  fullName: ' John Smith ',
  email: ' Person@Example.COM ',
  company: ' Acme Corporation ',
  phone: ' +1 555 000 0000 ',
  department: ' ',
  message: ' ',
  submittedAt: DateTime(2026),
);

void main() {
  test('creates one document with the exact Spark-compatible schema', () async {
    final writer = _DocumentWriterFake();
    final repository = FirestoreAccessRequestRepository.withWriter(writer.call);

    await repository.submitRequest(_request());

    expect(writer.calls, 1);
    expect(writer.document!.keys.toSet(), {
      'fullName',
      'email',
      'normalizedEmail',
      'company',
      'phone',
      'department',
      'message',
      'status',
      'submittedAt',
      'reviewedBy',
      'reviewedAt',
      'rejectionReason',
    });
    expect(writer.document, containsPair('fullName', 'John Smith'));
    expect(writer.document, containsPair('email', 'person@example.com'));
    expect(
      writer.document,
      containsPair('normalizedEmail', 'person@example.com'),
    );
    expect(writer.document, containsPair('company', 'Acme Corporation'));
    expect(writer.document, containsPair('phone', '+1 555 000 0000'));
    expect(writer.document, containsPair('department', ''));
    expect(writer.document, containsPair('message', ''));
    expect(writer.document, containsPair('status', 'pending'));
    expect(writer.document!['submittedAt'], isA<FieldValue>());
    expect(writer.document!['reviewedBy'], isNull);
    expect(writer.document!['reviewedAt'], isNull);
    expect(writer.document!['rejectionReason'], isNull);
  });

  test(
    'submission performs exactly one create and no preliminary read',
    () async {
      final writer = _DocumentWriterFake();
      final repository = FirestoreAccessRequestRepository.withWriter(
        writer.call,
      );

      await repository.submitRequest(_request());

      // The repository has only a document-writer dependency. It has no query or
      // read dependency that could expose applicant records.
      expect(writer.calls, 1);
    },
  );

  test('document contains no protected or unrelated fields', () async {
    final writer = _DocumentWriterFake();
    final repository = FirestoreAccessRequestRepository.withWriter(writer.call);

    await repository.submitRequest(_request());

    for (final forbidden in [
      'password',
      'uid',
      'role',
      'facilityIds',
      'token',
      'image',
      'storagePath',
    ]) {
      expect(writer.document, isNot(contains(forbidden)));
    }
  });

  final failureMappings = {
    'permission-denied': AccessRequestFailureType.permissionDenied,
    'unavailable': AccessRequestFailureType.unavailable,
    'deadline-exceeded': AccessRequestFailureType.timeout,
    'invalid-argument': AccessRequestFailureType.invalidData,
    'unauthenticated': AccessRequestFailureType.unauthenticated,
    'internal': AccessRequestFailureType.unknown,
  };

  for (final entry in failureMappings.entries) {
    test('${entry.key} maps to ${entry.value.name}', () async {
      final writer = _DocumentWriterFake()
        ..failure = FirebaseException(
          plugin: 'cloud_firestore',
          code: entry.key,
        );
      final repository = FirestoreAccessRequestRepository.withWriter(
        writer.call,
      );

      await expectLater(
        repository.submitRequest(_request()),
        throwsA(
          isA<AccessRequestFailure>().having(
            (failure) => failure.type,
            'type',
            entry.value,
          ),
        ),
      );
    });
  }

  test(
    'pending reader maps IDs, optional values, timestamps, and sorts',
    () async {
      final repository = FirestoreAccessRequestRepository.withDependencies(
        writeDocument: (_) async {},
        readPendingDocuments: () async => [
          AccessRequestDocumentData(
            id: 'without_timestamp',
            data: {
              'fullName': 'No Timestamp',
              'email': 'none@example.com',
              'company': 'Example',
              'phone': '',
              'department': null,
              'message': null,
              'status': 'pending',
              'submittedAt': null,
            },
          ),
          AccessRequestDocumentData(
            id: 'newest',
            data: {
              'fullName': 'Newest User',
              'email': 'new@example.com',
              'company': 'Trinode',
              'phone': '+123456789',
              'department': 'Design',
              'message': 'Please review',
              'status': 'pending',
              'submittedAt': Timestamp.fromDate(DateTime(2026, 6, 22, 12)),
            },
          ),
          AccessRequestDocumentData(
            id: 'older',
            data: {
              'fullName': 'Older User',
              'email': 'old@example.com',
              'company': 'Trinode',
              'phone': '',
              'department': '',
              'message': '',
              'status': 'pending',
              'submittedAt': Timestamp.fromDate(DateTime(2026, 6, 21, 12)),
            },
          ),
        ],
      );

      final records = await repository.getPendingRequests();

      expect(records.map((record) => record.id), [
        'newest',
        'older',
        'without_timestamp',
      ]);
      expect(records.first.request.requestId, 'newest');
      expect(records.last.submittedAt, isNull);
      expect(records.last.request.department, isEmpty);
      expect(records.last.request.message, isEmpty);
    },
  );

  test('malformed pending document maps to invalidData', () async {
    final repository = FirestoreAccessRequestRepository.withDependencies(
      writeDocument: (_) async {},
      readPendingDocuments: () async => [
        const AccessRequestDocumentData(
          id: 'bad',
          data: {
            'fullName': '',
            'email': 'bad@example.com',
            'company': 'Example',
            'status': 'pending',
          },
        ),
      ],
    );

    await expectLater(
      repository.getPendingRequests(),
      throwsA(
        isA<AccessRequestFailure>().having(
          (failure) => failure.type,
          'type',
          AccessRequestFailureType.invalidData,
        ),
      ),
    );
  });

  test('approve writes the exact server-owned review schema', () async {
    final review = _ReviewTransactionFake();
    final repository = FirestoreAccessRequestRepository.withDependencies(
      writeDocument: (_) async {},
      readPendingDocuments: () async => [],
      reviewRequest: review.call,
    );

    await repository.approveRequest(
      requestId: 'request_1',
      reviewerUid: 'admin_uid',
      assignedRole: UserRole.technician,
      assignedFacilityIds: const ['site_1', 'site_2'],
    );

    expect(review.calls, 1);
    expect(review.requestId, 'request_1');
    expect(review.reviewerUid, 'admin_uid');
    expect(review.updates!.keys.toSet(), {
      'status',
      'assignedRole',
      'assignedFacilityIds',
      'approvalSource',
      'reviewedBy',
      'reviewedAt',
      'rejectionReason',
      'activatedAt',
      'activatedUid',
    });
    expect(review.updates, containsPair('status', 'approved'));
    expect(review.updates, containsPair('assignedRole', 'technician'));
    expect(
      review.updates,
      containsPair('assignedFacilityIds', ['site_1', 'site_2']),
    );
    expect(review.updates!['reviewedAt'], isA<FieldValue>());
    expect(review.updates!['activatedAt'], isNull);
    expect(review.updates!['activatedUid'], isNull);
  });

  test('reject writes audit fields and clears approval-owned fields', () async {
    final review = _ReviewTransactionFake();
    final repository = FirestoreAccessRequestRepository.withDependencies(
      writeDocument: (_) async {},
      readPendingDocuments: () async => [],
      reviewRequest: review.call,
    );

    await repository.rejectRequest(
      requestId: 'request_1',
      reviewerUid: 'admin_uid',
      rejectionReason: '  Not eligible  ',
    );

    expect(review.updates, containsPair('status', 'rejected'));
    expect(review.updates, containsPair('rejectionReason', 'Not eligible'));
    expect(review.updates!['reviewedAt'], isA<FieldValue>());
    for (final key in [
      'assignedRole',
      'assignedFacilityIds',
      'approvalSource',
      'activatedAt',
      'activatedUid',
    ]) {
      expect(review.updates![key], isA<FieldValue>());
    }
  });

  test(
    'invalid approval role and empty facilities are rejected locally',
    () async {
      final review = _ReviewTransactionFake();
      final repository = FirestoreAccessRequestRepository.withDependencies(
        writeDocument: (_) async {},
        readPendingDocuments: () async => [],
        reviewRequest: review.call,
      );

      await expectLater(
        repository.approveRequest(
          requestId: 'request_1',
          reviewerUid: 'admin_uid',
          assignedRole: UserRole.admin,
          assignedFacilityIds: const ['site_1'],
        ),
        throwsA(
          isA<AccessRequestFailure>().having(
            (failure) => failure.type,
            'type',
            AccessRequestFailureType.invalidRole,
          ),
        ),
      );
      await expectLater(
        repository.approveRequest(
          requestId: 'request_1',
          reviewerUid: 'admin_uid',
          assignedRole: UserRole.viewer,
          assignedFacilityIds: const [],
        ),
        throwsA(
          isA<AccessRequestFailure>().having(
            (failure) => failure.type,
            'type',
            AccessRequestFailureType.noFacilitySelected,
          ),
        ),
      );
      expect(review.calls, 0);
    },
  );

  test(
    'transaction domain failures remain typed and do not retry locally',
    () async {
      for (final type in [
        AccessRequestFailureType.notFound,
        AccessRequestFailureType.alreadyReviewed,
        AccessRequestFailureType.unauthenticated,
      ]) {
        final review = _ReviewTransactionFake()
          ..failure = AccessRequestFailure(type);
        final repository = FirestoreAccessRequestRepository.withDependencies(
          writeDocument: (_) async {},
          readPendingDocuments: () async => [],
          reviewRequest: review.call,
        );

        await expectLater(
          repository.rejectRequest(
            requestId: 'request_1',
            reviewerUid: 'admin_uid',
            rejectionReason: '',
          ),
          throwsA(
            isA<AccessRequestFailure>().having(
              (failure) => failure.type,
              'type',
              type,
            ),
          ),
        );
        expect(review.calls, 1);
      }
    },
  );
}

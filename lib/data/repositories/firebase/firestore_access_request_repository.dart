import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/access_request.dart';
import '../../../domain/models/access_request_failure.dart';
import '../../../domain/models/access_request_record.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/models/create_admin_invitation_request.dart';
import '../../../domain/repositories/access_request_repository.dart';
import '../../../domain/repositories/admin_invitation_repository.dart';

typedef AccessRequestDocumentWriter =
    Future<void> Function(Map<String, Object?> data);
typedef PendingAccessRequestReader =
    Future<List<AccessRequestDocumentData>> Function();
typedef ReviewRequestTransaction =
    Future<void> Function(
      String requestId,
      String reviewerUid,
      Map<String, Object?> updates,
    );
typedef InvitationConflictReader =
    Future<List<AccessRequestDocumentData>> Function(String normalizedEmail);
typedef CurrentReviewerUidReader = String? Function();

@visibleForTesting
class AccessRequestDocumentData {
  const AccessRequestDocumentData({required this.id, required this.data});

  final String id;
  final Map<String, Object?> data;
}

class FirestoreAccessRequestRepository
    implements AccessRequestRepository, AdminInvitationRepository {
  FirestoreAccessRequestRepository(
    FirebaseFirestore firestore,
    FirebaseAuth firebaseAuth,
  ) : _writeDocument = ((data) async {
        await firestore.collection('accessRequests').add(data);
      }),
      _currentReviewerUid = (() => firebaseAuth.currentUser?.uid),
      _readPendingDocuments = (() async {
        final snapshot = await firestore
            .collection('accessRequests')
            .where('status', isEqualTo: 'pending')
            .orderBy('submittedAt', descending: true)
            .get();
        return snapshot.docs
            .map(
              (document) => AccessRequestDocumentData(
                id: document.id,
                data: document.data(),
              ),
            )
            .toList(growable: false);
      }),
      _readInvitationConflicts = ((normalizedEmail) async {
        final snapshot = await firestore
            .collection('accessRequests')
            .where('normalizedEmail', isEqualTo: normalizedEmail)
            .get();
        return snapshot.docs
            .map(
              (document) => AccessRequestDocumentData(
                id: document.id,
                data: document.data(),
              ),
            )
            .toList(growable: false);
      }),
      _reviewRequest = ((requestId, reviewerUid, updates) async {
        if (firebaseAuth.currentUser?.uid != reviewerUid) {
          throw const AccessRequestFailure(
            AccessRequestFailureType.unauthenticated,
          );
        }
        final reference = firestore.collection('accessRequests').doc(requestId);
        await firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(reference);
          if (!snapshot.exists) {
            throw const AccessRequestFailure(AccessRequestFailureType.notFound);
          }
          if (snapshot.data()?['status'] != 'pending') {
            throw const AccessRequestFailure(
              AccessRequestFailureType.alreadyReviewed,
            );
          }
          transaction.update(reference, updates);
        });
      });

  @visibleForTesting
  FirestoreAccessRequestRepository.withWriter(
    AccessRequestDocumentWriter writeDocument,
  ) : _writeDocument = writeDocument,
      _currentReviewerUid = null,
      _readPendingDocuments = _unsupportedReader,
      _readInvitationConflicts = _unsupportedConflictReader,
      _reviewRequest = _unsupportedReview;

  @visibleForTesting
  FirestoreAccessRequestRepository.withDependencies({
    required AccessRequestDocumentWriter writeDocument,
    required PendingAccessRequestReader readPendingDocuments,
    InvitationConflictReader readInvitationConflicts =
        _unsupportedConflictReader,
    CurrentReviewerUidReader? currentReviewerUid,
    ReviewRequestTransaction reviewRequest = _unsupportedReview,
  }) : _writeDocument = writeDocument,
       _currentReviewerUid = currentReviewerUid,
       _readPendingDocuments = readPendingDocuments,
       _readInvitationConflicts = readInvitationConflicts,
       _reviewRequest = reviewRequest;

  final AccessRequestDocumentWriter _writeDocument;
  final CurrentReviewerUidReader? _currentReviewerUid;
  final PendingAccessRequestReader _readPendingDocuments;
  final InvitationConflictReader _readInvitationConflicts;
  final ReviewRequestTransaction _reviewRequest;

  @override
  Future<AdminInvitationConflict> findInvitationConflict(
    String normalizedEmail,
  ) async {
    final email = normalizedEmail.trim().toLowerCase();
    if (email.isEmpty) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }
    try {
      final documents = await _readInvitationConflicts(email);
      if (documents.any((document) => document.data['status'] == 'pending')) {
        return AdminInvitationConflict.pendingRequest;
      }
      if (documents.any(
        (document) =>
            document.data['status'] == 'approved' &&
            document.data['activatedUid'] == null,
      )) {
        return AdminInvitationConflict.approvedUnused;
      }
      return AdminInvitationConflict.none;
    } on AccessRequestFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AccessRequestFailure(_mapFirebaseFailure(error), error);
    } catch (error) {
      throw AccessRequestFailure(AccessRequestFailureType.unknown, error);
    }
  }

  @override
  Future<void> createAdminInvitation(
    CreateAdminInvitationRequest request,
  ) async {
    final authenticatedUid = _currentReviewerUid?.call();
    if (_currentReviewerUid != null &&
        (authenticatedUid == null || authenticatedUid != request.reviewerUid)) {
      throw const AccessRequestFailure(
        AccessRequestFailureType.unauthenticated,
      );
    }
    final facilities = request.facilityIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (request.role == UserRole.admin) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidRole);
    }
    if (facilities.isEmpty || facilities.length > 20) {
      throw const AccessRequestFailure(
        AccessRequestFailureType.noFacilitySelected,
      );
    }
    final email = request.email.trim().toLowerCase();
    try {
      await _writeDocument(<String, Object?>{
        'fullName': request.fullName.trim(),
        'email': email,
        'normalizedEmail': email,
        'company': request.company.trim(),
        'phone': request.phone.trim(),
        'department': request.department.trim(),
        'message': '',
        'status': 'approved',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedBy': request.reviewerUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
        'assignedRole': request.role.name,
        'assignedFacilityIds': facilities,
        'approvalSource': 'admin',
        'activatedUid': null,
        'activatedAt': null,
      });
    } on FirebaseException catch (error) {
      throw AccessRequestFailure(_mapFirebaseFailure(error), error);
    } catch (error) {
      throw AccessRequestFailure(AccessRequestFailureType.unknown, error);
    }
  }

  @override
  Future<void> submitRequest(AccessRequest request) async {
    final normalizedEmail = request.normalizedEmail;
    if (normalizedEmail.isEmpty) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }

    final document = <String, Object?>{
      'fullName': request.fullName.trim(),
      'email': normalizedEmail,
      'normalizedEmail': normalizedEmail,
      'company': request.company.trim(),
      'phone': request.phone.trim(),
      'department': request.department.trim(),
      'message': request.message.trim(),
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedBy': null,
      'reviewedAt': null,
      'rejectionReason': null,
    };

    try {
      // Create only: there is deliberately no unauthenticated read or query.
      await _writeDocument(document);
    } on FirebaseException catch (error) {
      final type = switch (error.code) {
        'permission-denied' => AccessRequestFailureType.permissionDenied,
        'unavailable' => AccessRequestFailureType.unavailable,
        'deadline-exceeded' => AccessRequestFailureType.timeout,
        'invalid-argument' => AccessRequestFailureType.invalidData,
        'unauthenticated' => AccessRequestFailureType.unauthenticated,
        _ => AccessRequestFailureType.unknown,
      };
      throw AccessRequestFailure(type, error);
    } catch (error) {
      throw AccessRequestFailure(AccessRequestFailureType.unknown, error);
    }
  }

  @override
  Future<List<AccessRequestRecord>> getPendingRequests({String? siteId}) async {
    try {
      final documents = await _readPendingDocuments();
      final requests = documents.map(mapPendingDocument).toList();
      requests.sort((left, right) {
        final leftTime = left.submittedAt;
        final rightTime = right.submittedAt;
        if (leftTime == null && rightTime == null) return 0;
        if (leftTime == null) return 1;
        if (rightTime == null) return -1;
        return rightTime.compareTo(leftTime);
      });
      return List.unmodifiable(requests);
    } on AccessRequestFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AccessRequestFailure(_mapFirebaseFailure(error), error);
    } catch (error) {
      throw AccessRequestFailure(AccessRequestFailureType.unknown, error);
    }
  }

  @override
  Future<void> approveRequest({
    required String requestId,
    required String reviewerUid,
    required UserRole assignedRole,
    required List<String> assignedFacilityIds,
  }) async {
    if (assignedRole == UserRole.admin) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidRole);
    }
    final facilities = assignedFacilityIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (facilities.isEmpty) {
      throw const AccessRequestFailure(
        AccessRequestFailureType.noFacilitySelected,
      );
    }
    await _runReview(requestId, reviewerUid, <String, Object?>{
      'status': 'approved',
      'assignedRole': assignedRole.name,
      'assignedFacilityIds': facilities,
      'approvalSource': 'request',
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': null,
      'activatedAt': null,
      'activatedUid': null,
    });
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String reviewerUid,
    required String rejectionReason,
  }) async {
    final reason = rejectionReason.trim();
    if (reason.length > 300) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }
    await _runReview(requestId, reviewerUid, <String, Object?>{
      'status': 'rejected',
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
      'assignedRole': FieldValue.delete(),
      'assignedFacilityIds': FieldValue.delete(),
      'approvalSource': FieldValue.delete(),
      'activatedAt': FieldValue.delete(),
      'activatedUid': FieldValue.delete(),
    });
  }

  Future<void> _runReview(
    String requestId,
    String reviewerUid,
    Map<String, Object?> updates,
  ) async {
    if (requestId.trim().isEmpty || reviewerUid.trim().isEmpty) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }
    try {
      await _reviewRequest(requestId, reviewerUid, updates);
    } on AccessRequestFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AccessRequestFailure(_mapFirebaseFailure(error), error);
    } catch (error) {
      throw AccessRequestFailure(AccessRequestFailureType.unknown, error);
    }
  }

  @visibleForTesting
  static AccessRequestRecord mapPendingDocument(
    AccessRequestDocumentData document,
  ) {
    final data = document.data;
    final fullName = _requiredString(data['fullName']);
    final email = _requiredString(data['email']).toLowerCase();
    final company = _requiredString(data['company']);
    final statusValue = _requiredString(data['status']).toLowerCase();
    if (document.id.isEmpty || statusValue != 'pending') {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }

    final submittedValue = data['submittedAt'];
    if (submittedValue != null && submittedValue is! Timestamp) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }

    final request = AccessRequest(
      requestId: document.id,
      fullName: fullName,
      email: email,
      company: company,
      phone: _optionalString(data['phone']),
      department: _optionalString(data['department']),
      message: _optionalString(data['message']),
      status: AccessRequestStatus.pending,
      submittedAt: (submittedValue as Timestamp?)?.toDate(),
      reviewedBy: _nullableString(data['reviewedBy']),
      reviewedAt: _optionalTimestamp(data['reviewedAt']),
      rejectionReason: _nullableString(data['rejectionReason']),
      assignedRole: _nullableString(data['assignedRole']),
      assignedFacilityIds: _optionalStringList(data['assignedFacilityIds']),
      approvalSource: _nullableString(data['approvalSource']),
      activatedAt: _optionalTimestamp(data['activatedAt']),
      activatedUid: _nullableString(data['activatedUid']),
    );
    return AccessRequestRecord(
      id: document.id,
      request: request,
      status: AccessRequestStatus.pending,
    );
  }

  static String _requiredString(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }
    return value.trim();
  }

  static String _optionalString(Object? value) {
    if (value == null) return '';
    if (value is! String) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }
    return value.trim();
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _optionalTimestamp(Object? value) {
    if (value == null) return null;
    if (value is! Timestamp) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }
    return value.toDate();
  }

  static List<String> _optionalStringList(Object? value) {
    if (value == null) return const [];
    if (value is! List || value.any((item) => item is! String)) {
      throw const AccessRequestFailure(AccessRequestFailureType.invalidData);
    }
    return value.cast<String>().toList(growable: false);
  }

  static AccessRequestFailureType _mapFirebaseFailure(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' => AccessRequestFailureType.permissionDenied,
      'unauthenticated' => AccessRequestFailureType.unauthenticated,
      'unavailable' => AccessRequestFailureType.unavailable,
      'deadline-exceeded' => AccessRequestFailureType.timeout,
      'failed-precondition' => AccessRequestFailureType.missingIndex,
      'invalid-argument' => AccessRequestFailureType.invalidData,
      'not-found' => AccessRequestFailureType.notFound,
      _ => AccessRequestFailureType.unknown,
    };
  }

  static Future<List<AccessRequestDocumentData>> _unsupportedReader() {
    throw UnsupportedError('A pending-request reader was not configured.');
  }

  static Future<void> _unsupportedReview(
    String requestId,
    String reviewerUid,
    Map<String, Object?> updates,
  ) {
    throw UnsupportedError('A review transaction was not configured.');
  }

  static Future<List<AccessRequestDocumentData>> _unsupportedConflictReader(
    String normalizedEmail,
  ) {
    throw UnsupportedError('An invitation conflict reader was not configured.');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/app_user.dart';
import '../../../domain/models/manage_user_access_request.dart';
import '../../../domain/models/user_profile_failure.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  FirestoreUserRepository(this._firestore, this._firebaseAuth);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<AppUser?> getUserById(String id) async {
    try {
      _debug('firestore_profile_read:start uid=$id');
      final document = await _users.doc(id).get();
      if (!document.exists) {
        _debug('firestore_profile_read:missing uid=$id');
        return null;
      }
      final profile = mapProfile(id, document.data());
      _debug('firestore_profile_parse:success uid=$id');
      return profile;
    } on UserProfileFailure catch (failure) {
      _debug(
        'firestore_profile_parse:failure '
        'type=${failure.type.name} uid=$id',
      );
      rethrow;
    } on FirebaseException catch (error) {
      final type = _mapFirestoreFailure(error.code);
      _debug(
        'firestore_profile_read:failure code=${error.code} '
        'type=${type.name} uid=$id',
      );
      throw UserProfileFailure(type, error);
    }
  }

  @override
  Future<List<AppUser>> getUsers() async {
    try {
      final snapshot = await _users.get();
      return snapshot.docs
          .map((document) => mapProfile(document.id, document.data()))
          .toList(growable: false);
    } on UserProfileFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw UserProfileFailure(_mapFirestoreFailure(error.code), error);
    }
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    return updateOwnProfile(
      uid: user.id,
      firstName: user.firstName ?? _firstNameFrom(user.name),
      lastName: user.lastName ?? _lastNameFrom(user.name),
      jobTitle: user.jobTitle ?? '',
      department: user.department ?? '',
      phone: user.phoneNumber ?? '',
      bio: user.shortBio ?? '',
    );
  }

  @override
  Future<AppUser> updateOwnProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required String department,
    required String phone,
    required String bio,
  }) async {
    if (_firebaseAuth.currentUser?.uid != uid) {
      throw const UserProfileFailure(UserProfileFailureType.unauthenticated);
    }

    try {
      final reference = _users.doc(uid);
      await reference.update(
        buildOwnProfileUpdate(
          firstName: firstName,
          lastName: lastName,
          jobTitle: jobTitle,
          department: department,
          phone: phone,
          bio: bio,
          updatedAt: FieldValue.serverTimestamp(),
        ),
      );
      final refreshed = await reference.get();
      if (!refreshed.exists) {
        throw const UserProfileFailure(UserProfileFailureType.missing);
      }
      return mapProfile(uid, refreshed.data());
    } on UserProfileFailure {
      rethrow;
    } on FirebaseException catch (error) {
      final type = switch (error.code) {
        'not-found' => UserProfileFailureType.missing,
        'permission-denied' => UserProfileFailureType.permissionDenied,
        _ => UserProfileFailureType.unavailable,
      };
      throw UserProfileFailure(type, error);
    }
  }

  @override
  Future<AppUser> updateManagedUserAccess(
    ManageUserAccessRequest request,
  ) async {
    final authenticatedUid = _firebaseAuth.currentUser?.uid;
    if (authenticatedUid == null ||
        authenticatedUid != request.reviewerUid ||
        request.reviewerUid == request.targetUserId) {
      throw const UserProfileFailure(UserProfileFailureType.unauthenticated);
    }
    final normalizedFacilities =
        request.facilityIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    if (request.role == UserRole.admin ||
        normalizedFacilities.isEmpty ||
        normalizedFacilities.length > 20) {
      throw const UserProfileFailure(UserProfileFailureType.permissionDenied);
    }

    try {
      final reviewerReference = _users.doc(request.reviewerUid);
      final targetReference = _users.doc(request.targetUserId);
      await _firestore.runTransaction((transaction) async {
        final reviewer = await transaction.get(reviewerReference);
        final target = await transaction.get(targetReference);
        if (!reviewer.exists || !target.exists) {
          throw const UserProfileFailure(UserProfileFailureType.missing);
        }
        final reviewerData = reviewer.data();
        final targetData = target.data();
        if (reviewerData == null ||
            reviewerData['uid'] != request.reviewerUid ||
            reviewerData['role'] != 'admin' ||
            reviewerData['status'] != 'active') {
          throw const UserProfileFailure(
            UserProfileFailureType.permissionDenied,
          );
        }
        if (targetData == null ||
            targetData['uid'] != request.targetUserId ||
            targetData['role'] is! String ||
            targetData['status'] is! String) {
          throw const UserProfileFailure(UserProfileFailureType.malformed);
        }
        if (!const ['technician', 'viewer'].contains(targetData['role'])) {
          throw const UserProfileFailure(
            UserProfileFailureType.permissionDenied,
          );
        }
        transaction.update(
          targetReference,
          buildManagedAccessUpdate(
            role: request.role,
            facilityIds: normalizedFacilities,
            isActive: request.isActive,
            updatedAt: FieldValue.serverTimestamp(),
          ),
        );
      });
      final refreshed = await targetReference.get();
      if (!refreshed.exists) {
        throw const UserProfileFailure(UserProfileFailureType.missing);
      }
      return mapProfile(request.targetUserId, refreshed.data());
    } on UserProfileFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw UserProfileFailure(_mapFirestoreFailure(error.code), error);
    }
  }

  static AppUser mapProfile(String documentId, Map<String, dynamic>? data) {
    if (data == null) {
      throw const UserProfileFailure(UserProfileFailureType.malformed);
    }

    final declaredUid = data['uid'];
    final rawDisplayName = data['displayName'];
    final email = data['email'];
    final roleValue = data['role'];
    final statusValue = data['status'];
    final facilityIdsValue = data['facilityIds'];

    if (declaredUid is! String ||
        declaredUid != documentId ||
        email is! String ||
        email.trim().isEmpty ||
        roleValue is! String ||
        statusValue is! String ||
        facilityIdsValue is! List ||
        facilityIdsValue.any((value) => value is! String)) {
      throw const UserProfileFailure(UserProfileFailureType.malformed);
    }

    final role = switch (roleValue.trim().toLowerCase()) {
      'admin' => UserRole.admin,
      'technician' => UserRole.technician,
      'viewer' => UserRole.viewer,
      _ => throw const UserProfileFailure(UserProfileFailureType.unknownRole),
    };

    final isActive = switch (statusValue.trim().toLowerCase()) {
      'active' => true,
      'disabled' => false,
      _ => throw const UserProfileFailure(UserProfileFailureType.unknownStatus),
    };
    final displayName =
        rawDisplayName is String && rawDisplayName.trim().isNotEmpty
        ? rawDisplayName.trim()
        : [
            _optionalString(data['firstName']),
            _optionalString(data['lastName']),
          ].whereType<String>().join(' ').trim();
    final resolvedName = displayName.isNotEmpty
        ? displayName
        : email.trim().split('@').first;
    if (resolvedName.isEmpty) {
      throw const UserProfileFailure(UserProfileFailureType.malformed);
    }

    return AppUser(
      id: documentId,
      name: resolvedName,
      email: email.trim().toLowerCase(),
      role: role,
      isActive: isActive,
      siteAccessIds: facilityIdsValue.cast<String>(),
      company: _optionalString(data['company']),
      firstName: _optionalString(data['firstName']),
      lastName: _optionalString(data['lastName']),
      jobTitle: _optionalString(data['jobTitle']),
      department: _optionalString(data['department']),
      phoneNumber: _optionalString(data['phone']),
      shortBio: _optionalString(data['bio']),
      createdAt: _optionalDateTime(data['createdAt']),
      updatedAt: _optionalDateTime(data['updatedAt']),
    );
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const UserProfileFailure(UserProfileFailureType.malformed);
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime? _optionalDateTime(Object? value) {
    if (value == null) return null;
    if (value is! Timestamp) {
      throw const UserProfileFailure(UserProfileFailureType.malformed);
    }
    return value.toDate();
  }

  @visibleForTesting
  static Map<String, Object?> buildOwnProfileUpdate({
    required String firstName,
    required String lastName,
    required String jobTitle,
    required String department,
    required String phone,
    required String bio,
    required Object updatedAt,
  }) {
    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();
    return <String, Object?>{
      'firstName': normalizedFirstName,
      'lastName': normalizedLastName,
      'displayName': [
        normalizedFirstName,
        normalizedLastName,
      ].where((part) => part.isNotEmpty).join(' '),
      // Firestore profile fields have a stable string schema. Empty optional
      // form values are stored as empty strings, never null.
      'jobTitle': jobTitle.trim(),
      'department': department.trim(),
      'phone': phone.trim(),
      'bio': bio.trim(),
      'updatedAt': updatedAt,
    };
  }

  @visibleForTesting
  static Map<String, Object?> buildManagedAccessUpdate({
    required UserRole role,
    required List<String> facilityIds,
    required bool isActive,
    required Object updatedAt,
  }) {
    if (role == UserRole.admin) {
      throw const UserProfileFailure(UserProfileFailureType.permissionDenied);
    }
    final normalized =
        facilityIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    if (normalized.isEmpty || normalized.length > 20) {
      throw const UserProfileFailure(UserProfileFailureType.permissionDenied);
    }
    return <String, Object?>{
      'role': role.name,
      'facilityIds': normalized,
      'status': isActive ? 'active' : 'disabled',
      'updatedAt': updatedAt,
    };
  }

  static String _firstNameFrom(String displayName) {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  static String _lastNameFrom(String displayName) {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.length < 2 ? '' : parts.skip(1).join(' ');
  }

  static UserProfileFailureType _mapFirestoreFailure(String code) {
    return switch (code) {
      'permission-denied' => UserProfileFailureType.permissionDenied,
      'unauthenticated' => UserProfileFailureType.unauthenticated,
      _ => UserProfileFailureType.unavailable,
    };
  }

  static void _debug(String message) {
    if (kDebugMode) debugPrint('[BaitGuard Profile] $message');
  }
}

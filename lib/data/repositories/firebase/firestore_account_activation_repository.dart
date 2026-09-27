import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/account_activation_failure.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/approved_access_invitation.dart';
import '../../../domain/models/user_role.dart';
import '../../../domain/repositories/account_activation_repository.dart';

class FirestoreAccountActivationRepository
    implements AccountActivationRepository {
  FirestoreAccountActivationRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<ApprovedAccessInvitation>
  findApprovedInvitationForCurrentUser() async {
    final user = _auth.currentUser;
    final email = user?.email?.trim().toLowerCase();
    if (user == null || email == null || email.isEmpty) {
      throw const AccountActivationFailure(
        AccountActivationFailureType.unauthenticated,
      );
    }
    if (!user.emailVerified) {
      throw const AccountActivationFailure(
        AccountActivationFailureType.notVerified,
      );
    }

    try {
      final result = await _firestore
          .collection('accessRequests')
          .where('normalizedEmail', isEqualTo: email)
          .where('status', isEqualTo: 'approved')
          .where('activatedUid', isNull: true)
          .limit(2)
          .get();
      if (result.docs.isEmpty) {
        throw const AccountActivationFailure(
          AccountActivationFailureType.noInvitation,
        );
      }
      if (result.docs.length > 1) {
        throw const AccountActivationFailure(
          AccountActivationFailureType.multipleInvitations,
        );
      }
      return mapInvitation(result.docs.single.id, result.docs.single.data());
    } on AccountActivationFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AccountActivationFailure(_mapFirebase(error.code), error);
    } catch (error) {
      throw AccountActivationFailure(
        AccountActivationFailureType.unknown,
        error,
      );
    }
  }

  @override
  Future<AppUser> activateApprovedAccount({
    required ApprovedAccessInvitation invitation,
    required String firebaseUid,
  }) async {
    final authUser = _auth.currentUser;
    final verifiedEmail = authUser?.email?.trim().toLowerCase();
    if (authUser == null ||
        authUser.uid != firebaseUid ||
        verifiedEmail == null) {
      throw const AccountActivationFailure(
        AccountActivationFailureType.unauthenticated,
      );
    }
    if (!authUser.emailVerified) {
      throw const AccountActivationFailure(
        AccountActivationFailureType.notVerified,
      );
    }

    final requestRef = _firestore
        .collection('accessRequests')
        .doc(invitation.requestId);
    final userRef = _firestore.collection('users').doc(firebaseUid);
    try {
      await _firestore.runTransaction((transaction) async {
        final requestSnapshot = await transaction.get(requestRef);
        final userSnapshot = await transaction.get(userRef);
        if (!requestSnapshot.exists) {
          throw const AccountActivationFailure(
            AccountActivationFailureType.noInvitation,
          );
        }
        if (userSnapshot.exists) {
          throw const AccountActivationFailure(
            AccountActivationFailureType.profileAlreadyExists,
          );
        }
        final approved = mapInvitation(
          requestSnapshot.id,
          requestSnapshot.data()!,
        );
        final data = requestSnapshot.data()!;
        if (data['activatedUid'] != null || data['activatedAt'] != null) {
          throw const AccountActivationFailure(
            AccountActivationFailureType.alreadyActivated,
          );
        }
        if (approved.email != verifiedEmail) {
          throw const AccountActivationFailure(
            AccountActivationFailureType.invalidInvitation,
          );
        }
        final names = _splitName(approved.fullName);
        transaction.set(userRef, <String, Object?>{
          'uid': firebaseUid,
          'firstName': names.$1,
          'lastName': names.$2,
          'displayName': approved.fullName,
          'email': verifiedEmail,
          'role': approved.assignedRole.name,
          'status': 'active',
          'facilityIds': approved.assignedFacilityIds,
          'company': approved.company,
          'department': approved.department,
          'phone': approved.phone,
          'jobTitle': '',
          'bio': '',
          'activationRequestId': approved.requestId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(requestRef, <String, Object?>{
          'activatedUid': firebaseUid,
          'activatedAt': FieldValue.serverTimestamp(),
        });
      });
      final names = _splitName(invitation.fullName);
      return AppUser(
        id: firebaseUid,
        name: invitation.fullName,
        email: verifiedEmail,
        role: invitation.assignedRole,
        siteAccessIds: invitation.assignedFacilityIds,
        firstName: names.$1,
        lastName: names.$2,
        company: invitation.company,
        department: invitation.department,
        phoneNumber: invitation.phone,
      );
    } on AccountActivationFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AccountActivationFailure(_mapFirebase(error.code), error);
    } catch (error) {
      throw AccountActivationFailure(
        AccountActivationFailureType.unknown,
        error,
      );
    }
  }

  @visibleForTesting
  static ApprovedAccessInvitation mapInvitation(
    String id,
    Map<String, dynamic> data,
  ) {
    String requiredString(String key) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty) {
        throw const AccountActivationFailure(
          AccountActivationFailureType.invalidInvitation,
        );
      }
      return value.trim();
    }

    final role = switch (requiredString('assignedRole')) {
      'technician' => UserRole.technician,
      'viewer' => UserRole.viewer,
      _ => throw const AccountActivationFailure(
        AccountActivationFailureType.invalidInvitation,
      ),
    };
    final rawFacilities = data['assignedFacilityIds'];
    if (data['status'] != 'approved' ||
        !const ['request', 'admin'].contains(data['approvalSource']) ||
        rawFacilities is! List ||
        rawFacilities.isEmpty ||
        rawFacilities.any(
          (value) => value is! String || value.trim().isEmpty,
        )) {
      throw const AccountActivationFailure(
        AccountActivationFailureType.invalidInvitation,
      );
    }
    return ApprovedAccessInvitation(
      requestId: id,
      fullName: requiredString('fullName'),
      email: requiredString('normalizedEmail').toLowerCase(),
      company: requiredString('company'),
      department: (data['department'] as String? ?? '').trim(),
      phone: (data['phone'] as String? ?? '').trim(),
      assignedRole: role,
      assignedFacilityIds: List<String>.unmodifiable(
        rawFacilities.cast<String>().map((value) => value.trim()),
      ),
    );
  }

  static (String, String) _splitName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    return (parts.first, parts.skip(1).join(' '));
  }

  static AccountActivationFailureType _mapFirebase(String code) =>
      switch (code) {
        'permission-denied' => AccountActivationFailureType.permissionDenied,
        'unauthenticated' => AccountActivationFailureType.unauthenticated,
        'unavailable' => AccountActivationFailureType.network,
        'deadline-exceeded' => AccountActivationFailureType.timeout,
        'failed-precondition' => AccountActivationFailureType.missingIndex,
        _ => AccountActivationFailureType.unknown,
      };
}

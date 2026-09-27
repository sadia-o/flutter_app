import 'package:flutter_test/flutter_test.dart';

import 'package:baitguard/data/repositories/firebase/firestore_user_repository.dart';
import 'package:baitguard/domain/models/user_profile_failure.dart';
import 'package:baitguard/domain/models/user_role.dart';

Map<String, dynamic> _profileData({
  String role = 'viewer',
  String status = 'active',
  Object facilityIds = const ['site_1'],
}) {
  return {
    'uid': 'uid_1',
    'displayName': '  Firebase User  ',
    'email': ' USER@EXAMPLE.COM ',
    'role': role,
    'status': status,
    'facilityIds': facilityIds,
    'company': 'Bait Guard',
    'department': 'Operations',
    'phone': '+1 555 0100',
  };
}

void main() {
  test('profile update payload stores empty optionals as strings', () {
    final timestamp = Object();
    final payload = FirestoreUserRepository.buildOwnProfileUpdate(
      firstName: '  OneName ',
      lastName: ' ',
      jobTitle: '',
      department: '  ',
      phone: '',
      bio: ' ',
      updatedAt: timestamp,
    );

    expect(payload, {
      'firstName': 'OneName',
      'lastName': '',
      'displayName': 'OneName',
      'jobTitle': '',
      'department': '',
      'phone': '',
      'bio': '',
      'updatedAt': timestamp,
    });
    expect(
      payload.entries.where((entry) => entry.key != 'updatedAt'),
      everyElement(
        predicate<MapEntry<String, Object?>>((entry) => entry.value is String),
      ),
    );
    expect(payload.values, isNot(contains(null)));
    expect(payload.keys, isNot(contains('uid')));
    expect(payload.keys, isNot(contains('email')));
    expect(payload.keys, isNot(contains('role')));
    expect(payload.keys, isNot(contains('status')));
    expect(payload.keys, isNot(contains('facilityIds')));
    expect(payload.keys, isNot(contains('company')));
    expect(payload.keys, isNot(contains('createdAt')));
    expect(payload.keys, isNot(contains('activationRequestId')));
  });

  test('maps and normalizes users/{uid} without Firebase types leaking', () {
    final user = FirestoreUserRepository.mapProfile(
      'uid_1',
      _profileData(role: 'TECHNICIAN'),
    );

    expect(user.id, 'uid_1');
    expect(user.name, 'Firebase User');
    expect(user.email, 'user@example.com');
    expect(user.role, UserRole.technician);
    expect(user.isActive, isTrue);
    expect(user.siteAccessIds, ['site_1']);
    expect(user.company, 'Bait Guard');
  });

  test('legacy profile maps when every Batch 3 optional field is absent', () {
    final data = _profileData()
      ..remove('company')
      ..remove('department')
      ..remove('phone');

    final user = FirestoreUserRepository.mapProfile('uid_1', data);

    expect(user.firstName, isNull);
    expect(user.lastName, isNull);
    expect(user.jobTitle, isNull);
    expect(user.department, isNull);
    expect(user.company, isNull);
    expect(user.phoneNumber, isNull);
    expect(user.shortBio, isNull);
    expect(user.name, 'Firebase User');
  });

  test('unknown role is rejected without a default role', () {
    expect(
      () => FirestoreUserRepository.mapProfile(
        'uid_1',
        _profileData(role: 'super_admin'),
      ),
      throwsA(
        isA<UserProfileFailure>().having(
          (failure) => failure.type,
          'type',
          UserProfileFailureType.unknownRole,
        ),
      ),
    );
  });

  test('unknown status is rejected', () {
    expect(
      () => FirestoreUserRepository.mapProfile(
        'uid_1',
        _profileData(status: 'pending'),
      ),
      throwsA(
        isA<UserProfileFailure>().having(
          (failure) => failure.type,
          'type',
          UserProfileFailureType.unknownStatus,
        ),
      ),
    );
  });

  test('malformed facility IDs and mismatched uid are rejected', () {
    expect(
      () => FirestoreUserRepository.mapProfile(
        'uid_1',
        _profileData(facilityIds: const ['site_1', 2]),
      ),
      throwsA(isA<UserProfileFailure>()),
    );
    final mismatchedUid = _profileData()..['uid'] = 'different_uid';
    expect(
      () => FirestoreUserRepository.mapProfile('uid_1', mismatchedUid),
      throwsA(isA<UserProfileFailure>()),
    );
  });
}

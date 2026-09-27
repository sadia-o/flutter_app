import '../../../domain/models/user_role.dart';

/// Immutable presentation-permission model for station screen actions.
///
/// Derived from [AppUser.role] — never scatter direct UserRole comparisons
/// through station widgets. Passes no UI objects (Color, IconData, etc.).
class StationPermissions {
  final bool canAddStation;
  final bool canRefill;
  final bool canSilence;
  final bool canLocate;

  const StationPermissions({
    required this.canAddStation,
    required this.canRefill,
    required this.canSilence,
    required this.canLocate,
  });

  /// Derives the correct [StationPermissions] from a [UserRole].
  factory StationPermissions.fromRole(
    UserRole role, {
    bool supportsMutations = true,
  }) {
    if (!supportsMutations) {
      return const StationPermissions(
        canAddStation: false,
        canRefill: false,
        canSilence: false,
        canLocate: true,
      );
    }
    switch (role) {
      case UserRole.admin:
        return const StationPermissions(
          canAddStation: true,
          canRefill: true,
          canSilence: true,
          canLocate: true,
        );
      case UserRole.technician:
        return const StationPermissions(
          canAddStation: false,
          canRefill: true,
          canSilence: true,
          canLocate: true,
        );
      case UserRole.viewer:
        return const StationPermissions(
          canAddStation: false,
          canRefill: false,
          canSilence: false,
          canLocate: true,
        );
    }
  }

  /// Read-only permissions — no mutations, locate only.
  static const readOnly = StationPermissions(
    canAddStation: false,
    canRefill: false,
    canSilence: false,
    canLocate: true,
  );
}

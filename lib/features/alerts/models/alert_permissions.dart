import '../../../domain/models/user_role.dart';

class AlertPermissions {
  final bool canResolve;
  final bool canSnooze;
  final bool canAssign;
  final bool canDismiss;
  final bool canViewStation;

  const AlertPermissions({
    required this.canResolve,
    required this.canSnooze,
    required this.canAssign,
    required this.canDismiss,
    required this.canViewStation,
  });

  factory AlertPermissions.fromRole(
    UserRole role, {
    bool supportsMutations = true,
  }) {
    if (!supportsMutations) {
      return const AlertPermissions(
        canResolve: false,
        canSnooze: false,
        canAssign: false,
        canDismiss: false,
        canViewStation: true,
      );
    }
    switch (role) {
      case UserRole.admin:
        return const AlertPermissions(
          canResolve: true,
          canSnooze: true,
          canAssign: true,
          canDismiss: true,
          canViewStation: true,
        );
      case UserRole.technician:
        return const AlertPermissions(
          canResolve: true,
          canSnooze: true,
          canAssign: false,
          canDismiss: false,
          canViewStation: true,
        );
      case UserRole.viewer:
        return const AlertPermissions(
          canResolve: false,
          canSnooze: false,
          canAssign: false,
          canDismiss: false,
          canViewStation: true,
        );
    }
  }
}

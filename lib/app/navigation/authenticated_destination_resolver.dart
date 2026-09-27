import '../../../domain/models/user_role.dart';
import 'route_names.dart';

class AuthenticatedDestinationResolver {
  static String resolve(UserRole role) {
    switch (role) {
      case UserRole.viewer:
      case UserRole.technician:
        return RouteNames.userDashboard;
      case UserRole.admin:
        return RouteNames.adminDashboard;
    }
  }
}

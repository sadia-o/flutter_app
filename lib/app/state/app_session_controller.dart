import 'package:flutter/foundation.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/user_role.dart';

class AppSessionController extends ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  UserRole? get role => _currentUser?.role;

  void establishSession(AppUser user) {
    if (identical(_currentUser, user)) return;
    _currentUser = user;
    notifyListeners();
  }

  void clearSession() {
    if (_currentUser == null) return;
    _currentUser = null;
    notifyListeners();
  }
}

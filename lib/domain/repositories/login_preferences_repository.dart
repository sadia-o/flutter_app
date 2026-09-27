import '../models/remembered_login.dart';

abstract class LoginPreferencesRepository {
  Future<RememberedLogin> load();
  Future<void> saveRememberedEmail(String email);
  Future<void> clearRememberedEmail();
}

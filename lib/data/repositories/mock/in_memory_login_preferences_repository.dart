import '../../../domain/models/remembered_login.dart';
import '../../../domain/repositories/login_preferences_repository.dart';

class InMemoryLoginPreferencesRepository implements LoginPreferencesRepository {
  RememberedLogin _value = const RememberedLogin(enabled: false);

  @override
  Future<RememberedLogin> load() async => _value;

  @override
  Future<void> saveRememberedEmail(String email) async {
    _value = RememberedLogin(enabled: true, email: email.trim().toLowerCase());
  }

  @override
  Future<void> clearRememberedEmail() async {
    _value = const RememberedLogin(enabled: false);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/remembered_login.dart';
import '../../../domain/repositories/login_preferences_repository.dart';

class SharedPreferencesLoginRepository implements LoginPreferencesRepository {
  static const _rememberEmailKey = 'login.rememberEmail';
  static const _emailKey = 'login.email';

  @override
  Future<RememberedLogin> load() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool(_rememberEmailKey) ?? false;
    final email = preferences.getString(_emailKey)?.trim().toLowerCase();
    return RememberedLogin(
      enabled: enabled && email != null && email.isNotEmpty,
      email: enabled ? email : null,
    );
  }

  @override
  Future<void> saveRememberedEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_rememberEmailKey) == true &&
        preferences.getString(_emailKey) == normalizedEmail) {
      return;
    }
    await preferences.setString(_emailKey, normalizedEmail);
    await preferences.setBool(_rememberEmailKey, true);
  }

  @override
  Future<void> clearRememberedEmail() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_rememberEmailKey) == false &&
        !preferences.containsKey(_emailKey)) {
      return;
    }
    await preferences.remove(_emailKey);
    await preferences.setBool(_rememberEmailKey, false);
  }
}

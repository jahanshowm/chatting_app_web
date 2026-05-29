import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'admin_access_token';
  static const _savedUsernameKey = 'admin_saved_username';
  static const _saveUsernameKey = 'admin_save_username';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> getSaveUsernameEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_saveUsernameKey) ?? false;
  }

  Future<void> setSaveUsernameEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_saveUsernameKey, enabled);
  }

  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedUsernameKey);
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedUsernameKey, username);
  }

  Future<void> clearSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedUsernameKey);
  }
}

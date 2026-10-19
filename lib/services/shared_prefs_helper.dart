import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String _keyToken = 'jwt_token';
  static const String _keyEmail = 'user_email';
  static const String _keyVillageId = 'village_id';
  static const String _keyUserName = 'user_name';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail) ?? 'asha.worker@community.org';
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'ASHA Worker';
  }

  static Future<void> saveVillageId(int villageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyVillageId, villageId);
  }

  static Future<int> getVillageId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyVillageId) ?? 1;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

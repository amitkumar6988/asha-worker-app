import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyToken = 'jwt_token';
  static const String _keyUsername = 'asha_username';
  static const String _keyRole = 'user_role';
  static const String _keyVillage = 'assigned_village';

  // Mock login for ASHA worker adhering to architecture RBAC (Role: ASHA Worker)
  static Future<bool> login(String username, String password) async {
    // In production, this calls POST /api/v1/auth/login
    // For local & offline resilience, validate credentials or mock success for ASHA worker
    if (username.isNotEmpty && password.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, 'mock_jwt_token_asha_12345');
      await prefs.setString(_keyUsername, username);
      await prefs.setString(_keyRole, 'ASHA_WORKER');
      await prefs.setString(_keyVillage, 'Guwahati Rural / Basti 4');
      return true;
    }
    return false;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final role = prefs.getString(_keyRole);
    return token != null && role == 'ASHA_WORKER';
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? 'ASHA Worker';
  }

  static Future<String> getAssignedVillage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVillage) ?? 'Default Village';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

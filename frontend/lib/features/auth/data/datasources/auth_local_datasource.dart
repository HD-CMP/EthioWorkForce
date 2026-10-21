import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<void> saveUserData(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _userRoleKey = 'user_role';

  AuthLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> saveToken(String token) async {
    await sharedPreferences.setString(_tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(_tokenKey);
  }

  @override
  Future<void> clearToken() async {
    await sharedPreferences.remove(_tokenKey);
    await sharedPreferences.remove(_userDataKey);
    await sharedPreferences.remove(_userRoleKey);
    await sharedPreferences.remove('cached_total_workers');
    await sharedPreferences.remove('cached_present_today');
    await sharedPreferences.remove('cached_active_sites');
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await sharedPreferences.setString(_userDataKey, jsonEncode(userData));
    if (userData.containsKey('role') && userData['role'] != null) {
      await sharedPreferences.setString(_userRoleKey, userData['role'].toString());
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final raw = sharedPreferences.getString(_userDataKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

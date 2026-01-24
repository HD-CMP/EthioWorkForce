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
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await sharedPreferences.setString(_userDataKey, userData.toString());
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    return null;
  }
}

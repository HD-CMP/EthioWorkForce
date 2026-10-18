import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  // Default backend URLs for different environments
  // Web: Use 127.0.0.1 (localhost) since the backend runs on Windows
  // Mobile: Use 10.0.2.2 for Android emulator to reach host machine's localhost
  static String get defaultDevelopmentUrl => kIsWeb 
      ? 'http://127.0.0.1:8000/api/v1'
      : 'http://10.0.2.2:8000/api/v1';
  static const String defaultProductionUrl = 'https://ethioworkforce-api.onrender.com/api/v1';
  
  // Versioned cache key — bump this when you change the default URL
  // so that stale cached URLs from previous environments are invalidated.
  static const String _backendUrlKey = 'backend_url_v2';
  static const String _isOfflineModeKey = 'offline_mode';
  // Legacy keys to clean up
  static const String _legacyBackendUrlKey = 'backend_url';
  
  static String? _customBaseUrl;
  static bool _isOfflineMode = false;
  static bool _hasCleanedLegacy = false;
  
  /// Set custom backend URL (can be configured in settings)
  static Future<void> setBackendUrl(String url) async {
    _customBaseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, url);
  }
  
  /// Get configured backend URL
  static Future<String> getBackendUrl() async {
    if (_customBaseUrl != null) {
      return _customBaseUrl!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    
    // One-time cleanup: remove stale legacy cached URL (old WSL IPs etc.)
    if (!_hasCleanedLegacy) {
      _hasCleanedLegacy = true;
      if (prefs.containsKey(_legacyBackendUrlKey)) {
        await prefs.remove(_legacyBackendUrlKey);
      }
    }
    
    final savedUrl = prefs.getString(_backendUrlKey);
    
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _customBaseUrl = savedUrl;
      return savedUrl;
    }
    
    // Default to production URL in release mode, development URL otherwise
    return kIsWeb
        ? defaultDevelopmentUrl  // Web dev always uses localhost
        : (const bool.fromEnvironment('dart.vm.product')
            ? defaultProductionUrl
            : defaultDevelopmentUrl);
  }
  
  /// Set offline mode
  static Future<void> setOfflineMode(bool isOffline) async {
    _isOfflineMode = isOffline;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isOfflineModeKey, isOffline);
  }
  
  /// Check if in offline mode
  static Future<bool> isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isOfflineModeKey) ?? false;
  }
  
  static Future<Dio> createDio() async {
    final baseUrl = await getBackendUrl();
    
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // LogInterceptor removed to prevent LegacyJavaScriptObject crash on Flutter Web
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Check offline mode before making request
        final isOffline = await isOfflineMode();
        if (isOffline) {
          return handler.reject(
            DioException(
              requestOptions: options,
              error: 'App is in offline mode',
              type: DioExceptionType.cancel,
            ),
          );
        }
        
        // Add authentication token if available
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid — clear saved token
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          Logger().w('Auth token expired or invalid — cleared');
        }
        // Log network errors
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          Logger().w('Network error detected - consider enabling offline mode');
        }
        return handler.next(error);
      },
    ));
    
    return dio;
  }
}

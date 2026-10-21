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
  // v3: Release builds now reject http/LAN URLs automatically.
  static const String _backendUrlKey = 'backend_url_v3';
  static const String _isOfflineModeKey = 'offline_mode';
  // Legacy keys to clean up on first run
  static const String _legacyBackendUrlKey = 'backend_url';
  static const String _legacyBackendUrlKeyV2 = 'backend_url_v2';
  
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
      if (prefs.containsKey(_legacyBackendUrlKeyV2)) {
        await prefs.remove(_legacyBackendUrlKeyV2);
      }
    }

    // In release builds: NEVER use a cached local/dev URL.
    // A stale localhost/10.0.2.2/192.168.x.x URL from a dev session would
    // cause "invalid credentials" on real devices even though the password is correct.
    const isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease) {
      final savedUrl = prefs.getString(_backendUrlKey);
      // Only honour a saved URL if it points to a real HTTPS server (not localhost/LAN)
      if (savedUrl != null &&
          savedUrl.isNotEmpty &&
          savedUrl.startsWith('https://')) {
        _customBaseUrl = savedUrl;
        return savedUrl;
      }
      // Otherwise always fall back to the production cloud URL
      return defaultProductionUrl;
    }

    // Debug / development build: honour any saved URL as-is
    final savedUrl = prefs.getString(_backendUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _customBaseUrl = savedUrl;
      return savedUrl;
    }
    return defaultDevelopmentUrl;
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

  /// Resolves relative media paths (e.g. /uploads/id_cards/xxx.jpg) to full URLs
  static Future<String> resolveMediaUrl(String? path) async {
    if (path == null || path.trim().isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final backendUrl = await getBackendUrl();
    final baseUrl = backendUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$baseUrl$cleanPath';
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

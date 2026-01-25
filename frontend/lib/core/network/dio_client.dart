import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  // Default backend URLs for different environments
  static const String defaultDevelopmentUrl = 'http://localhost:8000/api/v1';
  static const String defaultProductionUrl = 'https://ethioworkforce-api.onrender.com/api/v1';
  
  // Custom backend URL key for SharedPreferences
  static const String _backendUrlKey = 'backend_url';
  static const String _isOfflineModeKey = 'offline_mode';
  
  static String? _customBaseUrl;
  static bool _isOfflineMode = false;
  
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
    final savedUrl = prefs.getString(_backendUrlKey);
    
    if (savedUrl != null && savedUrl.isNotEmpty) {
      // Migrate old localhost URLs to production
      if (savedUrl.contains('localhost') || savedUrl.contains('127.0.0.1') || savedUrl.contains('10.0.2.2')) {
        _customBaseUrl = defaultProductionUrl;
        await prefs.setString(_backendUrlKey, defaultProductionUrl);
        return defaultProductionUrl;
      }
      
      _customBaseUrl = savedUrl;
      return savedUrl;
    }
    
    // Default to production URL for fresh installs
    return defaultProductionUrl;
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
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => Logger().d(obj),
    ));
    
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
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Log network errors and suggest offline mode
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

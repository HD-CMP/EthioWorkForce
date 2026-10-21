import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../di/injection.dart';
import '../router/app_router.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';

/// Enterprise Session Manager for Financial & Workforce Security.
/// Automatically expires and logs out active sessions when the user is inactive
/// or exits the app for longer than the configured timeout threshold.
class SessionManager {
  static const String _lastActivityKey = 'session_last_activity_ms';
  static const String _autoLogoutMinutesKey = 'session_auto_logout_minutes';
  static const String _sessionExpiredNoticeKey = 'session_expired_notice';

  // Default inactivity timeout: 15 minutes (financial/payroll security standard)
  static const int defaultTimeoutMinutes = 15;

  static DateTime _lastActivity = DateTime.now();
  static Timer? _inactivityTimer;
  static bool _isSessionEnding = false;
  static DateTime? _lastPersisted;

  /// Get the configured inactivity timeout in minutes
  static Future<int> getTimeoutMinutes() async {
    try {
      final prefs = getIt<SharedPreferences>();
      return prefs.getInt(_autoLogoutMinutesKey) ?? defaultTimeoutMinutes;
    } catch (_) {
      return defaultTimeoutMinutes;
    }
  }

  /// Update the inactivity timeout in minutes (e.g. 5, 10, 15, 30)
  static Future<void> setTimeoutMinutes(int minutes) async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setInt(_autoLogoutMinutesKey, minutes);
      _resetInactivityTimer(minutes: minutes);
    } catch (_) {}
  }

  /// Record user activity (touch, scroll, drag, key event)
  static void recordActivity({bool syncNow = false}) {
    _lastActivity = DateTime.now();

    if (syncNow) {
      _persistLastActivity();
    } else {
      final now = DateTime.now();
      if (_lastPersisted == null || now.difference(_lastPersisted!).inSeconds >= 10) {
        _lastPersisted = now;
        _persistLastActivity();
      }
    }

    _resetInactivityTimer();
  }

  static Future<void> _persistLastActivity() async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setInt(_lastActivityKey, _lastActivity.millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Check whether the current session has expired due to inactivity
  static Future<bool> isSessionExpired() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        return false;
      }

      final lastMs = prefs.getInt(_lastActivityKey);
      if (lastMs == null) {
        // First initialization — record current time as baseline
        await prefs.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
        return false;
      }

      final timeoutMinutes = prefs.getInt(_autoLogoutMinutesKey) ?? defaultTimeoutMinutes;
      final elapsedMs = DateTime.now().millisecondsSinceEpoch - lastMs;
      final maxAllowedMs = timeoutMinutes * 60 * 1000;

      return elapsedMs > maxAllowedMs;
    } catch (_) {
      return false;
    }
  }

  /// Check session on app resume and trigger logout if inactive beyond limit
  static Future<bool> checkAndHandleResume() async {
    final expired = await isSessionExpired();
    if (expired) {
      await expireSession();
      return true;
    }
    // Session is still active: update activity timestamp
    recordActivity(syncNow: true);
    return false;
  }

  /// Securely terminate the session and redirect to the Login screen
  static Future<void> expireSession() async {
    if (_isSessionEnding) return;
    _isSessionEnding = true;

    try {
      _inactivityTimer?.cancel();
      _inactivityTimer = null;

      try {
        final localDs = getIt<AuthLocalDataSource>();
        await localDs.clearToken();
      } catch (_) {}

      try {
        final prefs = getIt<SharedPreferences>();
        await prefs.remove(_lastActivityKey);
        await prefs.setBool(_sessionExpiredNoticeKey, true);
      } catch (_) {}

      // Navigate to login screen
      AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRouter.login,
        (_) => false,
      );
    } finally {
      _isSessionEnding = false;
    }
  }

  /// Check and consume session expiration notice flag to display on Login page
  static Future<bool> consumeExpirationNotice() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final notice = prefs.getBool(_sessionExpiredNoticeKey) ?? false;
      if (notice) {
        await prefs.remove(_sessionExpiredNoticeKey);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Reset the foreground inactivity timer
  static void _resetInactivityTimer({int? minutes}) {
    _inactivityTimer?.cancel();
    final durationMinutes = minutes ?? defaultTimeoutMinutes;
    _inactivityTimer = Timer(Duration(minutes: durationMinutes), () async {
      try {
        final prefs = getIt<SharedPreferences>();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          await expireSession();
        }
      } catch (_) {}
    });
  }

  /// Start monitoring
  static void start() {
    recordActivity(syncNow: true);
  }

  /// Stop monitoring
  static void stop() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
}

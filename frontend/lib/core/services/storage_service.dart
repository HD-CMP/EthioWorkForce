import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

enum StorageMode {
  fullOffline,
  hybridSync,
  onlineFirst,
}

class StorageService {
  static const String _storageModeKey = 'storage_mode';
  static const String _autoSyncEnabledKey = 'auto_sync_enabled';
  static const String _syncIntervalKey = 'sync_interval_minutes';
  static const String _maxLocalStorageKey = 'max_local_storage_mb';
  static const String _enableBackupKey = 'enable_backup';
  static const String _lastBackupKey = 'last_backup';
  
  final Logger _logger = Logger();
  
  Future<StorageMode> getStorageMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_storageModeKey) ?? 'full_offline';
    
    switch (modeString) {
      case 'full_offline':
        return StorageMode.fullOffline;
      case 'hybrid_sync':
        return StorageMode.hybridSync;
      case 'online_first':
        return StorageMode.onlineFirst;
      default:
        return StorageMode.fullOffline;
    }
  }
  
  Future<void> setStorageMode(StorageMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    
    switch (mode) {
      case StorageMode.fullOffline:
        modeString = 'full_offline';
        break;
      case StorageMode.hybridSync:
        modeString = 'hybrid_sync';
        break;
      case StorageMode.onlineFirst:
        modeString = 'online_first';
        break;
    }
    
    await prefs.setString(_storageModeKey, modeString);
    _logger.i('Storage mode set to: $modeString');
  }
  
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncEnabledKey) ?? false;
  }
  
  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncEnabledKey, enabled);
    _logger.i('Auto sync ${enabled ? 'enabled' : 'disabled'}');
  }
  
  Future<int> getSyncIntervalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_syncIntervalKey) ?? 60;
  }
  
  Future<void> setSyncIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncIntervalKey, minutes);
    _logger.i('Sync interval set to $minutes minutes');
  }
  
  Future<int> getMaxLocalStorageMB() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxLocalStorageKey) ?? 500;
  }
  
  Future<void> setMaxLocalStorageMB(int mb) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxLocalStorageKey, mb);
  }
  
  Future<bool> isBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enableBackupKey) ?? true;
  }
  
  Future<void> setBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableBackupKey, enabled);
  }
  
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupKey);
    
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  Future<void> setLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupKey, time.millisecondsSinceEpoch);
  }
  
  Future<Map<String, dynamic>> getStorageConfiguration() async {
    return {
      'storage_mode': (await getStorageMode()).toString(),
      'auto_sync_enabled': await isAutoSyncEnabled(),
      'sync_interval_minutes': await getSyncIntervalMinutes(),
      'max_local_storage_mb': await getMaxLocalStorageMB(),
      'backup_enabled': await isBackupEnabled(),
      'last_backup': await getLastBackupTime(),
    };
  }
  
  Future<void> configureForOfflineOnly() async {
    await setStorageMode(StorageMode.fullOffline);
    await setAutoSyncEnabled(false);
    await setBackupEnabled(true);
    _logger.i('Configured for full offline mode');
  }
  
  Future<void> configureForHybridSync() async {
    await setStorageMode(StorageMode.hybridSync);
    await setAutoSyncEnabled(true);
    await setSyncIntervalMinutes(120);
    await setBackupEnabled(true);
    _logger.i('Configured for hybrid sync mode');
  }
}

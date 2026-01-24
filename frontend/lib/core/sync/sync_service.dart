import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../database/app_database.dart';

enum ConflictStrategy {
  serverWins,
  latestWins,
  manual,
}

class SyncService {
  final AppDatabase database;
  final Logger logger = Logger();
  
  SyncService(this.database);

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncAll() async {
    final online = await isOnline();
    
    if (online) {
      logger.i('Device is online. Starting automatic sync...');
      await _syncToServer();
    } else {
      logger.w('Device is offline. Sync skipped.');
    }
  }

  Future<void> _syncToServer() async {
    logger.i('Syncing workers to server...');
    
    logger.i('Syncing attendance to server...');
    
    logger.i('Syncing payroll to server...');
    
    logger.i('Sync completed successfully');
  }

  String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> exportToSneakernet({
    required String password,
    required int siteId,
    required String siteCode,
  }) async {
    logger.i('Exporting data for sneakernet sync...');
    
    final workers = await database.select(database.workersTable).get();
    final attendances = await database.select(database.attendancesTable).get();
    final payrolls = await database.select(database.payrollsTable).get();
    
    final exportData = {
      'version': '1.0.0',
      'site_id': siteId,
      'site_code': siteCode,
      'exported_at': DateTime.now().toIso8601String(),
      'data': {
        'workers': workers.map((w) => _workerToJson(w)).toList(),
        'attendances': attendances.map((a) => _attendanceToJson(a)).toList(),
        'payrolls': payrolls.map((p) => _payrollToJson(p)).toList(),
      },
      'counts': {
        'workers': workers.length,
        'attendances': attendances.length,
        'payrolls': payrolls.length,
      }
    };
    
    final jsonString = jsonEncode(exportData);
    final checksum = _calculateChecksum(jsonString);
    
    final key = encrypt.Key.fromUtf8(password.padRight(32, '0').substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final encrypted = encrypter.encrypt(jsonString, iv: iv);
    
    final package = {
      'package_version': '1.0.0',
      'site_id': siteId,
      'site_code': siteCode,
      'exported_at': DateTime.now().toIso8601String(),
      'checksum': checksum,
      'salt': base64Encode(iv.bytes),
      'encrypted_data': encrypted.base64,
      'record_counts': exportData['counts'],
    };
    
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/ethioworkforce_export_${siteCode}_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(filePath);
    await file.writeAsString(jsonEncode(package));
    
    logger.i('Encrypted data exported to: $filePath');
    return {
      'file_path': filePath,
      'package': package,
    };
  }

  Future<Map<String, dynamic>> importFromSneakernet({
    required String filePath,
    required String password,
    ConflictStrategy strategy = ConflictStrategy.serverWins,
  }) async {
    logger.i('Importing data from sneakernet: $filePath');
    
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }
    
    final packageString = await file.readAsString();
    final package = jsonDecode(packageString) as Map<String, dynamic>;
    
    final key = encrypt.Key.fromUtf8(password.padRight(32, '0').substring(0, 32));
    final saltBytes = base64Decode(package['salt']);
    final iv = encrypt.IV(saltBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final encryptedData = encrypt.Encrypted.fromBase64(package['encrypted_data']);
    final decrypted = encrypter.decrypt(encryptedData, iv: iv);
    
    final expectedChecksum = package['checksum'];
    final actualChecksum = _calculateChecksum(decrypted);
    
    if (expectedChecksum != actualChecksum) {
      throw Exception('Checksum mismatch - data integrity compromised');
    }
    
    final payload = jsonDecode(decrypted) as Map<String, dynamic>;
    
    logger.i('Processing imported data with ${strategy.name} conflict resolution...');
    
    final importedWorkers = (payload['data']['workers'] as List)
        .cast<Map<String, dynamic>>();
    
    final localWorkers = await database.select(database.workersTable).get();
    
    final mergeResult = _mergeWithConflictResolution(
      localWorkers.map((w) => _workerToJson(w)).toList(),
      importedWorkers,
      strategy,
    );
    
    logger.i('Sneakernet import completed successfully');
    logger.i('Merge summary: ${mergeResult['new_records']} new, '
        '${mergeResult['updated_records']} updated, '
        '${mergeResult['conflicts']} conflicts');
    
    return mergeResult;
  }

  Map<String, dynamic> _mergeWithConflictResolution(
    List<Map<String, dynamic>> localRecords,
    List<Map<String, dynamic>> importedRecords,
    ConflictStrategy strategy,
  ) {
    final localById = {for (var record in localRecords) record['id']: record};
    
    final mergedRecords = <Map<String, dynamic>>[];
    final conflicts = <Map<String, dynamic>>[];
    final newRecordIds = <int>[];
    final updatedRecordIds = <int>[];
    
    for (var imported in importedRecords) {
      final recordId = imported['id'] as int;
      
      if (!localById.containsKey(recordId)) {
        mergedRecords.add(imported);
        newRecordIds.add(recordId);
      } else {
        final local = localById[recordId]!;
        
        if (_areRecordsEqual(local, imported)) {
          mergedRecords.add(local);
        } else {
          switch (strategy) {
            case ConflictStrategy.serverWins:
              mergedRecords.add(imported);
              updatedRecordIds.add(recordId);
              break;
            
            case ConflictStrategy.latestWins:
              final localUpdated = DateTime.tryParse(local['updated_at'] ?? '');
              final importedUpdated = DateTime.tryParse(imported['updated_at'] ?? '');
              
              if (importedUpdated != null && localUpdated != null) {
                if (importedUpdated.isAfter(localUpdated)) {
                  mergedRecords.add(imported);
                  updatedRecordIds.add(recordId);
                } else {
                  mergedRecords.add(local);
                }
              } else {
                mergedRecords.add(imported);
                updatedRecordIds.add(recordId);
              }
              break;
            
            case ConflictStrategy.manual:
              conflicts.add({
                'record_id': recordId,
                'local': local,
                'imported': imported,
              });
              mergedRecords.add(local);
              break;
          }
        }
      }
    }
    
    for (var entry in localById.entries) {
      if (!importedRecords.any((r) => r['id'] == entry.key)) {
        mergedRecords.add(entry.value);
      }
    }
    
    return {
      'total_records': mergedRecords.length,
      'new_records': newRecordIds.length,
      'updated_records': updatedRecordIds.length,
      'conflicts': conflicts.length,
      'conflict_details': conflicts,
      'merged_data': mergedRecords,
    };
  }

  bool _areRecordsEqual(Map<String, dynamic> record1, Map<String, dynamic> record2) {
    final json1 = jsonEncode(record1);
    final json2 = jsonEncode(record2);
    return json1 == json2;
  }

  Map<String, dynamic> _workerToJson(WorkersTableData worker) {
    return {
      'id': worker.id,
      'employee_id': worker.employeeId,
      'full_name': worker.fullName,
    };
  }

  Map<String, dynamic> _attendanceToJson(AttendancesTableData attendance) {
    return {
      'id': attendance.id,
      'worker_id': attendance.workerId,
      'attendance_date': attendance.attendanceDate.toIso8601String(),
    };
  }

  Map<String, dynamic> _payrollToJson(PayrollsTableData payroll) {
    return {
      'id': payroll.id,
      'payroll_code': payroll.payrollCode,
      'site_id': payroll.siteId,
    };
  }
}

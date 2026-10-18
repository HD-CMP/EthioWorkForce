import '../../domain/entities/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Attendance>> getAttendances({DateTime? date, int? siteId}) async {
    try {
      return await remoteDataSource.getAttendances(dateFrom: date, dateTo: date, siteId: siteId);
    } catch (e) {
      throw Exception('Failed to fetch attendances: $e');
    }
  }

  @override
  Future<Attendance> markAttendance(int workerId, int siteId, String checkType) async {
    try {
      return await remoteDataSource.createAttendance(
        workerId: workerId,
        siteId: siteId,
        attendanceDate: DateTime.now(),
        status: 'present',
        method: 'manual_entry',
      );
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  @override
  Future<Attendance> updateAttendance(int id, Attendance attendance) async {
    try {
      return await remoteDataSource.updateAttendance(
        id: id,
        status: attendance.status,
        regularHours: attendance.regularHours.toInt(),
        overtimeHours: attendance.overtimeHours,
      );
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  @override
  Future<Map<String, int>> getAttendanceStats(DateTime date) async {
    try {
      // Mock stats implementation since we don't have siteId here
      final stats = await remoteDataSource.getStatistics(siteId: 1, dateFrom: date, dateTo: date);
      return {
        'present': stats['present'] ?? 0,
        'absent': stats['absent'] ?? 0,
        'late': stats['late'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch attendance stats: $e');
    }
  }

  @override
  Future<List<Attendance>> getWorkerAttendanceHistory(
    int workerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await remoteDataSource.getAttendances(
        workerId: workerId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to fetch worker attendance history: $e');
    }
  }
}

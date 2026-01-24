import '../../domain/entities/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Attendance>> getAttendances({DateTime? date, int? siteId}) async {
    try {
      return await remoteDataSource.getAttendances(date: date, siteId: siteId);
    } catch (e) {
      throw Exception('Failed to fetch attendances: $e');
    }
  }

  @override
  Future<Attendance> markAttendance(int workerId, int siteId, String checkType) async {
    try {
      return await remoteDataSource.markAttendance(workerId, siteId, checkType);
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  @override
  Future<Attendance> updateAttendance(int id, Attendance attendance) async {
    try {
      return await remoteDataSource.updateAttendance(id, attendance);
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  @override
  Future<Map<String, int>> getAttendanceStats(DateTime date) async {
    try {
      return await remoteDataSource.getAttendanceStats(date);
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
      return await remoteDataSource.getWorkerAttendanceHistory(
        workerId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to fetch worker attendance history: $e');
    }
  }
}

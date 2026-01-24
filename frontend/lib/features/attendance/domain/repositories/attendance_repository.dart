import '../entities/attendance.dart';

abstract class AttendanceRepository {
  Future<List<Attendance>> getAttendances({DateTime? date, int? siteId});
  Future<Attendance> markAttendance(int workerId, int siteId, String checkType);
  Future<Attendance> updateAttendance(int id, Attendance attendance);
  Future<Map<String, int>> getAttendanceStats(DateTime date);
  Future<List<Attendance>> getWorkerAttendanceHistory(int workerId, {DateTime? startDate, DateTime? endDate});
}

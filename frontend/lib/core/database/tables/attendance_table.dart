import 'package:drift/drift.dart';

class AttendancesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  IntColumn get workerId => integer()();
  IntColumn get siteId => integer()();
  
  DateTimeColumn get attendanceDate => dateTime()();
  TextColumn get checkInTime => text().nullable()();
  TextColumn get checkOutTime => text().nullable()();
  
  TextColumn get status => text().withLength(min: 1, max: 20)();
  TextColumn get method => text().withLength(min: 1, max: 20)();
  
  IntColumn get regularHours => integer().withDefault(const Constant(8))();
  IntColumn get overtimeHours => integer().withDefault(const Constant(0))();
  
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  IntColumn get verifiedById => integer().nullable()();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  
  TextColumn get overrideReason => text().nullable()();
  TextColumn get notes => text().nullable()();
  
  IntColumn get ethiopianYear => integer().nullable()();
  IntColumn get ethiopianMonth => integer().nullable()();
  IntColumn get ethiopianDay => integer().nullable()();
  
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

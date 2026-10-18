import 'package:drift/drift.dart';

class WorkersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  TextColumn get employeeId => text().withLength(min: 1, max: 50)();
  TextColumn get fullName => text().withLength(min: 1, max: 255)();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get nationalId => text().nullable()();
  
  IntColumn get siteId => integer()();
  IntColumn get workTypeId => integer()();
  
  DateTimeColumn get hireDate => dateTime()();
  DateTimeColumn get terminationDate => dateTime().nullable()();
  
  TextColumn get status => text().withLength(min: 1, max: 20)();
  TextColumn get calendarPreference => text().withDefault(const Constant('gregorian'))();
  
  TextColumn get photoUrl => text().nullable()();
  TextColumn get qrCode => text().nullable()();
  
  TextColumn get bankName => text().nullable()();
  TextColumn get bankAccountNumber => text().nullable()();
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

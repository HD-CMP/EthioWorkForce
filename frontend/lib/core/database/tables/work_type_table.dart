import 'package:drift/drift.dart';

class WorkTypesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get code => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  
  TextColumn get paymentMode => text().withLength(min: 1, max: 50)();
  RealColumn get baseRate => real()();
  
  TextColumn get taxRule => text().withLength(min: 1, max: 50)();
  
  BoolColumn get overtimeEligible => boolean().withDefault(const Constant(false))();
  RealColumn get overtimeRatePerHour => real().nullable()();
  
  BoolColumn get pensionEligible => boolean().withDefault(const Constant(true))();
  RealColumn get employeePensionRate => real().withDefault(const Constant(0.07))();
  RealColumn get employerPensionRate => real().withDefault(const Constant(0.11))();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

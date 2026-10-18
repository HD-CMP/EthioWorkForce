import 'package:drift/drift.dart';

class PayrollsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  TextColumn get payrollCode => text().withLength(min: 1, max: 50)();
  IntColumn get siteId => integer()();
  
  TextColumn get periodType => text().withLength(min: 1, max: 20)();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  
  TextColumn get ethiopianMonth => text().nullable()();
  IntColumn get ethiopianYear => integer().nullable()();
  
  RealColumn get totalGrossAmount => real().withDefault(const Constant(0))();
  RealColumn get totalDeductions => real().withDefault(const Constant(0))();
  RealColumn get totalNetAmount => real().withDefault(const Constant(0))();
  RealColumn get totalEmployerPension => real().withDefault(const Constant(0))();
  
  TextColumn get status => text().withLength(min: 1, max: 20)();
  
  IntColumn get calculatedById => integer().nullable()();
  IntColumn get approvedById => integer().nullable()();
  DateTimeColumn get approvedAt => dateTime().nullable()();
  
  TextColumn get notes => text().nullable()();
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PayrollItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  IntColumn get payrollId => integer()();
  IntColumn get workerId => integer()();
  
  IntColumn get daysWorked => integer().withDefault(const Constant(0))();
  IntColumn get regularHours => integer().withDefault(const Constant(0))();
  IntColumn get overtimeHours => integer().withDefault(const Constant(0))();
  
  RealColumn get baseSalary => real().withDefault(const Constant(0))();
  RealColumn get overtimePay => real().withDefault(const Constant(0))();
  RealColumn get allowances => real().withDefault(const Constant(0))();
  
  RealColumn get grossSalary => real().withDefault(const Constant(0))();
  
  RealColumn get incomeTax => real().withDefault(const Constant(0))();
  RealColumn get employeePension => real().withDefault(const Constant(0))();
  RealColumn get employerPension => real().withDefault(const Constant(0))();
  RealColumn get costSharing => real().withDefault(const Constant(0))();
  RealColumn get otherDeductions => real().withDefault(const Constant(0))();
  
  RealColumn get totalDeductions => real().withDefault(const Constant(0))();
  RealColumn get netSalary => real().withDefault(const Constant(0))();
  
  TextColumn get taxRuleApplied => text().nullable()();
  TextColumn get notes => text().nullable()();
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

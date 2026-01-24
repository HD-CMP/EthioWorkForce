import 'package:drift/drift.dart';

class SitesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get code => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  TextColumn get locationAddress => text().nullable()();
  
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

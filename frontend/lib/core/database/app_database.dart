import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'connection/connection.dart' as impl;

import 'tables/worker_table.dart';
import 'tables/site_table.dart';
import 'tables/work_type_table.dart';
import 'tables/attendance_table.dart';
import 'tables/payroll_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  WorkersTable,
  SitesTable,
  WorkTypesTable,
  AttendancesTable,
  PayrollsTable,
  PayrollItemsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());

  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
      },
    );
  }
}

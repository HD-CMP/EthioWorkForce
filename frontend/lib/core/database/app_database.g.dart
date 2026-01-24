// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WorkersTableTable extends WorkersTable
    with TableInfo<$WorkersTableTable, WorkersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nationalIdMeta =
      const VerificationMeta('nationalId');
  @override
  late final GeneratedColumn<String> nationalId = GeneratedColumn<String>(
      'national_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<int> siteId = GeneratedColumn<int>(
      'site_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _workTypeIdMeta =
      const VerificationMeta('workTypeId');
  @override
  late final GeneratedColumn<int> workTypeId = GeneratedColumn<int>(
      'work_type_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _hireDateMeta =
      const VerificationMeta('hireDate');
  @override
  late final GeneratedColumn<DateTime> hireDate = GeneratedColumn<DateTime>(
      'hire_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _terminationDateMeta =
      const VerificationMeta('terminationDate');
  @override
  late final GeneratedColumn<DateTime> terminationDate =
      GeneratedColumn<DateTime>('termination_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _calendarPreferenceMeta =
      const VerificationMeta('calendarPreference');
  @override
  late final GeneratedColumn<String> calendarPreference =
      GeneratedColumn<String>('calendar_preference', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('gregorian'));
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _qrCodeMeta = const VerificationMeta('qrCode');
  @override
  late final GeneratedColumn<String> qrCode = GeneratedColumn<String>(
      'qr_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bankNameMeta =
      const VerificationMeta('bankName');
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
      'bank_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bankAccountNumberMeta =
      const VerificationMeta('bankAccountNumber');
  @override
  late final GeneratedColumn<String> bankAccountNumber =
      GeneratedColumn<String>('bank_account_number', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        employeeId,
        fullName,
        phoneNumber,
        nationalId,
        siteId,
        workTypeId,
        hireDate,
        terminationDate,
        status,
        calendarPreference,
        photoUrl,
        qrCode,
        bankName,
        bankAccountNumber,
        isSynced,
        lastSyncedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workers_table';
  @override
  VerificationContext validateIntegrity(Insertable<WorkersTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    }
    if (data.containsKey('national_id')) {
      context.handle(
          _nationalIdMeta,
          nationalId.isAcceptableOrUnknown(
              data['national_id']!, _nationalIdMeta));
    }
    if (data.containsKey('site_id')) {
      context.handle(_siteIdMeta,
          siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta));
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('work_type_id')) {
      context.handle(
          _workTypeIdMeta,
          workTypeId.isAcceptableOrUnknown(
              data['work_type_id']!, _workTypeIdMeta));
    } else if (isInserting) {
      context.missing(_workTypeIdMeta);
    }
    if (data.containsKey('hire_date')) {
      context.handle(_hireDateMeta,
          hireDate.isAcceptableOrUnknown(data['hire_date']!, _hireDateMeta));
    } else if (isInserting) {
      context.missing(_hireDateMeta);
    }
    if (data.containsKey('termination_date')) {
      context.handle(
          _terminationDateMeta,
          terminationDate.isAcceptableOrUnknown(
              data['termination_date']!, _terminationDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('calendar_preference')) {
      context.handle(
          _calendarPreferenceMeta,
          calendarPreference.isAcceptableOrUnknown(
              data['calendar_preference']!, _calendarPreferenceMeta));
    }
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    if (data.containsKey('qr_code')) {
      context.handle(_qrCodeMeta,
          qrCode.isAcceptableOrUnknown(data['qr_code']!, _qrCodeMeta));
    }
    if (data.containsKey('bank_name')) {
      context.handle(_bankNameMeta,
          bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta));
    }
    if (data.containsKey('bank_account_number')) {
      context.handle(
          _bankAccountNumberMeta,
          bankAccountNumber.isAcceptableOrUnknown(
              data['bank_account_number']!, _bankAccountNumberMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkersTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number']),
      nationalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}national_id']),
      siteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}site_id'])!,
      workTypeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}work_type_id'])!,
      hireDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}hire_date'])!,
      terminationDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}termination_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      calendarPreference: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}calendar_preference'])!,
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
      qrCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}qr_code']),
      bankName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_name']),
      bankAccountNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}bank_account_number']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WorkersTableTable createAlias(String alias) {
    return $WorkersTableTable(attachedDatabase, alias);
  }
}

class WorkersTableData extends DataClass
    implements Insertable<WorkersTableData> {
  final int id;
  final int? serverId;
  final String employeeId;
  final String fullName;
  final String? phoneNumber;
  final String? nationalId;
  final int siteId;
  final int workTypeId;
  final DateTime hireDate;
  final DateTime? terminationDate;
  final String status;
  final String calendarPreference;
  final String? photoUrl;
  final String? qrCode;
  final String? bankName;
  final String? bankAccountNumber;
  final bool isSynced;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WorkersTableData(
      {required this.id,
      this.serverId,
      required this.employeeId,
      required this.fullName,
      this.phoneNumber,
      this.nationalId,
      required this.siteId,
      required this.workTypeId,
      required this.hireDate,
      this.terminationDate,
      required this.status,
      required this.calendarPreference,
      this.photoUrl,
      this.qrCode,
      this.bankName,
      this.bankAccountNumber,
      required this.isSynced,
      this.lastSyncedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['employee_id'] = Variable<String>(employeeId);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || nationalId != null) {
      map['national_id'] = Variable<String>(nationalId);
    }
    map['site_id'] = Variable<int>(siteId);
    map['work_type_id'] = Variable<int>(workTypeId);
    map['hire_date'] = Variable<DateTime>(hireDate);
    if (!nullToAbsent || terminationDate != null) {
      map['termination_date'] = Variable<DateTime>(terminationDate);
    }
    map['status'] = Variable<String>(status);
    map['calendar_preference'] = Variable<String>(calendarPreference);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || qrCode != null) {
      map['qr_code'] = Variable<String>(qrCode);
    }
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || bankAccountNumber != null) {
      map['bank_account_number'] = Variable<String>(bankAccountNumber);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorkersTableCompanion toCompanion(bool nullToAbsent) {
    return WorkersTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      employeeId: Value(employeeId),
      fullName: Value(fullName),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      nationalId: nationalId == null && nullToAbsent
          ? const Value.absent()
          : Value(nationalId),
      siteId: Value(siteId),
      workTypeId: Value(workTypeId),
      hireDate: Value(hireDate),
      terminationDate: terminationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(terminationDate),
      status: Value(status),
      calendarPreference: Value(calendarPreference),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      qrCode:
          qrCode == null && nullToAbsent ? const Value.absent() : Value(qrCode),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      bankAccountNumber: bankAccountNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(bankAccountNumber),
      isSynced: Value(isSynced),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkersTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkersTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      fullName: serializer.fromJson<String>(json['fullName']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      nationalId: serializer.fromJson<String?>(json['nationalId']),
      siteId: serializer.fromJson<int>(json['siteId']),
      workTypeId: serializer.fromJson<int>(json['workTypeId']),
      hireDate: serializer.fromJson<DateTime>(json['hireDate']),
      terminationDate: serializer.fromJson<DateTime?>(json['terminationDate']),
      status: serializer.fromJson<String>(json['status']),
      calendarPreference:
          serializer.fromJson<String>(json['calendarPreference']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      qrCode: serializer.fromJson<String?>(json['qrCode']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      bankAccountNumber:
          serializer.fromJson<String?>(json['bankAccountNumber']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'employeeId': serializer.toJson<String>(employeeId),
      'fullName': serializer.toJson<String>(fullName),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'nationalId': serializer.toJson<String?>(nationalId),
      'siteId': serializer.toJson<int>(siteId),
      'workTypeId': serializer.toJson<int>(workTypeId),
      'hireDate': serializer.toJson<DateTime>(hireDate),
      'terminationDate': serializer.toJson<DateTime?>(terminationDate),
      'status': serializer.toJson<String>(status),
      'calendarPreference': serializer.toJson<String>(calendarPreference),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'qrCode': serializer.toJson<String?>(qrCode),
      'bankName': serializer.toJson<String?>(bankName),
      'bankAccountNumber': serializer.toJson<String?>(bankAccountNumber),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorkersTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          String? employeeId,
          String? fullName,
          Value<String?> phoneNumber = const Value.absent(),
          Value<String?> nationalId = const Value.absent(),
          int? siteId,
          int? workTypeId,
          DateTime? hireDate,
          Value<DateTime?> terminationDate = const Value.absent(),
          String? status,
          String? calendarPreference,
          Value<String?> photoUrl = const Value.absent(),
          Value<String?> qrCode = const Value.absent(),
          Value<String?> bankName = const Value.absent(),
          Value<String?> bankAccountNumber = const Value.absent(),
          bool? isSynced,
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      WorkersTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        employeeId: employeeId ?? this.employeeId,
        fullName: fullName ?? this.fullName,
        phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
        nationalId: nationalId.present ? nationalId.value : this.nationalId,
        siteId: siteId ?? this.siteId,
        workTypeId: workTypeId ?? this.workTypeId,
        hireDate: hireDate ?? this.hireDate,
        terminationDate: terminationDate.present
            ? terminationDate.value
            : this.terminationDate,
        status: status ?? this.status,
        calendarPreference: calendarPreference ?? this.calendarPreference,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
        qrCode: qrCode.present ? qrCode.value : this.qrCode,
        bankName: bankName.present ? bankName.value : this.bankName,
        bankAccountNumber: bankAccountNumber.present
            ? bankAccountNumber.value
            : this.bankAccountNumber,
        isSynced: isSynced ?? this.isSynced,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WorkersTableData copyWithCompanion(WorkersTableCompanion data) {
    return WorkersTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      nationalId:
          data.nationalId.present ? data.nationalId.value : this.nationalId,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      workTypeId:
          data.workTypeId.present ? data.workTypeId.value : this.workTypeId,
      hireDate: data.hireDate.present ? data.hireDate.value : this.hireDate,
      terminationDate: data.terminationDate.present
          ? data.terminationDate.value
          : this.terminationDate,
      status: data.status.present ? data.status.value : this.status,
      calendarPreference: data.calendarPreference.present
          ? data.calendarPreference.value
          : this.calendarPreference,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      qrCode: data.qrCode.present ? data.qrCode.value : this.qrCode,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      bankAccountNumber: data.bankAccountNumber.present
          ? data.bankAccountNumber.value
          : this.bankAccountNumber,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkersTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('employeeId: $employeeId, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('nationalId: $nationalId, ')
          ..write('siteId: $siteId, ')
          ..write('workTypeId: $workTypeId, ')
          ..write('hireDate: $hireDate, ')
          ..write('terminationDate: $terminationDate, ')
          ..write('status: $status, ')
          ..write('calendarPreference: $calendarPreference, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('qrCode: $qrCode, ')
          ..write('bankName: $bankName, ')
          ..write('bankAccountNumber: $bankAccountNumber, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      employeeId,
      fullName,
      phoneNumber,
      nationalId,
      siteId,
      workTypeId,
      hireDate,
      terminationDate,
      status,
      calendarPreference,
      photoUrl,
      qrCode,
      bankName,
      bankAccountNumber,
      isSynced,
      lastSyncedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkersTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.employeeId == this.employeeId &&
          other.fullName == this.fullName &&
          other.phoneNumber == this.phoneNumber &&
          other.nationalId == this.nationalId &&
          other.siteId == this.siteId &&
          other.workTypeId == this.workTypeId &&
          other.hireDate == this.hireDate &&
          other.terminationDate == this.terminationDate &&
          other.status == this.status &&
          other.calendarPreference == this.calendarPreference &&
          other.photoUrl == this.photoUrl &&
          other.qrCode == this.qrCode &&
          other.bankName == this.bankName &&
          other.bankAccountNumber == this.bankAccountNumber &&
          other.isSynced == this.isSynced &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkersTableCompanion extends UpdateCompanion<WorkersTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> employeeId;
  final Value<String> fullName;
  final Value<String?> phoneNumber;
  final Value<String?> nationalId;
  final Value<int> siteId;
  final Value<int> workTypeId;
  final Value<DateTime> hireDate;
  final Value<DateTime?> terminationDate;
  final Value<String> status;
  final Value<String> calendarPreference;
  final Value<String?> photoUrl;
  final Value<String?> qrCode;
  final Value<String?> bankName;
  final Value<String?> bankAccountNumber;
  final Value<bool> isSynced;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WorkersTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.nationalId = const Value.absent(),
    this.siteId = const Value.absent(),
    this.workTypeId = const Value.absent(),
    this.hireDate = const Value.absent(),
    this.terminationDate = const Value.absent(),
    this.status = const Value.absent(),
    this.calendarPreference = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.qrCode = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankAccountNumber = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WorkersTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String employeeId,
    required String fullName,
    this.phoneNumber = const Value.absent(),
    this.nationalId = const Value.absent(),
    required int siteId,
    required int workTypeId,
    required DateTime hireDate,
    this.terminationDate = const Value.absent(),
    required String status,
    this.calendarPreference = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.qrCode = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankAccountNumber = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : employeeId = Value(employeeId),
        fullName = Value(fullName),
        siteId = Value(siteId),
        workTypeId = Value(workTypeId),
        hireDate = Value(hireDate),
        status = Value(status);
  static Insertable<WorkersTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? employeeId,
    Expression<String>? fullName,
    Expression<String>? phoneNumber,
    Expression<String>? nationalId,
    Expression<int>? siteId,
    Expression<int>? workTypeId,
    Expression<DateTime>? hireDate,
    Expression<DateTime>? terminationDate,
    Expression<String>? status,
    Expression<String>? calendarPreference,
    Expression<String>? photoUrl,
    Expression<String>? qrCode,
    Expression<String>? bankName,
    Expression<String>? bankAccountNumber,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (employeeId != null) 'employee_id': employeeId,
      if (fullName != null) 'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (nationalId != null) 'national_id': nationalId,
      if (siteId != null) 'site_id': siteId,
      if (workTypeId != null) 'work_type_id': workTypeId,
      if (hireDate != null) 'hire_date': hireDate,
      if (terminationDate != null) 'termination_date': terminationDate,
      if (status != null) 'status': status,
      if (calendarPreference != null) 'calendar_preference': calendarPreference,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (qrCode != null) 'qr_code': qrCode,
      if (bankName != null) 'bank_name': bankName,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WorkersTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<String>? employeeId,
      Value<String>? fullName,
      Value<String?>? phoneNumber,
      Value<String?>? nationalId,
      Value<int>? siteId,
      Value<int>? workTypeId,
      Value<DateTime>? hireDate,
      Value<DateTime?>? terminationDate,
      Value<String>? status,
      Value<String>? calendarPreference,
      Value<String?>? photoUrl,
      Value<String?>? qrCode,
      Value<String?>? bankName,
      Value<String?>? bankAccountNumber,
      Value<bool>? isSynced,
      Value<DateTime?>? lastSyncedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return WorkersTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalId: nationalId ?? this.nationalId,
      siteId: siteId ?? this.siteId,
      workTypeId: workTypeId ?? this.workTypeId,
      hireDate: hireDate ?? this.hireDate,
      terminationDate: terminationDate ?? this.terminationDate,
      status: status ?? this.status,
      calendarPreference: calendarPreference ?? this.calendarPreference,
      photoUrl: photoUrl ?? this.photoUrl,
      qrCode: qrCode ?? this.qrCode,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (nationalId.present) {
      map['national_id'] = Variable<String>(nationalId.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<int>(siteId.value);
    }
    if (workTypeId.present) {
      map['work_type_id'] = Variable<int>(workTypeId.value);
    }
    if (hireDate.present) {
      map['hire_date'] = Variable<DateTime>(hireDate.value);
    }
    if (terminationDate.present) {
      map['termination_date'] = Variable<DateTime>(terminationDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (calendarPreference.present) {
      map['calendar_preference'] = Variable<String>(calendarPreference.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (qrCode.present) {
      map['qr_code'] = Variable<String>(qrCode.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (bankAccountNumber.present) {
      map['bank_account_number'] = Variable<String>(bankAccountNumber.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkersTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('employeeId: $employeeId, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('nationalId: $nationalId, ')
          ..write('siteId: $siteId, ')
          ..write('workTypeId: $workTypeId, ')
          ..write('hireDate: $hireDate, ')
          ..write('terminationDate: $terminationDate, ')
          ..write('status: $status, ')
          ..write('calendarPreference: $calendarPreference, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('qrCode: $qrCode, ')
          ..write('bankName: $bankName, ')
          ..write('bankAccountNumber: $bankAccountNumber, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SitesTableTable extends SitesTable
    with TableInfo<$SitesTableTable, SitesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SitesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationAddressMeta =
      const VerificationMeta('locationAddress');
  @override
  late final GeneratedColumn<String> locationAddress = GeneratedColumn<String>(
      'location_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        name,
        code,
        description,
        locationAddress,
        latitude,
        longitude,
        isActive,
        isSynced,
        lastSyncedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sites_table';
  @override
  VerificationContext validateIntegrity(Insertable<SitesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('location_address')) {
      context.handle(
          _locationAddressMeta,
          locationAddress.isAcceptableOrUnknown(
              data['location_address']!, _locationAddressMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SitesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SitesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      locationAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}location_address']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SitesTableTable createAlias(String alias) {
    return $SitesTableTable(attachedDatabase, alias);
  }
}

class SitesTableData extends DataClass implements Insertable<SitesTableData> {
  final int id;
  final int? serverId;
  final String name;
  final String code;
  final String? description;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final bool isSynced;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SitesTableData(
      {required this.id,
      this.serverId,
      required this.name,
      required this.code,
      this.description,
      this.locationAddress,
      this.latitude,
      this.longitude,
      required this.isActive,
      required this.isSynced,
      this.lastSyncedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || locationAddress != null) {
      map['location_address'] = Variable<String>(locationAddress);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SitesTableCompanion toCompanion(bool nullToAbsent) {
    return SitesTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      code: Value(code),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      locationAddress: locationAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(locationAddress),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      isActive: Value(isActive),
      isSynced: Value(isSynced),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SitesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SitesTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      description: serializer.fromJson<String?>(json['description']),
      locationAddress: serializer.fromJson<String?>(json['locationAddress']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'description': serializer.toJson<String?>(description),
      'locationAddress': serializer.toJson<String?>(locationAddress),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'isActive': serializer.toJson<bool>(isActive),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SitesTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          String? name,
          String? code,
          Value<String?> description = const Value.absent(),
          Value<String?> locationAddress = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          bool? isActive,
          bool? isSynced,
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SitesTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        name: name ?? this.name,
        code: code ?? this.code,
        description: description.present ? description.value : this.description,
        locationAddress: locationAddress.present
            ? locationAddress.value
            : this.locationAddress,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        isActive: isActive ?? this.isActive,
        isSynced: isSynced ?? this.isSynced,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SitesTableData copyWithCompanion(SitesTableCompanion data) {
    return SitesTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      description:
          data.description.present ? data.description.value : this.description,
      locationAddress: data.locationAddress.present
          ? data.locationAddress.value
          : this.locationAddress,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SitesTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('locationAddress: $locationAddress, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isActive: $isActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      name,
      code,
      description,
      locationAddress,
      latitude,
      longitude,
      isActive,
      isSynced,
      lastSyncedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SitesTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.code == this.code &&
          other.description == this.description &&
          other.locationAddress == this.locationAddress &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.isActive == this.isActive &&
          other.isSynced == this.isSynced &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SitesTableCompanion extends UpdateCompanion<SitesTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> name;
  final Value<String> code;
  final Value<String?> description;
  final Value<String?> locationAddress;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<bool> isActive;
  final Value<bool> isSynced;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SitesTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.description = const Value.absent(),
    this.locationAddress = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SitesTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    required String code,
    this.description = const Value.absent(),
    this.locationAddress = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        code = Value(code);
  static Insertable<SitesTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? description,
    Expression<String>? locationAddress,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<bool>? isActive,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (locationAddress != null) 'location_address': locationAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isActive != null) 'is_active': isActive,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SitesTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<String>? name,
      Value<String>? code,
      Value<String?>? description,
      Value<String?>? locationAddress,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<bool>? isActive,
      Value<bool>? isSynced,
      Value<DateTime?>? lastSyncedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SitesTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (locationAddress.present) {
      map['location_address'] = Variable<String>(locationAddress.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SitesTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('locationAddress: $locationAddress, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isActive: $isActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WorkTypesTableTable extends WorkTypesTable
    with TableInfo<$WorkTypesTableTable, WorkTypesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkTypesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentModeMeta =
      const VerificationMeta('paymentMode');
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
      'payment_mode', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _baseRateMeta =
      const VerificationMeta('baseRate');
  @override
  late final GeneratedColumn<double> baseRate = GeneratedColumn<double>(
      'base_rate', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _taxRuleMeta =
      const VerificationMeta('taxRule');
  @override
  late final GeneratedColumn<String> taxRule = GeneratedColumn<String>(
      'tax_rule', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _overtimeEligibleMeta =
      const VerificationMeta('overtimeEligible');
  @override
  late final GeneratedColumn<bool> overtimeEligible = GeneratedColumn<bool>(
      'overtime_eligible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("overtime_eligible" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _overtimeMultiplierMeta =
      const VerificationMeta('overtimeMultiplier');
  @override
  late final GeneratedColumn<double> overtimeMultiplier =
      GeneratedColumn<double>('overtime_multiplier', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(1.5));
  static const VerificationMeta _pensionEligibleMeta =
      const VerificationMeta('pensionEligible');
  @override
  late final GeneratedColumn<bool> pensionEligible = GeneratedColumn<bool>(
      'pension_eligible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pension_eligible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _employeePensionRateMeta =
      const VerificationMeta('employeePensionRate');
  @override
  late final GeneratedColumn<double> employeePensionRate =
      GeneratedColumn<double>('employee_pension_rate', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.07));
  static const VerificationMeta _employerPensionRateMeta =
      const VerificationMeta('employerPensionRate');
  @override
  late final GeneratedColumn<double> employerPensionRate =
      GeneratedColumn<double>('employer_pension_rate', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.11));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        name,
        code,
        description,
        paymentMode,
        baseRate,
        taxRule,
        overtimeEligible,
        overtimeMultiplier,
        pensionEligible,
        employeePensionRate,
        employerPensionRate,
        isActive,
        isSynced,
        lastSyncedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_types_table';
  @override
  VerificationContext validateIntegrity(Insertable<WorkTypesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
          _paymentModeMeta,
          paymentMode.isAcceptableOrUnknown(
              data['payment_mode']!, _paymentModeMeta));
    } else if (isInserting) {
      context.missing(_paymentModeMeta);
    }
    if (data.containsKey('base_rate')) {
      context.handle(_baseRateMeta,
          baseRate.isAcceptableOrUnknown(data['base_rate']!, _baseRateMeta));
    } else if (isInserting) {
      context.missing(_baseRateMeta);
    }
    if (data.containsKey('tax_rule')) {
      context.handle(_taxRuleMeta,
          taxRule.isAcceptableOrUnknown(data['tax_rule']!, _taxRuleMeta));
    } else if (isInserting) {
      context.missing(_taxRuleMeta);
    }
    if (data.containsKey('overtime_eligible')) {
      context.handle(
          _overtimeEligibleMeta,
          overtimeEligible.isAcceptableOrUnknown(
              data['overtime_eligible']!, _overtimeEligibleMeta));
    }
    if (data.containsKey('overtime_multiplier')) {
      context.handle(
          _overtimeMultiplierMeta,
          overtimeMultiplier.isAcceptableOrUnknown(
              data['overtime_multiplier']!, _overtimeMultiplierMeta));
    }
    if (data.containsKey('pension_eligible')) {
      context.handle(
          _pensionEligibleMeta,
          pensionEligible.isAcceptableOrUnknown(
              data['pension_eligible']!, _pensionEligibleMeta));
    }
    if (data.containsKey('employee_pension_rate')) {
      context.handle(
          _employeePensionRateMeta,
          employeePensionRate.isAcceptableOrUnknown(
              data['employee_pension_rate']!, _employeePensionRateMeta));
    }
    if (data.containsKey('employer_pension_rate')) {
      context.handle(
          _employerPensionRateMeta,
          employerPensionRate.isAcceptableOrUnknown(
              data['employer_pension_rate']!, _employerPensionRateMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkTypesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkTypesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      paymentMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_mode'])!,
      baseRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}base_rate'])!,
      taxRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tax_rule'])!,
      overtimeEligible: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}overtime_eligible'])!,
      overtimeMultiplier: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}overtime_multiplier'])!,
      pensionEligible: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pension_eligible'])!,
      employeePensionRate: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}employee_pension_rate'])!,
      employerPensionRate: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}employer_pension_rate'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WorkTypesTableTable createAlias(String alias) {
    return $WorkTypesTableTable(attachedDatabase, alias);
  }
}

class WorkTypesTableData extends DataClass
    implements Insertable<WorkTypesTableData> {
  final int id;
  final int? serverId;
  final String name;
  final String code;
  final String? description;
  final String paymentMode;
  final double baseRate;
  final String taxRule;
  final bool overtimeEligible;
  final double overtimeMultiplier;
  final bool pensionEligible;
  final double employeePensionRate;
  final double employerPensionRate;
  final bool isActive;
  final bool isSynced;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WorkTypesTableData(
      {required this.id,
      this.serverId,
      required this.name,
      required this.code,
      this.description,
      required this.paymentMode,
      required this.baseRate,
      required this.taxRule,
      required this.overtimeEligible,
      required this.overtimeMultiplier,
      required this.pensionEligible,
      required this.employeePensionRate,
      required this.employerPensionRate,
      required this.isActive,
      required this.isSynced,
      this.lastSyncedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['payment_mode'] = Variable<String>(paymentMode);
    map['base_rate'] = Variable<double>(baseRate);
    map['tax_rule'] = Variable<String>(taxRule);
    map['overtime_eligible'] = Variable<bool>(overtimeEligible);
    map['overtime_multiplier'] = Variable<double>(overtimeMultiplier);
    map['pension_eligible'] = Variable<bool>(pensionEligible);
    map['employee_pension_rate'] = Variable<double>(employeePensionRate);
    map['employer_pension_rate'] = Variable<double>(employerPensionRate);
    map['is_active'] = Variable<bool>(isActive);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorkTypesTableCompanion toCompanion(bool nullToAbsent) {
    return WorkTypesTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      code: Value(code),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      paymentMode: Value(paymentMode),
      baseRate: Value(baseRate),
      taxRule: Value(taxRule),
      overtimeEligible: Value(overtimeEligible),
      overtimeMultiplier: Value(overtimeMultiplier),
      pensionEligible: Value(pensionEligible),
      employeePensionRate: Value(employeePensionRate),
      employerPensionRate: Value(employerPensionRate),
      isActive: Value(isActive),
      isSynced: Value(isSynced),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkTypesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkTypesTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      description: serializer.fromJson<String?>(json['description']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
      baseRate: serializer.fromJson<double>(json['baseRate']),
      taxRule: serializer.fromJson<String>(json['taxRule']),
      overtimeEligible: serializer.fromJson<bool>(json['overtimeEligible']),
      overtimeMultiplier:
          serializer.fromJson<double>(json['overtimeMultiplier']),
      pensionEligible: serializer.fromJson<bool>(json['pensionEligible']),
      employeePensionRate:
          serializer.fromJson<double>(json['employeePensionRate']),
      employerPensionRate:
          serializer.fromJson<double>(json['employerPensionRate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'description': serializer.toJson<String?>(description),
      'paymentMode': serializer.toJson<String>(paymentMode),
      'baseRate': serializer.toJson<double>(baseRate),
      'taxRule': serializer.toJson<String>(taxRule),
      'overtimeEligible': serializer.toJson<bool>(overtimeEligible),
      'overtimeMultiplier': serializer.toJson<double>(overtimeMultiplier),
      'pensionEligible': serializer.toJson<bool>(pensionEligible),
      'employeePensionRate': serializer.toJson<double>(employeePensionRate),
      'employerPensionRate': serializer.toJson<double>(employerPensionRate),
      'isActive': serializer.toJson<bool>(isActive),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorkTypesTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          String? name,
          String? code,
          Value<String?> description = const Value.absent(),
          String? paymentMode,
          double? baseRate,
          String? taxRule,
          bool? overtimeEligible,
          double? overtimeMultiplier,
          bool? pensionEligible,
          double? employeePensionRate,
          double? employerPensionRate,
          bool? isActive,
          bool? isSynced,
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      WorkTypesTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        name: name ?? this.name,
        code: code ?? this.code,
        description: description.present ? description.value : this.description,
        paymentMode: paymentMode ?? this.paymentMode,
        baseRate: baseRate ?? this.baseRate,
        taxRule: taxRule ?? this.taxRule,
        overtimeEligible: overtimeEligible ?? this.overtimeEligible,
        overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
        pensionEligible: pensionEligible ?? this.pensionEligible,
        employeePensionRate: employeePensionRate ?? this.employeePensionRate,
        employerPensionRate: employerPensionRate ?? this.employerPensionRate,
        isActive: isActive ?? this.isActive,
        isSynced: isSynced ?? this.isSynced,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WorkTypesTableData copyWithCompanion(WorkTypesTableCompanion data) {
    return WorkTypesTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      description:
          data.description.present ? data.description.value : this.description,
      paymentMode:
          data.paymentMode.present ? data.paymentMode.value : this.paymentMode,
      baseRate: data.baseRate.present ? data.baseRate.value : this.baseRate,
      taxRule: data.taxRule.present ? data.taxRule.value : this.taxRule,
      overtimeEligible: data.overtimeEligible.present
          ? data.overtimeEligible.value
          : this.overtimeEligible,
      overtimeMultiplier: data.overtimeMultiplier.present
          ? data.overtimeMultiplier.value
          : this.overtimeMultiplier,
      pensionEligible: data.pensionEligible.present
          ? data.pensionEligible.value
          : this.pensionEligible,
      employeePensionRate: data.employeePensionRate.present
          ? data.employeePensionRate.value
          : this.employeePensionRate,
      employerPensionRate: data.employerPensionRate.present
          ? data.employerPensionRate.value
          : this.employerPensionRate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkTypesTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('baseRate: $baseRate, ')
          ..write('taxRule: $taxRule, ')
          ..write('overtimeEligible: $overtimeEligible, ')
          ..write('overtimeMultiplier: $overtimeMultiplier, ')
          ..write('pensionEligible: $pensionEligible, ')
          ..write('employeePensionRate: $employeePensionRate, ')
          ..write('employerPensionRate: $employerPensionRate, ')
          ..write('isActive: $isActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      serverId,
      name,
      code,
      description,
      paymentMode,
      baseRate,
      taxRule,
      overtimeEligible,
      overtimeMultiplier,
      pensionEligible,
      employeePensionRate,
      employerPensionRate,
      isActive,
      isSynced,
      lastSyncedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkTypesTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.code == this.code &&
          other.description == this.description &&
          other.paymentMode == this.paymentMode &&
          other.baseRate == this.baseRate &&
          other.taxRule == this.taxRule &&
          other.overtimeEligible == this.overtimeEligible &&
          other.overtimeMultiplier == this.overtimeMultiplier &&
          other.pensionEligible == this.pensionEligible &&
          other.employeePensionRate == this.employeePensionRate &&
          other.employerPensionRate == this.employerPensionRate &&
          other.isActive == this.isActive &&
          other.isSynced == this.isSynced &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkTypesTableCompanion extends UpdateCompanion<WorkTypesTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> name;
  final Value<String> code;
  final Value<String?> description;
  final Value<String> paymentMode;
  final Value<double> baseRate;
  final Value<String> taxRule;
  final Value<bool> overtimeEligible;
  final Value<double> overtimeMultiplier;
  final Value<bool> pensionEligible;
  final Value<double> employeePensionRate;
  final Value<double> employerPensionRate;
  final Value<bool> isActive;
  final Value<bool> isSynced;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WorkTypesTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.baseRate = const Value.absent(),
    this.taxRule = const Value.absent(),
    this.overtimeEligible = const Value.absent(),
    this.overtimeMultiplier = const Value.absent(),
    this.pensionEligible = const Value.absent(),
    this.employeePensionRate = const Value.absent(),
    this.employerPensionRate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WorkTypesTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    required String code,
    this.description = const Value.absent(),
    required String paymentMode,
    required double baseRate,
    required String taxRule,
    this.overtimeEligible = const Value.absent(),
    this.overtimeMultiplier = const Value.absent(),
    this.pensionEligible = const Value.absent(),
    this.employeePensionRate = const Value.absent(),
    this.employerPensionRate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        code = Value(code),
        paymentMode = Value(paymentMode),
        baseRate = Value(baseRate),
        taxRule = Value(taxRule);
  static Insertable<WorkTypesTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? description,
    Expression<String>? paymentMode,
    Expression<double>? baseRate,
    Expression<String>? taxRule,
    Expression<bool>? overtimeEligible,
    Expression<double>? overtimeMultiplier,
    Expression<bool>? pensionEligible,
    Expression<double>? employeePensionRate,
    Expression<double>? employerPensionRate,
    Expression<bool>? isActive,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (baseRate != null) 'base_rate': baseRate,
      if (taxRule != null) 'tax_rule': taxRule,
      if (overtimeEligible != null) 'overtime_eligible': overtimeEligible,
      if (overtimeMultiplier != null) 'overtime_multiplier': overtimeMultiplier,
      if (pensionEligible != null) 'pension_eligible': pensionEligible,
      if (employeePensionRate != null)
        'employee_pension_rate': employeePensionRate,
      if (employerPensionRate != null)
        'employer_pension_rate': employerPensionRate,
      if (isActive != null) 'is_active': isActive,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WorkTypesTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<String>? name,
      Value<String>? code,
      Value<String?>? description,
      Value<String>? paymentMode,
      Value<double>? baseRate,
      Value<String>? taxRule,
      Value<bool>? overtimeEligible,
      Value<double>? overtimeMultiplier,
      Value<bool>? pensionEligible,
      Value<double>? employeePensionRate,
      Value<double>? employerPensionRate,
      Value<bool>? isActive,
      Value<bool>? isSynced,
      Value<DateTime?>? lastSyncedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return WorkTypesTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      paymentMode: paymentMode ?? this.paymentMode,
      baseRate: baseRate ?? this.baseRate,
      taxRule: taxRule ?? this.taxRule,
      overtimeEligible: overtimeEligible ?? this.overtimeEligible,
      overtimeMultiplier: overtimeMultiplier ?? this.overtimeMultiplier,
      pensionEligible: pensionEligible ?? this.pensionEligible,
      employeePensionRate: employeePensionRate ?? this.employeePensionRate,
      employerPensionRate: employerPensionRate ?? this.employerPensionRate,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (baseRate.present) {
      map['base_rate'] = Variable<double>(baseRate.value);
    }
    if (taxRule.present) {
      map['tax_rule'] = Variable<String>(taxRule.value);
    }
    if (overtimeEligible.present) {
      map['overtime_eligible'] = Variable<bool>(overtimeEligible.value);
    }
    if (overtimeMultiplier.present) {
      map['overtime_multiplier'] = Variable<double>(overtimeMultiplier.value);
    }
    if (pensionEligible.present) {
      map['pension_eligible'] = Variable<bool>(pensionEligible.value);
    }
    if (employeePensionRate.present) {
      map['employee_pension_rate'] =
          Variable<double>(employeePensionRate.value);
    }
    if (employerPensionRate.present) {
      map['employer_pension_rate'] =
          Variable<double>(employerPensionRate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkTypesTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('baseRate: $baseRate, ')
          ..write('taxRule: $taxRule, ')
          ..write('overtimeEligible: $overtimeEligible, ')
          ..write('overtimeMultiplier: $overtimeMultiplier, ')
          ..write('pensionEligible: $pensionEligible, ')
          ..write('employeePensionRate: $employeePensionRate, ')
          ..write('employerPensionRate: $employerPensionRate, ')
          ..write('isActive: $isActive, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AttendancesTableTable extends AttendancesTable
    with TableInfo<$AttendancesTableTable, AttendancesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendancesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _workerIdMeta =
      const VerificationMeta('workerId');
  @override
  late final GeneratedColumn<int> workerId = GeneratedColumn<int>(
      'worker_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<int> siteId = GeneratedColumn<int>(
      'site_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _attendanceDateMeta =
      const VerificationMeta('attendanceDate');
  @override
  late final GeneratedColumn<DateTime> attendanceDate =
      GeneratedColumn<DateTime>('attendance_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _checkInTimeMeta =
      const VerificationMeta('checkInTime');
  @override
  late final GeneratedColumn<String> checkInTime = GeneratedColumn<String>(
      'check_in_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checkOutTimeMeta =
      const VerificationMeta('checkOutTime');
  @override
  late final GeneratedColumn<String> checkOutTime = GeneratedColumn<String>(
      'check_out_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _regularHoursMeta =
      const VerificationMeta('regularHours');
  @override
  late final GeneratedColumn<int> regularHours = GeneratedColumn<int>(
      'regular_hours', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(8));
  static const VerificationMeta _overtimeHoursMeta =
      const VerificationMeta('overtimeHours');
  @override
  late final GeneratedColumn<int> overtimeHours = GeneratedColumn<int>(
      'overtime_hours', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isVerifiedMeta =
      const VerificationMeta('isVerified');
  @override
  late final GeneratedColumn<bool> isVerified = GeneratedColumn<bool>(
      'is_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_verified" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _verifiedByIdMeta =
      const VerificationMeta('verifiedById');
  @override
  late final GeneratedColumn<int> verifiedById = GeneratedColumn<int>(
      'verified_by_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _verifiedAtMeta =
      const VerificationMeta('verifiedAt');
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
      'verified_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _overrideReasonMeta =
      const VerificationMeta('overrideReason');
  @override
  late final GeneratedColumn<String> overrideReason = GeneratedColumn<String>(
      'override_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ethiopianYearMeta =
      const VerificationMeta('ethiopianYear');
  @override
  late final GeneratedColumn<int> ethiopianYear = GeneratedColumn<int>(
      'ethiopian_year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _ethiopianMonthMeta =
      const VerificationMeta('ethiopianMonth');
  @override
  late final GeneratedColumn<int> ethiopianMonth = GeneratedColumn<int>(
      'ethiopian_month', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _ethiopianDayMeta =
      const VerificationMeta('ethiopianDay');
  @override
  late final GeneratedColumn<int> ethiopianDay = GeneratedColumn<int>(
      'ethiopian_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isLockedMeta =
      const VerificationMeta('isLocked');
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
      'is_locked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_locked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        workerId,
        siteId,
        attendanceDate,
        checkInTime,
        checkOutTime,
        status,
        method,
        regularHours,
        overtimeHours,
        isVerified,
        verifiedById,
        verifiedAt,
        overrideReason,
        notes,
        ethiopianYear,
        ethiopianMonth,
        ethiopianDay,
        isLocked,
        isSynced,
        lastSyncedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendances_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<AttendancesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('worker_id')) {
      context.handle(_workerIdMeta,
          workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta));
    } else if (isInserting) {
      context.missing(_workerIdMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(_siteIdMeta,
          siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta));
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('attendance_date')) {
      context.handle(
          _attendanceDateMeta,
          attendanceDate.isAcceptableOrUnknown(
              data['attendance_date']!, _attendanceDateMeta));
    } else if (isInserting) {
      context.missing(_attendanceDateMeta);
    }
    if (data.containsKey('check_in_time')) {
      context.handle(
          _checkInTimeMeta,
          checkInTime.isAcceptableOrUnknown(
              data['check_in_time']!, _checkInTimeMeta));
    }
    if (data.containsKey('check_out_time')) {
      context.handle(
          _checkOutTimeMeta,
          checkOutTime.isAcceptableOrUnknown(
              data['check_out_time']!, _checkOutTimeMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('regular_hours')) {
      context.handle(
          _regularHoursMeta,
          regularHours.isAcceptableOrUnknown(
              data['regular_hours']!, _regularHoursMeta));
    }
    if (data.containsKey('overtime_hours')) {
      context.handle(
          _overtimeHoursMeta,
          overtimeHours.isAcceptableOrUnknown(
              data['overtime_hours']!, _overtimeHoursMeta));
    }
    if (data.containsKey('is_verified')) {
      context.handle(
          _isVerifiedMeta,
          isVerified.isAcceptableOrUnknown(
              data['is_verified']!, _isVerifiedMeta));
    }
    if (data.containsKey('verified_by_id')) {
      context.handle(
          _verifiedByIdMeta,
          verifiedById.isAcceptableOrUnknown(
              data['verified_by_id']!, _verifiedByIdMeta));
    }
    if (data.containsKey('verified_at')) {
      context.handle(
          _verifiedAtMeta,
          verifiedAt.isAcceptableOrUnknown(
              data['verified_at']!, _verifiedAtMeta));
    }
    if (data.containsKey('override_reason')) {
      context.handle(
          _overrideReasonMeta,
          overrideReason.isAcceptableOrUnknown(
              data['override_reason']!, _overrideReasonMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('ethiopian_year')) {
      context.handle(
          _ethiopianYearMeta,
          ethiopianYear.isAcceptableOrUnknown(
              data['ethiopian_year']!, _ethiopianYearMeta));
    }
    if (data.containsKey('ethiopian_month')) {
      context.handle(
          _ethiopianMonthMeta,
          ethiopianMonth.isAcceptableOrUnknown(
              data['ethiopian_month']!, _ethiopianMonthMeta));
    }
    if (data.containsKey('ethiopian_day')) {
      context.handle(
          _ethiopianDayMeta,
          ethiopianDay.isAcceptableOrUnknown(
              data['ethiopian_day']!, _ethiopianDayMeta));
    }
    if (data.containsKey('is_locked')) {
      context.handle(_isLockedMeta,
          isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendancesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendancesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      workerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}worker_id'])!,
      siteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}site_id'])!,
      attendanceDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}attendance_date'])!,
      checkInTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_in_time']),
      checkOutTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_out_time']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      regularHours: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}regular_hours'])!,
      overtimeHours: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}overtime_hours'])!,
      isVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_verified'])!,
      verifiedById: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verified_by_id']),
      verifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}verified_at']),
      overrideReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}override_reason']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      ethiopianYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ethiopian_year']),
      ethiopianMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ethiopian_month']),
      ethiopianDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ethiopian_day']),
      isLocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_locked'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AttendancesTableTable createAlias(String alias) {
    return $AttendancesTableTable(attachedDatabase, alias);
  }
}

class AttendancesTableData extends DataClass
    implements Insertable<AttendancesTableData> {
  final int id;
  final int? serverId;
  final int workerId;
  final int siteId;
  final DateTime attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String status;
  final String method;
  final int regularHours;
  final int overtimeHours;
  final bool isVerified;
  final int? verifiedById;
  final DateTime? verifiedAt;
  final String? overrideReason;
  final String? notes;
  final int? ethiopianYear;
  final int? ethiopianMonth;
  final int? ethiopianDay;
  final bool isLocked;
  final bool isSynced;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AttendancesTableData(
      {required this.id,
      this.serverId,
      required this.workerId,
      required this.siteId,
      required this.attendanceDate,
      this.checkInTime,
      this.checkOutTime,
      required this.status,
      required this.method,
      required this.regularHours,
      required this.overtimeHours,
      required this.isVerified,
      this.verifiedById,
      this.verifiedAt,
      this.overrideReason,
      this.notes,
      this.ethiopianYear,
      this.ethiopianMonth,
      this.ethiopianDay,
      required this.isLocked,
      required this.isSynced,
      this.lastSyncedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['worker_id'] = Variable<int>(workerId);
    map['site_id'] = Variable<int>(siteId);
    map['attendance_date'] = Variable<DateTime>(attendanceDate);
    if (!nullToAbsent || checkInTime != null) {
      map['check_in_time'] = Variable<String>(checkInTime);
    }
    if (!nullToAbsent || checkOutTime != null) {
      map['check_out_time'] = Variable<String>(checkOutTime);
    }
    map['status'] = Variable<String>(status);
    map['method'] = Variable<String>(method);
    map['regular_hours'] = Variable<int>(regularHours);
    map['overtime_hours'] = Variable<int>(overtimeHours);
    map['is_verified'] = Variable<bool>(isVerified);
    if (!nullToAbsent || verifiedById != null) {
      map['verified_by_id'] = Variable<int>(verifiedById);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    if (!nullToAbsent || overrideReason != null) {
      map['override_reason'] = Variable<String>(overrideReason);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || ethiopianYear != null) {
      map['ethiopian_year'] = Variable<int>(ethiopianYear);
    }
    if (!nullToAbsent || ethiopianMonth != null) {
      map['ethiopian_month'] = Variable<int>(ethiopianMonth);
    }
    if (!nullToAbsent || ethiopianDay != null) {
      map['ethiopian_day'] = Variable<int>(ethiopianDay);
    }
    map['is_locked'] = Variable<bool>(isLocked);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AttendancesTableCompanion toCompanion(bool nullToAbsent) {
    return AttendancesTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      workerId: Value(workerId),
      siteId: Value(siteId),
      attendanceDate: Value(attendanceDate),
      checkInTime: checkInTime == null && nullToAbsent
          ? const Value.absent()
          : Value(checkInTime),
      checkOutTime: checkOutTime == null && nullToAbsent
          ? const Value.absent()
          : Value(checkOutTime),
      status: Value(status),
      method: Value(method),
      regularHours: Value(regularHours),
      overtimeHours: Value(overtimeHours),
      isVerified: Value(isVerified),
      verifiedById: verifiedById == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedById),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      overrideReason: overrideReason == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideReason),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      ethiopianYear: ethiopianYear == null && nullToAbsent
          ? const Value.absent()
          : Value(ethiopianYear),
      ethiopianMonth: ethiopianMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(ethiopianMonth),
      ethiopianDay: ethiopianDay == null && nullToAbsent
          ? const Value.absent()
          : Value(ethiopianDay),
      isLocked: Value(isLocked),
      isSynced: Value(isSynced),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AttendancesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendancesTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      workerId: serializer.fromJson<int>(json['workerId']),
      siteId: serializer.fromJson<int>(json['siteId']),
      attendanceDate: serializer.fromJson<DateTime>(json['attendanceDate']),
      checkInTime: serializer.fromJson<String?>(json['checkInTime']),
      checkOutTime: serializer.fromJson<String?>(json['checkOutTime']),
      status: serializer.fromJson<String>(json['status']),
      method: serializer.fromJson<String>(json['method']),
      regularHours: serializer.fromJson<int>(json['regularHours']),
      overtimeHours: serializer.fromJson<int>(json['overtimeHours']),
      isVerified: serializer.fromJson<bool>(json['isVerified']),
      verifiedById: serializer.fromJson<int?>(json['verifiedById']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      overrideReason: serializer.fromJson<String?>(json['overrideReason']),
      notes: serializer.fromJson<String?>(json['notes']),
      ethiopianYear: serializer.fromJson<int?>(json['ethiopianYear']),
      ethiopianMonth: serializer.fromJson<int?>(json['ethiopianMonth']),
      ethiopianDay: serializer.fromJson<int?>(json['ethiopianDay']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'workerId': serializer.toJson<int>(workerId),
      'siteId': serializer.toJson<int>(siteId),
      'attendanceDate': serializer.toJson<DateTime>(attendanceDate),
      'checkInTime': serializer.toJson<String?>(checkInTime),
      'checkOutTime': serializer.toJson<String?>(checkOutTime),
      'status': serializer.toJson<String>(status),
      'method': serializer.toJson<String>(method),
      'regularHours': serializer.toJson<int>(regularHours),
      'overtimeHours': serializer.toJson<int>(overtimeHours),
      'isVerified': serializer.toJson<bool>(isVerified),
      'verifiedById': serializer.toJson<int?>(verifiedById),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'overrideReason': serializer.toJson<String?>(overrideReason),
      'notes': serializer.toJson<String?>(notes),
      'ethiopianYear': serializer.toJson<int?>(ethiopianYear),
      'ethiopianMonth': serializer.toJson<int?>(ethiopianMonth),
      'ethiopianDay': serializer.toJson<int?>(ethiopianDay),
      'isLocked': serializer.toJson<bool>(isLocked),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AttendancesTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          int? workerId,
          int? siteId,
          DateTime? attendanceDate,
          Value<String?> checkInTime = const Value.absent(),
          Value<String?> checkOutTime = const Value.absent(),
          String? status,
          String? method,
          int? regularHours,
          int? overtimeHours,
          bool? isVerified,
          Value<int?> verifiedById = const Value.absent(),
          Value<DateTime?> verifiedAt = const Value.absent(),
          Value<String?> overrideReason = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<int?> ethiopianYear = const Value.absent(),
          Value<int?> ethiopianMonth = const Value.absent(),
          Value<int?> ethiopianDay = const Value.absent(),
          bool? isLocked,
          bool? isSynced,
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AttendancesTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        workerId: workerId ?? this.workerId,
        siteId: siteId ?? this.siteId,
        attendanceDate: attendanceDate ?? this.attendanceDate,
        checkInTime: checkInTime.present ? checkInTime.value : this.checkInTime,
        checkOutTime:
            checkOutTime.present ? checkOutTime.value : this.checkOutTime,
        status: status ?? this.status,
        method: method ?? this.method,
        regularHours: regularHours ?? this.regularHours,
        overtimeHours: overtimeHours ?? this.overtimeHours,
        isVerified: isVerified ?? this.isVerified,
        verifiedById:
            verifiedById.present ? verifiedById.value : this.verifiedById,
        verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
        overrideReason:
            overrideReason.present ? overrideReason.value : this.overrideReason,
        notes: notes.present ? notes.value : this.notes,
        ethiopianYear:
            ethiopianYear.present ? ethiopianYear.value : this.ethiopianYear,
        ethiopianMonth:
            ethiopianMonth.present ? ethiopianMonth.value : this.ethiopianMonth,
        ethiopianDay:
            ethiopianDay.present ? ethiopianDay.value : this.ethiopianDay,
        isLocked: isLocked ?? this.isLocked,
        isSynced: isSynced ?? this.isSynced,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AttendancesTableData copyWithCompanion(AttendancesTableCompanion data) {
    return AttendancesTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      attendanceDate: data.attendanceDate.present
          ? data.attendanceDate.value
          : this.attendanceDate,
      checkInTime:
          data.checkInTime.present ? data.checkInTime.value : this.checkInTime,
      checkOutTime: data.checkOutTime.present
          ? data.checkOutTime.value
          : this.checkOutTime,
      status: data.status.present ? data.status.value : this.status,
      method: data.method.present ? data.method.value : this.method,
      regularHours: data.regularHours.present
          ? data.regularHours.value
          : this.regularHours,
      overtimeHours: data.overtimeHours.present
          ? data.overtimeHours.value
          : this.overtimeHours,
      isVerified:
          data.isVerified.present ? data.isVerified.value : this.isVerified,
      verifiedById: data.verifiedById.present
          ? data.verifiedById.value
          : this.verifiedById,
      verifiedAt:
          data.verifiedAt.present ? data.verifiedAt.value : this.verifiedAt,
      overrideReason: data.overrideReason.present
          ? data.overrideReason.value
          : this.overrideReason,
      notes: data.notes.present ? data.notes.value : this.notes,
      ethiopianYear: data.ethiopianYear.present
          ? data.ethiopianYear.value
          : this.ethiopianYear,
      ethiopianMonth: data.ethiopianMonth.present
          ? data.ethiopianMonth.value
          : this.ethiopianMonth,
      ethiopianDay: data.ethiopianDay.present
          ? data.ethiopianDay.value
          : this.ethiopianDay,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendancesTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('workerId: $workerId, ')
          ..write('siteId: $siteId, ')
          ..write('attendanceDate: $attendanceDate, ')
          ..write('checkInTime: $checkInTime, ')
          ..write('checkOutTime: $checkOutTime, ')
          ..write('status: $status, ')
          ..write('method: $method, ')
          ..write('regularHours: $regularHours, ')
          ..write('overtimeHours: $overtimeHours, ')
          ..write('isVerified: $isVerified, ')
          ..write('verifiedById: $verifiedById, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('overrideReason: $overrideReason, ')
          ..write('notes: $notes, ')
          ..write('ethiopianYear: $ethiopianYear, ')
          ..write('ethiopianMonth: $ethiopianMonth, ')
          ..write('ethiopianDay: $ethiopianDay, ')
          ..write('isLocked: $isLocked, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        serverId,
        workerId,
        siteId,
        attendanceDate,
        checkInTime,
        checkOutTime,
        status,
        method,
        regularHours,
        overtimeHours,
        isVerified,
        verifiedById,
        verifiedAt,
        overrideReason,
        notes,
        ethiopianYear,
        ethiopianMonth,
        ethiopianDay,
        isLocked,
        isSynced,
        lastSyncedAt,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendancesTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.workerId == this.workerId &&
          other.siteId == this.siteId &&
          other.attendanceDate == this.attendanceDate &&
          other.checkInTime == this.checkInTime &&
          other.checkOutTime == this.checkOutTime &&
          other.status == this.status &&
          other.method == this.method &&
          other.regularHours == this.regularHours &&
          other.overtimeHours == this.overtimeHours &&
          other.isVerified == this.isVerified &&
          other.verifiedById == this.verifiedById &&
          other.verifiedAt == this.verifiedAt &&
          other.overrideReason == this.overrideReason &&
          other.notes == this.notes &&
          other.ethiopianYear == this.ethiopianYear &&
          other.ethiopianMonth == this.ethiopianMonth &&
          other.ethiopianDay == this.ethiopianDay &&
          other.isLocked == this.isLocked &&
          other.isSynced == this.isSynced &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AttendancesTableCompanion extends UpdateCompanion<AttendancesTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> workerId;
  final Value<int> siteId;
  final Value<DateTime> attendanceDate;
  final Value<String?> checkInTime;
  final Value<String?> checkOutTime;
  final Value<String> status;
  final Value<String> method;
  final Value<int> regularHours;
  final Value<int> overtimeHours;
  final Value<bool> isVerified;
  final Value<int?> verifiedById;
  final Value<DateTime?> verifiedAt;
  final Value<String?> overrideReason;
  final Value<String?> notes;
  final Value<int?> ethiopianYear;
  final Value<int?> ethiopianMonth;
  final Value<int?> ethiopianDay;
  final Value<bool> isLocked;
  final Value<bool> isSynced;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AttendancesTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.workerId = const Value.absent(),
    this.siteId = const Value.absent(),
    this.attendanceDate = const Value.absent(),
    this.checkInTime = const Value.absent(),
    this.checkOutTime = const Value.absent(),
    this.status = const Value.absent(),
    this.method = const Value.absent(),
    this.regularHours = const Value.absent(),
    this.overtimeHours = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.verifiedById = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.overrideReason = const Value.absent(),
    this.notes = const Value.absent(),
    this.ethiopianYear = const Value.absent(),
    this.ethiopianMonth = const Value.absent(),
    this.ethiopianDay = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AttendancesTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int workerId,
    required int siteId,
    required DateTime attendanceDate,
    this.checkInTime = const Value.absent(),
    this.checkOutTime = const Value.absent(),
    required String status,
    required String method,
    this.regularHours = const Value.absent(),
    this.overtimeHours = const Value.absent(),
    this.isVerified = const Value.absent(),
    this.verifiedById = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.overrideReason = const Value.absent(),
    this.notes = const Value.absent(),
    this.ethiopianYear = const Value.absent(),
    this.ethiopianMonth = const Value.absent(),
    this.ethiopianDay = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : workerId = Value(workerId),
        siteId = Value(siteId),
        attendanceDate = Value(attendanceDate),
        status = Value(status),
        method = Value(method);
  static Insertable<AttendancesTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? workerId,
    Expression<int>? siteId,
    Expression<DateTime>? attendanceDate,
    Expression<String>? checkInTime,
    Expression<String>? checkOutTime,
    Expression<String>? status,
    Expression<String>? method,
    Expression<int>? regularHours,
    Expression<int>? overtimeHours,
    Expression<bool>? isVerified,
    Expression<int>? verifiedById,
    Expression<DateTime>? verifiedAt,
    Expression<String>? overrideReason,
    Expression<String>? notes,
    Expression<int>? ethiopianYear,
    Expression<int>? ethiopianMonth,
    Expression<int>? ethiopianDay,
    Expression<bool>? isLocked,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (workerId != null) 'worker_id': workerId,
      if (siteId != null) 'site_id': siteId,
      if (attendanceDate != null) 'attendance_date': attendanceDate,
      if (checkInTime != null) 'check_in_time': checkInTime,
      if (checkOutTime != null) 'check_out_time': checkOutTime,
      if (status != null) 'status': status,
      if (method != null) 'method': method,
      if (regularHours != null) 'regular_hours': regularHours,
      if (overtimeHours != null) 'overtime_hours': overtimeHours,
      if (isVerified != null) 'is_verified': isVerified,
      if (verifiedById != null) 'verified_by_id': verifiedById,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (overrideReason != null) 'override_reason': overrideReason,
      if (notes != null) 'notes': notes,
      if (ethiopianYear != null) 'ethiopian_year': ethiopianYear,
      if (ethiopianMonth != null) 'ethiopian_month': ethiopianMonth,
      if (ethiopianDay != null) 'ethiopian_day': ethiopianDay,
      if (isLocked != null) 'is_locked': isLocked,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AttendancesTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<int>? workerId,
      Value<int>? siteId,
      Value<DateTime>? attendanceDate,
      Value<String?>? checkInTime,
      Value<String?>? checkOutTime,
      Value<String>? status,
      Value<String>? method,
      Value<int>? regularHours,
      Value<int>? overtimeHours,
      Value<bool>? isVerified,
      Value<int?>? verifiedById,
      Value<DateTime?>? verifiedAt,
      Value<String?>? overrideReason,
      Value<String?>? notes,
      Value<int?>? ethiopianYear,
      Value<int?>? ethiopianMonth,
      Value<int?>? ethiopianDay,
      Value<bool>? isLocked,
      Value<bool>? isSynced,
      Value<DateTime?>? lastSyncedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return AttendancesTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      workerId: workerId ?? this.workerId,
      siteId: siteId ?? this.siteId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      method: method ?? this.method,
      regularHours: regularHours ?? this.regularHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      isVerified: isVerified ?? this.isVerified,
      verifiedById: verifiedById ?? this.verifiedById,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      overrideReason: overrideReason ?? this.overrideReason,
      notes: notes ?? this.notes,
      ethiopianYear: ethiopianYear ?? this.ethiopianYear,
      ethiopianMonth: ethiopianMonth ?? this.ethiopianMonth,
      ethiopianDay: ethiopianDay ?? this.ethiopianDay,
      isLocked: isLocked ?? this.isLocked,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<int>(workerId.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<int>(siteId.value);
    }
    if (attendanceDate.present) {
      map['attendance_date'] = Variable<DateTime>(attendanceDate.value);
    }
    if (checkInTime.present) {
      map['check_in_time'] = Variable<String>(checkInTime.value);
    }
    if (checkOutTime.present) {
      map['check_out_time'] = Variable<String>(checkOutTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (regularHours.present) {
      map['regular_hours'] = Variable<int>(regularHours.value);
    }
    if (overtimeHours.present) {
      map['overtime_hours'] = Variable<int>(overtimeHours.value);
    }
    if (isVerified.present) {
      map['is_verified'] = Variable<bool>(isVerified.value);
    }
    if (verifiedById.present) {
      map['verified_by_id'] = Variable<int>(verifiedById.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (overrideReason.present) {
      map['override_reason'] = Variable<String>(overrideReason.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (ethiopianYear.present) {
      map['ethiopian_year'] = Variable<int>(ethiopianYear.value);
    }
    if (ethiopianMonth.present) {
      map['ethiopian_month'] = Variable<int>(ethiopianMonth.value);
    }
    if (ethiopianDay.present) {
      map['ethiopian_day'] = Variable<int>(ethiopianDay.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendancesTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('workerId: $workerId, ')
          ..write('siteId: $siteId, ')
          ..write('attendanceDate: $attendanceDate, ')
          ..write('checkInTime: $checkInTime, ')
          ..write('checkOutTime: $checkOutTime, ')
          ..write('status: $status, ')
          ..write('method: $method, ')
          ..write('regularHours: $regularHours, ')
          ..write('overtimeHours: $overtimeHours, ')
          ..write('isVerified: $isVerified, ')
          ..write('verifiedById: $verifiedById, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('overrideReason: $overrideReason, ')
          ..write('notes: $notes, ')
          ..write('ethiopianYear: $ethiopianYear, ')
          ..write('ethiopianMonth: $ethiopianMonth, ')
          ..write('ethiopianDay: $ethiopianDay, ')
          ..write('isLocked: $isLocked, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PayrollsTableTable extends PayrollsTable
    with TableInfo<$PayrollsTableTable, PayrollsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayrollsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _payrollCodeMeta =
      const VerificationMeta('payrollCode');
  @override
  late final GeneratedColumn<String> payrollCode = GeneratedColumn<String>(
      'payroll_code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<int> siteId = GeneratedColumn<int>(
      'site_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _periodTypeMeta =
      const VerificationMeta('periodType');
  @override
  late final GeneratedColumn<String> periodType = GeneratedColumn<String>(
      'period_type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _periodStartMeta =
      const VerificationMeta('periodStart');
  @override
  late final GeneratedColumn<DateTime> periodStart = GeneratedColumn<DateTime>(
      'period_start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _periodEndMeta =
      const VerificationMeta('periodEnd');
  @override
  late final GeneratedColumn<DateTime> periodEnd = GeneratedColumn<DateTime>(
      'period_end', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _ethiopianMonthMeta =
      const VerificationMeta('ethiopianMonth');
  @override
  late final GeneratedColumn<String> ethiopianMonth = GeneratedColumn<String>(
      'ethiopian_month', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ethiopianYearMeta =
      const VerificationMeta('ethiopianYear');
  @override
  late final GeneratedColumn<int> ethiopianYear = GeneratedColumn<int>(
      'ethiopian_year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalGrossAmountMeta =
      const VerificationMeta('totalGrossAmount');
  @override
  late final GeneratedColumn<double> totalGrossAmount = GeneratedColumn<double>(
      'total_gross_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalDeductionsMeta =
      const VerificationMeta('totalDeductions');
  @override
  late final GeneratedColumn<double> totalDeductions = GeneratedColumn<double>(
      'total_deductions', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalNetAmountMeta =
      const VerificationMeta('totalNetAmount');
  @override
  late final GeneratedColumn<double> totalNetAmount = GeneratedColumn<double>(
      'total_net_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalEmployerPensionMeta =
      const VerificationMeta('totalEmployerPension');
  @override
  late final GeneratedColumn<double> totalEmployerPension =
      GeneratedColumn<double>('total_employer_pension', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _calculatedByIdMeta =
      const VerificationMeta('calculatedById');
  @override
  late final GeneratedColumn<int> calculatedById = GeneratedColumn<int>(
      'calculated_by_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _approvedByIdMeta =
      const VerificationMeta('approvedById');
  @override
  late final GeneratedColumn<int> approvedById = GeneratedColumn<int>(
      'approved_by_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _approvedAtMeta =
      const VerificationMeta('approvedAt');
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
      'approved_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        payrollCode,
        siteId,
        periodType,
        periodStart,
        periodEnd,
        ethiopianMonth,
        ethiopianYear,
        totalGrossAmount,
        totalDeductions,
        totalNetAmount,
        totalEmployerPension,
        status,
        calculatedById,
        approvedById,
        approvedAt,
        notes,
        isSynced,
        lastSyncedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payrolls_table';
  @override
  VerificationContext validateIntegrity(Insertable<PayrollsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('payroll_code')) {
      context.handle(
          _payrollCodeMeta,
          payrollCode.isAcceptableOrUnknown(
              data['payroll_code']!, _payrollCodeMeta));
    } else if (isInserting) {
      context.missing(_payrollCodeMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(_siteIdMeta,
          siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta));
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('period_type')) {
      context.handle(
          _periodTypeMeta,
          periodType.isAcceptableOrUnknown(
              data['period_type']!, _periodTypeMeta));
    } else if (isInserting) {
      context.missing(_periodTypeMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
          _periodStartMeta,
          periodStart.isAcceptableOrUnknown(
              data['period_start']!, _periodStartMeta));
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(_periodEndMeta,
          periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta));
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('ethiopian_month')) {
      context.handle(
          _ethiopianMonthMeta,
          ethiopianMonth.isAcceptableOrUnknown(
              data['ethiopian_month']!, _ethiopianMonthMeta));
    }
    if (data.containsKey('ethiopian_year')) {
      context.handle(
          _ethiopianYearMeta,
          ethiopianYear.isAcceptableOrUnknown(
              data['ethiopian_year']!, _ethiopianYearMeta));
    }
    if (data.containsKey('total_gross_amount')) {
      context.handle(
          _totalGrossAmountMeta,
          totalGrossAmount.isAcceptableOrUnknown(
              data['total_gross_amount']!, _totalGrossAmountMeta));
    }
    if (data.containsKey('total_deductions')) {
      context.handle(
          _totalDeductionsMeta,
          totalDeductions.isAcceptableOrUnknown(
              data['total_deductions']!, _totalDeductionsMeta));
    }
    if (data.containsKey('total_net_amount')) {
      context.handle(
          _totalNetAmountMeta,
          totalNetAmount.isAcceptableOrUnknown(
              data['total_net_amount']!, _totalNetAmountMeta));
    }
    if (data.containsKey('total_employer_pension')) {
      context.handle(
          _totalEmployerPensionMeta,
          totalEmployerPension.isAcceptableOrUnknown(
              data['total_employer_pension']!, _totalEmployerPensionMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('calculated_by_id')) {
      context.handle(
          _calculatedByIdMeta,
          calculatedById.isAcceptableOrUnknown(
              data['calculated_by_id']!, _calculatedByIdMeta));
    }
    if (data.containsKey('approved_by_id')) {
      context.handle(
          _approvedByIdMeta,
          approvedById.isAcceptableOrUnknown(
              data['approved_by_id']!, _approvedByIdMeta));
    }
    if (data.containsKey('approved_at')) {
      context.handle(
          _approvedAtMeta,
          approvedAt.isAcceptableOrUnknown(
              data['approved_at']!, _approvedAtMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PayrollsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayrollsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      payrollCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payroll_code'])!,
      siteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}site_id'])!,
      periodType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period_type'])!,
      periodStart: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}period_start'])!,
      periodEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}period_end'])!,
      ethiopianMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ethiopian_month']),
      ethiopianYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ethiopian_year']),
      totalGrossAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_gross_amount'])!,
      totalDeductions: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_deductions'])!,
      totalNetAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_net_amount'])!,
      totalEmployerPension: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}total_employer_pension'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      calculatedById: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calculated_by_id']),
      approvedById: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}approved_by_id']),
      approvedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}approved_at']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PayrollsTableTable createAlias(String alias) {
    return $PayrollsTableTable(attachedDatabase, alias);
  }
}

class PayrollsTableData extends DataClass
    implements Insertable<PayrollsTableData> {
  final int id;
  final int? serverId;
  final String payrollCode;
  final int siteId;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String? ethiopianMonth;
  final int? ethiopianYear;
  final double totalGrossAmount;
  final double totalDeductions;
  final double totalNetAmount;
  final double totalEmployerPension;
  final String status;
  final int? calculatedById;
  final int? approvedById;
  final DateTime? approvedAt;
  final String? notes;
  final bool isSynced;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PayrollsTableData(
      {required this.id,
      this.serverId,
      required this.payrollCode,
      required this.siteId,
      required this.periodType,
      required this.periodStart,
      required this.periodEnd,
      this.ethiopianMonth,
      this.ethiopianYear,
      required this.totalGrossAmount,
      required this.totalDeductions,
      required this.totalNetAmount,
      required this.totalEmployerPension,
      required this.status,
      this.calculatedById,
      this.approvedById,
      this.approvedAt,
      this.notes,
      required this.isSynced,
      this.lastSyncedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['payroll_code'] = Variable<String>(payrollCode);
    map['site_id'] = Variable<int>(siteId);
    map['period_type'] = Variable<String>(periodType);
    map['period_start'] = Variable<DateTime>(periodStart);
    map['period_end'] = Variable<DateTime>(periodEnd);
    if (!nullToAbsent || ethiopianMonth != null) {
      map['ethiopian_month'] = Variable<String>(ethiopianMonth);
    }
    if (!nullToAbsent || ethiopianYear != null) {
      map['ethiopian_year'] = Variable<int>(ethiopianYear);
    }
    map['total_gross_amount'] = Variable<double>(totalGrossAmount);
    map['total_deductions'] = Variable<double>(totalDeductions);
    map['total_net_amount'] = Variable<double>(totalNetAmount);
    map['total_employer_pension'] = Variable<double>(totalEmployerPension);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || calculatedById != null) {
      map['calculated_by_id'] = Variable<int>(calculatedById);
    }
    if (!nullToAbsent || approvedById != null) {
      map['approved_by_id'] = Variable<int>(approvedById);
    }
    if (!nullToAbsent || approvedAt != null) {
      map['approved_at'] = Variable<DateTime>(approvedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PayrollsTableCompanion toCompanion(bool nullToAbsent) {
    return PayrollsTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      payrollCode: Value(payrollCode),
      siteId: Value(siteId),
      periodType: Value(periodType),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      ethiopianMonth: ethiopianMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(ethiopianMonth),
      ethiopianYear: ethiopianYear == null && nullToAbsent
          ? const Value.absent()
          : Value(ethiopianYear),
      totalGrossAmount: Value(totalGrossAmount),
      totalDeductions: Value(totalDeductions),
      totalNetAmount: Value(totalNetAmount),
      totalEmployerPension: Value(totalEmployerPension),
      status: Value(status),
      calculatedById: calculatedById == null && nullToAbsent
          ? const Value.absent()
          : Value(calculatedById),
      approvedById: approvedById == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedById),
      approvedAt: approvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isSynced: Value(isSynced),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PayrollsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayrollsTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      payrollCode: serializer.fromJson<String>(json['payrollCode']),
      siteId: serializer.fromJson<int>(json['siteId']),
      periodType: serializer.fromJson<String>(json['periodType']),
      periodStart: serializer.fromJson<DateTime>(json['periodStart']),
      periodEnd: serializer.fromJson<DateTime>(json['periodEnd']),
      ethiopianMonth: serializer.fromJson<String?>(json['ethiopianMonth']),
      ethiopianYear: serializer.fromJson<int?>(json['ethiopianYear']),
      totalGrossAmount: serializer.fromJson<double>(json['totalGrossAmount']),
      totalDeductions: serializer.fromJson<double>(json['totalDeductions']),
      totalNetAmount: serializer.fromJson<double>(json['totalNetAmount']),
      totalEmployerPension:
          serializer.fromJson<double>(json['totalEmployerPension']),
      status: serializer.fromJson<String>(json['status']),
      calculatedById: serializer.fromJson<int?>(json['calculatedById']),
      approvedById: serializer.fromJson<int?>(json['approvedById']),
      approvedAt: serializer.fromJson<DateTime?>(json['approvedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'payrollCode': serializer.toJson<String>(payrollCode),
      'siteId': serializer.toJson<int>(siteId),
      'periodType': serializer.toJson<String>(periodType),
      'periodStart': serializer.toJson<DateTime>(periodStart),
      'periodEnd': serializer.toJson<DateTime>(periodEnd),
      'ethiopianMonth': serializer.toJson<String?>(ethiopianMonth),
      'ethiopianYear': serializer.toJson<int?>(ethiopianYear),
      'totalGrossAmount': serializer.toJson<double>(totalGrossAmount),
      'totalDeductions': serializer.toJson<double>(totalDeductions),
      'totalNetAmount': serializer.toJson<double>(totalNetAmount),
      'totalEmployerPension': serializer.toJson<double>(totalEmployerPension),
      'status': serializer.toJson<String>(status),
      'calculatedById': serializer.toJson<int?>(calculatedById),
      'approvedById': serializer.toJson<int?>(approvedById),
      'approvedAt': serializer.toJson<DateTime?>(approvedAt),
      'notes': serializer.toJson<String?>(notes),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PayrollsTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          String? payrollCode,
          int? siteId,
          String? periodType,
          DateTime? periodStart,
          DateTime? periodEnd,
          Value<String?> ethiopianMonth = const Value.absent(),
          Value<int?> ethiopianYear = const Value.absent(),
          double? totalGrossAmount,
          double? totalDeductions,
          double? totalNetAmount,
          double? totalEmployerPension,
          String? status,
          Value<int?> calculatedById = const Value.absent(),
          Value<int?> approvedById = const Value.absent(),
          Value<DateTime?> approvedAt = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? isSynced,
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      PayrollsTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        payrollCode: payrollCode ?? this.payrollCode,
        siteId: siteId ?? this.siteId,
        periodType: periodType ?? this.periodType,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
        ethiopianMonth:
            ethiopianMonth.present ? ethiopianMonth.value : this.ethiopianMonth,
        ethiopianYear:
            ethiopianYear.present ? ethiopianYear.value : this.ethiopianYear,
        totalGrossAmount: totalGrossAmount ?? this.totalGrossAmount,
        totalDeductions: totalDeductions ?? this.totalDeductions,
        totalNetAmount: totalNetAmount ?? this.totalNetAmount,
        totalEmployerPension: totalEmployerPension ?? this.totalEmployerPension,
        status: status ?? this.status,
        calculatedById:
            calculatedById.present ? calculatedById.value : this.calculatedById,
        approvedById:
            approvedById.present ? approvedById.value : this.approvedById,
        approvedAt: approvedAt.present ? approvedAt.value : this.approvedAt,
        notes: notes.present ? notes.value : this.notes,
        isSynced: isSynced ?? this.isSynced,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PayrollsTableData copyWithCompanion(PayrollsTableCompanion data) {
    return PayrollsTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      payrollCode:
          data.payrollCode.present ? data.payrollCode.value : this.payrollCode,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      periodType:
          data.periodType.present ? data.periodType.value : this.periodType,
      periodStart:
          data.periodStart.present ? data.periodStart.value : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      ethiopianMonth: data.ethiopianMonth.present
          ? data.ethiopianMonth.value
          : this.ethiopianMonth,
      ethiopianYear: data.ethiopianYear.present
          ? data.ethiopianYear.value
          : this.ethiopianYear,
      totalGrossAmount: data.totalGrossAmount.present
          ? data.totalGrossAmount.value
          : this.totalGrossAmount,
      totalDeductions: data.totalDeductions.present
          ? data.totalDeductions.value
          : this.totalDeductions,
      totalNetAmount: data.totalNetAmount.present
          ? data.totalNetAmount.value
          : this.totalNetAmount,
      totalEmployerPension: data.totalEmployerPension.present
          ? data.totalEmployerPension.value
          : this.totalEmployerPension,
      status: data.status.present ? data.status.value : this.status,
      calculatedById: data.calculatedById.present
          ? data.calculatedById.value
          : this.calculatedById,
      approvedById: data.approvedById.present
          ? data.approvedById.value
          : this.approvedById,
      approvedAt:
          data.approvedAt.present ? data.approvedAt.value : this.approvedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayrollsTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('payrollCode: $payrollCode, ')
          ..write('siteId: $siteId, ')
          ..write('periodType: $periodType, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('ethiopianMonth: $ethiopianMonth, ')
          ..write('ethiopianYear: $ethiopianYear, ')
          ..write('totalGrossAmount: $totalGrossAmount, ')
          ..write('totalDeductions: $totalDeductions, ')
          ..write('totalNetAmount: $totalNetAmount, ')
          ..write('totalEmployerPension: $totalEmployerPension, ')
          ..write('status: $status, ')
          ..write('calculatedById: $calculatedById, ')
          ..write('approvedById: $approvedById, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('notes: $notes, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        serverId,
        payrollCode,
        siteId,
        periodType,
        periodStart,
        periodEnd,
        ethiopianMonth,
        ethiopianYear,
        totalGrossAmount,
        totalDeductions,
        totalNetAmount,
        totalEmployerPension,
        status,
        calculatedById,
        approvedById,
        approvedAt,
        notes,
        isSynced,
        lastSyncedAt,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayrollsTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.payrollCode == this.payrollCode &&
          other.siteId == this.siteId &&
          other.periodType == this.periodType &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.ethiopianMonth == this.ethiopianMonth &&
          other.ethiopianYear == this.ethiopianYear &&
          other.totalGrossAmount == this.totalGrossAmount &&
          other.totalDeductions == this.totalDeductions &&
          other.totalNetAmount == this.totalNetAmount &&
          other.totalEmployerPension == this.totalEmployerPension &&
          other.status == this.status &&
          other.calculatedById == this.calculatedById &&
          other.approvedById == this.approvedById &&
          other.approvedAt == this.approvedAt &&
          other.notes == this.notes &&
          other.isSynced == this.isSynced &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PayrollsTableCompanion extends UpdateCompanion<PayrollsTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> payrollCode;
  final Value<int> siteId;
  final Value<String> periodType;
  final Value<DateTime> periodStart;
  final Value<DateTime> periodEnd;
  final Value<String?> ethiopianMonth;
  final Value<int?> ethiopianYear;
  final Value<double> totalGrossAmount;
  final Value<double> totalDeductions;
  final Value<double> totalNetAmount;
  final Value<double> totalEmployerPension;
  final Value<String> status;
  final Value<int?> calculatedById;
  final Value<int?> approvedById;
  final Value<DateTime?> approvedAt;
  final Value<String?> notes;
  final Value<bool> isSynced;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PayrollsTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.payrollCode = const Value.absent(),
    this.siteId = const Value.absent(),
    this.periodType = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.ethiopianMonth = const Value.absent(),
    this.ethiopianYear = const Value.absent(),
    this.totalGrossAmount = const Value.absent(),
    this.totalDeductions = const Value.absent(),
    this.totalNetAmount = const Value.absent(),
    this.totalEmployerPension = const Value.absent(),
    this.status = const Value.absent(),
    this.calculatedById = const Value.absent(),
    this.approvedById = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PayrollsTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String payrollCode,
    required int siteId,
    required String periodType,
    required DateTime periodStart,
    required DateTime periodEnd,
    this.ethiopianMonth = const Value.absent(),
    this.ethiopianYear = const Value.absent(),
    this.totalGrossAmount = const Value.absent(),
    this.totalDeductions = const Value.absent(),
    this.totalNetAmount = const Value.absent(),
    this.totalEmployerPension = const Value.absent(),
    required String status,
    this.calculatedById = const Value.absent(),
    this.approvedById = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : payrollCode = Value(payrollCode),
        siteId = Value(siteId),
        periodType = Value(periodType),
        periodStart = Value(periodStart),
        periodEnd = Value(periodEnd),
        status = Value(status);
  static Insertable<PayrollsTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? payrollCode,
    Expression<int>? siteId,
    Expression<String>? periodType,
    Expression<DateTime>? periodStart,
    Expression<DateTime>? periodEnd,
    Expression<String>? ethiopianMonth,
    Expression<int>? ethiopianYear,
    Expression<double>? totalGrossAmount,
    Expression<double>? totalDeductions,
    Expression<double>? totalNetAmount,
    Expression<double>? totalEmployerPension,
    Expression<String>? status,
    Expression<int>? calculatedById,
    Expression<int>? approvedById,
    Expression<DateTime>? approvedAt,
    Expression<String>? notes,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (payrollCode != null) 'payroll_code': payrollCode,
      if (siteId != null) 'site_id': siteId,
      if (periodType != null) 'period_type': periodType,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (ethiopianMonth != null) 'ethiopian_month': ethiopianMonth,
      if (ethiopianYear != null) 'ethiopian_year': ethiopianYear,
      if (totalGrossAmount != null) 'total_gross_amount': totalGrossAmount,
      if (totalDeductions != null) 'total_deductions': totalDeductions,
      if (totalNetAmount != null) 'total_net_amount': totalNetAmount,
      if (totalEmployerPension != null)
        'total_employer_pension': totalEmployerPension,
      if (status != null) 'status': status,
      if (calculatedById != null) 'calculated_by_id': calculatedById,
      if (approvedById != null) 'approved_by_id': approvedById,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (notes != null) 'notes': notes,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PayrollsTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<String>? payrollCode,
      Value<int>? siteId,
      Value<String>? periodType,
      Value<DateTime>? periodStart,
      Value<DateTime>? periodEnd,
      Value<String?>? ethiopianMonth,
      Value<int?>? ethiopianYear,
      Value<double>? totalGrossAmount,
      Value<double>? totalDeductions,
      Value<double>? totalNetAmount,
      Value<double>? totalEmployerPension,
      Value<String>? status,
      Value<int?>? calculatedById,
      Value<int?>? approvedById,
      Value<DateTime?>? approvedAt,
      Value<String?>? notes,
      Value<bool>? isSynced,
      Value<DateTime?>? lastSyncedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return PayrollsTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      payrollCode: payrollCode ?? this.payrollCode,
      siteId: siteId ?? this.siteId,
      periodType: periodType ?? this.periodType,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      ethiopianMonth: ethiopianMonth ?? this.ethiopianMonth,
      ethiopianYear: ethiopianYear ?? this.ethiopianYear,
      totalGrossAmount: totalGrossAmount ?? this.totalGrossAmount,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      totalNetAmount: totalNetAmount ?? this.totalNetAmount,
      totalEmployerPension: totalEmployerPension ?? this.totalEmployerPension,
      status: status ?? this.status,
      calculatedById: calculatedById ?? this.calculatedById,
      approvedById: approvedById ?? this.approvedById,
      approvedAt: approvedAt ?? this.approvedAt,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (payrollCode.present) {
      map['payroll_code'] = Variable<String>(payrollCode.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<int>(siteId.value);
    }
    if (periodType.present) {
      map['period_type'] = Variable<String>(periodType.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<DateTime>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<DateTime>(periodEnd.value);
    }
    if (ethiopianMonth.present) {
      map['ethiopian_month'] = Variable<String>(ethiopianMonth.value);
    }
    if (ethiopianYear.present) {
      map['ethiopian_year'] = Variable<int>(ethiopianYear.value);
    }
    if (totalGrossAmount.present) {
      map['total_gross_amount'] = Variable<double>(totalGrossAmount.value);
    }
    if (totalDeductions.present) {
      map['total_deductions'] = Variable<double>(totalDeductions.value);
    }
    if (totalNetAmount.present) {
      map['total_net_amount'] = Variable<double>(totalNetAmount.value);
    }
    if (totalEmployerPension.present) {
      map['total_employer_pension'] =
          Variable<double>(totalEmployerPension.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (calculatedById.present) {
      map['calculated_by_id'] = Variable<int>(calculatedById.value);
    }
    if (approvedById.present) {
      map['approved_by_id'] = Variable<int>(approvedById.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PayrollsTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('payrollCode: $payrollCode, ')
          ..write('siteId: $siteId, ')
          ..write('periodType: $periodType, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('ethiopianMonth: $ethiopianMonth, ')
          ..write('ethiopianYear: $ethiopianYear, ')
          ..write('totalGrossAmount: $totalGrossAmount, ')
          ..write('totalDeductions: $totalDeductions, ')
          ..write('totalNetAmount: $totalNetAmount, ')
          ..write('totalEmployerPension: $totalEmployerPension, ')
          ..write('status: $status, ')
          ..write('calculatedById: $calculatedById, ')
          ..write('approvedById: $approvedById, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('notes: $notes, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PayrollItemsTableTable extends PayrollItemsTable
    with TableInfo<$PayrollItemsTableTable, PayrollItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayrollItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _payrollIdMeta =
      const VerificationMeta('payrollId');
  @override
  late final GeneratedColumn<int> payrollId = GeneratedColumn<int>(
      'payroll_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _workerIdMeta =
      const VerificationMeta('workerId');
  @override
  late final GeneratedColumn<int> workerId = GeneratedColumn<int>(
      'worker_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _daysWorkedMeta =
      const VerificationMeta('daysWorked');
  @override
  late final GeneratedColumn<int> daysWorked = GeneratedColumn<int>(
      'days_worked', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _regularHoursMeta =
      const VerificationMeta('regularHours');
  @override
  late final GeneratedColumn<int> regularHours = GeneratedColumn<int>(
      'regular_hours', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _overtimeHoursMeta =
      const VerificationMeta('overtimeHours');
  @override
  late final GeneratedColumn<int> overtimeHours = GeneratedColumn<int>(
      'overtime_hours', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _baseSalaryMeta =
      const VerificationMeta('baseSalary');
  @override
  late final GeneratedColumn<double> baseSalary = GeneratedColumn<double>(
      'base_salary', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _overtimePayMeta =
      const VerificationMeta('overtimePay');
  @override
  late final GeneratedColumn<double> overtimePay = GeneratedColumn<double>(
      'overtime_pay', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _allowancesMeta =
      const VerificationMeta('allowances');
  @override
  late final GeneratedColumn<double> allowances = GeneratedColumn<double>(
      'allowances', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _grossSalaryMeta =
      const VerificationMeta('grossSalary');
  @override
  late final GeneratedColumn<double> grossSalary = GeneratedColumn<double>(
      'gross_salary', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _incomeTaxMeta =
      const VerificationMeta('incomeTax');
  @override
  late final GeneratedColumn<double> incomeTax = GeneratedColumn<double>(
      'income_tax', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _employeePensionMeta =
      const VerificationMeta('employeePension');
  @override
  late final GeneratedColumn<double> employeePension = GeneratedColumn<double>(
      'employee_pension', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _employerPensionMeta =
      const VerificationMeta('employerPension');
  @override
  late final GeneratedColumn<double> employerPension = GeneratedColumn<double>(
      'employer_pension', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _costSharingMeta =
      const VerificationMeta('costSharing');
  @override
  late final GeneratedColumn<double> costSharing = GeneratedColumn<double>(
      'cost_sharing', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _otherDeductionsMeta =
      const VerificationMeta('otherDeductions');
  @override
  late final GeneratedColumn<double> otherDeductions = GeneratedColumn<double>(
      'other_deductions', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalDeductionsMeta =
      const VerificationMeta('totalDeductions');
  @override
  late final GeneratedColumn<double> totalDeductions = GeneratedColumn<double>(
      'total_deductions', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _netSalaryMeta =
      const VerificationMeta('netSalary');
  @override
  late final GeneratedColumn<double> netSalary = GeneratedColumn<double>(
      'net_salary', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _taxRuleAppliedMeta =
      const VerificationMeta('taxRuleApplied');
  @override
  late final GeneratedColumn<String> taxRuleApplied = GeneratedColumn<String>(
      'tax_rule_applied', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        payrollId,
        workerId,
        daysWorked,
        regularHours,
        overtimeHours,
        baseSalary,
        overtimePay,
        allowances,
        grossSalary,
        incomeTax,
        employeePension,
        employerPension,
        costSharing,
        otherDeductions,
        totalDeductions,
        netSalary,
        taxRuleApplied,
        notes,
        isSynced,
        lastSyncedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payroll_items_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<PayrollItemsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('payroll_id')) {
      context.handle(_payrollIdMeta,
          payrollId.isAcceptableOrUnknown(data['payroll_id']!, _payrollIdMeta));
    } else if (isInserting) {
      context.missing(_payrollIdMeta);
    }
    if (data.containsKey('worker_id')) {
      context.handle(_workerIdMeta,
          workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta));
    } else if (isInserting) {
      context.missing(_workerIdMeta);
    }
    if (data.containsKey('days_worked')) {
      context.handle(
          _daysWorkedMeta,
          daysWorked.isAcceptableOrUnknown(
              data['days_worked']!, _daysWorkedMeta));
    }
    if (data.containsKey('regular_hours')) {
      context.handle(
          _regularHoursMeta,
          regularHours.isAcceptableOrUnknown(
              data['regular_hours']!, _regularHoursMeta));
    }
    if (data.containsKey('overtime_hours')) {
      context.handle(
          _overtimeHoursMeta,
          overtimeHours.isAcceptableOrUnknown(
              data['overtime_hours']!, _overtimeHoursMeta));
    }
    if (data.containsKey('base_salary')) {
      context.handle(
          _baseSalaryMeta,
          baseSalary.isAcceptableOrUnknown(
              data['base_salary']!, _baseSalaryMeta));
    }
    if (data.containsKey('overtime_pay')) {
      context.handle(
          _overtimePayMeta,
          overtimePay.isAcceptableOrUnknown(
              data['overtime_pay']!, _overtimePayMeta));
    }
    if (data.containsKey('allowances')) {
      context.handle(
          _allowancesMeta,
          allowances.isAcceptableOrUnknown(
              data['allowances']!, _allowancesMeta));
    }
    if (data.containsKey('gross_salary')) {
      context.handle(
          _grossSalaryMeta,
          grossSalary.isAcceptableOrUnknown(
              data['gross_salary']!, _grossSalaryMeta));
    }
    if (data.containsKey('income_tax')) {
      context.handle(_incomeTaxMeta,
          incomeTax.isAcceptableOrUnknown(data['income_tax']!, _incomeTaxMeta));
    }
    if (data.containsKey('employee_pension')) {
      context.handle(
          _employeePensionMeta,
          employeePension.isAcceptableOrUnknown(
              data['employee_pension']!, _employeePensionMeta));
    }
    if (data.containsKey('employer_pension')) {
      context.handle(
          _employerPensionMeta,
          employerPension.isAcceptableOrUnknown(
              data['employer_pension']!, _employerPensionMeta));
    }
    if (data.containsKey('cost_sharing')) {
      context.handle(
          _costSharingMeta,
          costSharing.isAcceptableOrUnknown(
              data['cost_sharing']!, _costSharingMeta));
    }
    if (data.containsKey('other_deductions')) {
      context.handle(
          _otherDeductionsMeta,
          otherDeductions.isAcceptableOrUnknown(
              data['other_deductions']!, _otherDeductionsMeta));
    }
    if (data.containsKey('total_deductions')) {
      context.handle(
          _totalDeductionsMeta,
          totalDeductions.isAcceptableOrUnknown(
              data['total_deductions']!, _totalDeductionsMeta));
    }
    if (data.containsKey('net_salary')) {
      context.handle(_netSalaryMeta,
          netSalary.isAcceptableOrUnknown(data['net_salary']!, _netSalaryMeta));
    }
    if (data.containsKey('tax_rule_applied')) {
      context.handle(
          _taxRuleAppliedMeta,
          taxRuleApplied.isAcceptableOrUnknown(
              data['tax_rule_applied']!, _taxRuleAppliedMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PayrollItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayrollItemsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      payrollId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payroll_id'])!,
      workerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}worker_id'])!,
      daysWorked: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}days_worked'])!,
      regularHours: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}regular_hours'])!,
      overtimeHours: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}overtime_hours'])!,
      baseSalary: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}base_salary'])!,
      overtimePay: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}overtime_pay'])!,
      allowances: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}allowances'])!,
      grossSalary: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gross_salary'])!,
      incomeTax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}income_tax'])!,
      employeePension: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}employee_pension'])!,
      employerPension: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}employer_pension'])!,
      costSharing: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_sharing'])!,
      otherDeductions: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}other_deductions'])!,
      totalDeductions: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_deductions'])!,
      netSalary: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}net_salary'])!,
      taxRuleApplied: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}tax_rule_applied']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PayrollItemsTableTable createAlias(String alias) {
    return $PayrollItemsTableTable(attachedDatabase, alias);
  }
}

class PayrollItemsTableData extends DataClass
    implements Insertable<PayrollItemsTableData> {
  final int id;
  final int? serverId;
  final int payrollId;
  final int workerId;
  final int daysWorked;
  final int regularHours;
  final int overtimeHours;
  final double baseSalary;
  final double overtimePay;
  final double allowances;
  final double grossSalary;
  final double incomeTax;
  final double employeePension;
  final double employerPension;
  final double costSharing;
  final double otherDeductions;
  final double totalDeductions;
  final double netSalary;
  final String? taxRuleApplied;
  final String? notes;
  final bool isSynced;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PayrollItemsTableData(
      {required this.id,
      this.serverId,
      required this.payrollId,
      required this.workerId,
      required this.daysWorked,
      required this.regularHours,
      required this.overtimeHours,
      required this.baseSalary,
      required this.overtimePay,
      required this.allowances,
      required this.grossSalary,
      required this.incomeTax,
      required this.employeePension,
      required this.employerPension,
      required this.costSharing,
      required this.otherDeductions,
      required this.totalDeductions,
      required this.netSalary,
      this.taxRuleApplied,
      this.notes,
      required this.isSynced,
      this.lastSyncedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['payroll_id'] = Variable<int>(payrollId);
    map['worker_id'] = Variable<int>(workerId);
    map['days_worked'] = Variable<int>(daysWorked);
    map['regular_hours'] = Variable<int>(regularHours);
    map['overtime_hours'] = Variable<int>(overtimeHours);
    map['base_salary'] = Variable<double>(baseSalary);
    map['overtime_pay'] = Variable<double>(overtimePay);
    map['allowances'] = Variable<double>(allowances);
    map['gross_salary'] = Variable<double>(grossSalary);
    map['income_tax'] = Variable<double>(incomeTax);
    map['employee_pension'] = Variable<double>(employeePension);
    map['employer_pension'] = Variable<double>(employerPension);
    map['cost_sharing'] = Variable<double>(costSharing);
    map['other_deductions'] = Variable<double>(otherDeductions);
    map['total_deductions'] = Variable<double>(totalDeductions);
    map['net_salary'] = Variable<double>(netSalary);
    if (!nullToAbsent || taxRuleApplied != null) {
      map['tax_rule_applied'] = Variable<String>(taxRuleApplied);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PayrollItemsTableCompanion toCompanion(bool nullToAbsent) {
    return PayrollItemsTableCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      payrollId: Value(payrollId),
      workerId: Value(workerId),
      daysWorked: Value(daysWorked),
      regularHours: Value(regularHours),
      overtimeHours: Value(overtimeHours),
      baseSalary: Value(baseSalary),
      overtimePay: Value(overtimePay),
      allowances: Value(allowances),
      grossSalary: Value(grossSalary),
      incomeTax: Value(incomeTax),
      employeePension: Value(employeePension),
      employerPension: Value(employerPension),
      costSharing: Value(costSharing),
      otherDeductions: Value(otherDeductions),
      totalDeductions: Value(totalDeductions),
      netSalary: Value(netSalary),
      taxRuleApplied: taxRuleApplied == null && nullToAbsent
          ? const Value.absent()
          : Value(taxRuleApplied),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isSynced: Value(isSynced),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PayrollItemsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayrollItemsTableData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      payrollId: serializer.fromJson<int>(json['payrollId']),
      workerId: serializer.fromJson<int>(json['workerId']),
      daysWorked: serializer.fromJson<int>(json['daysWorked']),
      regularHours: serializer.fromJson<int>(json['regularHours']),
      overtimeHours: serializer.fromJson<int>(json['overtimeHours']),
      baseSalary: serializer.fromJson<double>(json['baseSalary']),
      overtimePay: serializer.fromJson<double>(json['overtimePay']),
      allowances: serializer.fromJson<double>(json['allowances']),
      grossSalary: serializer.fromJson<double>(json['grossSalary']),
      incomeTax: serializer.fromJson<double>(json['incomeTax']),
      employeePension: serializer.fromJson<double>(json['employeePension']),
      employerPension: serializer.fromJson<double>(json['employerPension']),
      costSharing: serializer.fromJson<double>(json['costSharing']),
      otherDeductions: serializer.fromJson<double>(json['otherDeductions']),
      totalDeductions: serializer.fromJson<double>(json['totalDeductions']),
      netSalary: serializer.fromJson<double>(json['netSalary']),
      taxRuleApplied: serializer.fromJson<String?>(json['taxRuleApplied']),
      notes: serializer.fromJson<String?>(json['notes']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'payrollId': serializer.toJson<int>(payrollId),
      'workerId': serializer.toJson<int>(workerId),
      'daysWorked': serializer.toJson<int>(daysWorked),
      'regularHours': serializer.toJson<int>(regularHours),
      'overtimeHours': serializer.toJson<int>(overtimeHours),
      'baseSalary': serializer.toJson<double>(baseSalary),
      'overtimePay': serializer.toJson<double>(overtimePay),
      'allowances': serializer.toJson<double>(allowances),
      'grossSalary': serializer.toJson<double>(grossSalary),
      'incomeTax': serializer.toJson<double>(incomeTax),
      'employeePension': serializer.toJson<double>(employeePension),
      'employerPension': serializer.toJson<double>(employerPension),
      'costSharing': serializer.toJson<double>(costSharing),
      'otherDeductions': serializer.toJson<double>(otherDeductions),
      'totalDeductions': serializer.toJson<double>(totalDeductions),
      'netSalary': serializer.toJson<double>(netSalary),
      'taxRuleApplied': serializer.toJson<String?>(taxRuleApplied),
      'notes': serializer.toJson<String?>(notes),
      'isSynced': serializer.toJson<bool>(isSynced),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PayrollItemsTableData copyWith(
          {int? id,
          Value<int?> serverId = const Value.absent(),
          int? payrollId,
          int? workerId,
          int? daysWorked,
          int? regularHours,
          int? overtimeHours,
          double? baseSalary,
          double? overtimePay,
          double? allowances,
          double? grossSalary,
          double? incomeTax,
          double? employeePension,
          double? employerPension,
          double? costSharing,
          double? otherDeductions,
          double? totalDeductions,
          double? netSalary,
          Value<String?> taxRuleApplied = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? isSynced,
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      PayrollItemsTableData(
        id: id ?? this.id,
        serverId: serverId.present ? serverId.value : this.serverId,
        payrollId: payrollId ?? this.payrollId,
        workerId: workerId ?? this.workerId,
        daysWorked: daysWorked ?? this.daysWorked,
        regularHours: regularHours ?? this.regularHours,
        overtimeHours: overtimeHours ?? this.overtimeHours,
        baseSalary: baseSalary ?? this.baseSalary,
        overtimePay: overtimePay ?? this.overtimePay,
        allowances: allowances ?? this.allowances,
        grossSalary: grossSalary ?? this.grossSalary,
        incomeTax: incomeTax ?? this.incomeTax,
        employeePension: employeePension ?? this.employeePension,
        employerPension: employerPension ?? this.employerPension,
        costSharing: costSharing ?? this.costSharing,
        otherDeductions: otherDeductions ?? this.otherDeductions,
        totalDeductions: totalDeductions ?? this.totalDeductions,
        netSalary: netSalary ?? this.netSalary,
        taxRuleApplied:
            taxRuleApplied.present ? taxRuleApplied.value : this.taxRuleApplied,
        notes: notes.present ? notes.value : this.notes,
        isSynced: isSynced ?? this.isSynced,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PayrollItemsTableData copyWithCompanion(PayrollItemsTableCompanion data) {
    return PayrollItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      payrollId: data.payrollId.present ? data.payrollId.value : this.payrollId,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      daysWorked:
          data.daysWorked.present ? data.daysWorked.value : this.daysWorked,
      regularHours: data.regularHours.present
          ? data.regularHours.value
          : this.regularHours,
      overtimeHours: data.overtimeHours.present
          ? data.overtimeHours.value
          : this.overtimeHours,
      baseSalary:
          data.baseSalary.present ? data.baseSalary.value : this.baseSalary,
      overtimePay:
          data.overtimePay.present ? data.overtimePay.value : this.overtimePay,
      allowances:
          data.allowances.present ? data.allowances.value : this.allowances,
      grossSalary:
          data.grossSalary.present ? data.grossSalary.value : this.grossSalary,
      incomeTax: data.incomeTax.present ? data.incomeTax.value : this.incomeTax,
      employeePension: data.employeePension.present
          ? data.employeePension.value
          : this.employeePension,
      employerPension: data.employerPension.present
          ? data.employerPension.value
          : this.employerPension,
      costSharing:
          data.costSharing.present ? data.costSharing.value : this.costSharing,
      otherDeductions: data.otherDeductions.present
          ? data.otherDeductions.value
          : this.otherDeductions,
      totalDeductions: data.totalDeductions.present
          ? data.totalDeductions.value
          : this.totalDeductions,
      netSalary: data.netSalary.present ? data.netSalary.value : this.netSalary,
      taxRuleApplied: data.taxRuleApplied.present
          ? data.taxRuleApplied.value
          : this.taxRuleApplied,
      notes: data.notes.present ? data.notes.value : this.notes,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayrollItemsTableData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('payrollId: $payrollId, ')
          ..write('workerId: $workerId, ')
          ..write('daysWorked: $daysWorked, ')
          ..write('regularHours: $regularHours, ')
          ..write('overtimeHours: $overtimeHours, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('overtimePay: $overtimePay, ')
          ..write('allowances: $allowances, ')
          ..write('grossSalary: $grossSalary, ')
          ..write('incomeTax: $incomeTax, ')
          ..write('employeePension: $employeePension, ')
          ..write('employerPension: $employerPension, ')
          ..write('costSharing: $costSharing, ')
          ..write('otherDeductions: $otherDeductions, ')
          ..write('totalDeductions: $totalDeductions, ')
          ..write('netSalary: $netSalary, ')
          ..write('taxRuleApplied: $taxRuleApplied, ')
          ..write('notes: $notes, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        serverId,
        payrollId,
        workerId,
        daysWorked,
        regularHours,
        overtimeHours,
        baseSalary,
        overtimePay,
        allowances,
        grossSalary,
        incomeTax,
        employeePension,
        employerPension,
        costSharing,
        otherDeductions,
        totalDeductions,
        netSalary,
        taxRuleApplied,
        notes,
        isSynced,
        lastSyncedAt,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayrollItemsTableData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.payrollId == this.payrollId &&
          other.workerId == this.workerId &&
          other.daysWorked == this.daysWorked &&
          other.regularHours == this.regularHours &&
          other.overtimeHours == this.overtimeHours &&
          other.baseSalary == this.baseSalary &&
          other.overtimePay == this.overtimePay &&
          other.allowances == this.allowances &&
          other.grossSalary == this.grossSalary &&
          other.incomeTax == this.incomeTax &&
          other.employeePension == this.employeePension &&
          other.employerPension == this.employerPension &&
          other.costSharing == this.costSharing &&
          other.otherDeductions == this.otherDeductions &&
          other.totalDeductions == this.totalDeductions &&
          other.netSalary == this.netSalary &&
          other.taxRuleApplied == this.taxRuleApplied &&
          other.notes == this.notes &&
          other.isSynced == this.isSynced &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PayrollItemsTableCompanion
    extends UpdateCompanion<PayrollItemsTableData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> payrollId;
  final Value<int> workerId;
  final Value<int> daysWorked;
  final Value<int> regularHours;
  final Value<int> overtimeHours;
  final Value<double> baseSalary;
  final Value<double> overtimePay;
  final Value<double> allowances;
  final Value<double> grossSalary;
  final Value<double> incomeTax;
  final Value<double> employeePension;
  final Value<double> employerPension;
  final Value<double> costSharing;
  final Value<double> otherDeductions;
  final Value<double> totalDeductions;
  final Value<double> netSalary;
  final Value<String?> taxRuleApplied;
  final Value<String?> notes;
  final Value<bool> isSynced;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PayrollItemsTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.payrollId = const Value.absent(),
    this.workerId = const Value.absent(),
    this.daysWorked = const Value.absent(),
    this.regularHours = const Value.absent(),
    this.overtimeHours = const Value.absent(),
    this.baseSalary = const Value.absent(),
    this.overtimePay = const Value.absent(),
    this.allowances = const Value.absent(),
    this.grossSalary = const Value.absent(),
    this.incomeTax = const Value.absent(),
    this.employeePension = const Value.absent(),
    this.employerPension = const Value.absent(),
    this.costSharing = const Value.absent(),
    this.otherDeductions = const Value.absent(),
    this.totalDeductions = const Value.absent(),
    this.netSalary = const Value.absent(),
    this.taxRuleApplied = const Value.absent(),
    this.notes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PayrollItemsTableCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int payrollId,
    required int workerId,
    this.daysWorked = const Value.absent(),
    this.regularHours = const Value.absent(),
    this.overtimeHours = const Value.absent(),
    this.baseSalary = const Value.absent(),
    this.overtimePay = const Value.absent(),
    this.allowances = const Value.absent(),
    this.grossSalary = const Value.absent(),
    this.incomeTax = const Value.absent(),
    this.employeePension = const Value.absent(),
    this.employerPension = const Value.absent(),
    this.costSharing = const Value.absent(),
    this.otherDeductions = const Value.absent(),
    this.totalDeductions = const Value.absent(),
    this.netSalary = const Value.absent(),
    this.taxRuleApplied = const Value.absent(),
    this.notes = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : payrollId = Value(payrollId),
        workerId = Value(workerId);
  static Insertable<PayrollItemsTableData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? payrollId,
    Expression<int>? workerId,
    Expression<int>? daysWorked,
    Expression<int>? regularHours,
    Expression<int>? overtimeHours,
    Expression<double>? baseSalary,
    Expression<double>? overtimePay,
    Expression<double>? allowances,
    Expression<double>? grossSalary,
    Expression<double>? incomeTax,
    Expression<double>? employeePension,
    Expression<double>? employerPension,
    Expression<double>? costSharing,
    Expression<double>? otherDeductions,
    Expression<double>? totalDeductions,
    Expression<double>? netSalary,
    Expression<String>? taxRuleApplied,
    Expression<String>? notes,
    Expression<bool>? isSynced,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (payrollId != null) 'payroll_id': payrollId,
      if (workerId != null) 'worker_id': workerId,
      if (daysWorked != null) 'days_worked': daysWorked,
      if (regularHours != null) 'regular_hours': regularHours,
      if (overtimeHours != null) 'overtime_hours': overtimeHours,
      if (baseSalary != null) 'base_salary': baseSalary,
      if (overtimePay != null) 'overtime_pay': overtimePay,
      if (allowances != null) 'allowances': allowances,
      if (grossSalary != null) 'gross_salary': grossSalary,
      if (incomeTax != null) 'income_tax': incomeTax,
      if (employeePension != null) 'employee_pension': employeePension,
      if (employerPension != null) 'employer_pension': employerPension,
      if (costSharing != null) 'cost_sharing': costSharing,
      if (otherDeductions != null) 'other_deductions': otherDeductions,
      if (totalDeductions != null) 'total_deductions': totalDeductions,
      if (netSalary != null) 'net_salary': netSalary,
      if (taxRuleApplied != null) 'tax_rule_applied': taxRuleApplied,
      if (notes != null) 'notes': notes,
      if (isSynced != null) 'is_synced': isSynced,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PayrollItemsTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? serverId,
      Value<int>? payrollId,
      Value<int>? workerId,
      Value<int>? daysWorked,
      Value<int>? regularHours,
      Value<int>? overtimeHours,
      Value<double>? baseSalary,
      Value<double>? overtimePay,
      Value<double>? allowances,
      Value<double>? grossSalary,
      Value<double>? incomeTax,
      Value<double>? employeePension,
      Value<double>? employerPension,
      Value<double>? costSharing,
      Value<double>? otherDeductions,
      Value<double>? totalDeductions,
      Value<double>? netSalary,
      Value<String?>? taxRuleApplied,
      Value<String?>? notes,
      Value<bool>? isSynced,
      Value<DateTime?>? lastSyncedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return PayrollItemsTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      payrollId: payrollId ?? this.payrollId,
      workerId: workerId ?? this.workerId,
      daysWorked: daysWorked ?? this.daysWorked,
      regularHours: regularHours ?? this.regularHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      baseSalary: baseSalary ?? this.baseSalary,
      overtimePay: overtimePay ?? this.overtimePay,
      allowances: allowances ?? this.allowances,
      grossSalary: grossSalary ?? this.grossSalary,
      incomeTax: incomeTax ?? this.incomeTax,
      employeePension: employeePension ?? this.employeePension,
      employerPension: employerPension ?? this.employerPension,
      costSharing: costSharing ?? this.costSharing,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      netSalary: netSalary ?? this.netSalary,
      taxRuleApplied: taxRuleApplied ?? this.taxRuleApplied,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (payrollId.present) {
      map['payroll_id'] = Variable<int>(payrollId.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<int>(workerId.value);
    }
    if (daysWorked.present) {
      map['days_worked'] = Variable<int>(daysWorked.value);
    }
    if (regularHours.present) {
      map['regular_hours'] = Variable<int>(regularHours.value);
    }
    if (overtimeHours.present) {
      map['overtime_hours'] = Variable<int>(overtimeHours.value);
    }
    if (baseSalary.present) {
      map['base_salary'] = Variable<double>(baseSalary.value);
    }
    if (overtimePay.present) {
      map['overtime_pay'] = Variable<double>(overtimePay.value);
    }
    if (allowances.present) {
      map['allowances'] = Variable<double>(allowances.value);
    }
    if (grossSalary.present) {
      map['gross_salary'] = Variable<double>(grossSalary.value);
    }
    if (incomeTax.present) {
      map['income_tax'] = Variable<double>(incomeTax.value);
    }
    if (employeePension.present) {
      map['employee_pension'] = Variable<double>(employeePension.value);
    }
    if (employerPension.present) {
      map['employer_pension'] = Variable<double>(employerPension.value);
    }
    if (costSharing.present) {
      map['cost_sharing'] = Variable<double>(costSharing.value);
    }
    if (otherDeductions.present) {
      map['other_deductions'] = Variable<double>(otherDeductions.value);
    }
    if (totalDeductions.present) {
      map['total_deductions'] = Variable<double>(totalDeductions.value);
    }
    if (netSalary.present) {
      map['net_salary'] = Variable<double>(netSalary.value);
    }
    if (taxRuleApplied.present) {
      map['tax_rule_applied'] = Variable<String>(taxRuleApplied.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PayrollItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('payrollId: $payrollId, ')
          ..write('workerId: $workerId, ')
          ..write('daysWorked: $daysWorked, ')
          ..write('regularHours: $regularHours, ')
          ..write('overtimeHours: $overtimeHours, ')
          ..write('baseSalary: $baseSalary, ')
          ..write('overtimePay: $overtimePay, ')
          ..write('allowances: $allowances, ')
          ..write('grossSalary: $grossSalary, ')
          ..write('incomeTax: $incomeTax, ')
          ..write('employeePension: $employeePension, ')
          ..write('employerPension: $employerPension, ')
          ..write('costSharing: $costSharing, ')
          ..write('otherDeductions: $otherDeductions, ')
          ..write('totalDeductions: $totalDeductions, ')
          ..write('netSalary: $netSalary, ')
          ..write('taxRuleApplied: $taxRuleApplied, ')
          ..write('notes: $notes, ')
          ..write('isSynced: $isSynced, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkersTableTable workersTable = $WorkersTableTable(this);
  late final $SitesTableTable sitesTable = $SitesTableTable(this);
  late final $WorkTypesTableTable workTypesTable = $WorkTypesTableTable(this);
  late final $AttendancesTableTable attendancesTable =
      $AttendancesTableTable(this);
  late final $PayrollsTableTable payrollsTable = $PayrollsTableTable(this);
  late final $PayrollItemsTableTable payrollItemsTable =
      $PayrollItemsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        workersTable,
        sitesTable,
        workTypesTable,
        attendancesTable,
        payrollsTable,
        payrollItemsTable
      ];
}

typedef $$WorkersTableTableCreateCompanionBuilder = WorkersTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  required String employeeId,
  required String fullName,
  Value<String?> phoneNumber,
  Value<String?> nationalId,
  required int siteId,
  required int workTypeId,
  required DateTime hireDate,
  Value<DateTime?> terminationDate,
  required String status,
  Value<String> calendarPreference,
  Value<String?> photoUrl,
  Value<String?> qrCode,
  Value<String?> bankName,
  Value<String?> bankAccountNumber,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$WorkersTableTableUpdateCompanionBuilder = WorkersTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  Value<String> employeeId,
  Value<String> fullName,
  Value<String?> phoneNumber,
  Value<String?> nationalId,
  Value<int> siteId,
  Value<int> workTypeId,
  Value<DateTime> hireDate,
  Value<DateTime?> terminationDate,
  Value<String> status,
  Value<String> calendarPreference,
  Value<String?> photoUrl,
  Value<String?> qrCode,
  Value<String?> bankName,
  Value<String?> bankAccountNumber,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$WorkersTableTableFilterComposer
    extends Composer<_$AppDatabase, $WorkersTableTable> {
  $$WorkersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nationalId => $composableBuilder(
      column: $table.nationalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get siteId => $composableBuilder(
      column: $table.siteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get workTypeId => $composableBuilder(
      column: $table.workTypeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get terminationDate => $composableBuilder(
      column: $table.terminationDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get calendarPreference => $composableBuilder(
      column: $table.calendarPreference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get qrCode => $composableBuilder(
      column: $table.qrCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankAccountNumber => $composableBuilder(
      column: $table.bankAccountNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WorkersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkersTableTable> {
  $$WorkersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullName => $composableBuilder(
      column: $table.fullName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nationalId => $composableBuilder(
      column: $table.nationalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get siteId => $composableBuilder(
      column: $table.siteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get workTypeId => $composableBuilder(
      column: $table.workTypeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get hireDate => $composableBuilder(
      column: $table.hireDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get terminationDate => $composableBuilder(
      column: $table.terminationDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get calendarPreference => $composableBuilder(
      column: $table.calendarPreference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get qrCode => $composableBuilder(
      column: $table.qrCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankAccountNumber => $composableBuilder(
      column: $table.bankAccountNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorkersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkersTableTable> {
  $$WorkersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<String> get nationalId => $composableBuilder(
      column: $table.nationalId, builder: (column) => column);

  GeneratedColumn<int> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<int> get workTypeId => $composableBuilder(
      column: $table.workTypeId, builder: (column) => column);

  GeneratedColumn<DateTime> get hireDate =>
      $composableBuilder(column: $table.hireDate, builder: (column) => column);

  GeneratedColumn<DateTime> get terminationDate => $composableBuilder(
      column: $table.terminationDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get calendarPreference => $composableBuilder(
      column: $table.calendarPreference, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get qrCode =>
      $composableBuilder(column: $table.qrCode, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get bankAccountNumber => $composableBuilder(
      column: $table.bankAccountNumber, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorkersTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkersTableTable,
    WorkersTableData,
    $$WorkersTableTableFilterComposer,
    $$WorkersTableTableOrderingComposer,
    $$WorkersTableTableAnnotationComposer,
    $$WorkersTableTableCreateCompanionBuilder,
    $$WorkersTableTableUpdateCompanionBuilder,
    (
      WorkersTableData,
      BaseReferences<_$AppDatabase, $WorkersTableTable, WorkersTableData>
    ),
    WorkersTableData,
    PrefetchHooks Function()> {
  $$WorkersTableTableTableManager(_$AppDatabase db, $WorkersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<String> employeeId = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> nationalId = const Value.absent(),
            Value<int> siteId = const Value.absent(),
            Value<int> workTypeId = const Value.absent(),
            Value<DateTime> hireDate = const Value.absent(),
            Value<DateTime?> terminationDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> calendarPreference = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String?> qrCode = const Value.absent(),
            Value<String?> bankName = const Value.absent(),
            Value<String?> bankAccountNumber = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WorkersTableCompanion(
            id: id,
            serverId: serverId,
            employeeId: employeeId,
            fullName: fullName,
            phoneNumber: phoneNumber,
            nationalId: nationalId,
            siteId: siteId,
            workTypeId: workTypeId,
            hireDate: hireDate,
            terminationDate: terminationDate,
            status: status,
            calendarPreference: calendarPreference,
            photoUrl: photoUrl,
            qrCode: qrCode,
            bankName: bankName,
            bankAccountNumber: bankAccountNumber,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            required String employeeId,
            required String fullName,
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> nationalId = const Value.absent(),
            required int siteId,
            required int workTypeId,
            required DateTime hireDate,
            Value<DateTime?> terminationDate = const Value.absent(),
            required String status,
            Value<String> calendarPreference = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<String?> qrCode = const Value.absent(),
            Value<String?> bankName = const Value.absent(),
            Value<String?> bankAccountNumber = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WorkersTableCompanion.insert(
            id: id,
            serverId: serverId,
            employeeId: employeeId,
            fullName: fullName,
            phoneNumber: phoneNumber,
            nationalId: nationalId,
            siteId: siteId,
            workTypeId: workTypeId,
            hireDate: hireDate,
            terminationDate: terminationDate,
            status: status,
            calendarPreference: calendarPreference,
            photoUrl: photoUrl,
            qrCode: qrCode,
            bankName: bankName,
            bankAccountNumber: bankAccountNumber,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkersTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkersTableTable,
    WorkersTableData,
    $$WorkersTableTableFilterComposer,
    $$WorkersTableTableOrderingComposer,
    $$WorkersTableTableAnnotationComposer,
    $$WorkersTableTableCreateCompanionBuilder,
    $$WorkersTableTableUpdateCompanionBuilder,
    (
      WorkersTableData,
      BaseReferences<_$AppDatabase, $WorkersTableTable, WorkersTableData>
    ),
    WorkersTableData,
    PrefetchHooks Function()>;
typedef $$SitesTableTableCreateCompanionBuilder = SitesTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  required String name,
  required String code,
  Value<String?> description,
  Value<String?> locationAddress,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<bool> isActive,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$SitesTableTableUpdateCompanionBuilder = SitesTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<String> name,
  Value<String> code,
  Value<String?> description,
  Value<String?> locationAddress,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<bool> isActive,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$SitesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SitesTableTable> {
  $$SitesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locationAddress => $composableBuilder(
      column: $table.locationAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SitesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SitesTableTable> {
  $$SitesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locationAddress => $composableBuilder(
      column: $table.locationAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SitesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SitesTableTable> {
  $$SitesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get locationAddress => $composableBuilder(
      column: $table.locationAddress, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SitesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SitesTableTable,
    SitesTableData,
    $$SitesTableTableFilterComposer,
    $$SitesTableTableOrderingComposer,
    $$SitesTableTableAnnotationComposer,
    $$SitesTableTableCreateCompanionBuilder,
    $$SitesTableTableUpdateCompanionBuilder,
    (
      SitesTableData,
      BaseReferences<_$AppDatabase, $SitesTableTable, SitesTableData>
    ),
    SitesTableData,
    PrefetchHooks Function()> {
  $$SitesTableTableTableManager(_$AppDatabase db, $SitesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SitesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SitesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SitesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> locationAddress = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SitesTableCompanion(
            id: id,
            serverId: serverId,
            name: name,
            code: code,
            description: description,
            locationAddress: locationAddress,
            latitude: latitude,
            longitude: longitude,
            isActive: isActive,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            required String name,
            required String code,
            Value<String?> description = const Value.absent(),
            Value<String?> locationAddress = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SitesTableCompanion.insert(
            id: id,
            serverId: serverId,
            name: name,
            code: code,
            description: description,
            locationAddress: locationAddress,
            latitude: latitude,
            longitude: longitude,
            isActive: isActive,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SitesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SitesTableTable,
    SitesTableData,
    $$SitesTableTableFilterComposer,
    $$SitesTableTableOrderingComposer,
    $$SitesTableTableAnnotationComposer,
    $$SitesTableTableCreateCompanionBuilder,
    $$SitesTableTableUpdateCompanionBuilder,
    (
      SitesTableData,
      BaseReferences<_$AppDatabase, $SitesTableTable, SitesTableData>
    ),
    SitesTableData,
    PrefetchHooks Function()>;
typedef $$WorkTypesTableTableCreateCompanionBuilder = WorkTypesTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  required String name,
  required String code,
  Value<String?> description,
  required String paymentMode,
  required double baseRate,
  required String taxRule,
  Value<bool> overtimeEligible,
  Value<double> overtimeMultiplier,
  Value<bool> pensionEligible,
  Value<double> employeePensionRate,
  Value<double> employerPensionRate,
  Value<bool> isActive,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$WorkTypesTableTableUpdateCompanionBuilder = WorkTypesTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  Value<String> name,
  Value<String> code,
  Value<String?> description,
  Value<String> paymentMode,
  Value<double> baseRate,
  Value<String> taxRule,
  Value<bool> overtimeEligible,
  Value<double> overtimeMultiplier,
  Value<bool> pensionEligible,
  Value<double> employeePensionRate,
  Value<double> employerPensionRate,
  Value<bool> isActive,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$WorkTypesTableTableFilterComposer
    extends Composer<_$AppDatabase, $WorkTypesTableTable> {
  $$WorkTypesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMode => $composableBuilder(
      column: $table.paymentMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get baseRate => $composableBuilder(
      column: $table.baseRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxRule => $composableBuilder(
      column: $table.taxRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get overtimeEligible => $composableBuilder(
      column: $table.overtimeEligible,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get overtimeMultiplier => $composableBuilder(
      column: $table.overtimeMultiplier,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pensionEligible => $composableBuilder(
      column: $table.pensionEligible,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get employeePensionRate => $composableBuilder(
      column: $table.employeePensionRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get employerPensionRate => $composableBuilder(
      column: $table.employerPensionRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WorkTypesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkTypesTableTable> {
  $$WorkTypesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMode => $composableBuilder(
      column: $table.paymentMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get baseRate => $composableBuilder(
      column: $table.baseRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxRule => $composableBuilder(
      column: $table.taxRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get overtimeEligible => $composableBuilder(
      column: $table.overtimeEligible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get overtimeMultiplier => $composableBuilder(
      column: $table.overtimeMultiplier,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pensionEligible => $composableBuilder(
      column: $table.pensionEligible,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get employeePensionRate => $composableBuilder(
      column: $table.employeePensionRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get employerPensionRate => $composableBuilder(
      column: $table.employerPensionRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorkTypesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkTypesTableTable> {
  $$WorkTypesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get paymentMode => $composableBuilder(
      column: $table.paymentMode, builder: (column) => column);

  GeneratedColumn<double> get baseRate =>
      $composableBuilder(column: $table.baseRate, builder: (column) => column);

  GeneratedColumn<String> get taxRule =>
      $composableBuilder(column: $table.taxRule, builder: (column) => column);

  GeneratedColumn<bool> get overtimeEligible => $composableBuilder(
      column: $table.overtimeEligible, builder: (column) => column);

  GeneratedColumn<double> get overtimeMultiplier => $composableBuilder(
      column: $table.overtimeMultiplier, builder: (column) => column);

  GeneratedColumn<bool> get pensionEligible => $composableBuilder(
      column: $table.pensionEligible, builder: (column) => column);

  GeneratedColumn<double> get employeePensionRate => $composableBuilder(
      column: $table.employeePensionRate, builder: (column) => column);

  GeneratedColumn<double> get employerPensionRate => $composableBuilder(
      column: $table.employerPensionRate, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorkTypesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkTypesTableTable,
    WorkTypesTableData,
    $$WorkTypesTableTableFilterComposer,
    $$WorkTypesTableTableOrderingComposer,
    $$WorkTypesTableTableAnnotationComposer,
    $$WorkTypesTableTableCreateCompanionBuilder,
    $$WorkTypesTableTableUpdateCompanionBuilder,
    (
      WorkTypesTableData,
      BaseReferences<_$AppDatabase, $WorkTypesTableTable, WorkTypesTableData>
    ),
    WorkTypesTableData,
    PrefetchHooks Function()> {
  $$WorkTypesTableTableTableManager(
      _$AppDatabase db, $WorkTypesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkTypesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkTypesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkTypesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> paymentMode = const Value.absent(),
            Value<double> baseRate = const Value.absent(),
            Value<String> taxRule = const Value.absent(),
            Value<bool> overtimeEligible = const Value.absent(),
            Value<double> overtimeMultiplier = const Value.absent(),
            Value<bool> pensionEligible = const Value.absent(),
            Value<double> employeePensionRate = const Value.absent(),
            Value<double> employerPensionRate = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WorkTypesTableCompanion(
            id: id,
            serverId: serverId,
            name: name,
            code: code,
            description: description,
            paymentMode: paymentMode,
            baseRate: baseRate,
            taxRule: taxRule,
            overtimeEligible: overtimeEligible,
            overtimeMultiplier: overtimeMultiplier,
            pensionEligible: pensionEligible,
            employeePensionRate: employeePensionRate,
            employerPensionRate: employerPensionRate,
            isActive: isActive,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            required String name,
            required String code,
            Value<String?> description = const Value.absent(),
            required String paymentMode,
            required double baseRate,
            required String taxRule,
            Value<bool> overtimeEligible = const Value.absent(),
            Value<double> overtimeMultiplier = const Value.absent(),
            Value<bool> pensionEligible = const Value.absent(),
            Value<double> employeePensionRate = const Value.absent(),
            Value<double> employerPensionRate = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              WorkTypesTableCompanion.insert(
            id: id,
            serverId: serverId,
            name: name,
            code: code,
            description: description,
            paymentMode: paymentMode,
            baseRate: baseRate,
            taxRule: taxRule,
            overtimeEligible: overtimeEligible,
            overtimeMultiplier: overtimeMultiplier,
            pensionEligible: pensionEligible,
            employeePensionRate: employeePensionRate,
            employerPensionRate: employerPensionRate,
            isActive: isActive,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkTypesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkTypesTableTable,
    WorkTypesTableData,
    $$WorkTypesTableTableFilterComposer,
    $$WorkTypesTableTableOrderingComposer,
    $$WorkTypesTableTableAnnotationComposer,
    $$WorkTypesTableTableCreateCompanionBuilder,
    $$WorkTypesTableTableUpdateCompanionBuilder,
    (
      WorkTypesTableData,
      BaseReferences<_$AppDatabase, $WorkTypesTableTable, WorkTypesTableData>
    ),
    WorkTypesTableData,
    PrefetchHooks Function()>;
typedef $$AttendancesTableTableCreateCompanionBuilder
    = AttendancesTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  required int workerId,
  required int siteId,
  required DateTime attendanceDate,
  Value<String?> checkInTime,
  Value<String?> checkOutTime,
  required String status,
  required String method,
  Value<int> regularHours,
  Value<int> overtimeHours,
  Value<bool> isVerified,
  Value<int?> verifiedById,
  Value<DateTime?> verifiedAt,
  Value<String?> overrideReason,
  Value<String?> notes,
  Value<int?> ethiopianYear,
  Value<int?> ethiopianMonth,
  Value<int?> ethiopianDay,
  Value<bool> isLocked,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$AttendancesTableTableUpdateCompanionBuilder
    = AttendancesTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int> workerId,
  Value<int> siteId,
  Value<DateTime> attendanceDate,
  Value<String?> checkInTime,
  Value<String?> checkOutTime,
  Value<String> status,
  Value<String> method,
  Value<int> regularHours,
  Value<int> overtimeHours,
  Value<bool> isVerified,
  Value<int?> verifiedById,
  Value<DateTime?> verifiedAt,
  Value<String?> overrideReason,
  Value<String?> notes,
  Value<int?> ethiopianYear,
  Value<int?> ethiopianMonth,
  Value<int?> ethiopianDay,
  Value<bool> isLocked,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$AttendancesTableTableFilterComposer
    extends Composer<_$AppDatabase, $AttendancesTableTable> {
  $$AttendancesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get workerId => $composableBuilder(
      column: $table.workerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get siteId => $composableBuilder(
      column: $table.siteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get attendanceDate => $composableBuilder(
      column: $table.attendanceDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkInTime => $composableBuilder(
      column: $table.checkInTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkOutTime => $composableBuilder(
      column: $table.checkOutTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get regularHours => $composableBuilder(
      column: $table.regularHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get overtimeHours => $composableBuilder(
      column: $table.overtimeHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verifiedById => $composableBuilder(
      column: $table.verifiedById, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overrideReason => $composableBuilder(
      column: $table.overrideReason,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ethiopianYear => $composableBuilder(
      column: $table.ethiopianYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ethiopianMonth => $composableBuilder(
      column: $table.ethiopianMonth,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ethiopianDay => $composableBuilder(
      column: $table.ethiopianDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AttendancesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendancesTableTable> {
  $$AttendancesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get workerId => $composableBuilder(
      column: $table.workerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get siteId => $composableBuilder(
      column: $table.siteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get attendanceDate => $composableBuilder(
      column: $table.attendanceDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkInTime => $composableBuilder(
      column: $table.checkInTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkOutTime => $composableBuilder(
      column: $table.checkOutTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get regularHours => $composableBuilder(
      column: $table.regularHours,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get overtimeHours => $composableBuilder(
      column: $table.overtimeHours,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verifiedById => $composableBuilder(
      column: $table.verifiedById,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overrideReason => $composableBuilder(
      column: $table.overrideReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ethiopianYear => $composableBuilder(
      column: $table.ethiopianYear,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ethiopianMonth => $composableBuilder(
      column: $table.ethiopianMonth,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ethiopianDay => $composableBuilder(
      column: $table.ethiopianDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AttendancesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendancesTableTable> {
  $$AttendancesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<int> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<DateTime> get attendanceDate => $composableBuilder(
      column: $table.attendanceDate, builder: (column) => column);

  GeneratedColumn<String> get checkInTime => $composableBuilder(
      column: $table.checkInTime, builder: (column) => column);

  GeneratedColumn<String> get checkOutTime => $composableBuilder(
      column: $table.checkOutTime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get regularHours => $composableBuilder(
      column: $table.regularHours, builder: (column) => column);

  GeneratedColumn<int> get overtimeHours => $composableBuilder(
      column: $table.overtimeHours, builder: (column) => column);

  GeneratedColumn<bool> get isVerified => $composableBuilder(
      column: $table.isVerified, builder: (column) => column);

  GeneratedColumn<int> get verifiedById => $composableBuilder(
      column: $table.verifiedById, builder: (column) => column);

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => column);

  GeneratedColumn<String> get overrideReason => $composableBuilder(
      column: $table.overrideReason, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get ethiopianYear => $composableBuilder(
      column: $table.ethiopianYear, builder: (column) => column);

  GeneratedColumn<int> get ethiopianMonth => $composableBuilder(
      column: $table.ethiopianMonth, builder: (column) => column);

  GeneratedColumn<int> get ethiopianDay => $composableBuilder(
      column: $table.ethiopianDay, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AttendancesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttendancesTableTable,
    AttendancesTableData,
    $$AttendancesTableTableFilterComposer,
    $$AttendancesTableTableOrderingComposer,
    $$AttendancesTableTableAnnotationComposer,
    $$AttendancesTableTableCreateCompanionBuilder,
    $$AttendancesTableTableUpdateCompanionBuilder,
    (
      AttendancesTableData,
      BaseReferences<_$AppDatabase, $AttendancesTableTable,
          AttendancesTableData>
    ),
    AttendancesTableData,
    PrefetchHooks Function()> {
  $$AttendancesTableTableTableManager(
      _$AppDatabase db, $AttendancesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendancesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendancesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendancesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int> workerId = const Value.absent(),
            Value<int> siteId = const Value.absent(),
            Value<DateTime> attendanceDate = const Value.absent(),
            Value<String?> checkInTime = const Value.absent(),
            Value<String?> checkOutTime = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<int> regularHours = const Value.absent(),
            Value<int> overtimeHours = const Value.absent(),
            Value<bool> isVerified = const Value.absent(),
            Value<int?> verifiedById = const Value.absent(),
            Value<DateTime?> verifiedAt = const Value.absent(),
            Value<String?> overrideReason = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int?> ethiopianYear = const Value.absent(),
            Value<int?> ethiopianMonth = const Value.absent(),
            Value<int?> ethiopianDay = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              AttendancesTableCompanion(
            id: id,
            serverId: serverId,
            workerId: workerId,
            siteId: siteId,
            attendanceDate: attendanceDate,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            status: status,
            method: method,
            regularHours: regularHours,
            overtimeHours: overtimeHours,
            isVerified: isVerified,
            verifiedById: verifiedById,
            verifiedAt: verifiedAt,
            overrideReason: overrideReason,
            notes: notes,
            ethiopianYear: ethiopianYear,
            ethiopianMonth: ethiopianMonth,
            ethiopianDay: ethiopianDay,
            isLocked: isLocked,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            required int workerId,
            required int siteId,
            required DateTime attendanceDate,
            Value<String?> checkInTime = const Value.absent(),
            Value<String?> checkOutTime = const Value.absent(),
            required String status,
            required String method,
            Value<int> regularHours = const Value.absent(),
            Value<int> overtimeHours = const Value.absent(),
            Value<bool> isVerified = const Value.absent(),
            Value<int?> verifiedById = const Value.absent(),
            Value<DateTime?> verifiedAt = const Value.absent(),
            Value<String?> overrideReason = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int?> ethiopianYear = const Value.absent(),
            Value<int?> ethiopianMonth = const Value.absent(),
            Value<int?> ethiopianDay = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              AttendancesTableCompanion.insert(
            id: id,
            serverId: serverId,
            workerId: workerId,
            siteId: siteId,
            attendanceDate: attendanceDate,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            status: status,
            method: method,
            regularHours: regularHours,
            overtimeHours: overtimeHours,
            isVerified: isVerified,
            verifiedById: verifiedById,
            verifiedAt: verifiedAt,
            overrideReason: overrideReason,
            notes: notes,
            ethiopianYear: ethiopianYear,
            ethiopianMonth: ethiopianMonth,
            ethiopianDay: ethiopianDay,
            isLocked: isLocked,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttendancesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttendancesTableTable,
    AttendancesTableData,
    $$AttendancesTableTableFilterComposer,
    $$AttendancesTableTableOrderingComposer,
    $$AttendancesTableTableAnnotationComposer,
    $$AttendancesTableTableCreateCompanionBuilder,
    $$AttendancesTableTableUpdateCompanionBuilder,
    (
      AttendancesTableData,
      BaseReferences<_$AppDatabase, $AttendancesTableTable,
          AttendancesTableData>
    ),
    AttendancesTableData,
    PrefetchHooks Function()>;
typedef $$PayrollsTableTableCreateCompanionBuilder = PayrollsTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  required String payrollCode,
  required int siteId,
  required String periodType,
  required DateTime periodStart,
  required DateTime periodEnd,
  Value<String?> ethiopianMonth,
  Value<int?> ethiopianYear,
  Value<double> totalGrossAmount,
  Value<double> totalDeductions,
  Value<double> totalNetAmount,
  Value<double> totalEmployerPension,
  required String status,
  Value<int?> calculatedById,
  Value<int?> approvedById,
  Value<DateTime?> approvedAt,
  Value<String?> notes,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$PayrollsTableTableUpdateCompanionBuilder = PayrollsTableCompanion
    Function({
  Value<int> id,
  Value<int?> serverId,
  Value<String> payrollCode,
  Value<int> siteId,
  Value<String> periodType,
  Value<DateTime> periodStart,
  Value<DateTime> periodEnd,
  Value<String?> ethiopianMonth,
  Value<int?> ethiopianYear,
  Value<double> totalGrossAmount,
  Value<double> totalDeductions,
  Value<double> totalNetAmount,
  Value<double> totalEmployerPension,
  Value<String> status,
  Value<int?> calculatedById,
  Value<int?> approvedById,
  Value<DateTime?> approvedAt,
  Value<String?> notes,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$PayrollsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PayrollsTableTable> {
  $$PayrollsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payrollCode => $composableBuilder(
      column: $table.payrollCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get siteId => $composableBuilder(
      column: $table.siteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get periodEnd => $composableBuilder(
      column: $table.periodEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ethiopianMonth => $composableBuilder(
      column: $table.ethiopianMonth,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ethiopianYear => $composableBuilder(
      column: $table.ethiopianYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalGrossAmount => $composableBuilder(
      column: $table.totalGrossAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalDeductions => $composableBuilder(
      column: $table.totalDeductions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalNetAmount => $composableBuilder(
      column: $table.totalNetAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalEmployerPension => $composableBuilder(
      column: $table.totalEmployerPension,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calculatedById => $composableBuilder(
      column: $table.calculatedById,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get approvedById => $composableBuilder(
      column: $table.approvedById, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get approvedAt => $composableBuilder(
      column: $table.approvedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PayrollsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PayrollsTableTable> {
  $$PayrollsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payrollCode => $composableBuilder(
      column: $table.payrollCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get siteId => $composableBuilder(
      column: $table.siteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get periodEnd => $composableBuilder(
      column: $table.periodEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ethiopianMonth => $composableBuilder(
      column: $table.ethiopianMonth,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ethiopianYear => $composableBuilder(
      column: $table.ethiopianYear,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalGrossAmount => $composableBuilder(
      column: $table.totalGrossAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalDeductions => $composableBuilder(
      column: $table.totalDeductions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalNetAmount => $composableBuilder(
      column: $table.totalNetAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalEmployerPension => $composableBuilder(
      column: $table.totalEmployerPension,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calculatedById => $composableBuilder(
      column: $table.calculatedById,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get approvedById => $composableBuilder(
      column: $table.approvedById,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get approvedAt => $composableBuilder(
      column: $table.approvedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PayrollsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayrollsTableTable> {
  $$PayrollsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get payrollCode => $composableBuilder(
      column: $table.payrollCode, builder: (column) => column);

  GeneratedColumn<int> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => column);

  GeneratedColumn<DateTime> get periodStart => $composableBuilder(
      column: $table.periodStart, builder: (column) => column);

  GeneratedColumn<DateTime> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<String> get ethiopianMonth => $composableBuilder(
      column: $table.ethiopianMonth, builder: (column) => column);

  GeneratedColumn<int> get ethiopianYear => $composableBuilder(
      column: $table.ethiopianYear, builder: (column) => column);

  GeneratedColumn<double> get totalGrossAmount => $composableBuilder(
      column: $table.totalGrossAmount, builder: (column) => column);

  GeneratedColumn<double> get totalDeductions => $composableBuilder(
      column: $table.totalDeductions, builder: (column) => column);

  GeneratedColumn<double> get totalNetAmount => $composableBuilder(
      column: $table.totalNetAmount, builder: (column) => column);

  GeneratedColumn<double> get totalEmployerPension => $composableBuilder(
      column: $table.totalEmployerPension, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get calculatedById => $composableBuilder(
      column: $table.calculatedById, builder: (column) => column);

  GeneratedColumn<int> get approvedById => $composableBuilder(
      column: $table.approvedById, builder: (column) => column);

  GeneratedColumn<DateTime> get approvedAt => $composableBuilder(
      column: $table.approvedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PayrollsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PayrollsTableTable,
    PayrollsTableData,
    $$PayrollsTableTableFilterComposer,
    $$PayrollsTableTableOrderingComposer,
    $$PayrollsTableTableAnnotationComposer,
    $$PayrollsTableTableCreateCompanionBuilder,
    $$PayrollsTableTableUpdateCompanionBuilder,
    (
      PayrollsTableData,
      BaseReferences<_$AppDatabase, $PayrollsTableTable, PayrollsTableData>
    ),
    PayrollsTableData,
    PrefetchHooks Function()> {
  $$PayrollsTableTableTableManager(_$AppDatabase db, $PayrollsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayrollsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayrollsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayrollsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<String> payrollCode = const Value.absent(),
            Value<int> siteId = const Value.absent(),
            Value<String> periodType = const Value.absent(),
            Value<DateTime> periodStart = const Value.absent(),
            Value<DateTime> periodEnd = const Value.absent(),
            Value<String?> ethiopianMonth = const Value.absent(),
            Value<int?> ethiopianYear = const Value.absent(),
            Value<double> totalGrossAmount = const Value.absent(),
            Value<double> totalDeductions = const Value.absent(),
            Value<double> totalNetAmount = const Value.absent(),
            Value<double> totalEmployerPension = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> calculatedById = const Value.absent(),
            Value<int?> approvedById = const Value.absent(),
            Value<DateTime?> approvedAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PayrollsTableCompanion(
            id: id,
            serverId: serverId,
            payrollCode: payrollCode,
            siteId: siteId,
            periodType: periodType,
            periodStart: periodStart,
            periodEnd: periodEnd,
            ethiopianMonth: ethiopianMonth,
            ethiopianYear: ethiopianYear,
            totalGrossAmount: totalGrossAmount,
            totalDeductions: totalDeductions,
            totalNetAmount: totalNetAmount,
            totalEmployerPension: totalEmployerPension,
            status: status,
            calculatedById: calculatedById,
            approvedById: approvedById,
            approvedAt: approvedAt,
            notes: notes,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            required String payrollCode,
            required int siteId,
            required String periodType,
            required DateTime periodStart,
            required DateTime periodEnd,
            Value<String?> ethiopianMonth = const Value.absent(),
            Value<int?> ethiopianYear = const Value.absent(),
            Value<double> totalGrossAmount = const Value.absent(),
            Value<double> totalDeductions = const Value.absent(),
            Value<double> totalNetAmount = const Value.absent(),
            Value<double> totalEmployerPension = const Value.absent(),
            required String status,
            Value<int?> calculatedById = const Value.absent(),
            Value<int?> approvedById = const Value.absent(),
            Value<DateTime?> approvedAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PayrollsTableCompanion.insert(
            id: id,
            serverId: serverId,
            payrollCode: payrollCode,
            siteId: siteId,
            periodType: periodType,
            periodStart: periodStart,
            periodEnd: periodEnd,
            ethiopianMonth: ethiopianMonth,
            ethiopianYear: ethiopianYear,
            totalGrossAmount: totalGrossAmount,
            totalDeductions: totalDeductions,
            totalNetAmount: totalNetAmount,
            totalEmployerPension: totalEmployerPension,
            status: status,
            calculatedById: calculatedById,
            approvedById: approvedById,
            approvedAt: approvedAt,
            notes: notes,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PayrollsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PayrollsTableTable,
    PayrollsTableData,
    $$PayrollsTableTableFilterComposer,
    $$PayrollsTableTableOrderingComposer,
    $$PayrollsTableTableAnnotationComposer,
    $$PayrollsTableTableCreateCompanionBuilder,
    $$PayrollsTableTableUpdateCompanionBuilder,
    (
      PayrollsTableData,
      BaseReferences<_$AppDatabase, $PayrollsTableTable, PayrollsTableData>
    ),
    PayrollsTableData,
    PrefetchHooks Function()>;
typedef $$PayrollItemsTableTableCreateCompanionBuilder
    = PayrollItemsTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  required int payrollId,
  required int workerId,
  Value<int> daysWorked,
  Value<int> regularHours,
  Value<int> overtimeHours,
  Value<double> baseSalary,
  Value<double> overtimePay,
  Value<double> allowances,
  Value<double> grossSalary,
  Value<double> incomeTax,
  Value<double> employeePension,
  Value<double> employerPension,
  Value<double> costSharing,
  Value<double> otherDeductions,
  Value<double> totalDeductions,
  Value<double> netSalary,
  Value<String?> taxRuleApplied,
  Value<String?> notes,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$PayrollItemsTableTableUpdateCompanionBuilder
    = PayrollItemsTableCompanion Function({
  Value<int> id,
  Value<int?> serverId,
  Value<int> payrollId,
  Value<int> workerId,
  Value<int> daysWorked,
  Value<int> regularHours,
  Value<int> overtimeHours,
  Value<double> baseSalary,
  Value<double> overtimePay,
  Value<double> allowances,
  Value<double> grossSalary,
  Value<double> incomeTax,
  Value<double> employeePension,
  Value<double> employerPension,
  Value<double> costSharing,
  Value<double> otherDeductions,
  Value<double> totalDeductions,
  Value<double> netSalary,
  Value<String?> taxRuleApplied,
  Value<String?> notes,
  Value<bool> isSynced,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$PayrollItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PayrollItemsTableTable> {
  $$PayrollItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get payrollId => $composableBuilder(
      column: $table.payrollId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get workerId => $composableBuilder(
      column: $table.workerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get daysWorked => $composableBuilder(
      column: $table.daysWorked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get regularHours => $composableBuilder(
      column: $table.regularHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get overtimeHours => $composableBuilder(
      column: $table.overtimeHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get baseSalary => $composableBuilder(
      column: $table.baseSalary, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get overtimePay => $composableBuilder(
      column: $table.overtimePay, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get allowances => $composableBuilder(
      column: $table.allowances, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get grossSalary => $composableBuilder(
      column: $table.grossSalary, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get incomeTax => $composableBuilder(
      column: $table.incomeTax, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get employeePension => $composableBuilder(
      column: $table.employeePension,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get employerPension => $composableBuilder(
      column: $table.employerPension,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costSharing => $composableBuilder(
      column: $table.costSharing, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get otherDeductions => $composableBuilder(
      column: $table.otherDeductions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalDeductions => $composableBuilder(
      column: $table.totalDeductions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get netSalary => $composableBuilder(
      column: $table.netSalary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxRuleApplied => $composableBuilder(
      column: $table.taxRuleApplied,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PayrollItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PayrollItemsTableTable> {
  $$PayrollItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get payrollId => $composableBuilder(
      column: $table.payrollId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get workerId => $composableBuilder(
      column: $table.workerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysWorked => $composableBuilder(
      column: $table.daysWorked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get regularHours => $composableBuilder(
      column: $table.regularHours,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get overtimeHours => $composableBuilder(
      column: $table.overtimeHours,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get baseSalary => $composableBuilder(
      column: $table.baseSalary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get overtimePay => $composableBuilder(
      column: $table.overtimePay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get allowances => $composableBuilder(
      column: $table.allowances, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get grossSalary => $composableBuilder(
      column: $table.grossSalary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get incomeTax => $composableBuilder(
      column: $table.incomeTax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get employeePension => $composableBuilder(
      column: $table.employeePension,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get employerPension => $composableBuilder(
      column: $table.employerPension,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costSharing => $composableBuilder(
      column: $table.costSharing, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get otherDeductions => $composableBuilder(
      column: $table.otherDeductions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalDeductions => $composableBuilder(
      column: $table.totalDeductions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get netSalary => $composableBuilder(
      column: $table.netSalary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxRuleApplied => $composableBuilder(
      column: $table.taxRuleApplied,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PayrollItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayrollItemsTableTable> {
  $$PayrollItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get payrollId =>
      $composableBuilder(column: $table.payrollId, builder: (column) => column);

  GeneratedColumn<int> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<int> get daysWorked => $composableBuilder(
      column: $table.daysWorked, builder: (column) => column);

  GeneratedColumn<int> get regularHours => $composableBuilder(
      column: $table.regularHours, builder: (column) => column);

  GeneratedColumn<int> get overtimeHours => $composableBuilder(
      column: $table.overtimeHours, builder: (column) => column);

  GeneratedColumn<double> get baseSalary => $composableBuilder(
      column: $table.baseSalary, builder: (column) => column);

  GeneratedColumn<double> get overtimePay => $composableBuilder(
      column: $table.overtimePay, builder: (column) => column);

  GeneratedColumn<double> get allowances => $composableBuilder(
      column: $table.allowances, builder: (column) => column);

  GeneratedColumn<double> get grossSalary => $composableBuilder(
      column: $table.grossSalary, builder: (column) => column);

  GeneratedColumn<double> get incomeTax =>
      $composableBuilder(column: $table.incomeTax, builder: (column) => column);

  GeneratedColumn<double> get employeePension => $composableBuilder(
      column: $table.employeePension, builder: (column) => column);

  GeneratedColumn<double> get employerPension => $composableBuilder(
      column: $table.employerPension, builder: (column) => column);

  GeneratedColumn<double> get costSharing => $composableBuilder(
      column: $table.costSharing, builder: (column) => column);

  GeneratedColumn<double> get otherDeductions => $composableBuilder(
      column: $table.otherDeductions, builder: (column) => column);

  GeneratedColumn<double> get totalDeductions => $composableBuilder(
      column: $table.totalDeductions, builder: (column) => column);

  GeneratedColumn<double> get netSalary =>
      $composableBuilder(column: $table.netSalary, builder: (column) => column);

  GeneratedColumn<String> get taxRuleApplied => $composableBuilder(
      column: $table.taxRuleApplied, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PayrollItemsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PayrollItemsTableTable,
    PayrollItemsTableData,
    $$PayrollItemsTableTableFilterComposer,
    $$PayrollItemsTableTableOrderingComposer,
    $$PayrollItemsTableTableAnnotationComposer,
    $$PayrollItemsTableTableCreateCompanionBuilder,
    $$PayrollItemsTableTableUpdateCompanionBuilder,
    (
      PayrollItemsTableData,
      BaseReferences<_$AppDatabase, $PayrollItemsTableTable,
          PayrollItemsTableData>
    ),
    PayrollItemsTableData,
    PrefetchHooks Function()> {
  $$PayrollItemsTableTableTableManager(
      _$AppDatabase db, $PayrollItemsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayrollItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayrollItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayrollItemsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<int> payrollId = const Value.absent(),
            Value<int> workerId = const Value.absent(),
            Value<int> daysWorked = const Value.absent(),
            Value<int> regularHours = const Value.absent(),
            Value<int> overtimeHours = const Value.absent(),
            Value<double> baseSalary = const Value.absent(),
            Value<double> overtimePay = const Value.absent(),
            Value<double> allowances = const Value.absent(),
            Value<double> grossSalary = const Value.absent(),
            Value<double> incomeTax = const Value.absent(),
            Value<double> employeePension = const Value.absent(),
            Value<double> employerPension = const Value.absent(),
            Value<double> costSharing = const Value.absent(),
            Value<double> otherDeductions = const Value.absent(),
            Value<double> totalDeductions = const Value.absent(),
            Value<double> netSalary = const Value.absent(),
            Value<String?> taxRuleApplied = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PayrollItemsTableCompanion(
            id: id,
            serverId: serverId,
            payrollId: payrollId,
            workerId: workerId,
            daysWorked: daysWorked,
            regularHours: regularHours,
            overtimeHours: overtimeHours,
            baseSalary: baseSalary,
            overtimePay: overtimePay,
            allowances: allowances,
            grossSalary: grossSalary,
            incomeTax: incomeTax,
            employeePension: employeePension,
            employerPension: employerPension,
            costSharing: costSharing,
            otherDeductions: otherDeductions,
            totalDeductions: totalDeductions,
            netSalary: netSalary,
            taxRuleApplied: taxRuleApplied,
            notes: notes,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            required int payrollId,
            required int workerId,
            Value<int> daysWorked = const Value.absent(),
            Value<int> regularHours = const Value.absent(),
            Value<int> overtimeHours = const Value.absent(),
            Value<double> baseSalary = const Value.absent(),
            Value<double> overtimePay = const Value.absent(),
            Value<double> allowances = const Value.absent(),
            Value<double> grossSalary = const Value.absent(),
            Value<double> incomeTax = const Value.absent(),
            Value<double> employeePension = const Value.absent(),
            Value<double> employerPension = const Value.absent(),
            Value<double> costSharing = const Value.absent(),
            Value<double> otherDeductions = const Value.absent(),
            Value<double> totalDeductions = const Value.absent(),
            Value<double> netSalary = const Value.absent(),
            Value<String?> taxRuleApplied = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PayrollItemsTableCompanion.insert(
            id: id,
            serverId: serverId,
            payrollId: payrollId,
            workerId: workerId,
            daysWorked: daysWorked,
            regularHours: regularHours,
            overtimeHours: overtimeHours,
            baseSalary: baseSalary,
            overtimePay: overtimePay,
            allowances: allowances,
            grossSalary: grossSalary,
            incomeTax: incomeTax,
            employeePension: employeePension,
            employerPension: employerPension,
            costSharing: costSharing,
            otherDeductions: otherDeductions,
            totalDeductions: totalDeductions,
            netSalary: netSalary,
            taxRuleApplied: taxRuleApplied,
            notes: notes,
            isSynced: isSynced,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PayrollItemsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PayrollItemsTableTable,
    PayrollItemsTableData,
    $$PayrollItemsTableTableFilterComposer,
    $$PayrollItemsTableTableOrderingComposer,
    $$PayrollItemsTableTableAnnotationComposer,
    $$PayrollItemsTableTableCreateCompanionBuilder,
    $$PayrollItemsTableTableUpdateCompanionBuilder,
    (
      PayrollItemsTableData,
      BaseReferences<_$AppDatabase, $PayrollItemsTableTable,
          PayrollItemsTableData>
    ),
    PayrollItemsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkersTableTableTableManager get workersTable =>
      $$WorkersTableTableTableManager(_db, _db.workersTable);
  $$SitesTableTableTableManager get sitesTable =>
      $$SitesTableTableTableManager(_db, _db.sitesTable);
  $$WorkTypesTableTableTableManager get workTypesTable =>
      $$WorkTypesTableTableTableManager(_db, _db.workTypesTable);
  $$AttendancesTableTableTableManager get attendancesTable =>
      $$AttendancesTableTableTableManager(_db, _db.attendancesTable);
  $$PayrollsTableTableTableManager get payrollsTable =>
      $$PayrollsTableTableTableManager(_db, _db.payrollsTable);
  $$PayrollItemsTableTableTableManager get payrollItemsTable =>
      $$PayrollItemsTableTableTableManager(_db, _db.payrollItemsTable);
}

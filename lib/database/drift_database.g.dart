// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    age,
    gender,
    createdAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final int? age;

  /// Gender: 'male', 'female', or 'other'. Nullable for backwards compatibility.
  final String? gender;
  final DateTime createdAt;
  final bool isActive;
  const User({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    required this.createdAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      age: serializer.fromJson<int?>(json['age']),
      gender: serializer.fromJson<String?>(json['gender']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'age': serializer.toJson<int?>(age),
      'gender': serializer.toJson<String?>(gender),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  User copyWith({
    int? id,
    String? name,
    Value<int?> age = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    DateTime? createdAt,
    bool? isActive,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    age: age.present ? age.value : this.age,
    gender: gender.present ? gender.value : this.gender,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      age: data.age.present ? data.age.value : this.age,
      gender: data.gender.present ? data.gender.value : this.gender,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('age: $age, ')
          ..write('gender: $gender, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, age, gender, createdAt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.age == this.age &&
          other.gender == this.gender &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> age;
  final Value<String?> gender;
  final Value<DateTime> createdAt;
  final Value<bool> isActive;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.age = const Value.absent(),
    this.gender = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.age = const Value.absent(),
    this.gender = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : name = Value(name);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? age,
    Expression<String>? gender,
    Expression<DateTime>? createdAt,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? age,
    Value<String?>? gender,
    Value<DateTime>? createdAt,
    Value<bool>? isActive,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('age: $age, ')
          ..write('gender: $gender, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dosagesRemainingMeta = const VerificationMeta(
    'dosagesRemaining',
  );
  @override
  late final GeneratedColumn<double> dosagesRemaining = GeneratedColumn<double>(
    'dosages_remaining',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nationalCodeMeta = const VerificationMeta(
    'nationalCode',
  );
  @override
  late final GeneratedColumn<int> nationalCode = GeneratedColumn<int>(
    'national_code',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MedicationType, int> medType =
      GeneratedColumn<int>(
        'med_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MedicationType>($MedicationsTable.$convertermedType);
  @override
  late final GeneratedColumnWithTypeConverter<MedicationStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<MedicationStatus>($MedicationsTable.$converterstatus);
  static const VerificationMeta _intakeAdviceMeta = const VerificationMeta(
    'intakeAdvice',
  );
  @override
  late final GeneratedColumn<String> intakeAdvice = GeneratedColumn<String>(
    'intake_advice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _criticalReminderMeta = const VerificationMeta(
    'criticalReminder',
  );
  @override
  late final GeneratedColumn<bool> criticalReminder = GeneratedColumn<bool>(
    'critical_reminder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("critical_reminder" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    dosagesRemaining,
    notes,
    nationalCode,
    medType,
    status,
    intakeAdvice,
    criticalReminder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Medication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dosages_remaining')) {
      context.handle(
        _dosagesRemainingMeta,
        dosagesRemaining.isAcceptableOrUnknown(
          data['dosages_remaining']!,
          _dosagesRemainingMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('national_code')) {
      context.handle(
        _nationalCodeMeta,
        nationalCode.isAcceptableOrUnknown(
          data['national_code']!,
          _nationalCodeMeta,
        ),
      );
    }
    if (data.containsKey('intake_advice')) {
      context.handle(
        _intakeAdviceMeta,
        intakeAdvice.isAcceptableOrUnknown(
          data['intake_advice']!,
          _intakeAdviceMeta,
        ),
      );
    }
    if (data.containsKey('critical_reminder')) {
      context.handle(
        _criticalReminderMeta,
        criticalReminder.isAcceptableOrUnknown(
          data['critical_reminder']!,
          _criticalReminderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dosagesRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dosages_remaining'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      nationalCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}national_code'],
      ),
      medType: $MedicationsTable.$convertermedType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}med_type'],
        )!,
      ),
      status: $MedicationsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      intakeAdvice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intake_advice'],
      ),
      criticalReminder: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}critical_reminder'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MedicationType, int, int> $convertermedType =
      const EnumIndexConverter<MedicationType>(MedicationType.values);
  static JsonTypeConverter2<MedicationStatus, int, int> $converterstatus =
      const EnumIndexConverter<MedicationStatus>(MedicationStatus.values);
}

class Medication extends DataClass implements Insertable<Medication> {
  final int id;
  final String name;
  final double? dosagesRemaining;
  final String? notes;
  final int? nationalCode;
  final MedicationType medType;
  final MedicationStatus status;
  final String? intakeAdvice;
  final bool criticalReminder;
  const Medication({
    required this.id,
    required this.name,
    this.dosagesRemaining,
    this.notes,
    this.nationalCode,
    required this.medType,
    required this.status,
    this.intakeAdvice,
    required this.criticalReminder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || dosagesRemaining != null) {
      map['dosages_remaining'] = Variable<double>(dosagesRemaining);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || nationalCode != null) {
      map['national_code'] = Variable<int>(nationalCode);
    }
    {
      map['med_type'] = Variable<int>(
        $MedicationsTable.$convertermedType.toSql(medType),
      );
    }
    {
      map['status'] = Variable<int>(
        $MedicationsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || intakeAdvice != null) {
      map['intake_advice'] = Variable<String>(intakeAdvice);
    }
    map['critical_reminder'] = Variable<bool>(criticalReminder);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      name: Value(name),
      dosagesRemaining: dosagesRemaining == null && nullToAbsent
          ? const Value.absent()
          : Value(dosagesRemaining),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      nationalCode: nationalCode == null && nullToAbsent
          ? const Value.absent()
          : Value(nationalCode),
      medType: Value(medType),
      status: Value(status),
      intakeAdvice: intakeAdvice == null && nullToAbsent
          ? const Value.absent()
          : Value(intakeAdvice),
      criticalReminder: Value(criticalReminder),
    );
  }

  factory Medication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dosagesRemaining: serializer.fromJson<double?>(json['dosagesRemaining']),
      notes: serializer.fromJson<String?>(json['notes']),
      nationalCode: serializer.fromJson<int?>(json['nationalCode']),
      medType: $MedicationsTable.$convertermedType.fromJson(
        serializer.fromJson<int>(json['medType']),
      ),
      status: $MedicationsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      intakeAdvice: serializer.fromJson<String?>(json['intakeAdvice']),
      criticalReminder: serializer.fromJson<bool>(json['criticalReminder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'dosagesRemaining': serializer.toJson<double?>(dosagesRemaining),
      'notes': serializer.toJson<String?>(notes),
      'nationalCode': serializer.toJson<int?>(nationalCode),
      'medType': serializer.toJson<int>(
        $MedicationsTable.$convertermedType.toJson(medType),
      ),
      'status': serializer.toJson<int>(
        $MedicationsTable.$converterstatus.toJson(status),
      ),
      'intakeAdvice': serializer.toJson<String?>(intakeAdvice),
      'criticalReminder': serializer.toJson<bool>(criticalReminder),
    };
  }

  Medication copyWith({
    int? id,
    String? name,
    Value<double?> dosagesRemaining = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> nationalCode = const Value.absent(),
    MedicationType? medType,
    MedicationStatus? status,
    Value<String?> intakeAdvice = const Value.absent(),
    bool? criticalReminder,
  }) => Medication(
    id: id ?? this.id,
    name: name ?? this.name,
    dosagesRemaining: dosagesRemaining.present
        ? dosagesRemaining.value
        : this.dosagesRemaining,
    notes: notes.present ? notes.value : this.notes,
    nationalCode: nationalCode.present ? nationalCode.value : this.nationalCode,
    medType: medType ?? this.medType,
    status: status ?? this.status,
    intakeAdvice: intakeAdvice.present ? intakeAdvice.value : this.intakeAdvice,
    criticalReminder: criticalReminder ?? this.criticalReminder,
  );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dosagesRemaining: data.dosagesRemaining.present
          ? data.dosagesRemaining.value
          : this.dosagesRemaining,
      notes: data.notes.present ? data.notes.value : this.notes,
      nationalCode: data.nationalCode.present
          ? data.nationalCode.value
          : this.nationalCode,
      medType: data.medType.present ? data.medType.value : this.medType,
      status: data.status.present ? data.status.value : this.status,
      intakeAdvice: data.intakeAdvice.present
          ? data.intakeAdvice.value
          : this.intakeAdvice,
      criticalReminder: data.criticalReminder.present
          ? data.criticalReminder.value
          : this.criticalReminder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dosagesRemaining: $dosagesRemaining, ')
          ..write('notes: $notes, ')
          ..write('nationalCode: $nationalCode, ')
          ..write('medType: $medType, ')
          ..write('status: $status, ')
          ..write('intakeAdvice: $intakeAdvice, ')
          ..write('criticalReminder: $criticalReminder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dosagesRemaining,
    notes,
    nationalCode,
    medType,
    status,
    intakeAdvice,
    criticalReminder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.name == this.name &&
          other.dosagesRemaining == this.dosagesRemaining &&
          other.notes == this.notes &&
          other.nationalCode == this.nationalCode &&
          other.medType == this.medType &&
          other.status == this.status &&
          other.intakeAdvice == this.intakeAdvice &&
          other.criticalReminder == this.criticalReminder);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<int> id;
  final Value<String> name;
  final Value<double?> dosagesRemaining;
  final Value<String?> notes;
  final Value<int?> nationalCode;
  final Value<MedicationType> medType;
  final Value<MedicationStatus> status;
  final Value<String?> intakeAdvice;
  final Value<bool> criticalReminder;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dosagesRemaining = const Value.absent(),
    this.notes = const Value.absent(),
    this.nationalCode = const Value.absent(),
    this.medType = const Value.absent(),
    this.status = const Value.absent(),
    this.intakeAdvice = const Value.absent(),
    this.criticalReminder = const Value.absent(),
  });
  MedicationsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.dosagesRemaining = const Value.absent(),
    this.notes = const Value.absent(),
    this.nationalCode = const Value.absent(),
    required MedicationType medType,
    this.status = const Value.absent(),
    this.intakeAdvice = const Value.absent(),
    this.criticalReminder = const Value.absent(),
  }) : name = Value(name),
       medType = Value(medType);
  static Insertable<Medication> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? dosagesRemaining,
    Expression<String>? notes,
    Expression<int>? nationalCode,
    Expression<int>? medType,
    Expression<int>? status,
    Expression<String>? intakeAdvice,
    Expression<bool>? criticalReminder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dosagesRemaining != null) 'dosages_remaining': dosagesRemaining,
      if (notes != null) 'notes': notes,
      if (nationalCode != null) 'national_code': nationalCode,
      if (medType != null) 'med_type': medType,
      if (status != null) 'status': status,
      if (intakeAdvice != null) 'intake_advice': intakeAdvice,
      if (criticalReminder != null) 'critical_reminder': criticalReminder,
    });
  }

  MedicationsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double?>? dosagesRemaining,
    Value<String?>? notes,
    Value<int?>? nationalCode,
    Value<MedicationType>? medType,
    Value<MedicationStatus>? status,
    Value<String?>? intakeAdvice,
    Value<bool>? criticalReminder,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dosagesRemaining: dosagesRemaining ?? this.dosagesRemaining,
      notes: notes ?? this.notes,
      nationalCode: nationalCode ?? this.nationalCode,
      medType: medType ?? this.medType,
      status: status ?? this.status,
      intakeAdvice: intakeAdvice ?? this.intakeAdvice,
      criticalReminder: criticalReminder ?? this.criticalReminder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dosagesRemaining.present) {
      map['dosages_remaining'] = Variable<double>(dosagesRemaining.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (nationalCode.present) {
      map['national_code'] = Variable<int>(nationalCode.value);
    }
    if (medType.present) {
      map['med_type'] = Variable<int>(
        $MedicationsTable.$convertermedType.toSql(medType.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $MedicationsTable.$converterstatus.toSql(status.value),
      );
    }
    if (intakeAdvice.present) {
      map['intake_advice'] = Variable<String>(intakeAdvice.value);
    }
    if (criticalReminder.present) {
      map['critical_reminder'] = Variable<bool>(criticalReminder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dosagesRemaining: $dosagesRemaining, ')
          ..write('notes: $notes, ')
          ..write('nationalCode: $nationalCode, ')
          ..write('medType: $medType, ')
          ..write('status: $status, ')
          ..write('intakeAdvice: $intakeAdvice, ')
          ..write('criticalReminder: $criticalReminder')
          ..write(')'))
        .toString();
  }
}

class $MedicationPlansTable extends MedicationPlans
    with TableInfo<$MedicationPlansTable, MedicationPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<int> medicationId = GeneratedColumn<int>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id)',
    ),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dosageAmountMeta = const VerificationMeta(
    'dosageAmount',
  );
  @override
  late final GeneratedColumn<double> dosageAmount = GeneratedColumn<double>(
    'dosage_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    medicationId,
    startDate,
    endDate,
    dosageAmount,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('dosage_amount')) {
      context.handle(
        _dosageAmountMeta,
        dosageAmount.isAcceptableOrUnknown(
          data['dosage_amount']!,
          _dosageAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dosageAmountMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}medication_id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      dosageAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dosage_amount'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $MedicationPlansTable createAlias(String alias) {
    return $MedicationPlansTable(attachedDatabase, alias);
  }
}

class MedicationPlan extends DataClass implements Insertable<MedicationPlan> {
  final int id;
  final int userId;
  final int medicationId;
  final DateTime startDate;
  final DateTime? endDate;
  final double dosageAmount;
  final bool isActive;
  const MedicationPlan({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.startDate,
    this.endDate,
    required this.dosageAmount,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['medication_id'] = Variable<int>(medicationId);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['dosage_amount'] = Variable<double>(dosageAmount);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  MedicationPlansCompanion toCompanion(bool nullToAbsent) {
    return MedicationPlansCompanion(
      id: Value(id),
      userId: Value(userId),
      medicationId: Value(medicationId),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      dosageAmount: Value(dosageAmount),
      isActive: Value(isActive),
    );
  }

  factory MedicationPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationPlan(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      medicationId: serializer.fromJson<int>(json['medicationId']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      dosageAmount: serializer.fromJson<double>(json['dosageAmount']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'medicationId': serializer.toJson<int>(medicationId),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'dosageAmount': serializer.toJson<double>(dosageAmount),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  MedicationPlan copyWith({
    int? id,
    int? userId,
    int? medicationId,
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    double? dosageAmount,
    bool? isActive,
  }) => MedicationPlan(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    medicationId: medicationId ?? this.medicationId,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    dosageAmount: dosageAmount ?? this.dosageAmount,
    isActive: isActive ?? this.isActive,
  );
  MedicationPlan copyWithCompanion(MedicationPlansCompanion data) {
    return MedicationPlan(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      dosageAmount: data.dosageAmount.present
          ? data.dosageAmount.value
          : this.dosageAmount,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationPlan(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('medicationId: $medicationId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('dosageAmount: $dosageAmount, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    medicationId,
    startDate,
    endDate,
    dosageAmount,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationPlan &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.medicationId == this.medicationId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.dosageAmount == this.dosageAmount &&
          other.isActive == this.isActive);
}

class MedicationPlansCompanion extends UpdateCompanion<MedicationPlan> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> medicationId;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<double> dosageAmount;
  final Value<bool> isActive;
  const MedicationPlansCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.dosageAmount = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  MedicationPlansCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int medicationId,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    required double dosageAmount,
    this.isActive = const Value.absent(),
  }) : userId = Value(userId),
       medicationId = Value(medicationId),
       startDate = Value(startDate),
       dosageAmount = Value(dosageAmount);
  static Insertable<MedicationPlan> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? medicationId,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<double>? dosageAmount,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (medicationId != null) 'medication_id': medicationId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (dosageAmount != null) 'dosage_amount': dosageAmount,
      if (isActive != null) 'is_active': isActive,
    });
  }

  MedicationPlansCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? medicationId,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<double>? dosageAmount,
    Value<bool>? isActive,
  }) {
    return MedicationPlansCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicationId: medicationId ?? this.medicationId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<int>(medicationId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (dosageAmount.present) {
      map['dosage_amount'] = Variable<double>(dosageAmount.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationPlansCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('medicationId: $medicationId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('dosageAmount: $dosageAmount, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $MedicationScheduleRulesTable extends MedicationScheduleRules
    with TableInfo<$MedicationScheduleRulesTable, MedicationScheduleRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationScheduleRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medication_plans (id)',
    ),
  );
  static const VerificationMeta _ruleTypeMeta = const VerificationMeta(
    'ruleType',
  );
  @override
  late final GeneratedColumn<String> ruleType = GeneratedColumn<String>(
    'rule_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timesOfDayMeta = const VerificationMeta(
    'timesOfDay',
  );
  @override
  late final GeneratedColumn<String> timesOfDay = GeneratedColumn<String>(
    'times_of_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _daysOfWeekMeta = const VerificationMeta(
    'daysOfWeek',
  );
  @override
  late final GeneratedColumn<String> daysOfWeek = GeneratedColumn<String>(
    'days_of_week',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalHoursMeta = const VerificationMeta(
    'intervalHours',
  );
  @override
  late final GeneratedColumn<int> intervalHours = GeneratedColumn<int>(
    'interval_hours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleDaysOnMeta = const VerificationMeta(
    'cycleDaysOn',
  );
  @override
  late final GeneratedColumn<int> cycleDaysOn = GeneratedColumn<int>(
    'cycle_days_on',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleDaysOffMeta = const VerificationMeta(
    'cycleDaysOff',
  );
  @override
  late final GeneratedColumn<int> cycleDaysOff = GeneratedColumn<int>(
    'cycle_days_off',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    ruleType,
    timesOfDay,
    daysOfWeek,
    intervalHours,
    intervalDays,
    cycleDaysOn,
    cycleDaysOff,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_schedule_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationScheduleRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('rule_type')) {
      context.handle(
        _ruleTypeMeta,
        ruleType.isAcceptableOrUnknown(data['rule_type']!, _ruleTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleTypeMeta);
    }
    if (data.containsKey('times_of_day')) {
      context.handle(
        _timesOfDayMeta,
        timesOfDay.isAcceptableOrUnknown(
          data['times_of_day']!,
          _timesOfDayMeta,
        ),
      );
    }
    if (data.containsKey('days_of_week')) {
      context.handle(
        _daysOfWeekMeta,
        daysOfWeek.isAcceptableOrUnknown(
          data['days_of_week']!,
          _daysOfWeekMeta,
        ),
      );
    }
    if (data.containsKey('interval_hours')) {
      context.handle(
        _intervalHoursMeta,
        intervalHours.isAcceptableOrUnknown(
          data['interval_hours']!,
          _intervalHoursMeta,
        ),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('cycle_days_on')) {
      context.handle(
        _cycleDaysOnMeta,
        cycleDaysOn.isAcceptableOrUnknown(
          data['cycle_days_on']!,
          _cycleDaysOnMeta,
        ),
      );
    }
    if (data.containsKey('cycle_days_off')) {
      context.handle(
        _cycleDaysOffMeta,
        cycleDaysOff.isAcceptableOrUnknown(
          data['cycle_days_off']!,
          _cycleDaysOffMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationScheduleRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationScheduleRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      ruleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_type'],
      )!,
      timesOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}times_of_day'],
      ),
      daysOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days_of_week'],
      ),
      intervalHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_hours'],
      ),
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      ),
      cycleDaysOn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_days_on'],
      ),
      cycleDaysOff: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_days_off'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $MedicationScheduleRulesTable createAlias(String alias) {
    return $MedicationScheduleRulesTable(attachedDatabase, alias);
  }
}

class MedicationScheduleRule extends DataClass
    implements Insertable<MedicationScheduleRule> {
  final int id;
  final int planId;

  /// "daily", "hourInterval", "dayInterval", "weekly", "cyclic"
  final String ruleType;
  final String? timesOfDay;
  final String? daysOfWeek;
  final int? intervalHours;
  final int? intervalDays;
  final int? cycleDaysOn;
  final int? cycleDaysOff;
  final bool isActive;
  const MedicationScheduleRule({
    required this.id,
    required this.planId,
    required this.ruleType,
    this.timesOfDay,
    this.daysOfWeek,
    this.intervalHours,
    this.intervalDays,
    this.cycleDaysOn,
    this.cycleDaysOff,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['rule_type'] = Variable<String>(ruleType);
    if (!nullToAbsent || timesOfDay != null) {
      map['times_of_day'] = Variable<String>(timesOfDay);
    }
    if (!nullToAbsent || daysOfWeek != null) {
      map['days_of_week'] = Variable<String>(daysOfWeek);
    }
    if (!nullToAbsent || intervalHours != null) {
      map['interval_hours'] = Variable<int>(intervalHours);
    }
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    if (!nullToAbsent || cycleDaysOn != null) {
      map['cycle_days_on'] = Variable<int>(cycleDaysOn);
    }
    if (!nullToAbsent || cycleDaysOff != null) {
      map['cycle_days_off'] = Variable<int>(cycleDaysOff);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  MedicationScheduleRulesCompanion toCompanion(bool nullToAbsent) {
    return MedicationScheduleRulesCompanion(
      id: Value(id),
      planId: Value(planId),
      ruleType: Value(ruleType),
      timesOfDay: timesOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(timesOfDay),
      daysOfWeek: daysOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(daysOfWeek),
      intervalHours: intervalHours == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalHours),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      cycleDaysOn: cycleDaysOn == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleDaysOn),
      cycleDaysOff: cycleDaysOff == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleDaysOff),
      isActive: Value(isActive),
    );
  }

  factory MedicationScheduleRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationScheduleRule(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      ruleType: serializer.fromJson<String>(json['ruleType']),
      timesOfDay: serializer.fromJson<String?>(json['timesOfDay']),
      daysOfWeek: serializer.fromJson<String?>(json['daysOfWeek']),
      intervalHours: serializer.fromJson<int?>(json['intervalHours']),
      intervalDays: serializer.fromJson<int?>(json['intervalDays']),
      cycleDaysOn: serializer.fromJson<int?>(json['cycleDaysOn']),
      cycleDaysOff: serializer.fromJson<int?>(json['cycleDaysOff']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'ruleType': serializer.toJson<String>(ruleType),
      'timesOfDay': serializer.toJson<String?>(timesOfDay),
      'daysOfWeek': serializer.toJson<String?>(daysOfWeek),
      'intervalHours': serializer.toJson<int?>(intervalHours),
      'intervalDays': serializer.toJson<int?>(intervalDays),
      'cycleDaysOn': serializer.toJson<int?>(cycleDaysOn),
      'cycleDaysOff': serializer.toJson<int?>(cycleDaysOff),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  MedicationScheduleRule copyWith({
    int? id,
    int? planId,
    String? ruleType,
    Value<String?> timesOfDay = const Value.absent(),
    Value<String?> daysOfWeek = const Value.absent(),
    Value<int?> intervalHours = const Value.absent(),
    Value<int?> intervalDays = const Value.absent(),
    Value<int?> cycleDaysOn = const Value.absent(),
    Value<int?> cycleDaysOff = const Value.absent(),
    bool? isActive,
  }) => MedicationScheduleRule(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    ruleType: ruleType ?? this.ruleType,
    timesOfDay: timesOfDay.present ? timesOfDay.value : this.timesOfDay,
    daysOfWeek: daysOfWeek.present ? daysOfWeek.value : this.daysOfWeek,
    intervalHours: intervalHours.present
        ? intervalHours.value
        : this.intervalHours,
    intervalDays: intervalDays.present ? intervalDays.value : this.intervalDays,
    cycleDaysOn: cycleDaysOn.present ? cycleDaysOn.value : this.cycleDaysOn,
    cycleDaysOff: cycleDaysOff.present ? cycleDaysOff.value : this.cycleDaysOff,
    isActive: isActive ?? this.isActive,
  );
  MedicationScheduleRule copyWithCompanion(
    MedicationScheduleRulesCompanion data,
  ) {
    return MedicationScheduleRule(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      ruleType: data.ruleType.present ? data.ruleType.value : this.ruleType,
      timesOfDay: data.timesOfDay.present
          ? data.timesOfDay.value
          : this.timesOfDay,
      daysOfWeek: data.daysOfWeek.present
          ? data.daysOfWeek.value
          : this.daysOfWeek,
      intervalHours: data.intervalHours.present
          ? data.intervalHours.value
          : this.intervalHours,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      cycleDaysOn: data.cycleDaysOn.present
          ? data.cycleDaysOn.value
          : this.cycleDaysOn,
      cycleDaysOff: data.cycleDaysOff.present
          ? data.cycleDaysOff.value
          : this.cycleDaysOff,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationScheduleRule(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('ruleType: $ruleType, ')
          ..write('timesOfDay: $timesOfDay, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('intervalHours: $intervalHours, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('cycleDaysOn: $cycleDaysOn, ')
          ..write('cycleDaysOff: $cycleDaysOff, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    ruleType,
    timesOfDay,
    daysOfWeek,
    intervalHours,
    intervalDays,
    cycleDaysOn,
    cycleDaysOff,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationScheduleRule &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.ruleType == this.ruleType &&
          other.timesOfDay == this.timesOfDay &&
          other.daysOfWeek == this.daysOfWeek &&
          other.intervalHours == this.intervalHours &&
          other.intervalDays == this.intervalDays &&
          other.cycleDaysOn == this.cycleDaysOn &&
          other.cycleDaysOff == this.cycleDaysOff &&
          other.isActive == this.isActive);
}

class MedicationScheduleRulesCompanion
    extends UpdateCompanion<MedicationScheduleRule> {
  final Value<int> id;
  final Value<int> planId;
  final Value<String> ruleType;
  final Value<String?> timesOfDay;
  final Value<String?> daysOfWeek;
  final Value<int?> intervalHours;
  final Value<int?> intervalDays;
  final Value<int?> cycleDaysOn;
  final Value<int?> cycleDaysOff;
  final Value<bool> isActive;
  const MedicationScheduleRulesCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.ruleType = const Value.absent(),
    this.timesOfDay = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.intervalHours = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.cycleDaysOn = const Value.absent(),
    this.cycleDaysOff = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  MedicationScheduleRulesCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required String ruleType,
    this.timesOfDay = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.intervalHours = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.cycleDaysOn = const Value.absent(),
    this.cycleDaysOff = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : planId = Value(planId),
       ruleType = Value(ruleType);
  static Insertable<MedicationScheduleRule> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<String>? ruleType,
    Expression<String>? timesOfDay,
    Expression<String>? daysOfWeek,
    Expression<int>? intervalHours,
    Expression<int>? intervalDays,
    Expression<int>? cycleDaysOn,
    Expression<int>? cycleDaysOff,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (ruleType != null) 'rule_type': ruleType,
      if (timesOfDay != null) 'times_of_day': timesOfDay,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (intervalHours != null) 'interval_hours': intervalHours,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (cycleDaysOn != null) 'cycle_days_on': cycleDaysOn,
      if (cycleDaysOff != null) 'cycle_days_off': cycleDaysOff,
      if (isActive != null) 'is_active': isActive,
    });
  }

  MedicationScheduleRulesCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<String>? ruleType,
    Value<String?>? timesOfDay,
    Value<String?>? daysOfWeek,
    Value<int?>? intervalHours,
    Value<int?>? intervalDays,
    Value<int?>? cycleDaysOn,
    Value<int?>? cycleDaysOff,
    Value<bool>? isActive,
  }) {
    return MedicationScheduleRulesCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      ruleType: ruleType ?? this.ruleType,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      intervalHours: intervalHours ?? this.intervalHours,
      intervalDays: intervalDays ?? this.intervalDays,
      cycleDaysOn: cycleDaysOn ?? this.cycleDaysOn,
      cycleDaysOff: cycleDaysOff ?? this.cycleDaysOff,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (ruleType.present) {
      map['rule_type'] = Variable<String>(ruleType.value);
    }
    if (timesOfDay.present) {
      map['times_of_day'] = Variable<String>(timesOfDay.value);
    }
    if (daysOfWeek.present) {
      map['days_of_week'] = Variable<String>(daysOfWeek.value);
    }
    if (intervalHours.present) {
      map['interval_hours'] = Variable<int>(intervalHours.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (cycleDaysOn.present) {
      map['cycle_days_on'] = Variable<int>(cycleDaysOn.value);
    }
    if (cycleDaysOff.present) {
      map['cycle_days_off'] = Variable<int>(cycleDaysOff.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationScheduleRulesCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('ruleType: $ruleType, ')
          ..write('timesOfDay: $timesOfDay, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('intervalHours: $intervalHours, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('cycleDaysOn: $cycleDaysOn, ')
          ..write('cycleDaysOff: $cycleDaysOff, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $MedicationIntakeLogsTable extends MedicationIntakeLogs
    with TableInfo<$MedicationIntakeLogsTable, MedicationIntakeLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationIntakeLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medication_plans (id)',
    ),
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<int> medicationId = GeneratedColumn<int>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id)',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _scheduledTimeMeta = const VerificationMeta(
    'scheduledTime',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledTime =
      GeneratedColumn<DateTime>(
        'scheduled_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _takenTimeMeta = const VerificationMeta(
    'takenTime',
  );
  @override
  late final GeneratedColumn<DateTime> takenTime = GeneratedColumn<DateTime>(
    'taken_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wasTakenMeta = const VerificationMeta(
    'wasTaken',
  );
  @override
  late final GeneratedColumn<bool> wasTaken = GeneratedColumn<bool>(
    'was_taken',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_taken" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dosageAmountMeta = const VerificationMeta(
    'dosageAmount',
  );
  @override
  late final GeneratedColumn<double> dosageAmount = GeneratedColumn<double>(
    'dosage_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    medicationId,
    userId,
    scheduledTime,
    takenTime,
    wasTaken,
    dosageAmount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_intake_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationIntakeLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
        _scheduledTimeMeta,
        scheduledTime.isAcceptableOrUnknown(
          data['scheduled_time']!,
          _scheduledTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledTimeMeta);
    }
    if (data.containsKey('taken_time')) {
      context.handle(
        _takenTimeMeta,
        takenTime.isAcceptableOrUnknown(data['taken_time']!, _takenTimeMeta),
      );
    }
    if (data.containsKey('was_taken')) {
      context.handle(
        _wasTakenMeta,
        wasTaken.isAcceptableOrUnknown(data['was_taken']!, _wasTakenMeta),
      );
    }
    if (data.containsKey('dosage_amount')) {
      context.handle(
        _dosageAmountMeta,
        dosageAmount.isAcceptableOrUnknown(
          data['dosage_amount']!,
          _dosageAmountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationIntakeLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationIntakeLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}medication_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      scheduledTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_time'],
      )!,
      takenTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_time'],
      ),
      wasTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_taken'],
      )!,
      dosageAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dosage_amount'],
      ),
    );
  }

  @override
  $MedicationIntakeLogsTable createAlias(String alias) {
    return $MedicationIntakeLogsTable(attachedDatabase, alias);
  }
}

class MedicationIntakeLog extends DataClass
    implements Insertable<MedicationIntakeLog> {
  final int id;
  final int planId;
  final int medicationId;
  final int userId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final bool wasTaken;

  /// The dosage amount taken (used for as-needed entries where dosage may vary)
  final double? dosageAmount;
  const MedicationIntakeLog({
    required this.id,
    required this.planId,
    required this.medicationId,
    required this.userId,
    required this.scheduledTime,
    this.takenTime,
    required this.wasTaken,
    this.dosageAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['medication_id'] = Variable<int>(medicationId);
    map['user_id'] = Variable<int>(userId);
    map['scheduled_time'] = Variable<DateTime>(scheduledTime);
    if (!nullToAbsent || takenTime != null) {
      map['taken_time'] = Variable<DateTime>(takenTime);
    }
    map['was_taken'] = Variable<bool>(wasTaken);
    if (!nullToAbsent || dosageAmount != null) {
      map['dosage_amount'] = Variable<double>(dosageAmount);
    }
    return map;
  }

  MedicationIntakeLogsCompanion toCompanion(bool nullToAbsent) {
    return MedicationIntakeLogsCompanion(
      id: Value(id),
      planId: Value(planId),
      medicationId: Value(medicationId),
      userId: Value(userId),
      scheduledTime: Value(scheduledTime),
      takenTime: takenTime == null && nullToAbsent
          ? const Value.absent()
          : Value(takenTime),
      wasTaken: Value(wasTaken),
      dosageAmount: dosageAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(dosageAmount),
    );
  }

  factory MedicationIntakeLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationIntakeLog(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      medicationId: serializer.fromJson<int>(json['medicationId']),
      userId: serializer.fromJson<int>(json['userId']),
      scheduledTime: serializer.fromJson<DateTime>(json['scheduledTime']),
      takenTime: serializer.fromJson<DateTime?>(json['takenTime']),
      wasTaken: serializer.fromJson<bool>(json['wasTaken']),
      dosageAmount: serializer.fromJson<double?>(json['dosageAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'medicationId': serializer.toJson<int>(medicationId),
      'userId': serializer.toJson<int>(userId),
      'scheduledTime': serializer.toJson<DateTime>(scheduledTime),
      'takenTime': serializer.toJson<DateTime?>(takenTime),
      'wasTaken': serializer.toJson<bool>(wasTaken),
      'dosageAmount': serializer.toJson<double?>(dosageAmount),
    };
  }

  MedicationIntakeLog copyWith({
    int? id,
    int? planId,
    int? medicationId,
    int? userId,
    DateTime? scheduledTime,
    Value<DateTime?> takenTime = const Value.absent(),
    bool? wasTaken,
    Value<double?> dosageAmount = const Value.absent(),
  }) => MedicationIntakeLog(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    medicationId: medicationId ?? this.medicationId,
    userId: userId ?? this.userId,
    scheduledTime: scheduledTime ?? this.scheduledTime,
    takenTime: takenTime.present ? takenTime.value : this.takenTime,
    wasTaken: wasTaken ?? this.wasTaken,
    dosageAmount: dosageAmount.present ? dosageAmount.value : this.dosageAmount,
  );
  MedicationIntakeLog copyWithCompanion(MedicationIntakeLogsCompanion data) {
    return MedicationIntakeLog(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      userId: data.userId.present ? data.userId.value : this.userId,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      takenTime: data.takenTime.present ? data.takenTime.value : this.takenTime,
      wasTaken: data.wasTaken.present ? data.wasTaken.value : this.wasTaken,
      dosageAmount: data.dosageAmount.present
          ? data.dosageAmount.value
          : this.dosageAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationIntakeLog(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('medicationId: $medicationId, ')
          ..write('userId: $userId, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('takenTime: $takenTime, ')
          ..write('wasTaken: $wasTaken, ')
          ..write('dosageAmount: $dosageAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    medicationId,
    userId,
    scheduledTime,
    takenTime,
    wasTaken,
    dosageAmount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationIntakeLog &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.medicationId == this.medicationId &&
          other.userId == this.userId &&
          other.scheduledTime == this.scheduledTime &&
          other.takenTime == this.takenTime &&
          other.wasTaken == this.wasTaken &&
          other.dosageAmount == this.dosageAmount);
}

class MedicationIntakeLogsCompanion
    extends UpdateCompanion<MedicationIntakeLog> {
  final Value<int> id;
  final Value<int> planId;
  final Value<int> medicationId;
  final Value<int> userId;
  final Value<DateTime> scheduledTime;
  final Value<DateTime?> takenTime;
  final Value<bool> wasTaken;
  final Value<double?> dosageAmount;
  const MedicationIntakeLogsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.takenTime = const Value.absent(),
    this.wasTaken = const Value.absent(),
    this.dosageAmount = const Value.absent(),
  });
  MedicationIntakeLogsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required int medicationId,
    required int userId,
    required DateTime scheduledTime,
    this.takenTime = const Value.absent(),
    this.wasTaken = const Value.absent(),
    this.dosageAmount = const Value.absent(),
  }) : planId = Value(planId),
       medicationId = Value(medicationId),
       userId = Value(userId),
       scheduledTime = Value(scheduledTime);
  static Insertable<MedicationIntakeLog> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<int>? medicationId,
    Expression<int>? userId,
    Expression<DateTime>? scheduledTime,
    Expression<DateTime>? takenTime,
    Expression<bool>? wasTaken,
    Expression<double>? dosageAmount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (medicationId != null) 'medication_id': medicationId,
      if (userId != null) 'user_id': userId,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (takenTime != null) 'taken_time': takenTime,
      if (wasTaken != null) 'was_taken': wasTaken,
      if (dosageAmount != null) 'dosage_amount': dosageAmount,
    });
  }

  MedicationIntakeLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<int>? medicationId,
    Value<int>? userId,
    Value<DateTime>? scheduledTime,
    Value<DateTime?>? takenTime,
    Value<bool>? wasTaken,
    Value<double?>? dosageAmount,
  }) {
    return MedicationIntakeLogsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      medicationId: medicationId ?? this.medicationId,
      userId: userId ?? this.userId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      wasTaken: wasTaken ?? this.wasTaken,
      dosageAmount: dosageAmount ?? this.dosageAmount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<int>(medicationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<DateTime>(scheduledTime.value);
    }
    if (takenTime.present) {
      map['taken_time'] = Variable<DateTime>(takenTime.value);
    }
    if (wasTaken.present) {
      map['was_taken'] = Variable<bool>(wasTaken.value);
    }
    if (dosageAmount.present) {
      map['dosage_amount'] = Variable<double>(dosageAmount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationIntakeLogsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('medicationId: $medicationId, ')
          ..write('userId: $userId, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('takenTime: $takenTime, ')
          ..write('wasTaken: $wasTaken, ')
          ..write('dosageAmount: $dosageAmount')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _defaultUserIdMeta = const VerificationMeta(
    'defaultUserId',
  );
  @override
  late final GeneratedColumn<int> defaultUserId = GeneratedColumn<int>(
    'default_user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _alarmVolumeMeta = const VerificationMeta(
    'alarmVolume',
  );
  @override
  late final GeneratedColumn<double> alarmVolume = GeneratedColumn<double>(
    'alarm_volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.8),
  );
  static const VerificationMeta _alarmSoundMeta = const VerificationMeta(
    'alarmSound',
  );
  @override
  late final GeneratedColumn<String> alarmSound = GeneratedColumn<String>(
    'alarm_sound',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('nokia.mp3'),
  );
  static const VerificationMeta _alarmVibrationMeta = const VerificationMeta(
    'alarmVibration',
  );
  @override
  late final GeneratedColumn<bool> alarmVibration = GeneratedColumn<bool>(
    'alarm_vibration',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("alarm_vibration" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showKillWarningMeta = const VerificationMeta(
    'showKillWarning',
  );
  @override
  late final GeneratedColumn<bool> showKillWarning = GeneratedColumn<bool>(
    'show_kill_warning',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_kill_warning" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themeMode,
    defaultUserId,
    alarmVolume,
    alarmSound,
    alarmVibration,
    showKillWarning,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('default_user_id')) {
      context.handle(
        _defaultUserIdMeta,
        defaultUserId.isAcceptableOrUnknown(
          data['default_user_id']!,
          _defaultUserIdMeta,
        ),
      );
    }
    if (data.containsKey('alarm_volume')) {
      context.handle(
        _alarmVolumeMeta,
        alarmVolume.isAcceptableOrUnknown(
          data['alarm_volume']!,
          _alarmVolumeMeta,
        ),
      );
    }
    if (data.containsKey('alarm_sound')) {
      context.handle(
        _alarmSoundMeta,
        alarmSound.isAcceptableOrUnknown(data['alarm_sound']!, _alarmSoundMeta),
      );
    }
    if (data.containsKey('alarm_vibration')) {
      context.handle(
        _alarmVibrationMeta,
        alarmVibration.isAcceptableOrUnknown(
          data['alarm_vibration']!,
          _alarmVibrationMeta,
        ),
      );
    }
    if (data.containsKey('show_kill_warning')) {
      context.handle(
        _showKillWarningMeta,
        showKillWarning.isAcceptableOrUnknown(
          data['show_kill_warning']!,
          _showKillWarningMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      defaultUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_user_id'],
      ),
      alarmVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alarm_volume'],
      )!,
      alarmSound: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_sound'],
      )!,
      alarmVibration: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}alarm_vibration'],
      )!,
      showKillWarning: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_kill_warning'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String themeMode;
  final int? defaultUserId;
  final double alarmVolume;
  final String alarmSound;
  final bool alarmVibration;
  final bool showKillWarning;
  const AppSetting({
    required this.id,
    required this.themeMode,
    this.defaultUserId,
    required this.alarmVolume,
    required this.alarmSound,
    required this.alarmVibration,
    required this.showKillWarning,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme_mode'] = Variable<String>(themeMode);
    if (!nullToAbsent || defaultUserId != null) {
      map['default_user_id'] = Variable<int>(defaultUserId);
    }
    map['alarm_volume'] = Variable<double>(alarmVolume);
    map['alarm_sound'] = Variable<String>(alarmSound);
    map['alarm_vibration'] = Variable<bool>(alarmVibration);
    map['show_kill_warning'] = Variable<bool>(showKillWarning);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      defaultUserId: defaultUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultUserId),
      alarmVolume: Value(alarmVolume),
      alarmSound: Value(alarmSound),
      alarmVibration: Value(alarmVibration),
      showKillWarning: Value(showKillWarning),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      defaultUserId: serializer.fromJson<int?>(json['defaultUserId']),
      alarmVolume: serializer.fromJson<double>(json['alarmVolume']),
      alarmSound: serializer.fromJson<String>(json['alarmSound']),
      alarmVibration: serializer.fromJson<bool>(json['alarmVibration']),
      showKillWarning: serializer.fromJson<bool>(json['showKillWarning']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'themeMode': serializer.toJson<String>(themeMode),
      'defaultUserId': serializer.toJson<int?>(defaultUserId),
      'alarmVolume': serializer.toJson<double>(alarmVolume),
      'alarmSound': serializer.toJson<String>(alarmSound),
      'alarmVibration': serializer.toJson<bool>(alarmVibration),
      'showKillWarning': serializer.toJson<bool>(showKillWarning),
    };
  }

  AppSetting copyWith({
    int? id,
    String? themeMode,
    Value<int?> defaultUserId = const Value.absent(),
    double? alarmVolume,
    String? alarmSound,
    bool? alarmVibration,
    bool? showKillWarning,
  }) => AppSetting(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    defaultUserId: defaultUserId.present
        ? defaultUserId.value
        : this.defaultUserId,
    alarmVolume: alarmVolume ?? this.alarmVolume,
    alarmSound: alarmSound ?? this.alarmSound,
    alarmVibration: alarmVibration ?? this.alarmVibration,
    showKillWarning: showKillWarning ?? this.showKillWarning,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      defaultUserId: data.defaultUserId.present
          ? data.defaultUserId.value
          : this.defaultUserId,
      alarmVolume: data.alarmVolume.present
          ? data.alarmVolume.value
          : this.alarmVolume,
      alarmSound: data.alarmSound.present
          ? data.alarmSound.value
          : this.alarmSound,
      alarmVibration: data.alarmVibration.present
          ? data.alarmVibration.value
          : this.alarmVibration,
      showKillWarning: data.showKillWarning.present
          ? data.showKillWarning.value
          : this.showKillWarning,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('defaultUserId: $defaultUserId, ')
          ..write('alarmVolume: $alarmVolume, ')
          ..write('alarmSound: $alarmSound, ')
          ..write('alarmVibration: $alarmVibration, ')
          ..write('showKillWarning: $showKillWarning')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    themeMode,
    defaultUserId,
    alarmVolume,
    alarmSound,
    alarmVibration,
    showKillWarning,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.defaultUserId == this.defaultUserId &&
          other.alarmVolume == this.alarmVolume &&
          other.alarmSound == this.alarmSound &&
          other.alarmVibration == this.alarmVibration &&
          other.showKillWarning == this.showKillWarning);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> themeMode;
  final Value<int?> defaultUserId;
  final Value<double> alarmVolume;
  final Value<String> alarmSound;
  final Value<bool> alarmVibration;
  final Value<bool> showKillWarning;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.defaultUserId = const Value.absent(),
    this.alarmVolume = const Value.absent(),
    this.alarmSound = const Value.absent(),
    this.alarmVibration = const Value.absent(),
    this.showKillWarning = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.defaultUserId = const Value.absent(),
    this.alarmVolume = const Value.absent(),
    this.alarmSound = const Value.absent(),
    this.alarmVibration = const Value.absent(),
    this.showKillWarning = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? themeMode,
    Expression<int>? defaultUserId,
    Expression<double>? alarmVolume,
    Expression<String>? alarmSound,
    Expression<bool>? alarmVibration,
    Expression<bool>? showKillWarning,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (defaultUserId != null) 'default_user_id': defaultUserId,
      if (alarmVolume != null) 'alarm_volume': alarmVolume,
      if (alarmSound != null) 'alarm_sound': alarmSound,
      if (alarmVibration != null) 'alarm_vibration': alarmVibration,
      if (showKillWarning != null) 'show_kill_warning': showKillWarning,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? themeMode,
    Value<int?>? defaultUserId,
    Value<double>? alarmVolume,
    Value<String>? alarmSound,
    Value<bool>? alarmVibration,
    Value<bool>? showKillWarning,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      defaultUserId: defaultUserId ?? this.defaultUserId,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      alarmSound: alarmSound ?? this.alarmSound,
      alarmVibration: alarmVibration ?? this.alarmVibration,
      showKillWarning: showKillWarning ?? this.showKillWarning,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (defaultUserId.present) {
      map['default_user_id'] = Variable<int>(defaultUserId.value);
    }
    if (alarmVolume.present) {
      map['alarm_volume'] = Variable<double>(alarmVolume.value);
    }
    if (alarmSound.present) {
      map['alarm_sound'] = Variable<String>(alarmSound.value);
    }
    if (alarmVibration.present) {
      map['alarm_vibration'] = Variable<bool>(alarmVibration.value);
    }
    if (showKillWarning.present) {
      map['show_kill_warning'] = Variable<bool>(showKillWarning.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('defaultUserId: $defaultUserId, ')
          ..write('alarmVolume: $alarmVolume, ')
          ..write('alarmSound: $alarmSound, ')
          ..write('alarmVibration: $alarmVibration, ')
          ..write('showKillWarning: $showKillWarning')
          ..write(')'))
        .toString();
  }
}

class $OnboardingSettingsTable extends OnboardingSettings
    with TableInfo<$OnboardingSettingsTable, OnboardingSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OnboardingSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<UserType?, int> userType =
      GeneratedColumn<int>(
        'user_type',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<UserType?>($OnboardingSettingsTable.$converteruserTypen);
  static const VerificationMeta _familyNameMeta = const VerificationMeta(
    'familyName',
  );
  @override
  late final GeneratedColumn<String> familyName = GeneratedColumn<String>(
    'family_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isCompleted,
    userType,
    familyName,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'onboarding_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<OnboardingSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('family_name')) {
      context.handle(
        _familyNameMeta,
        familyName.isAcceptableOrUnknown(data['family_name']!, _familyNameMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OnboardingSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OnboardingSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      userType: $OnboardingSettingsTable.$converteruserTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}user_type'],
        ),
      ),
      familyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_name'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $OnboardingSettingsTable createAlias(String alias) {
    return $OnboardingSettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UserType, int, int> $converteruserType =
      const EnumIndexConverter<UserType>(UserType.values);
  static JsonTypeConverter2<UserType?, int?, int?> $converteruserTypen =
      JsonTypeConverter2.asNullable($converteruserType);
}

class OnboardingSetting extends DataClass
    implements Insertable<OnboardingSetting> {
  final int id;
  final bool isCompleted;
  final UserType? userType;
  final String? familyName;
  final DateTime? completedAt;
  const OnboardingSetting({
    required this.id,
    required this.isCompleted,
    this.userType,
    this.familyName,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || userType != null) {
      map['user_type'] = Variable<int>(
        $OnboardingSettingsTable.$converteruserTypen.toSql(userType),
      );
    }
    if (!nullToAbsent || familyName != null) {
      map['family_name'] = Variable<String>(familyName);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  OnboardingSettingsCompanion toCompanion(bool nullToAbsent) {
    return OnboardingSettingsCompanion(
      id: Value(id),
      isCompleted: Value(isCompleted),
      userType: userType == null && nullToAbsent
          ? const Value.absent()
          : Value(userType),
      familyName: familyName == null && nullToAbsent
          ? const Value.absent()
          : Value(familyName),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory OnboardingSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OnboardingSetting(
      id: serializer.fromJson<int>(json['id']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      userType: $OnboardingSettingsTable.$converteruserTypen.fromJson(
        serializer.fromJson<int?>(json['userType']),
      ),
      familyName: serializer.fromJson<String?>(json['familyName']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'userType': serializer.toJson<int?>(
        $OnboardingSettingsTable.$converteruserTypen.toJson(userType),
      ),
      'familyName': serializer.toJson<String?>(familyName),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  OnboardingSetting copyWith({
    int? id,
    bool? isCompleted,
    Value<UserType?> userType = const Value.absent(),
    Value<String?> familyName = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => OnboardingSetting(
    id: id ?? this.id,
    isCompleted: isCompleted ?? this.isCompleted,
    userType: userType.present ? userType.value : this.userType,
    familyName: familyName.present ? familyName.value : this.familyName,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  OnboardingSetting copyWithCompanion(OnboardingSettingsCompanion data) {
    return OnboardingSetting(
      id: data.id.present ? data.id.value : this.id,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      userType: data.userType.present ? data.userType.value : this.userType,
      familyName: data.familyName.present
          ? data.familyName.value
          : this.familyName,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingSetting(')
          ..write('id: $id, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('userType: $userType, ')
          ..write('familyName: $familyName, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, isCompleted, userType, familyName, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OnboardingSetting &&
          other.id == this.id &&
          other.isCompleted == this.isCompleted &&
          other.userType == this.userType &&
          other.familyName == this.familyName &&
          other.completedAt == this.completedAt);
}

class OnboardingSettingsCompanion extends UpdateCompanion<OnboardingSetting> {
  final Value<int> id;
  final Value<bool> isCompleted;
  final Value<UserType?> userType;
  final Value<String?> familyName;
  final Value<DateTime?> completedAt;
  const OnboardingSettingsCompanion({
    this.id = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.userType = const Value.absent(),
    this.familyName = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  OnboardingSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.userType = const Value.absent(),
    this.familyName = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  static Insertable<OnboardingSetting> custom({
    Expression<int>? id,
    Expression<bool>? isCompleted,
    Expression<int>? userType,
    Expression<String>? familyName,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (userType != null) 'user_type': userType,
      if (familyName != null) 'family_name': familyName,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  OnboardingSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? isCompleted,
    Value<UserType?>? userType,
    Value<String?>? familyName,
    Value<DateTime?>? completedAt,
  }) {
    return OnboardingSettingsCompanion(
      id: id ?? this.id,
      isCompleted: isCompleted ?? this.isCompleted,
      userType: userType ?? this.userType,
      familyName: familyName ?? this.familyName,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (userType.present) {
      map['user_type'] = Variable<int>(
        $OnboardingSettingsTable.$converteruserTypen.toSql(userType.value),
      );
    }
    if (familyName.present) {
      map['family_name'] = Variable<String>(familyName.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingSettingsCompanion(')
          ..write('id: $id, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('userType: $userType, ')
          ..write('familyName: $familyName, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $MoodEntriesTable extends MoodEntries
    with TableInfo<$MoodEntriesTable, MoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _moodLevelMeta = const VerificationMeta(
    'moodLevel',
  );
  @override
  late final GeneratedColumn<int> moodLevel = GeneratedColumn<int>(
    'mood_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    moodLevel,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mood_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('mood_level')) {
      context.handle(
        _moodLevelMeta,
        moodLevel.isAcceptableOrUnknown(data['mood_level']!, _moodLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_moodLevelMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      moodLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood_level'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MoodEntriesTable createAlias(String alias) {
    return $MoodEntriesTable(attachedDatabase, alias);
  }
}

class MoodEntry extends DataClass implements Insertable<MoodEntry> {
  final int id;
  final int userId;

  /// Mood level from 1 (very bad) to 5 (great)
  final int moodLevel;

  /// Optional note about the mood
  final String? note;
  final DateTime createdAt;
  const MoodEntry({
    required this.id,
    required this.userId,
    required this.moodLevel,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['mood_level'] = Variable<int>(moodLevel);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return MoodEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      moodLevel: Value(moodLevel),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory MoodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodEntry(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      moodLevel: serializer.fromJson<int>(json['moodLevel']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'moodLevel': serializer.toJson<int>(moodLevel),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MoodEntry copyWith({
    int? id,
    int? userId,
    int? moodLevel,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => MoodEntry(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    moodLevel: moodLevel ?? this.moodLevel,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  MoodEntry copyWithCompanion(MoodEntriesCompanion data) {
    return MoodEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      moodLevel: data.moodLevel.present ? data.moodLevel.value : this.moodLevel,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('moodLevel: $moodLevel, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, moodLevel, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.moodLevel == this.moodLevel &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class MoodEntriesCompanion extends UpdateCompanion<MoodEntry> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> moodLevel;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const MoodEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.moodLevel = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int moodLevel,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : userId = Value(userId),
       moodLevel = Value(moodLevel);
  static Insertable<MoodEntry> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? moodLevel,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (moodLevel != null) 'mood_level': moodLevel,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MoodEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? moodLevel,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return MoodEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodLevel: moodLevel ?? this.moodLevel,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (moodLevel.present) {
      map['mood_level'] = Variable<int>(moodLevel.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('moodLevel: $moodLevel, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PeriodEntriesTable extends PeriodEntries
    with TableInfo<$PeriodEntriesTable, PeriodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _entryTypeMeta = const VerificationMeta(
    'entryType',
  );
  @override
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
    'entry_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flowIntensityMeta = const VerificationMeta(
    'flowIntensity',
  );
  @override
  late final GeneratedColumn<int> flowIntensity = GeneratedColumn<int>(
    'flow_intensity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    entryType,
    flowIntensity,
    note,
    date,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeriodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('entry_type')) {
      context.handle(
        _entryTypeMeta,
        entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entryTypeMeta);
    }
    if (data.containsKey('flow_intensity')) {
      context.handle(
        _flowIntensityMeta,
        flowIntensity.isAcceptableOrUnknown(
          data['flow_intensity']!,
          _flowIntensityMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      entryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_type'],
      )!,
      flowIntensity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flow_intensity'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PeriodEntriesTable createAlias(String alias) {
    return $PeriodEntriesTable(attachedDatabase, alias);
  }
}

class PeriodEntry extends DataClass implements Insertable<PeriodEntry> {
  final int id;
  final int userId;

  /// Type of entry: 'start', 'end', 'note'
  final String entryType;

  /// Flow intensity 1 (light) to 3 (heavy), nullable for end/note types
  final int? flowIntensity;

  /// Optional note
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  const PeriodEntry({
    required this.id,
    required this.userId,
    required this.entryType,
    this.flowIntensity,
    this.note,
    required this.date,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['entry_type'] = Variable<String>(entryType);
    if (!nullToAbsent || flowIntensity != null) {
      map['flow_intensity'] = Variable<int>(flowIntensity);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['date'] = Variable<DateTime>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PeriodEntriesCompanion toCompanion(bool nullToAbsent) {
    return PeriodEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      entryType: Value(entryType),
      flowIntensity: flowIntensity == null && nullToAbsent
          ? const Value.absent()
          : Value(flowIntensity),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      date: Value(date),
      createdAt: Value(createdAt),
    );
  }

  factory PeriodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodEntry(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      entryType: serializer.fromJson<String>(json['entryType']),
      flowIntensity: serializer.fromJson<int?>(json['flowIntensity']),
      note: serializer.fromJson<String?>(json['note']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'entryType': serializer.toJson<String>(entryType),
      'flowIntensity': serializer.toJson<int?>(flowIntensity),
      'note': serializer.toJson<String?>(note),
      'date': serializer.toJson<DateTime>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PeriodEntry copyWith({
    int? id,
    int? userId,
    String? entryType,
    Value<int?> flowIntensity = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? date,
    DateTime? createdAt,
  }) => PeriodEntry(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    entryType: entryType ?? this.entryType,
    flowIntensity: flowIntensity.present
        ? flowIntensity.value
        : this.flowIntensity,
    note: note.present ? note.value : this.note,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
  );
  PeriodEntry copyWithCompanion(PeriodEntriesCompanion data) {
    return PeriodEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      flowIntensity: data.flowIntensity.present
          ? data.flowIntensity.value
          : this.flowIntensity,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entryType: $entryType, ')
          ..write('flowIntensity: $flowIntensity, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, entryType, flowIntensity, note, date, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.entryType == this.entryType &&
          other.flowIntensity == this.flowIntensity &&
          other.note == this.note &&
          other.date == this.date &&
          other.createdAt == this.createdAt);
}

class PeriodEntriesCompanion extends UpdateCompanion<PeriodEntry> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> entryType;
  final Value<int?> flowIntensity;
  final Value<String?> note;
  final Value<DateTime> date;
  final Value<DateTime> createdAt;
  const PeriodEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.entryType = const Value.absent(),
    this.flowIntensity = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PeriodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String entryType,
    this.flowIntensity = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime date,
    this.createdAt = const Value.absent(),
  }) : userId = Value(userId),
       entryType = Value(entryType),
       date = Value(date);
  static Insertable<PeriodEntry> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? entryType,
    Expression<int>? flowIntensity,
    Expression<String>? note,
    Expression<DateTime>? date,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (entryType != null) 'entry_type': entryType,
      if (flowIntensity != null) 'flow_intensity': flowIntensity,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PeriodEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? entryType,
    Value<int?>? flowIntensity,
    Value<String?>? note,
    Value<DateTime>? date,
    Value<DateTime>? createdAt,
  }) {
    return PeriodEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entryType: entryType ?? this.entryType,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (flowIntensity.present) {
      map['flow_intensity'] = Variable<int>(flowIntensity.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entryType: $entryType, ')
          ..write('flowIntensity: $flowIntensity, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $MedicationPlansTable medicationPlans = $MedicationPlansTable(
    this,
  );
  late final $MedicationScheduleRulesTable medicationScheduleRules =
      $MedicationScheduleRulesTable(this);
  late final $MedicationIntakeLogsTable medicationIntakeLogs =
      $MedicationIntakeLogsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $OnboardingSettingsTable onboardingSettings =
      $OnboardingSettingsTable(this);
  late final $MoodEntriesTable moodEntries = $MoodEntriesTable(this);
  late final $PeriodEntriesTable periodEntries = $PeriodEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    medications,
    medicationPlans,
    medicationScheduleRules,
    medicationIntakeLogs,
    appSettings,
    onboardingSettings,
    moodEntries,
    periodEntries,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> age,
      Value<String?> gender,
      Value<DateTime> createdAt,
      Value<bool> isActive,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> age,
      Value<String?> gender,
      Value<DateTime> createdAt,
      Value<bool> isActive,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MedicationPlansTable, List<MedicationPlan>>
  _medicationPlansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.medicationPlans,
    aliasName: $_aliasNameGenerator(db.users.id, db.medicationPlans.userId),
  );

  $$MedicationPlansTableProcessedTableManager get medicationPlansRefs {
    final manager = $$MedicationPlansTableTableManager(
      $_db,
      $_db.medicationPlans,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationPlansRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MedicationIntakeLogsTable,
    List<MedicationIntakeLog>
  >
  _medicationIntakeLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationIntakeLogs,
        aliasName: $_aliasNameGenerator(
          db.users.id,
          db.medicationIntakeLogs.userId,
        ),
      );

  $$MedicationIntakeLogsTableProcessedTableManager
  get medicationIntakeLogsRefs {
    final manager = $$MedicationIntakeLogsTableTableManager(
      $_db,
      $_db.medicationIntakeLogs,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationIntakeLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AppSettingsTable, List<AppSetting>>
  _appSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.appSettings,
    aliasName: $_aliasNameGenerator(db.users.id, db.appSettings.defaultUserId),
  );

  $$AppSettingsTableProcessedTableManager get appSettingsRefs {
    final manager = $$AppSettingsTableTableManager(
      $_db,
      $_db.appSettings,
    ).filter((f) => f.defaultUserId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_appSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MoodEntriesTable, List<MoodEntry>>
  _moodEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.moodEntries,
    aliasName: $_aliasNameGenerator(db.users.id, db.moodEntries.userId),
  );

  $$MoodEntriesTableProcessedTableManager get moodEntriesRefs {
    final manager = $$MoodEntriesTableTableManager(
      $_db,
      $_db.moodEntries,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_moodEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PeriodEntriesTable, List<PeriodEntry>>
  _periodEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.periodEntries,
    aliasName: $_aliasNameGenerator(db.users.id, db.periodEntries.userId),
  );

  $$PeriodEntriesTableProcessedTableManager get periodEntriesRefs {
    final manager = $$PeriodEntriesTableTableManager(
      $_db,
      $_db.periodEntries,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_periodEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> medicationPlansRefs(
    Expression<bool> Function($$MedicationPlansTableFilterComposer f) f,
  ) {
    final $$MedicationPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableFilterComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> medicationIntakeLogsRefs(
    Expression<bool> Function($$MedicationIntakeLogsTableFilterComposer f) f,
  ) {
    final $$MedicationIntakeLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationIntakeLogs,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationIntakeLogsTableFilterComposer(
            $db: $db,
            $table: $db.medicationIntakeLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> appSettingsRefs(
    Expression<bool> Function($$AppSettingsTableFilterComposer f) f,
  ) {
    final $$AppSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.defaultUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppSettingsTableFilterComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> moodEntriesRefs(
    Expression<bool> Function($$MoodEntriesTableFilterComposer f) f,
  ) {
    final $$MoodEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.moodEntries,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoodEntriesTableFilterComposer(
            $db: $db,
            $table: $db.moodEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> periodEntriesRefs(
    Expression<bool> Function($$PeriodEntriesTableFilterComposer f) f,
  ) {
    final $$PeriodEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.periodEntries,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodEntriesTableFilterComposer(
            $db: $db,
            $table: $db.periodEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> medicationPlansRefs<T extends Object>(
    Expression<T> Function($$MedicationPlansTableAnnotationComposer a) f,
  ) {
    final $$MedicationPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> medicationIntakeLogsRefs<T extends Object>(
    Expression<T> Function($$MedicationIntakeLogsTableAnnotationComposer a) f,
  ) {
    final $$MedicationIntakeLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationIntakeLogs,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationIntakeLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationIntakeLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> appSettingsRefs<T extends Object>(
    Expression<T> Function($$AppSettingsTableAnnotationComposer a) f,
  ) {
    final $$AppSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.defaultUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> moodEntriesRefs<T extends Object>(
    Expression<T> Function($$MoodEntriesTableAnnotationComposer a) f,
  ) {
    final $$MoodEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.moodEntries,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoodEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.moodEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> periodEntriesRefs<T extends Object>(
    Expression<T> Function($$PeriodEntriesTableAnnotationComposer a) f,
  ) {
    final $$PeriodEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.periodEntries,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeriodEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.periodEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, $$UsersTableReferences),
          User,
          PrefetchHooks Function({
            bool medicationPlansRefs,
            bool medicationIntakeLogsRefs,
            bool appSettingsRefs,
            bool moodEntriesRefs,
            bool periodEntriesRefs,
          })
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> age = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                age: age,
                gender: gender,
                createdAt: createdAt,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> age = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                age: age,
                gender: gender,
                createdAt: createdAt,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$UsersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                medicationPlansRefs = false,
                medicationIntakeLogsRefs = false,
                appSettingsRefs = false,
                moodEntriesRefs = false,
                periodEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (medicationPlansRefs) db.medicationPlans,
                    if (medicationIntakeLogsRefs) db.medicationIntakeLogs,
                    if (appSettingsRefs) db.appSettings,
                    if (moodEntriesRefs) db.moodEntries,
                    if (periodEntriesRefs) db.periodEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (medicationPlansRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          MedicationPlan
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._medicationPlansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).medicationPlansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (medicationIntakeLogsRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          MedicationIntakeLog
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._medicationIntakeLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).medicationIntakeLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (appSettingsRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          AppSetting
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._appSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).appSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.defaultUserId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (moodEntriesRefs)
                        await $_getPrefetchedData<User, $UsersTable, MoodEntry>(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._moodEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).moodEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (periodEntriesRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          PeriodEntry
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._periodEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).periodEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, $$UsersTableReferences),
      User,
      PrefetchHooks Function({
        bool medicationPlansRefs,
        bool medicationIntakeLogsRefs,
        bool appSettingsRefs,
        bool moodEntriesRefs,
        bool periodEntriesRefs,
      })
    >;
typedef $$MedicationsTableCreateCompanionBuilder =
    MedicationsCompanion Function({
      Value<int> id,
      required String name,
      Value<double?> dosagesRemaining,
      Value<String?> notes,
      Value<int?> nationalCode,
      required MedicationType medType,
      Value<MedicationStatus> status,
      Value<String?> intakeAdvice,
      Value<bool> criticalReminder,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double?> dosagesRemaining,
      Value<String?> notes,
      Value<int?> nationalCode,
      Value<MedicationType> medType,
      Value<MedicationStatus> status,
      Value<String?> intakeAdvice,
      Value<bool> criticalReminder,
    });

final class $$MedicationsTableReferences
    extends BaseReferences<_$AppDatabase, $MedicationsTable, Medication> {
  $$MedicationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MedicationPlansTable, List<MedicationPlan>>
  _medicationPlansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.medicationPlans,
    aliasName: $_aliasNameGenerator(
      db.medications.id,
      db.medicationPlans.medicationId,
    ),
  );

  $$MedicationPlansTableProcessedTableManager get medicationPlansRefs {
    final manager = $$MedicationPlansTableTableManager(
      $_db,
      $_db.medicationPlans,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationPlansRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MedicationIntakeLogsTable,
    List<MedicationIntakeLog>
  >
  _medicationIntakeLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationIntakeLogs,
        aliasName: $_aliasNameGenerator(
          db.medications.id,
          db.medicationIntakeLogs.medicationId,
        ),
      );

  $$MedicationIntakeLogsTableProcessedTableManager
  get medicationIntakeLogsRefs {
    final manager = $$MedicationIntakeLogsTableTableManager(
      $_db,
      $_db.medicationIntakeLogs,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationIntakeLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dosagesRemaining => $composableBuilder(
    column: $table.dosagesRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nationalCode => $composableBuilder(
    column: $table.nationalCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicationType, MedicationType, int>
  get medType => $composableBuilder(
    column: $table.medType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicationStatus, MedicationStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get intakeAdvice => $composableBuilder(
    column: $table.intakeAdvice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get criticalReminder => $composableBuilder(
    column: $table.criticalReminder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> medicationPlansRefs(
    Expression<bool> Function($$MedicationPlansTableFilterComposer f) f,
  ) {
    final $$MedicationPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableFilterComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> medicationIntakeLogsRefs(
    Expression<bool> Function($$MedicationIntakeLogsTableFilterComposer f) f,
  ) {
    final $$MedicationIntakeLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationIntakeLogs,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationIntakeLogsTableFilterComposer(
            $db: $db,
            $table: $db.medicationIntakeLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dosagesRemaining => $composableBuilder(
    column: $table.dosagesRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nationalCode => $composableBuilder(
    column: $table.nationalCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get medType => $composableBuilder(
    column: $table.medType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intakeAdvice => $composableBuilder(
    column: $table.intakeAdvice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get criticalReminder => $composableBuilder(
    column: $table.criticalReminder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get dosagesRemaining => $composableBuilder(
    column: $table.dosagesRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get nationalCode => $composableBuilder(
    column: $table.nationalCode,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MedicationType, int> get medType =>
      $composableBuilder(column: $table.medType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MedicationStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get intakeAdvice => $composableBuilder(
    column: $table.intakeAdvice,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get criticalReminder => $composableBuilder(
    column: $table.criticalReminder,
    builder: (column) => column,
  );

  Expression<T> medicationPlansRefs<T extends Object>(
    Expression<T> Function($$MedicationPlansTableAnnotationComposer a) f,
  ) {
    final $$MedicationPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> medicationIntakeLogsRefs<T extends Object>(
    Expression<T> Function($$MedicationIntakeLogsTableAnnotationComposer a) f,
  ) {
    final $$MedicationIntakeLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationIntakeLogs,
          getReferencedColumn: (t) => t.medicationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationIntakeLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationIntakeLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTable,
          Medication,
          $$MedicationsTableFilterComposer,
          $$MedicationsTableOrderingComposer,
          $$MedicationsTableAnnotationComposer,
          $$MedicationsTableCreateCompanionBuilder,
          $$MedicationsTableUpdateCompanionBuilder,
          (Medication, $$MedicationsTableReferences),
          Medication,
          PrefetchHooks Function({
            bool medicationPlansRefs,
            bool medicationIntakeLogsRefs,
          })
        > {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> dosagesRemaining = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> nationalCode = const Value.absent(),
                Value<MedicationType> medType = const Value.absent(),
                Value<MedicationStatus> status = const Value.absent(),
                Value<String?> intakeAdvice = const Value.absent(),
                Value<bool> criticalReminder = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                name: name,
                dosagesRemaining: dosagesRemaining,
                notes: notes,
                nationalCode: nationalCode,
                medType: medType,
                status: status,
                intakeAdvice: intakeAdvice,
                criticalReminder: criticalReminder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<double?> dosagesRemaining = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> nationalCode = const Value.absent(),
                required MedicationType medType,
                Value<MedicationStatus> status = const Value.absent(),
                Value<String?> intakeAdvice = const Value.absent(),
                Value<bool> criticalReminder = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                name: name,
                dosagesRemaining: dosagesRemaining,
                notes: notes,
                nationalCode: nationalCode,
                medType: medType,
                status: status,
                intakeAdvice: intakeAdvice,
                criticalReminder: criticalReminder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                medicationPlansRefs = false,
                medicationIntakeLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (medicationPlansRefs) db.medicationPlans,
                    if (medicationIntakeLogsRefs) db.medicationIntakeLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (medicationPlansRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          MedicationPlan
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._medicationPlansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).medicationPlansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (medicationIntakeLogsRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          MedicationIntakeLog
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._medicationIntakeLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).medicationIntakeLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTable,
      Medication,
      $$MedicationsTableFilterComposer,
      $$MedicationsTableOrderingComposer,
      $$MedicationsTableAnnotationComposer,
      $$MedicationsTableCreateCompanionBuilder,
      $$MedicationsTableUpdateCompanionBuilder,
      (Medication, $$MedicationsTableReferences),
      Medication,
      PrefetchHooks Function({
        bool medicationPlansRefs,
        bool medicationIntakeLogsRefs,
      })
    >;
typedef $$MedicationPlansTableCreateCompanionBuilder =
    MedicationPlansCompanion Function({
      Value<int> id,
      required int userId,
      required int medicationId,
      required DateTime startDate,
      Value<DateTime?> endDate,
      required double dosageAmount,
      Value<bool> isActive,
    });
typedef $$MedicationPlansTableUpdateCompanionBuilder =
    MedicationPlansCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> medicationId,
      Value<DateTime> startDate,
      Value<DateTime?> endDate,
      Value<double> dosageAmount,
      Value<bool> isActive,
    });

final class $$MedicationPlansTableReferences
    extends
        BaseReferences<_$AppDatabase, $MedicationPlansTable, MedicationPlan> {
  $$MedicationPlansTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.medicationPlans.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) =>
      db.medications.createAlias(
        $_aliasNameGenerator(
          db.medicationPlans.medicationId,
          db.medications.id,
        ),
      );

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<int>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $MedicationScheduleRulesTable,
    List<MedicationScheduleRule>
  >
  _medicationScheduleRulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationScheduleRules,
        aliasName: $_aliasNameGenerator(
          db.medicationPlans.id,
          db.medicationScheduleRules.planId,
        ),
      );

  $$MedicationScheduleRulesTableProcessedTableManager
  get medicationScheduleRulesRefs {
    final manager = $$MedicationScheduleRulesTableTableManager(
      $_db,
      $_db.medicationScheduleRules,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationScheduleRulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MedicationIntakeLogsTable,
    List<MedicationIntakeLog>
  >
  _medicationIntakeLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationIntakeLogs,
        aliasName: $_aliasNameGenerator(
          db.medicationPlans.id,
          db.medicationIntakeLogs.planId,
        ),
      );

  $$MedicationIntakeLogsTableProcessedTableManager
  get medicationIntakeLogsRefs {
    final manager = $$MedicationIntakeLogsTableTableManager(
      $_db,
      $_db.medicationIntakeLogs,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationIntakeLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MedicationPlansTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationPlansTable> {
  $$MedicationPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dosageAmount => $composableBuilder(
    column: $table.dosageAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> medicationScheduleRulesRefs(
    Expression<bool> Function($$MedicationScheduleRulesTableFilterComposer f) f,
  ) {
    final $$MedicationScheduleRulesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationScheduleRules,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationScheduleRulesTableFilterComposer(
                $db: $db,
                $table: $db.medicationScheduleRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> medicationIntakeLogsRefs(
    Expression<bool> Function($$MedicationIntakeLogsTableFilterComposer f) f,
  ) {
    final $$MedicationIntakeLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationIntakeLogs,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationIntakeLogsTableFilterComposer(
            $db: $db,
            $table: $db.medicationIntakeLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationPlansTable> {
  $$MedicationPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dosageAmount => $composableBuilder(
    column: $table.dosageAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationPlansTable> {
  $$MedicationPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<double> get dosageAmount => $composableBuilder(
    column: $table.dosageAmount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> medicationScheduleRulesRefs<T extends Object>(
    Expression<T> Function($$MedicationScheduleRulesTableAnnotationComposer a)
    f,
  ) {
    final $$MedicationScheduleRulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationScheduleRules,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationScheduleRulesTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationScheduleRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> medicationIntakeLogsRefs<T extends Object>(
    Expression<T> Function($$MedicationIntakeLogsTableAnnotationComposer a) f,
  ) {
    final $$MedicationIntakeLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationIntakeLogs,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationIntakeLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationIntakeLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MedicationPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationPlansTable,
          MedicationPlan,
          $$MedicationPlansTableFilterComposer,
          $$MedicationPlansTableOrderingComposer,
          $$MedicationPlansTableAnnotationComposer,
          $$MedicationPlansTableCreateCompanionBuilder,
          $$MedicationPlansTableUpdateCompanionBuilder,
          (MedicationPlan, $$MedicationPlansTableReferences),
          MedicationPlan,
          PrefetchHooks Function({
            bool userId,
            bool medicationId,
            bool medicationScheduleRulesRefs,
            bool medicationIntakeLogsRefs,
          })
        > {
  $$MedicationPlansTableTableManager(
    _$AppDatabase db,
    $MedicationPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> medicationId = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<double> dosageAmount = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => MedicationPlansCompanion(
                id: id,
                userId: userId,
                medicationId: medicationId,
                startDate: startDate,
                endDate: endDate,
                dosageAmount: dosageAmount,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int medicationId,
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                required double dosageAmount,
                Value<bool> isActive = const Value.absent(),
              }) => MedicationPlansCompanion.insert(
                id: id,
                userId: userId,
                medicationId: medicationId,
                startDate: startDate,
                endDate: endDate,
                dosageAmount: dosageAmount,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationPlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                userId = false,
                medicationId = false,
                medicationScheduleRulesRefs = false,
                medicationIntakeLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (medicationScheduleRulesRefs) db.medicationScheduleRules,
                    if (medicationIntakeLogsRefs) db.medicationIntakeLogs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable:
                                        $$MedicationPlansTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$MedicationPlansTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (medicationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.medicationId,
                                    referencedTable:
                                        $$MedicationPlansTableReferences
                                            ._medicationIdTable(db),
                                    referencedColumn:
                                        $$MedicationPlansTableReferences
                                            ._medicationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (medicationScheduleRulesRefs)
                        await $_getPrefetchedData<
                          MedicationPlan,
                          $MedicationPlansTable,
                          MedicationScheduleRule
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationPlansTableReferences
                              ._medicationScheduleRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationPlansTableReferences(
                                db,
                                table,
                                p0,
                              ).medicationScheduleRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (medicationIntakeLogsRefs)
                        await $_getPrefetchedData<
                          MedicationPlan,
                          $MedicationPlansTable,
                          MedicationIntakeLog
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationPlansTableReferences
                              ._medicationIntakeLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationPlansTableReferences(
                                db,
                                table,
                                p0,
                              ).medicationIntakeLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MedicationPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationPlansTable,
      MedicationPlan,
      $$MedicationPlansTableFilterComposer,
      $$MedicationPlansTableOrderingComposer,
      $$MedicationPlansTableAnnotationComposer,
      $$MedicationPlansTableCreateCompanionBuilder,
      $$MedicationPlansTableUpdateCompanionBuilder,
      (MedicationPlan, $$MedicationPlansTableReferences),
      MedicationPlan,
      PrefetchHooks Function({
        bool userId,
        bool medicationId,
        bool medicationScheduleRulesRefs,
        bool medicationIntakeLogsRefs,
      })
    >;
typedef $$MedicationScheduleRulesTableCreateCompanionBuilder =
    MedicationScheduleRulesCompanion Function({
      Value<int> id,
      required int planId,
      required String ruleType,
      Value<String?> timesOfDay,
      Value<String?> daysOfWeek,
      Value<int?> intervalHours,
      Value<int?> intervalDays,
      Value<int?> cycleDaysOn,
      Value<int?> cycleDaysOff,
      Value<bool> isActive,
    });
typedef $$MedicationScheduleRulesTableUpdateCompanionBuilder =
    MedicationScheduleRulesCompanion Function({
      Value<int> id,
      Value<int> planId,
      Value<String> ruleType,
      Value<String?> timesOfDay,
      Value<String?> daysOfWeek,
      Value<int?> intervalHours,
      Value<int?> intervalDays,
      Value<int?> cycleDaysOn,
      Value<int?> cycleDaysOff,
      Value<bool> isActive,
    });

final class $$MedicationScheduleRulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MedicationScheduleRulesTable,
          MedicationScheduleRule
        > {
  $$MedicationScheduleRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MedicationPlansTable _planIdTable(_$AppDatabase db) =>
      db.medicationPlans.createAlias(
        $_aliasNameGenerator(
          db.medicationScheduleRules.planId,
          db.medicationPlans.id,
        ),
      );

  $$MedicationPlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$MedicationPlansTableTableManager(
      $_db,
      $_db.medicationPlans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MedicationScheduleRulesTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationScheduleRulesTable> {
  $$MedicationScheduleRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleType => $composableBuilder(
    column: $table.ruleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timesOfDay => $composableBuilder(
    column: $table.timesOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalHours => $composableBuilder(
    column: $table.intervalHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleDaysOn => $composableBuilder(
    column: $table.cycleDaysOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleDaysOff => $composableBuilder(
    column: $table.cycleDaysOff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationPlansTableFilterComposer get planId {
    final $$MedicationPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableFilterComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationScheduleRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationScheduleRulesTable> {
  $$MedicationScheduleRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleType => $composableBuilder(
    column: $table.ruleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timesOfDay => $composableBuilder(
    column: $table.timesOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalHours => $composableBuilder(
    column: $table.intervalHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleDaysOn => $composableBuilder(
    column: $table.cycleDaysOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleDaysOff => $composableBuilder(
    column: $table.cycleDaysOff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationPlansTableOrderingComposer get planId {
    final $$MedicationPlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableOrderingComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationScheduleRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationScheduleRulesTable> {
  $$MedicationScheduleRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ruleType =>
      $composableBuilder(column: $table.ruleType, builder: (column) => column);

  GeneratedColumn<String> get timesOfDay => $composableBuilder(
    column: $table.timesOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalHours => $composableBuilder(
    column: $table.intervalHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cycleDaysOn => $composableBuilder(
    column: $table.cycleDaysOn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cycleDaysOff => $composableBuilder(
    column: $table.cycleDaysOff,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$MedicationPlansTableAnnotationComposer get planId {
    final $$MedicationPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationScheduleRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationScheduleRulesTable,
          MedicationScheduleRule,
          $$MedicationScheduleRulesTableFilterComposer,
          $$MedicationScheduleRulesTableOrderingComposer,
          $$MedicationScheduleRulesTableAnnotationComposer,
          $$MedicationScheduleRulesTableCreateCompanionBuilder,
          $$MedicationScheduleRulesTableUpdateCompanionBuilder,
          (MedicationScheduleRule, $$MedicationScheduleRulesTableReferences),
          MedicationScheduleRule,
          PrefetchHooks Function({bool planId})
        > {
  $$MedicationScheduleRulesTableTableManager(
    _$AppDatabase db,
    $MedicationScheduleRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationScheduleRulesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MedicationScheduleRulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationScheduleRulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<String> ruleType = const Value.absent(),
                Value<String?> timesOfDay = const Value.absent(),
                Value<String?> daysOfWeek = const Value.absent(),
                Value<int?> intervalHours = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<int?> cycleDaysOn = const Value.absent(),
                Value<int?> cycleDaysOff = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => MedicationScheduleRulesCompanion(
                id: id,
                planId: planId,
                ruleType: ruleType,
                timesOfDay: timesOfDay,
                daysOfWeek: daysOfWeek,
                intervalHours: intervalHours,
                intervalDays: intervalDays,
                cycleDaysOn: cycleDaysOn,
                cycleDaysOff: cycleDaysOff,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required String ruleType,
                Value<String?> timesOfDay = const Value.absent(),
                Value<String?> daysOfWeek = const Value.absent(),
                Value<int?> intervalHours = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<int?> cycleDaysOn = const Value.absent(),
                Value<int?> cycleDaysOff = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => MedicationScheduleRulesCompanion.insert(
                id: id,
                planId: planId,
                ruleType: ruleType,
                timesOfDay: timesOfDay,
                daysOfWeek: daysOfWeek,
                intervalHours: intervalHours,
                intervalDays: intervalDays,
                cycleDaysOn: cycleDaysOn,
                cycleDaysOff: cycleDaysOff,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationScheduleRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.planId,
                                referencedTable:
                                    $$MedicationScheduleRulesTableReferences
                                        ._planIdTable(db),
                                referencedColumn:
                                    $$MedicationScheduleRulesTableReferences
                                        ._planIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MedicationScheduleRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationScheduleRulesTable,
      MedicationScheduleRule,
      $$MedicationScheduleRulesTableFilterComposer,
      $$MedicationScheduleRulesTableOrderingComposer,
      $$MedicationScheduleRulesTableAnnotationComposer,
      $$MedicationScheduleRulesTableCreateCompanionBuilder,
      $$MedicationScheduleRulesTableUpdateCompanionBuilder,
      (MedicationScheduleRule, $$MedicationScheduleRulesTableReferences),
      MedicationScheduleRule,
      PrefetchHooks Function({bool planId})
    >;
typedef $$MedicationIntakeLogsTableCreateCompanionBuilder =
    MedicationIntakeLogsCompanion Function({
      Value<int> id,
      required int planId,
      required int medicationId,
      required int userId,
      required DateTime scheduledTime,
      Value<DateTime?> takenTime,
      Value<bool> wasTaken,
      Value<double?> dosageAmount,
    });
typedef $$MedicationIntakeLogsTableUpdateCompanionBuilder =
    MedicationIntakeLogsCompanion Function({
      Value<int> id,
      Value<int> planId,
      Value<int> medicationId,
      Value<int> userId,
      Value<DateTime> scheduledTime,
      Value<DateTime?> takenTime,
      Value<bool> wasTaken,
      Value<double?> dosageAmount,
    });

final class $$MedicationIntakeLogsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MedicationIntakeLogsTable,
          MedicationIntakeLog
        > {
  $$MedicationIntakeLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MedicationPlansTable _planIdTable(_$AppDatabase db) =>
      db.medicationPlans.createAlias(
        $_aliasNameGenerator(
          db.medicationIntakeLogs.planId,
          db.medicationPlans.id,
        ),
      );

  $$MedicationPlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$MedicationPlansTableTableManager(
      $_db,
      $_db.medicationPlans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) =>
      db.medications.createAlias(
        $_aliasNameGenerator(
          db.medicationIntakeLogs.medicationId,
          db.medications.id,
        ),
      );

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<int>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.medicationIntakeLogs.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MedicationIntakeLogsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationIntakeLogsTable> {
  $$MedicationIntakeLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenTime => $composableBuilder(
    column: $table.takenTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasTaken => $composableBuilder(
    column: $table.wasTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dosageAmount => $composableBuilder(
    column: $table.dosageAmount,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationPlansTableFilterComposer get planId {
    final $$MedicationPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableFilterComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationIntakeLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationIntakeLogsTable> {
  $$MedicationIntakeLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenTime => $composableBuilder(
    column: $table.takenTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasTaken => $composableBuilder(
    column: $table.wasTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dosageAmount => $composableBuilder(
    column: $table.dosageAmount,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationPlansTableOrderingComposer get planId {
    final $$MedicationPlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableOrderingComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationIntakeLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationIntakeLogsTable> {
  $$MedicationIntakeLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get takenTime =>
      $composableBuilder(column: $table.takenTime, builder: (column) => column);

  GeneratedColumn<bool> get wasTaken =>
      $composableBuilder(column: $table.wasTaken, builder: (column) => column);

  GeneratedColumn<double> get dosageAmount => $composableBuilder(
    column: $table.dosageAmount,
    builder: (column) => column,
  );

  $$MedicationPlansTableAnnotationComposer get planId {
    final $$MedicationPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.medicationPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.medicationPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationIntakeLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationIntakeLogsTable,
          MedicationIntakeLog,
          $$MedicationIntakeLogsTableFilterComposer,
          $$MedicationIntakeLogsTableOrderingComposer,
          $$MedicationIntakeLogsTableAnnotationComposer,
          $$MedicationIntakeLogsTableCreateCompanionBuilder,
          $$MedicationIntakeLogsTableUpdateCompanionBuilder,
          (MedicationIntakeLog, $$MedicationIntakeLogsTableReferences),
          MedicationIntakeLog,
          PrefetchHooks Function({bool planId, bool medicationId, bool userId})
        > {
  $$MedicationIntakeLogsTableTableManager(
    _$AppDatabase db,
    $MedicationIntakeLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationIntakeLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationIntakeLogsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationIntakeLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<int> medicationId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<DateTime> scheduledTime = const Value.absent(),
                Value<DateTime?> takenTime = const Value.absent(),
                Value<bool> wasTaken = const Value.absent(),
                Value<double?> dosageAmount = const Value.absent(),
              }) => MedicationIntakeLogsCompanion(
                id: id,
                planId: planId,
                medicationId: medicationId,
                userId: userId,
                scheduledTime: scheduledTime,
                takenTime: takenTime,
                wasTaken: wasTaken,
                dosageAmount: dosageAmount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required int medicationId,
                required int userId,
                required DateTime scheduledTime,
                Value<DateTime?> takenTime = const Value.absent(),
                Value<bool> wasTaken = const Value.absent(),
                Value<double?> dosageAmount = const Value.absent(),
              }) => MedicationIntakeLogsCompanion.insert(
                id: id,
                planId: planId,
                medicationId: medicationId,
                userId: userId,
                scheduledTime: scheduledTime,
                takenTime: takenTime,
                wasTaken: wasTaken,
                dosageAmount: dosageAmount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationIntakeLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({planId = false, medicationId = false, userId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (planId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.planId,
                                    referencedTable:
                                        $$MedicationIntakeLogsTableReferences
                                            ._planIdTable(db),
                                    referencedColumn:
                                        $$MedicationIntakeLogsTableReferences
                                            ._planIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (medicationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.medicationId,
                                    referencedTable:
                                        $$MedicationIntakeLogsTableReferences
                                            ._medicationIdTable(db),
                                    referencedColumn:
                                        $$MedicationIntakeLogsTableReferences
                                            ._medicationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable:
                                        $$MedicationIntakeLogsTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$MedicationIntakeLogsTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$MedicationIntakeLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationIntakeLogsTable,
      MedicationIntakeLog,
      $$MedicationIntakeLogsTableFilterComposer,
      $$MedicationIntakeLogsTableOrderingComposer,
      $$MedicationIntakeLogsTableAnnotationComposer,
      $$MedicationIntakeLogsTableCreateCompanionBuilder,
      $$MedicationIntakeLogsTableUpdateCompanionBuilder,
      (MedicationIntakeLog, $$MedicationIntakeLogsTableReferences),
      MedicationIntakeLog,
      PrefetchHooks Function({bool planId, bool medicationId, bool userId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<int?> defaultUserId,
      Value<double> alarmVolume,
      Value<String> alarmSound,
      Value<bool> alarmVibration,
      Value<bool> showKillWarning,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<int?> defaultUserId,
      Value<double> alarmVolume,
      Value<String> alarmSound,
      Value<bool> alarmVibration,
      Value<bool> showKillWarning,
    });

final class $$AppSettingsTableReferences
    extends BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting> {
  $$AppSettingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _defaultUserIdTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.appSettings.defaultUserId, db.users.id),
      );

  $$UsersTableProcessedTableManager? get defaultUserId {
    final $_column = $_itemColumn<int>('default_user_id');
    if ($_column == null) return null;
    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_defaultUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alarmVolume => $composableBuilder(
    column: $table.alarmVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmSound => $composableBuilder(
    column: $table.alarmSound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alarmVibration => $composableBuilder(
    column: $table.alarmVibration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showKillWarning => $composableBuilder(
    column: $table.showKillWarning,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get defaultUserId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alarmVolume => $composableBuilder(
    column: $table.alarmVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmSound => $composableBuilder(
    column: $table.alarmSound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alarmVibration => $composableBuilder(
    column: $table.alarmVibration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showKillWarning => $composableBuilder(
    column: $table.showKillWarning,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get defaultUserId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<double> get alarmVolume => $composableBuilder(
    column: $table.alarmVolume,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alarmSound => $composableBuilder(
    column: $table.alarmSound,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get alarmVibration => $composableBuilder(
    column: $table.alarmVibration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showKillWarning => $composableBuilder(
    column: $table.showKillWarning,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get defaultUserId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (AppSetting, $$AppSettingsTableReferences),
          AppSetting,
          PrefetchHooks Function({bool defaultUserId})
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<int?> defaultUserId = const Value.absent(),
                Value<double> alarmVolume = const Value.absent(),
                Value<String> alarmSound = const Value.absent(),
                Value<bool> alarmVibration = const Value.absent(),
                Value<bool> showKillWarning = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                themeMode: themeMode,
                defaultUserId: defaultUserId,
                alarmVolume: alarmVolume,
                alarmSound: alarmSound,
                alarmVibration: alarmVibration,
                showKillWarning: showKillWarning,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<int?> defaultUserId = const Value.absent(),
                Value<double> alarmVolume = const Value.absent(),
                Value<String> alarmSound = const Value.absent(),
                Value<bool> alarmVibration = const Value.absent(),
                Value<bool> showKillWarning = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                themeMode: themeMode,
                defaultUserId: defaultUserId,
                alarmVolume: alarmVolume,
                alarmSound: alarmSound,
                alarmVibration: alarmVibration,
                showKillWarning: showKillWarning,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AppSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({defaultUserId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (defaultUserId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.defaultUserId,
                                referencedTable: $$AppSettingsTableReferences
                                    ._defaultUserIdTable(db),
                                referencedColumn: $$AppSettingsTableReferences
                                    ._defaultUserIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (AppSetting, $$AppSettingsTableReferences),
      AppSetting,
      PrefetchHooks Function({bool defaultUserId})
    >;
typedef $$OnboardingSettingsTableCreateCompanionBuilder =
    OnboardingSettingsCompanion Function({
      Value<int> id,
      Value<bool> isCompleted,
      Value<UserType?> userType,
      Value<String?> familyName,
      Value<DateTime?> completedAt,
    });
typedef $$OnboardingSettingsTableUpdateCompanionBuilder =
    OnboardingSettingsCompanion Function({
      Value<int> id,
      Value<bool> isCompleted,
      Value<UserType?> userType,
      Value<String?> familyName,
      Value<DateTime?> completedAt,
    });

class $$OnboardingSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $OnboardingSettingsTable> {
  $$OnboardingSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<UserType?, UserType, int> get userType =>
      $composableBuilder(
        column: $table.userType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get familyName => $composableBuilder(
    column: $table.familyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OnboardingSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $OnboardingSettingsTable> {
  $$OnboardingSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userType => $composableBuilder(
    column: $table.userType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get familyName => $composableBuilder(
    column: $table.familyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OnboardingSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OnboardingSettingsTable> {
  $$OnboardingSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<UserType?, int> get userType =>
      $composableBuilder(column: $table.userType, builder: (column) => column);

  GeneratedColumn<String> get familyName => $composableBuilder(
    column: $table.familyName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$OnboardingSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OnboardingSettingsTable,
          OnboardingSetting,
          $$OnboardingSettingsTableFilterComposer,
          $$OnboardingSettingsTableOrderingComposer,
          $$OnboardingSettingsTableAnnotationComposer,
          $$OnboardingSettingsTableCreateCompanionBuilder,
          $$OnboardingSettingsTableUpdateCompanionBuilder,
          (
            OnboardingSetting,
            BaseReferences<
              _$AppDatabase,
              $OnboardingSettingsTable,
              OnboardingSetting
            >,
          ),
          OnboardingSetting,
          PrefetchHooks Function()
        > {
  $$OnboardingSettingsTableTableManager(
    _$AppDatabase db,
    $OnboardingSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OnboardingSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OnboardingSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OnboardingSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<UserType?> userType = const Value.absent(),
                Value<String?> familyName = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => OnboardingSettingsCompanion(
                id: id,
                isCompleted: isCompleted,
                userType: userType,
                familyName: familyName,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<UserType?> userType = const Value.absent(),
                Value<String?> familyName = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => OnboardingSettingsCompanion.insert(
                id: id,
                isCompleted: isCompleted,
                userType: userType,
                familyName: familyName,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OnboardingSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OnboardingSettingsTable,
      OnboardingSetting,
      $$OnboardingSettingsTableFilterComposer,
      $$OnboardingSettingsTableOrderingComposer,
      $$OnboardingSettingsTableAnnotationComposer,
      $$OnboardingSettingsTableCreateCompanionBuilder,
      $$OnboardingSettingsTableUpdateCompanionBuilder,
      (
        OnboardingSetting,
        BaseReferences<
          _$AppDatabase,
          $OnboardingSettingsTable,
          OnboardingSetting
        >,
      ),
      OnboardingSetting,
      PrefetchHooks Function()
    >;
typedef $$MoodEntriesTableCreateCompanionBuilder =
    MoodEntriesCompanion Function({
      Value<int> id,
      required int userId,
      required int moodLevel,
      Value<String?> note,
      Value<DateTime> createdAt,
    });
typedef $$MoodEntriesTableUpdateCompanionBuilder =
    MoodEntriesCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> moodLevel,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

final class $$MoodEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $MoodEntriesTable, MoodEntry> {
  $$MoodEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.moodEntries.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MoodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get moodLevel => $composableBuilder(
    column: $table.moodLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moodLevel => $composableBuilder(
    column: $table.moodLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get moodLevel =>
      $composableBuilder(column: $table.moodLevel, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoodEntriesTable,
          MoodEntry,
          $$MoodEntriesTableFilterComposer,
          $$MoodEntriesTableOrderingComposer,
          $$MoodEntriesTableAnnotationComposer,
          $$MoodEntriesTableCreateCompanionBuilder,
          $$MoodEntriesTableUpdateCompanionBuilder,
          (MoodEntry, $$MoodEntriesTableReferences),
          MoodEntry,
          PrefetchHooks Function({bool userId})
        > {
  $$MoodEntriesTableTableManager(_$AppDatabase db, $MoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> moodLevel = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MoodEntriesCompanion(
                id: id,
                userId: userId,
                moodLevel: moodLevel,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int moodLevel,
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MoodEntriesCompanion.insert(
                id: id,
                userId: userId,
                moodLevel: moodLevel,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MoodEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$MoodEntriesTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$MoodEntriesTableReferences
                                    ._userIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoodEntriesTable,
      MoodEntry,
      $$MoodEntriesTableFilterComposer,
      $$MoodEntriesTableOrderingComposer,
      $$MoodEntriesTableAnnotationComposer,
      $$MoodEntriesTableCreateCompanionBuilder,
      $$MoodEntriesTableUpdateCompanionBuilder,
      (MoodEntry, $$MoodEntriesTableReferences),
      MoodEntry,
      PrefetchHooks Function({bool userId})
    >;
typedef $$PeriodEntriesTableCreateCompanionBuilder =
    PeriodEntriesCompanion Function({
      Value<int> id,
      required int userId,
      required String entryType,
      Value<int?> flowIntensity,
      Value<String?> note,
      required DateTime date,
      Value<DateTime> createdAt,
    });
typedef $$PeriodEntriesTableUpdateCompanionBuilder =
    PeriodEntriesCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> entryType,
      Value<int?> flowIntensity,
      Value<String?> note,
      Value<DateTime> date,
      Value<DateTime> createdAt,
    });

final class $$PeriodEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $PeriodEntriesTable, PeriodEntry> {
  $$PeriodEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.periodEntries.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PeriodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodEntriesTable> {
  $$PeriodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flowIntensity => $composableBuilder(
    column: $table.flowIntensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodEntriesTable> {
  $$PeriodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flowIntensity => $composableBuilder(
    column: $table.flowIntensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodEntriesTable> {
  $$PeriodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<int> get flowIntensity => $composableBuilder(
    column: $table.flowIntensity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeriodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeriodEntriesTable,
          PeriodEntry,
          $$PeriodEntriesTableFilterComposer,
          $$PeriodEntriesTableOrderingComposer,
          $$PeriodEntriesTableAnnotationComposer,
          $$PeriodEntriesTableCreateCompanionBuilder,
          $$PeriodEntriesTableUpdateCompanionBuilder,
          (PeriodEntry, $$PeriodEntriesTableReferences),
          PeriodEntry,
          PrefetchHooks Function({bool userId})
        > {
  $$PeriodEntriesTableTableManager(_$AppDatabase db, $PeriodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> entryType = const Value.absent(),
                Value<int?> flowIntensity = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PeriodEntriesCompanion(
                id: id,
                userId: userId,
                entryType: entryType,
                flowIntensity: flowIntensity,
                note: note,
                date: date,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String entryType,
                Value<int?> flowIntensity = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime date,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PeriodEntriesCompanion.insert(
                id: id,
                userId: userId,
                entryType: entryType,
                flowIntensity: flowIntensity,
                note: note,
                date: date,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PeriodEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$PeriodEntriesTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$PeriodEntriesTableReferences
                                    ._userIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PeriodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeriodEntriesTable,
      PeriodEntry,
      $$PeriodEntriesTableFilterComposer,
      $$PeriodEntriesTableOrderingComposer,
      $$PeriodEntriesTableAnnotationComposer,
      $$PeriodEntriesTableCreateCompanionBuilder,
      $$PeriodEntriesTableUpdateCompanionBuilder,
      (PeriodEntry, $$PeriodEntriesTableReferences),
      PeriodEntry,
      PrefetchHooks Function({bool userId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$MedicationPlansTableTableManager get medicationPlans =>
      $$MedicationPlansTableTableManager(_db, _db.medicationPlans);
  $$MedicationScheduleRulesTableTableManager get medicationScheduleRules =>
      $$MedicationScheduleRulesTableTableManager(
        _db,
        _db.medicationScheduleRules,
      );
  $$MedicationIntakeLogsTableTableManager get medicationIntakeLogs =>
      $$MedicationIntakeLogsTableTableManager(_db, _db.medicationIntakeLogs);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$OnboardingSettingsTableTableManager get onboardingSettings =>
      $$OnboardingSettingsTableTableManager(_db, _db.onboardingSettings);
  $$MoodEntriesTableTableManager get moodEntries =>
      $$MoodEntriesTableTableManager(_db, _db.moodEntries);
  $$PeriodEntriesTableTableManager get periodEntries =>
      $$PeriodEntriesTableTableManager(_db, _db.periodEntries);
}

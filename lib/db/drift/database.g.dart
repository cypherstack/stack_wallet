// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SparkNamesTable extends SparkNames
    with TableInfo<$SparkNamesTable, SparkName> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SparkNamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'UNIQUE NOT NULL COLLATE NOCASE');
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _validUntilMeta =
      const VerificationMeta('validUntil');
  @override
  late final GeneratedColumn<int> validUntil = GeneratedColumn<int>(
      'valid_until', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _additionalInfoMeta =
      const VerificationMeta('additionalInfo');
  @override
  late final GeneratedColumn<String> additionalInfo = GeneratedColumn<String>(
      'additional_info', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [name, address, validUntil, additionalInfo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spark_names';
  @override
  VerificationContext validateIntegrity(Insertable<SparkName> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('valid_until')) {
      context.handle(
          _validUntilMeta,
          validUntil.isAcceptableOrUnknown(
              data['valid_until']!, _validUntilMeta));
    } else if (isInserting) {
      context.missing(_validUntilMeta);
    }
    if (data.containsKey('additional_info')) {
      context.handle(
          _additionalInfoMeta,
          additionalInfo.isAcceptableOrUnknown(
              data['additional_info']!, _additionalInfoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  SparkName map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SparkName(
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      validUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}valid_until'])!,
      additionalInfo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}additional_info']),
    );
  }

  @override
  $SparkNamesTable createAlias(String alias) {
    return $SparkNamesTable(attachedDatabase, alias);
  }
}

class SparkName extends DataClass implements Insertable<SparkName> {
  final String name;
  final String address;
  final int validUntil;
  final String? additionalInfo;
  const SparkName(
      {required this.name,
      required this.address,
      required this.validUntil,
      this.additionalInfo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['valid_until'] = Variable<int>(validUntil);
    if (!nullToAbsent || additionalInfo != null) {
      map['additional_info'] = Variable<String>(additionalInfo);
    }
    return map;
  }

  SparkNamesCompanion toCompanion(bool nullToAbsent) {
    return SparkNamesCompanion(
      name: Value(name),
      address: Value(address),
      validUntil: Value(validUntil),
      additionalInfo: additionalInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(additionalInfo),
    );
  }

  factory SparkName.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SparkName(
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      validUntil: serializer.fromJson<int>(json['validUntil']),
      additionalInfo: serializer.fromJson<String?>(json['additionalInfo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'validUntil': serializer.toJson<int>(validUntil),
      'additionalInfo': serializer.toJson<String?>(additionalInfo),
    };
  }

  SparkName copyWith(
          {String? name,
          String? address,
          int? validUntil,
          Value<String?> additionalInfo = const Value.absent()}) =>
      SparkName(
        name: name ?? this.name,
        address: address ?? this.address,
        validUntil: validUntil ?? this.validUntil,
        additionalInfo:
            additionalInfo.present ? additionalInfo.value : this.additionalInfo,
      );
  SparkName copyWithCompanion(SparkNamesCompanion data) {
    return SparkName(
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      validUntil:
          data.validUntil.present ? data.validUntil.value : this.validUntil,
      additionalInfo: data.additionalInfo.present
          ? data.additionalInfo.value
          : this.additionalInfo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SparkName(')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('validUntil: $validUntil, ')
          ..write('additionalInfo: $additionalInfo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, address, validUntil, additionalInfo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SparkName &&
          other.name == this.name &&
          other.address == this.address &&
          other.validUntil == this.validUntil &&
          other.additionalInfo == this.additionalInfo);
}

class SparkNamesCompanion extends UpdateCompanion<SparkName> {
  final Value<String> name;
  final Value<String> address;
  final Value<int> validUntil;
  final Value<String?> additionalInfo;
  final Value<int> rowid;
  const SparkNamesCompanion({
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.additionalInfo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SparkNamesCompanion.insert({
    required String name,
    required String address,
    required int validUntil,
    this.additionalInfo = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : name = Value(name),
        address = Value(address),
        validUntil = Value(validUntil);
  static Insertable<SparkName> custom({
    Expression<String>? name,
    Expression<String>? address,
    Expression<int>? validUntil,
    Expression<String>? additionalInfo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (validUntil != null) 'valid_until': validUntil,
      if (additionalInfo != null) 'additional_info': additionalInfo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SparkNamesCompanion copyWith(
      {Value<String>? name,
      Value<String>? address,
      Value<int>? validUntil,
      Value<String?>? additionalInfo,
      Value<int>? rowid}) {
    return SparkNamesCompanion(
      name: name ?? this.name,
      address: address ?? this.address,
      validUntil: validUntil ?? this.validUntil,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<int>(validUntil.value);
    }
    if (additionalInfo.present) {
      map['additional_info'] = Variable<String>(additionalInfo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SparkNamesCompanion(')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('validUntil: $validUntil, ')
          ..write('additionalInfo: $additionalInfo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WalletDatabase extends GeneratedDatabase {
  _$WalletDatabase(QueryExecutor e) : super(e);
  $WalletDatabaseManager get managers => $WalletDatabaseManager(this);
  late final $SparkNamesTable sparkNames = $SparkNamesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sparkNames];
}

typedef $$SparkNamesTableCreateCompanionBuilder = SparkNamesCompanion Function({
  required String name,
  required String address,
  required int validUntil,
  Value<String?> additionalInfo,
  Value<int> rowid,
});
typedef $$SparkNamesTableUpdateCompanionBuilder = SparkNamesCompanion Function({
  Value<String> name,
  Value<String> address,
  Value<int> validUntil,
  Value<String?> additionalInfo,
  Value<int> rowid,
});

class $$SparkNamesTableFilterComposer
    extends Composer<_$WalletDatabase, $SparkNamesTable> {
  $$SparkNamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get validUntil => $composableBuilder(
      column: $table.validUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get additionalInfo => $composableBuilder(
      column: $table.additionalInfo,
      builder: (column) => ColumnFilters(column));
}

class $$SparkNamesTableOrderingComposer
    extends Composer<_$WalletDatabase, $SparkNamesTable> {
  $$SparkNamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get validUntil => $composableBuilder(
      column: $table.validUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get additionalInfo => $composableBuilder(
      column: $table.additionalInfo,
      builder: (column) => ColumnOrderings(column));
}

class $$SparkNamesTableAnnotationComposer
    extends Composer<_$WalletDatabase, $SparkNamesTable> {
  $$SparkNamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get validUntil => $composableBuilder(
      column: $table.validUntil, builder: (column) => column);

  GeneratedColumn<String> get additionalInfo => $composableBuilder(
      column: $table.additionalInfo, builder: (column) => column);
}

class $$SparkNamesTableTableManager extends RootTableManager<
    _$WalletDatabase,
    $SparkNamesTable,
    SparkName,
    $$SparkNamesTableFilterComposer,
    $$SparkNamesTableOrderingComposer,
    $$SparkNamesTableAnnotationComposer,
    $$SparkNamesTableCreateCompanionBuilder,
    $$SparkNamesTableUpdateCompanionBuilder,
    (SparkName, BaseReferences<_$WalletDatabase, $SparkNamesTable, SparkName>),
    SparkName,
    PrefetchHooks Function()> {
  $$SparkNamesTableTableManager(_$WalletDatabase db, $SparkNamesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SparkNamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SparkNamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SparkNamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<int> validUntil = const Value.absent(),
            Value<String?> additionalInfo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SparkNamesCompanion(
            name: name,
            address: address,
            validUntil: validUntil,
            additionalInfo: additionalInfo,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String name,
            required String address,
            required int validUntil,
            Value<String?> additionalInfo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SparkNamesCompanion.insert(
            name: name,
            address: address,
            validUntil: validUntil,
            additionalInfo: additionalInfo,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SparkNamesTableProcessedTableManager = ProcessedTableManager<
    _$WalletDatabase,
    $SparkNamesTable,
    SparkName,
    $$SparkNamesTableFilterComposer,
    $$SparkNamesTableOrderingComposer,
    $$SparkNamesTableAnnotationComposer,
    $$SparkNamesTableCreateCompanionBuilder,
    $$SparkNamesTableUpdateCompanionBuilder,
    (SparkName, BaseReferences<_$WalletDatabase, $SparkNamesTable, SparkName>),
    SparkName,
    PrefetchHooks Function()>;

class $WalletDatabaseManager {
  final _$WalletDatabase _db;
  $WalletDatabaseManager(this._db);
  $$SparkNamesTableTableManager get sparkNames =>
      $$SparkNamesTableTableManager(_db, _db.sparkNames);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_database.dart';

// ignore_for_file: type=lint
mixin _$ShopinBitSettingsDaoMixin on DatabaseAccessor<SharedDatabase> {
  $ShopinBitSettingsTable get shopinBitSettings =>
      attachedDatabase.shopinBitSettings;
  ShopinBitSettingsDaoManager get managers => ShopinBitSettingsDaoManager(this);
}

class ShopinBitSettingsDaoManager {
  final _$ShopinBitSettingsDaoMixin _db;
  ShopinBitSettingsDaoManager(this._db);
  $$ShopinBitSettingsTableTableManager get shopinBitSettings =>
      $$ShopinBitSettingsTableTableManager(
        _db.attachedDatabase,
        _db.shopinBitSettings,
      );
}

class $CakepayOrdersTable extends CakepayOrders
    with TableInfo<$CakepayOrdersTable, CakepayOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CakepayOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [orderId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cakepay_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CakepayOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {orderId};
  @override
  CakepayOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CakepayOrder(
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
    );
  }

  @override
  $CakepayOrdersTable createAlias(String alias) {
    return $CakepayOrdersTable(attachedDatabase, alias);
  }
}

class CakepayOrder extends DataClass implements Insertable<CakepayOrder> {
  final String orderId;
  const CakepayOrder({required this.orderId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['order_id'] = Variable<String>(orderId);
    return map;
  }

  CakepayOrdersCompanion toCompanion(bool nullToAbsent) {
    return CakepayOrdersCompanion(orderId: Value(orderId));
  }

  factory CakepayOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CakepayOrder(orderId: serializer.fromJson<String>(json['orderId']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'orderId': serializer.toJson<String>(orderId)};
  }

  CakepayOrder copyWith({String? orderId}) =>
      CakepayOrder(orderId: orderId ?? this.orderId);
  CakepayOrder copyWithCompanion(CakepayOrdersCompanion data) {
    return CakepayOrder(
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CakepayOrder(')
          ..write('orderId: $orderId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => orderId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CakepayOrder && other.orderId == this.orderId);
}

class CakepayOrdersCompanion extends UpdateCompanion<CakepayOrder> {
  final Value<String> orderId;
  final Value<int> rowid;
  const CakepayOrdersCompanion({
    this.orderId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CakepayOrdersCompanion.insert({
    required String orderId,
    this.rowid = const Value.absent(),
  }) : orderId = Value(orderId);
  static Insertable<CakepayOrder> custom({
    Expression<String>? orderId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (orderId != null) 'order_id': orderId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CakepayOrdersCompanion copyWith({Value<String>? orderId, Value<int>? rowid}) {
    return CakepayOrdersCompanion(
      orderId: orderId ?? this.orderId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CakepayOrdersCompanion(')
          ..write('orderId: $orderId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShopinBitSettingsTable extends ShopinBitSettings
    with TableInfo<$ShopinBitSettingsTable, ShopinBitSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopinBitSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _guidelinesAcceptedMeta =
      const VerificationMeta('guidelinesAccepted');
  @override
  late final GeneratedColumn<bool> guidelinesAccepted = GeneratedColumn<bool>(
    'guidelines_accepted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("guidelines_accepted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _setupCompleteMeta = const VerificationMeta(
    'setupComplete',
  );
  @override
  late final GeneratedColumn<bool> setupComplete = GeneratedColumn<bool>(
    'setup_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("setup_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    guidelinesAccepted,
    setupComplete,
    displayName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopin_bit_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShopinBitSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('guidelines_accepted')) {
      context.handle(
        _guidelinesAcceptedMeta,
        guidelinesAccepted.isAcceptableOrUnknown(
          data['guidelines_accepted']!,
          _guidelinesAcceptedMeta,
        ),
      );
    }
    if (data.containsKey('setup_complete')) {
      context.handle(
        _setupCompleteMeta,
        setupComplete.isAcceptableOrUnknown(
          data['setup_complete']!,
          _setupCompleteMeta,
        ),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShopinBitSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShopinBitSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      guidelinesAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}guidelines_accepted'],
      )!,
      setupComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}setup_complete'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
    );
  }

  @override
  $ShopinBitSettingsTable createAlias(String alias) {
    return $ShopinBitSettingsTable(attachedDatabase, alias);
  }
}

class ShopinBitSetting extends DataClass
    implements Insertable<ShopinBitSetting> {
  final int id;
  final bool guidelinesAccepted;
  final bool setupComplete;
  final String? displayName;
  const ShopinBitSetting({
    required this.id,
    required this.guidelinesAccepted,
    required this.setupComplete,
    this.displayName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['guidelines_accepted'] = Variable<bool>(guidelinesAccepted);
    map['setup_complete'] = Variable<bool>(setupComplete);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    return map;
  }

  ShopinBitSettingsCompanion toCompanion(bool nullToAbsent) {
    return ShopinBitSettingsCompanion(
      id: Value(id),
      guidelinesAccepted: Value(guidelinesAccepted),
      setupComplete: Value(setupComplete),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
    );
  }

  factory ShopinBitSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShopinBitSetting(
      id: serializer.fromJson<int>(json['id']),
      guidelinesAccepted: serializer.fromJson<bool>(json['guidelinesAccepted']),
      setupComplete: serializer.fromJson<bool>(json['setupComplete']),
      displayName: serializer.fromJson<String?>(json['displayName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'guidelinesAccepted': serializer.toJson<bool>(guidelinesAccepted),
      'setupComplete': serializer.toJson<bool>(setupComplete),
      'displayName': serializer.toJson<String?>(displayName),
    };
  }

  ShopinBitSetting copyWith({
    int? id,
    bool? guidelinesAccepted,
    bool? setupComplete,
    Value<String?> displayName = const Value.absent(),
  }) => ShopinBitSetting(
    id: id ?? this.id,
    guidelinesAccepted: guidelinesAccepted ?? this.guidelinesAccepted,
    setupComplete: setupComplete ?? this.setupComplete,
    displayName: displayName.present ? displayName.value : this.displayName,
  );
  ShopinBitSetting copyWithCompanion(ShopinBitSettingsCompanion data) {
    return ShopinBitSetting(
      id: data.id.present ? data.id.value : this.id,
      guidelinesAccepted: data.guidelinesAccepted.present
          ? data.guidelinesAccepted.value
          : this.guidelinesAccepted,
      setupComplete: data.setupComplete.present
          ? data.setupComplete.value
          : this.setupComplete,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShopinBitSetting(')
          ..write('id: $id, ')
          ..write('guidelinesAccepted: $guidelinesAccepted, ')
          ..write('setupComplete: $setupComplete, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, guidelinesAccepted, setupComplete, displayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShopinBitSetting &&
          other.id == this.id &&
          other.guidelinesAccepted == this.guidelinesAccepted &&
          other.setupComplete == this.setupComplete &&
          other.displayName == this.displayName);
}

class ShopinBitSettingsCompanion extends UpdateCompanion<ShopinBitSetting> {
  final Value<int> id;
  final Value<bool> guidelinesAccepted;
  final Value<bool> setupComplete;
  final Value<String?> displayName;
  const ShopinBitSettingsCompanion({
    this.id = const Value.absent(),
    this.guidelinesAccepted = const Value.absent(),
    this.setupComplete = const Value.absent(),
    this.displayName = const Value.absent(),
  });
  ShopinBitSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.guidelinesAccepted = const Value.absent(),
    this.setupComplete = const Value.absent(),
    this.displayName = const Value.absent(),
  });
  static Insertable<ShopinBitSetting> custom({
    Expression<int>? id,
    Expression<bool>? guidelinesAccepted,
    Expression<bool>? setupComplete,
    Expression<String>? displayName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (guidelinesAccepted != null) 'guidelines_accepted': guidelinesAccepted,
      if (setupComplete != null) 'setup_complete': setupComplete,
      if (displayName != null) 'display_name': displayName,
    });
  }

  ShopinBitSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? guidelinesAccepted,
    Value<bool>? setupComplete,
    Value<String?>? displayName,
  }) {
    return ShopinBitSettingsCompanion(
      id: id ?? this.id,
      guidelinesAccepted: guidelinesAccepted ?? this.guidelinesAccepted,
      setupComplete: setupComplete ?? this.setupComplete,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (guidelinesAccepted.present) {
      map['guidelines_accepted'] = Variable<bool>(guidelinesAccepted.value);
    }
    if (setupComplete.present) {
      map['setup_complete'] = Variable<bool>(setupComplete.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopinBitSettingsCompanion(')
          ..write('id: $id, ')
          ..write('guidelinesAccepted: $guidelinesAccepted, ')
          ..write('setupComplete: $setupComplete, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }
}

abstract class _$SharedDatabase extends GeneratedDatabase {
  _$SharedDatabase(QueryExecutor e) : super(e);
  $SharedDatabaseManager get managers => $SharedDatabaseManager(this);
  late final $CakepayOrdersTable cakepayOrders = $CakepayOrdersTable(this);
  late final $ShopinBitSettingsTable shopinBitSettings =
      $ShopinBitSettingsTable(this);
  late final ShopinBitSettingsDao shopinBitSettingsDao = ShopinBitSettingsDao(
    this as SharedDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cakepayOrders,
    shopinBitSettings,
  ];
}

typedef $$CakepayOrdersTableCreateCompanionBuilder =
    CakepayOrdersCompanion Function({
      required String orderId,
      Value<int> rowid,
    });
typedef $$CakepayOrdersTableUpdateCompanionBuilder =
    CakepayOrdersCompanion Function({Value<String> orderId, Value<int> rowid});

class $$CakepayOrdersTableFilterComposer
    extends Composer<_$SharedDatabase, $CakepayOrdersTable> {
  $$CakepayOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CakepayOrdersTableOrderingComposer
    extends Composer<_$SharedDatabase, $CakepayOrdersTable> {
  $$CakepayOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CakepayOrdersTableAnnotationComposer
    extends Composer<_$SharedDatabase, $CakepayOrdersTable> {
  $$CakepayOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);
}

class $$CakepayOrdersTableTableManager
    extends
        RootTableManager<
          _$SharedDatabase,
          $CakepayOrdersTable,
          CakepayOrder,
          $$CakepayOrdersTableFilterComposer,
          $$CakepayOrdersTableOrderingComposer,
          $$CakepayOrdersTableAnnotationComposer,
          $$CakepayOrdersTableCreateCompanionBuilder,
          $$CakepayOrdersTableUpdateCompanionBuilder,
          (
            CakepayOrder,
            BaseReferences<_$SharedDatabase, $CakepayOrdersTable, CakepayOrder>,
          ),
          CakepayOrder,
          PrefetchHooks Function()
        > {
  $$CakepayOrdersTableTableManager(
    _$SharedDatabase db,
    $CakepayOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CakepayOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CakepayOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CakepayOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> orderId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CakepayOrdersCompanion(orderId: orderId, rowid: rowid),
          createCompanionCallback:
              ({
                required String orderId,
                Value<int> rowid = const Value.absent(),
              }) =>
                  CakepayOrdersCompanion.insert(orderId: orderId, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CakepayOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$SharedDatabase,
      $CakepayOrdersTable,
      CakepayOrder,
      $$CakepayOrdersTableFilterComposer,
      $$CakepayOrdersTableOrderingComposer,
      $$CakepayOrdersTableAnnotationComposer,
      $$CakepayOrdersTableCreateCompanionBuilder,
      $$CakepayOrdersTableUpdateCompanionBuilder,
      (
        CakepayOrder,
        BaseReferences<_$SharedDatabase, $CakepayOrdersTable, CakepayOrder>,
      ),
      CakepayOrder,
      PrefetchHooks Function()
    >;
typedef $$ShopinBitSettingsTableCreateCompanionBuilder =
    ShopinBitSettingsCompanion Function({
      Value<int> id,
      Value<bool> guidelinesAccepted,
      Value<bool> setupComplete,
      Value<String?> displayName,
    });
typedef $$ShopinBitSettingsTableUpdateCompanionBuilder =
    ShopinBitSettingsCompanion Function({
      Value<int> id,
      Value<bool> guidelinesAccepted,
      Value<bool> setupComplete,
      Value<String?> displayName,
    });

class $$ShopinBitSettingsTableFilterComposer
    extends Composer<_$SharedDatabase, $ShopinBitSettingsTable> {
  $$ShopinBitSettingsTableFilterComposer({
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

  ColumnFilters<bool> get guidelinesAccepted => $composableBuilder(
    column: $table.guidelinesAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get setupComplete => $composableBuilder(
    column: $table.setupComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShopinBitSettingsTableOrderingComposer
    extends Composer<_$SharedDatabase, $ShopinBitSettingsTable> {
  $$ShopinBitSettingsTableOrderingComposer({
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

  ColumnOrderings<bool> get guidelinesAccepted => $composableBuilder(
    column: $table.guidelinesAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get setupComplete => $composableBuilder(
    column: $table.setupComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShopinBitSettingsTableAnnotationComposer
    extends Composer<_$SharedDatabase, $ShopinBitSettingsTable> {
  $$ShopinBitSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get guidelinesAccepted => $composableBuilder(
    column: $table.guidelinesAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get setupComplete => $composableBuilder(
    column: $table.setupComplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );
}

class $$ShopinBitSettingsTableTableManager
    extends
        RootTableManager<
          _$SharedDatabase,
          $ShopinBitSettingsTable,
          ShopinBitSetting,
          $$ShopinBitSettingsTableFilterComposer,
          $$ShopinBitSettingsTableOrderingComposer,
          $$ShopinBitSettingsTableAnnotationComposer,
          $$ShopinBitSettingsTableCreateCompanionBuilder,
          $$ShopinBitSettingsTableUpdateCompanionBuilder,
          (
            ShopinBitSetting,
            BaseReferences<
              _$SharedDatabase,
              $ShopinBitSettingsTable,
              ShopinBitSetting
            >,
          ),
          ShopinBitSetting,
          PrefetchHooks Function()
        > {
  $$ShopinBitSettingsTableTableManager(
    _$SharedDatabase db,
    $ShopinBitSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShopinBitSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShopinBitSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShopinBitSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> guidelinesAccepted = const Value.absent(),
                Value<bool> setupComplete = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
              }) => ShopinBitSettingsCompanion(
                id: id,
                guidelinesAccepted: guidelinesAccepted,
                setupComplete: setupComplete,
                displayName: displayName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> guidelinesAccepted = const Value.absent(),
                Value<bool> setupComplete = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
              }) => ShopinBitSettingsCompanion.insert(
                id: id,
                guidelinesAccepted: guidelinesAccepted,
                setupComplete: setupComplete,
                displayName: displayName,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShopinBitSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$SharedDatabase,
      $ShopinBitSettingsTable,
      ShopinBitSetting,
      $$ShopinBitSettingsTableFilterComposer,
      $$ShopinBitSettingsTableOrderingComposer,
      $$ShopinBitSettingsTableAnnotationComposer,
      $$ShopinBitSettingsTableCreateCompanionBuilder,
      $$ShopinBitSettingsTableUpdateCompanionBuilder,
      (
        ShopinBitSetting,
        BaseReferences<
          _$SharedDatabase,
          $ShopinBitSettingsTable,
          ShopinBitSetting
        >,
      ),
      ShopinBitSetting,
      PrefetchHooks Function()
    >;

class $SharedDatabaseManager {
  final _$SharedDatabase _db;
  $SharedDatabaseManager(this._db);
  $$CakepayOrdersTableTableManager get cakepayOrders =>
      $$CakepayOrdersTableTableManager(_db, _db.cakepayOrders);
  $$ShopinBitSettingsTableTableManager get shopinBitSettings =>
      $$ShopinBitSettingsTableTableManager(_db, _db.shopinBitSettings);
}

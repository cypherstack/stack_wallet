// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_database.dart';

// ignore_for_file: type=lint
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

abstract class _$SharedDatabase extends GeneratedDatabase {
  _$SharedDatabase(QueryExecutor e) : super(e);
  $SharedDatabaseManager get managers => $SharedDatabaseManager(this);
  late final $CakepayOrdersTable cakepayOrders = $CakepayOrdersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cakepayOrders];
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

class $SharedDatabaseManager {
  final _$SharedDatabase _db;
  $SharedDatabaseManager(this._db);
  $$CakepayOrdersTableTableManager get cakepayOrders =>
      $$CakepayOrdersTableTableManager(_db, _db.cakepayOrders);
}

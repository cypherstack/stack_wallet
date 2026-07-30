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

class $ShopInBitSettingsTable extends ShopInBitSettings
    with TableInfo<$ShopInBitSettingsTable, ShopInBitSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopInBitSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _customerKeyMeta = const VerificationMeta(
    'customerKey',
  );
  @override
  late final GeneratedColumn<String> customerKey = GeneratedColumn<String>(
    'customer_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _privacyAcceptedMeta = const VerificationMeta(
    'privacyAccepted',
  );
  @override
  late final GeneratedColumn<bool> privacyAccepted = GeneratedColumn<bool>(
    'privacy_accepted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("privacy_accepted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _conciergeGuidelinesAcceptedMeta =
      const VerificationMeta('conciergeGuidelinesAccepted');
  @override
  late final GeneratedColumn<bool> conciergeGuidelinesAccepted =
      GeneratedColumn<bool>(
        'concierge_guidelines_accepted',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("concierge_guidelines_accepted" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _travelGuidelinesAcceptedMeta =
      const VerificationMeta('travelGuidelinesAccepted');
  @override
  late final GeneratedColumn<bool> travelGuidelinesAccepted =
      GeneratedColumn<bool>(
        'travel_guidelines_accepted',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("travel_guidelines_accepted" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _carGuidelinesAcceptedMeta =
      const VerificationMeta('carGuidelinesAccepted');
  @override
  late final GeneratedColumn<bool> carGuidelinesAccepted =
      GeneratedColumn<bool>(
        'car_guidelines_accepted',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("car_guidelines_accepted" IN (0, 1))',
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
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    customerKey,
    privacyAccepted,
    conciergeGuidelinesAccepted,
    travelGuidelinesAccepted,
    carGuidelinesAccepted,
    setupComplete,
    createdAt,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shop_in_bit_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShopInBitSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('customer_key')) {
      context.handle(
        _customerKeyMeta,
        customerKey.isAcceptableOrUnknown(
          data['customer_key']!,
          _customerKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerKeyMeta);
    }
    if (data.containsKey('privacy_accepted')) {
      context.handle(
        _privacyAcceptedMeta,
        privacyAccepted.isAcceptableOrUnknown(
          data['privacy_accepted']!,
          _privacyAcceptedMeta,
        ),
      );
    }
    if (data.containsKey('concierge_guidelines_accepted')) {
      context.handle(
        _conciergeGuidelinesAcceptedMeta,
        conciergeGuidelinesAccepted.isAcceptableOrUnknown(
          data['concierge_guidelines_accepted']!,
          _conciergeGuidelinesAcceptedMeta,
        ),
      );
    }
    if (data.containsKey('travel_guidelines_accepted')) {
      context.handle(
        _travelGuidelinesAcceptedMeta,
        travelGuidelinesAccepted.isAcceptableOrUnknown(
          data['travel_guidelines_accepted']!,
          _travelGuidelinesAcceptedMeta,
        ),
      );
    }
    if (data.containsKey('car_guidelines_accepted')) {
      context.handle(
        _carGuidelinesAcceptedMeta,
        carGuidelinesAccepted.isAcceptableOrUnknown(
          data['car_guidelines_accepted']!,
          _carGuidelinesAcceptedMeta,
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {customerKey};
  @override
  ShopInBitSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShopInBitSetting(
      customerKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_key'],
      )!,
      privacyAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}privacy_accepted'],
      )!,
      conciergeGuidelinesAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}concierge_guidelines_accepted'],
      )!,
      travelGuidelinesAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}travel_guidelines_accepted'],
      )!,
      carGuidelinesAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}car_guidelines_accepted'],
      )!,
      setupComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}setup_complete'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $ShopInBitSettingsTable createAlias(String alias) {
    return $ShopInBitSettingsTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class ShopInBitSetting extends DataClass
    implements Insertable<ShopInBitSetting> {
  final String customerKey;
  final bool privacyAccepted;
  final bool conciergeGuidelinesAccepted;
  final bool travelGuidelinesAccepted;
  final bool carGuidelinesAccepted;
  final bool setupComplete;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  const ShopInBitSetting({
    required this.customerKey,
    required this.privacyAccepted,
    required this.conciergeGuidelinesAccepted,
    required this.travelGuidelinesAccepted,
    required this.carGuidelinesAccepted,
    required this.setupComplete,
    required this.createdAt,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['customer_key'] = Variable<String>(customerKey);
    map['privacy_accepted'] = Variable<bool>(privacyAccepted);
    map['concierge_guidelines_accepted'] = Variable<bool>(
      conciergeGuidelinesAccepted,
    );
    map['travel_guidelines_accepted'] = Variable<bool>(
      travelGuidelinesAccepted,
    );
    map['car_guidelines_accepted'] = Variable<bool>(carGuidelinesAccepted);
    map['setup_complete'] = Variable<bool>(setupComplete);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  ShopInBitSettingsCompanion toCompanion(bool nullToAbsent) {
    return ShopInBitSettingsCompanion(
      customerKey: Value(customerKey),
      privacyAccepted: Value(privacyAccepted),
      conciergeGuidelinesAccepted: Value(conciergeGuidelinesAccepted),
      travelGuidelinesAccepted: Value(travelGuidelinesAccepted),
      carGuidelinesAccepted: Value(carGuidelinesAccepted),
      setupComplete: Value(setupComplete),
      createdAt: Value(createdAt),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory ShopInBitSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShopInBitSetting(
      customerKey: serializer.fromJson<String>(json['customerKey']),
      privacyAccepted: serializer.fromJson<bool>(json['privacyAccepted']),
      conciergeGuidelinesAccepted: serializer.fromJson<bool>(
        json['conciergeGuidelinesAccepted'],
      ),
      travelGuidelinesAccepted: serializer.fromJson<bool>(
        json['travelGuidelinesAccepted'],
      ),
      carGuidelinesAccepted: serializer.fromJson<bool>(
        json['carGuidelinesAccepted'],
      ),
      setupComplete: serializer.fromJson<bool>(json['setupComplete']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'customerKey': serializer.toJson<String>(customerKey),
      'privacyAccepted': serializer.toJson<bool>(privacyAccepted),
      'conciergeGuidelinesAccepted': serializer.toJson<bool>(
        conciergeGuidelinesAccepted,
      ),
      'travelGuidelinesAccepted': serializer.toJson<bool>(
        travelGuidelinesAccepted,
      ),
      'carGuidelinesAccepted': serializer.toJson<bool>(carGuidelinesAccepted),
      'setupComplete': serializer.toJson<bool>(setupComplete),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  ShopInBitSetting copyWith({
    String? customerKey,
    bool? privacyAccepted,
    bool? conciergeGuidelinesAccepted,
    bool? travelGuidelinesAccepted,
    bool? carGuidelinesAccepted,
    bool? setupComplete,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) => ShopInBitSetting(
    customerKey: customerKey ?? this.customerKey,
    privacyAccepted: privacyAccepted ?? this.privacyAccepted,
    conciergeGuidelinesAccepted:
        conciergeGuidelinesAccepted ?? this.conciergeGuidelinesAccepted,
    travelGuidelinesAccepted:
        travelGuidelinesAccepted ?? this.travelGuidelinesAccepted,
    carGuidelinesAccepted: carGuidelinesAccepted ?? this.carGuidelinesAccepted,
    setupComplete: setupComplete ?? this.setupComplete,
    createdAt: createdAt ?? this.createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  ShopInBitSetting copyWithCompanion(ShopInBitSettingsCompanion data) {
    return ShopInBitSetting(
      customerKey: data.customerKey.present
          ? data.customerKey.value
          : this.customerKey,
      privacyAccepted: data.privacyAccepted.present
          ? data.privacyAccepted.value
          : this.privacyAccepted,
      conciergeGuidelinesAccepted: data.conciergeGuidelinesAccepted.present
          ? data.conciergeGuidelinesAccepted.value
          : this.conciergeGuidelinesAccepted,
      travelGuidelinesAccepted: data.travelGuidelinesAccepted.present
          ? data.travelGuidelinesAccepted.value
          : this.travelGuidelinesAccepted,
      carGuidelinesAccepted: data.carGuidelinesAccepted.present
          ? data.carGuidelinesAccepted.value
          : this.carGuidelinesAccepted,
      setupComplete: data.setupComplete.present
          ? data.setupComplete.value
          : this.setupComplete,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShopInBitSetting(')
          ..write('customerKey: $customerKey, ')
          ..write('privacyAccepted: $privacyAccepted, ')
          ..write('conciergeGuidelinesAccepted: $conciergeGuidelinesAccepted, ')
          ..write('travelGuidelinesAccepted: $travelGuidelinesAccepted, ')
          ..write('carGuidelinesAccepted: $carGuidelinesAccepted, ')
          ..write('setupComplete: $setupComplete, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    customerKey,
    privacyAccepted,
    conciergeGuidelinesAccepted,
    travelGuidelinesAccepted,
    carGuidelinesAccepted,
    setupComplete,
    createdAt,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShopInBitSetting &&
          other.customerKey == this.customerKey &&
          other.privacyAccepted == this.privacyAccepted &&
          other.conciergeGuidelinesAccepted ==
              this.conciergeGuidelinesAccepted &&
          other.travelGuidelinesAccepted == this.travelGuidelinesAccepted &&
          other.carGuidelinesAccepted == this.carGuidelinesAccepted &&
          other.setupComplete == this.setupComplete &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class ShopInBitSettingsCompanion extends UpdateCompanion<ShopInBitSetting> {
  final Value<String> customerKey;
  final Value<bool> privacyAccepted;
  final Value<bool> conciergeGuidelinesAccepted;
  final Value<bool> travelGuidelinesAccepted;
  final Value<bool> carGuidelinesAccepted;
  final Value<bool> setupComplete;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastUsedAt;
  const ShopInBitSettingsCompanion({
    this.customerKey = const Value.absent(),
    this.privacyAccepted = const Value.absent(),
    this.conciergeGuidelinesAccepted = const Value.absent(),
    this.travelGuidelinesAccepted = const Value.absent(),
    this.carGuidelinesAccepted = const Value.absent(),
    this.setupComplete = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  });
  ShopInBitSettingsCompanion.insert({
    required String customerKey,
    this.privacyAccepted = const Value.absent(),
    this.conciergeGuidelinesAccepted = const Value.absent(),
    this.travelGuidelinesAccepted = const Value.absent(),
    this.carGuidelinesAccepted = const Value.absent(),
    this.setupComplete = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  }) : customerKey = Value(customerKey);
  static Insertable<ShopInBitSetting> custom({
    Expression<String>? customerKey,
    Expression<bool>? privacyAccepted,
    Expression<bool>? conciergeGuidelinesAccepted,
    Expression<bool>? travelGuidelinesAccepted,
    Expression<bool>? carGuidelinesAccepted,
    Expression<bool>? setupComplete,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUsedAt,
  }) {
    return RawValuesInsertable({
      if (customerKey != null) 'customer_key': customerKey,
      if (privacyAccepted != null) 'privacy_accepted': privacyAccepted,
      if (conciergeGuidelinesAccepted != null)
        'concierge_guidelines_accepted': conciergeGuidelinesAccepted,
      if (travelGuidelinesAccepted != null)
        'travel_guidelines_accepted': travelGuidelinesAccepted,
      if (carGuidelinesAccepted != null)
        'car_guidelines_accepted': carGuidelinesAccepted,
      if (setupComplete != null) 'setup_complete': setupComplete,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
    });
  }

  ShopInBitSettingsCompanion copyWith({
    Value<String>? customerKey,
    Value<bool>? privacyAccepted,
    Value<bool>? conciergeGuidelinesAccepted,
    Value<bool>? travelGuidelinesAccepted,
    Value<bool>? carGuidelinesAccepted,
    Value<bool>? setupComplete,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastUsedAt,
  }) {
    return ShopInBitSettingsCompanion(
      customerKey: customerKey ?? this.customerKey,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
      conciergeGuidelinesAccepted:
          conciergeGuidelinesAccepted ?? this.conciergeGuidelinesAccepted,
      travelGuidelinesAccepted:
          travelGuidelinesAccepted ?? this.travelGuidelinesAccepted,
      carGuidelinesAccepted:
          carGuidelinesAccepted ?? this.carGuidelinesAccepted,
      setupComplete: setupComplete ?? this.setupComplete,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (customerKey.present) {
      map['customer_key'] = Variable<String>(customerKey.value);
    }
    if (privacyAccepted.present) {
      map['privacy_accepted'] = Variable<bool>(privacyAccepted.value);
    }
    if (conciergeGuidelinesAccepted.present) {
      map['concierge_guidelines_accepted'] = Variable<bool>(
        conciergeGuidelinesAccepted.value,
      );
    }
    if (travelGuidelinesAccepted.present) {
      map['travel_guidelines_accepted'] = Variable<bool>(
        travelGuidelinesAccepted.value,
      );
    }
    if (carGuidelinesAccepted.present) {
      map['car_guidelines_accepted'] = Variable<bool>(
        carGuidelinesAccepted.value,
      );
    }
    if (setupComplete.present) {
      map['setup_complete'] = Variable<bool>(setupComplete.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopInBitSettingsCompanion(')
          ..write('customerKey: $customerKey, ')
          ..write('privacyAccepted: $privacyAccepted, ')
          ..write('conciergeGuidelinesAccepted: $conciergeGuidelinesAccepted, ')
          ..write('travelGuidelinesAccepted: $travelGuidelinesAccepted, ')
          ..write('carGuidelinesAccepted: $carGuidelinesAccepted, ')
          ..write('setupComplete: $setupComplete, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }
}

class $ShopInBitTicketsTable extends ShopInBitTickets
    with TableInfo<$ShopInBitTicketsTable, ShopInBitTicket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopInBitTicketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _apiTicketIdMeta = const VerificationMeta(
    'apiTicketId',
  );
  @override
  late final GeneratedColumn<int> apiTicketId = GeneratedColumn<int>(
    'api_ticket_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerKeyMeta = const VerificationMeta(
    'customerKey',
  );
  @override
  late final GeneratedColumn<String> customerKey = GeneratedColumn<String>(
    'customer_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ticketNumberMeta = const VerificationMeta(
    'ticketNumber',
  );
  @override
  late final GeneratedColumn<String> ticketNumber = GeneratedColumn<String>(
    'ticket_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ShopInBitCategory, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ShopInBitCategory>($ShopInBitTicketsTable.$convertercategory);
  static const VerificationMeta _requestDescriptionMeta =
      const VerificationMeta('requestDescription');
  @override
  late final GeneratedColumn<String> requestDescription =
      GeneratedColumn<String>(
        'request_description',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _deliveryCountryMeta = const VerificationMeta(
    'deliveryCountry',
  );
  @override
  late final GeneratedColumn<String> deliveryCountry = GeneratedColumn<String>(
    'delivery_country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ShopInBitOrderStatus, String>
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ShopInBitOrderStatus>(
        $ShopInBitTicketsTable.$converterstatus,
      );
  static const VerificationMeta _statusRawMeta = const VerificationMeta(
    'statusRaw',
  );
  @override
  late final GeneratedColumn<String> statusRaw = GeneratedColumn<String>(
    'status_raw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offerProductNameMeta = const VerificationMeta(
    'offerProductName',
  );
  @override
  late final GeneratedColumn<String> offerProductName = GeneratedColumn<String>(
    'offer_product_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offerPriceMeta = const VerificationMeta(
    'offerPrice',
  );
  @override
  late final GeneratedColumn<String> offerPrice = GeneratedColumn<String>(
    'offer_price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentInvoiceStatusMeta =
      const VerificationMeta('paymentInvoiceStatus');
  @override
  late final GeneratedColumn<String> paymentInvoiceStatus =
      GeneratedColumn<String>(
        'payment_invoice_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _trackingLinkMeta = const VerificationMeta(
    'trackingLink',
  );
  @override
  late final GeneratedColumn<String> trackingLink = GeneratedColumn<String>(
    'tracking_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String>
  lastAgentMessageAt =
      GeneratedColumn<String>(
        'last_agent_message_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $ShopInBitTicketsTable.$converterlastAgentMessageAtn,
      );
  static const VerificationMeta _feeTicketNumberMeta = const VerificationMeta(
    'feeTicketNumber',
  );
  @override
  late final GeneratedColumn<String> feeTicketNumber = GeneratedColumn<String>(
    'fee_ticket_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<TicketMessage>, String>
  messages =
      GeneratedColumn<String>(
        'messages',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant("[]"),
      ).withConverter<List<TicketMessage>>(
        $ShopInBitTicketsTable.$convertermessages,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () =>
            ShopInBitTickets.dateConverter.toSql(DateTime.now()),
      ).withConverter<DateTime>($ShopInBitTicketsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> updatedAt =
      GeneratedColumn<String>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () =>
            ShopInBitTickets.dateConverter.toSql(DateTime.now()),
      ).withConverter<DateTime>($ShopInBitTicketsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> lastReadAt =
      GeneratedColumn<String>(
        'last_read_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ShopInBitTicketsTable.$converterlastReadAtn);
  @override
  List<GeneratedColumn> get $columns => [
    apiTicketId,
    customerKey,
    ticketNumber,
    category,
    requestDescription,
    deliveryCountry,
    status,
    statusRaw,
    offerProductName,
    offerPrice,
    paymentInvoiceStatus,
    trackingLink,
    lastAgentMessageAt,
    feeTicketNumber,
    messages,
    createdAt,
    updatedAt,
    lastReadAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shop_in_bit_tickets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShopInBitTicket> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('api_ticket_id')) {
      context.handle(
        _apiTicketIdMeta,
        apiTicketId.isAcceptableOrUnknown(
          data['api_ticket_id']!,
          _apiTicketIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_apiTicketIdMeta);
    }
    if (data.containsKey('customer_key')) {
      context.handle(
        _customerKeyMeta,
        customerKey.isAcceptableOrUnknown(
          data['customer_key']!,
          _customerKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerKeyMeta);
    }
    if (data.containsKey('ticket_number')) {
      context.handle(
        _ticketNumberMeta,
        ticketNumber.isAcceptableOrUnknown(
          data['ticket_number']!,
          _ticketNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ticketNumberMeta);
    }
    if (data.containsKey('request_description')) {
      context.handle(
        _requestDescriptionMeta,
        requestDescription.isAcceptableOrUnknown(
          data['request_description']!,
          _requestDescriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestDescriptionMeta);
    }
    if (data.containsKey('delivery_country')) {
      context.handle(
        _deliveryCountryMeta,
        deliveryCountry.isAcceptableOrUnknown(
          data['delivery_country']!,
          _deliveryCountryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryCountryMeta);
    }
    if (data.containsKey('status_raw')) {
      context.handle(
        _statusRawMeta,
        statusRaw.isAcceptableOrUnknown(data['status_raw']!, _statusRawMeta),
      );
    } else if (isInserting) {
      context.missing(_statusRawMeta);
    }
    if (data.containsKey('offer_product_name')) {
      context.handle(
        _offerProductNameMeta,
        offerProductName.isAcceptableOrUnknown(
          data['offer_product_name']!,
          _offerProductNameMeta,
        ),
      );
    }
    if (data.containsKey('offer_price')) {
      context.handle(
        _offerPriceMeta,
        offerPrice.isAcceptableOrUnknown(data['offer_price']!, _offerPriceMeta),
      );
    }
    if (data.containsKey('payment_invoice_status')) {
      context.handle(
        _paymentInvoiceStatusMeta,
        paymentInvoiceStatus.isAcceptableOrUnknown(
          data['payment_invoice_status']!,
          _paymentInvoiceStatusMeta,
        ),
      );
    }
    if (data.containsKey('tracking_link')) {
      context.handle(
        _trackingLinkMeta,
        trackingLink.isAcceptableOrUnknown(
          data['tracking_link']!,
          _trackingLinkMeta,
        ),
      );
    }
    if (data.containsKey('fee_ticket_number')) {
      context.handle(
        _feeTicketNumberMeta,
        feeTicketNumber.isAcceptableOrUnknown(
          data['fee_ticket_number']!,
          _feeTicketNumberMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {apiTicketId};
  @override
  ShopInBitTicket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShopInBitTicket(
      apiTicketId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}api_ticket_id'],
      )!,
      customerKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_key'],
      )!,
      ticketNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_number'],
      )!,
      category: $ShopInBitTicketsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      requestDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_description'],
      )!,
      deliveryCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_country'],
      )!,
      status: $ShopInBitTicketsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      statusRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_raw'],
      )!,
      offerProductName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offer_product_name'],
      ),
      offerPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offer_price'],
      ),
      paymentInvoiceStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_invoice_status'],
      ),
      trackingLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracking_link'],
      ),
      lastAgentMessageAt: $ShopInBitTicketsTable.$converterlastAgentMessageAtn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}last_agent_message_at'],
            ),
          ),
      feeTicketNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fee_ticket_number'],
      ),
      messages: $ShopInBitTicketsTable.$convertermessages.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}messages'],
        )!,
      ),
      createdAt: $ShopInBitTicketsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $ShopInBitTicketsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      lastReadAt: $ShopInBitTicketsTable.$converterlastReadAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_read_at'],
        ),
      ),
    );
  }

  @override
  $ShopInBitTicketsTable createAlias(String alias) {
    return $ShopInBitTicketsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ShopInBitCategory, String, String>
  $convertercategory = const EnumNameConverter<ShopInBitCategory>(
    ShopInBitCategory.values,
  );
  static JsonTypeConverter2<ShopInBitOrderStatus, String, String>
  $converterstatus = const EnumNameConverter<ShopInBitOrderStatus>(
    ShopInBitOrderStatus.values,
  );
  static TypeConverter<DateTime, String> $converterlastAgentMessageAt =
      ShopInBitTickets.dateConverter;
  static TypeConverter<DateTime?, String?> $converterlastAgentMessageAtn =
      NullAwareTypeConverter.wrap($converterlastAgentMessageAt);
  static TypeConverter<List<TicketMessage>, String> $convertermessages =
      const MessagesConverter();
  static TypeConverter<DateTime, String> $convertercreatedAt =
      ShopInBitTickets.dateConverter;
  static TypeConverter<DateTime, String> $converterupdatedAt =
      ShopInBitTickets.dateConverter;
  static TypeConverter<DateTime, String> $converterlastReadAt =
      ShopInBitTickets.dateConverter;
  static TypeConverter<DateTime?, String?> $converterlastReadAtn =
      NullAwareTypeConverter.wrap($converterlastReadAt);
  @override
  bool get withoutRowId => true;
}

class ShopInBitTicket extends DataClass implements Insertable<ShopInBitTicket> {
  final int apiTicketId;
  final String customerKey;
  final String ticketNumber;
  final ShopInBitCategory category;
  final String requestDescription;
  final String deliveryCountry;
  final ShopInBitOrderStatus status;
  final String statusRaw;
  final String? offerProductName;
  final String? offerPrice;
  final String? paymentInvoiceStatus;
  final String? trackingLink;
  final DateTime? lastAgentMessageAt;
  final String? feeTicketNumber;
  final List<TicketMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReadAt;
  const ShopInBitTicket({
    required this.apiTicketId,
    required this.customerKey,
    required this.ticketNumber,
    required this.category,
    required this.requestDescription,
    required this.deliveryCountry,
    required this.status,
    required this.statusRaw,
    this.offerProductName,
    this.offerPrice,
    this.paymentInvoiceStatus,
    this.trackingLink,
    this.lastAgentMessageAt,
    this.feeTicketNumber,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.lastReadAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['api_ticket_id'] = Variable<int>(apiTicketId);
    map['customer_key'] = Variable<String>(customerKey);
    map['ticket_number'] = Variable<String>(ticketNumber);
    {
      map['category'] = Variable<String>(
        $ShopInBitTicketsTable.$convertercategory.toSql(category),
      );
    }
    map['request_description'] = Variable<String>(requestDescription);
    map['delivery_country'] = Variable<String>(deliveryCountry);
    {
      map['status'] = Variable<String>(
        $ShopInBitTicketsTable.$converterstatus.toSql(status),
      );
    }
    map['status_raw'] = Variable<String>(statusRaw);
    if (!nullToAbsent || offerProductName != null) {
      map['offer_product_name'] = Variable<String>(offerProductName);
    }
    if (!nullToAbsent || offerPrice != null) {
      map['offer_price'] = Variable<String>(offerPrice);
    }
    if (!nullToAbsent || paymentInvoiceStatus != null) {
      map['payment_invoice_status'] = Variable<String>(paymentInvoiceStatus);
    }
    if (!nullToAbsent || trackingLink != null) {
      map['tracking_link'] = Variable<String>(trackingLink);
    }
    if (!nullToAbsent || lastAgentMessageAt != null) {
      map['last_agent_message_at'] = Variable<String>(
        $ShopInBitTicketsTable.$converterlastAgentMessageAtn.toSql(
          lastAgentMessageAt,
        ),
      );
    }
    if (!nullToAbsent || feeTicketNumber != null) {
      map['fee_ticket_number'] = Variable<String>(feeTicketNumber);
    }
    {
      map['messages'] = Variable<String>(
        $ShopInBitTicketsTable.$convertermessages.toSql(messages),
      );
    }
    {
      map['created_at'] = Variable<String>(
        $ShopInBitTicketsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<String>(
        $ShopInBitTicketsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<String>(
        $ShopInBitTicketsTable.$converterlastReadAtn.toSql(lastReadAt),
      );
    }
    return map;
  }

  ShopInBitTicketsCompanion toCompanion(bool nullToAbsent) {
    return ShopInBitTicketsCompanion(
      apiTicketId: Value(apiTicketId),
      customerKey: Value(customerKey),
      ticketNumber: Value(ticketNumber),
      category: Value(category),
      requestDescription: Value(requestDescription),
      deliveryCountry: Value(deliveryCountry),
      status: Value(status),
      statusRaw: Value(statusRaw),
      offerProductName: offerProductName == null && nullToAbsent
          ? const Value.absent()
          : Value(offerProductName),
      offerPrice: offerPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(offerPrice),
      paymentInvoiceStatus: paymentInvoiceStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentInvoiceStatus),
      trackingLink: trackingLink == null && nullToAbsent
          ? const Value.absent()
          : Value(trackingLink),
      lastAgentMessageAt: lastAgentMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAgentMessageAt),
      feeTicketNumber: feeTicketNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(feeTicketNumber),
      messages: Value(messages),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
    );
  }

  factory ShopInBitTicket.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShopInBitTicket(
      apiTicketId: serializer.fromJson<int>(json['apiTicketId']),
      customerKey: serializer.fromJson<String>(json['customerKey']),
      ticketNumber: serializer.fromJson<String>(json['ticketNumber']),
      category: $ShopInBitTicketsTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      requestDescription: serializer.fromJson<String>(
        json['requestDescription'],
      ),
      deliveryCountry: serializer.fromJson<String>(json['deliveryCountry']),
      status: $ShopInBitTicketsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      statusRaw: serializer.fromJson<String>(json['statusRaw']),
      offerProductName: serializer.fromJson<String?>(json['offerProductName']),
      offerPrice: serializer.fromJson<String?>(json['offerPrice']),
      paymentInvoiceStatus: serializer.fromJson<String?>(
        json['paymentInvoiceStatus'],
      ),
      trackingLink: serializer.fromJson<String?>(json['trackingLink']),
      lastAgentMessageAt: serializer.fromJson<DateTime?>(
        json['lastAgentMessageAt'],
      ),
      feeTicketNumber: serializer.fromJson<String?>(json['feeTicketNumber']),
      messages: serializer.fromJson<List<TicketMessage>>(json['messages']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastReadAt: serializer.fromJson<DateTime?>(json['lastReadAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'apiTicketId': serializer.toJson<int>(apiTicketId),
      'customerKey': serializer.toJson<String>(customerKey),
      'ticketNumber': serializer.toJson<String>(ticketNumber),
      'category': serializer.toJson<String>(
        $ShopInBitTicketsTable.$convertercategory.toJson(category),
      ),
      'requestDescription': serializer.toJson<String>(requestDescription),
      'deliveryCountry': serializer.toJson<String>(deliveryCountry),
      'status': serializer.toJson<String>(
        $ShopInBitTicketsTable.$converterstatus.toJson(status),
      ),
      'statusRaw': serializer.toJson<String>(statusRaw),
      'offerProductName': serializer.toJson<String?>(offerProductName),
      'offerPrice': serializer.toJson<String?>(offerPrice),
      'paymentInvoiceStatus': serializer.toJson<String?>(paymentInvoiceStatus),
      'trackingLink': serializer.toJson<String?>(trackingLink),
      'lastAgentMessageAt': serializer.toJson<DateTime?>(lastAgentMessageAt),
      'feeTicketNumber': serializer.toJson<String?>(feeTicketNumber),
      'messages': serializer.toJson<List<TicketMessage>>(messages),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastReadAt': serializer.toJson<DateTime?>(lastReadAt),
    };
  }

  ShopInBitTicket copyWith({
    int? apiTicketId,
    String? customerKey,
    String? ticketNumber,
    ShopInBitCategory? category,
    String? requestDescription,
    String? deliveryCountry,
    ShopInBitOrderStatus? status,
    String? statusRaw,
    Value<String?> offerProductName = const Value.absent(),
    Value<String?> offerPrice = const Value.absent(),
    Value<String?> paymentInvoiceStatus = const Value.absent(),
    Value<String?> trackingLink = const Value.absent(),
    Value<DateTime?> lastAgentMessageAt = const Value.absent(),
    Value<String?> feeTicketNumber = const Value.absent(),
    List<TicketMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastReadAt = const Value.absent(),
  }) => ShopInBitTicket(
    apiTicketId: apiTicketId ?? this.apiTicketId,
    customerKey: customerKey ?? this.customerKey,
    ticketNumber: ticketNumber ?? this.ticketNumber,
    category: category ?? this.category,
    requestDescription: requestDescription ?? this.requestDescription,
    deliveryCountry: deliveryCountry ?? this.deliveryCountry,
    status: status ?? this.status,
    statusRaw: statusRaw ?? this.statusRaw,
    offerProductName: offerProductName.present
        ? offerProductName.value
        : this.offerProductName,
    offerPrice: offerPrice.present ? offerPrice.value : this.offerPrice,
    paymentInvoiceStatus: paymentInvoiceStatus.present
        ? paymentInvoiceStatus.value
        : this.paymentInvoiceStatus,
    trackingLink: trackingLink.present ? trackingLink.value : this.trackingLink,
    lastAgentMessageAt: lastAgentMessageAt.present
        ? lastAgentMessageAt.value
        : this.lastAgentMessageAt,
    feeTicketNumber: feeTicketNumber.present
        ? feeTicketNumber.value
        : this.feeTicketNumber,
    messages: messages ?? this.messages,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
  );
  ShopInBitTicket copyWithCompanion(ShopInBitTicketsCompanion data) {
    return ShopInBitTicket(
      apiTicketId: data.apiTicketId.present
          ? data.apiTicketId.value
          : this.apiTicketId,
      customerKey: data.customerKey.present
          ? data.customerKey.value
          : this.customerKey,
      ticketNumber: data.ticketNumber.present
          ? data.ticketNumber.value
          : this.ticketNumber,
      category: data.category.present ? data.category.value : this.category,
      requestDescription: data.requestDescription.present
          ? data.requestDescription.value
          : this.requestDescription,
      deliveryCountry: data.deliveryCountry.present
          ? data.deliveryCountry.value
          : this.deliveryCountry,
      status: data.status.present ? data.status.value : this.status,
      statusRaw: data.statusRaw.present ? data.statusRaw.value : this.statusRaw,
      offerProductName: data.offerProductName.present
          ? data.offerProductName.value
          : this.offerProductName,
      offerPrice: data.offerPrice.present
          ? data.offerPrice.value
          : this.offerPrice,
      paymentInvoiceStatus: data.paymentInvoiceStatus.present
          ? data.paymentInvoiceStatus.value
          : this.paymentInvoiceStatus,
      trackingLink: data.trackingLink.present
          ? data.trackingLink.value
          : this.trackingLink,
      lastAgentMessageAt: data.lastAgentMessageAt.present
          ? data.lastAgentMessageAt.value
          : this.lastAgentMessageAt,
      feeTicketNumber: data.feeTicketNumber.present
          ? data.feeTicketNumber.value
          : this.feeTicketNumber,
      messages: data.messages.present ? data.messages.value : this.messages,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShopInBitTicket(')
          ..write('apiTicketId: $apiTicketId, ')
          ..write('customerKey: $customerKey, ')
          ..write('ticketNumber: $ticketNumber, ')
          ..write('category: $category, ')
          ..write('requestDescription: $requestDescription, ')
          ..write('deliveryCountry: $deliveryCountry, ')
          ..write('status: $status, ')
          ..write('statusRaw: $statusRaw, ')
          ..write('offerProductName: $offerProductName, ')
          ..write('offerPrice: $offerPrice, ')
          ..write('paymentInvoiceStatus: $paymentInvoiceStatus, ')
          ..write('trackingLink: $trackingLink, ')
          ..write('lastAgentMessageAt: $lastAgentMessageAt, ')
          ..write('feeTicketNumber: $feeTicketNumber, ')
          ..write('messages: $messages, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    apiTicketId,
    customerKey,
    ticketNumber,
    category,
    requestDescription,
    deliveryCountry,
    status,
    statusRaw,
    offerProductName,
    offerPrice,
    paymentInvoiceStatus,
    trackingLink,
    lastAgentMessageAt,
    feeTicketNumber,
    messages,
    createdAt,
    updatedAt,
    lastReadAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShopInBitTicket &&
          other.apiTicketId == this.apiTicketId &&
          other.customerKey == this.customerKey &&
          other.ticketNumber == this.ticketNumber &&
          other.category == this.category &&
          other.requestDescription == this.requestDescription &&
          other.deliveryCountry == this.deliveryCountry &&
          other.status == this.status &&
          other.statusRaw == this.statusRaw &&
          other.offerProductName == this.offerProductName &&
          other.offerPrice == this.offerPrice &&
          other.paymentInvoiceStatus == this.paymentInvoiceStatus &&
          other.trackingLink == this.trackingLink &&
          other.lastAgentMessageAt == this.lastAgentMessageAt &&
          other.feeTicketNumber == this.feeTicketNumber &&
          other.messages == this.messages &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastReadAt == this.lastReadAt);
}

class ShopInBitTicketsCompanion extends UpdateCompanion<ShopInBitTicket> {
  final Value<int> apiTicketId;
  final Value<String> customerKey;
  final Value<String> ticketNumber;
  final Value<ShopInBitCategory> category;
  final Value<String> requestDescription;
  final Value<String> deliveryCountry;
  final Value<ShopInBitOrderStatus> status;
  final Value<String> statusRaw;
  final Value<String?> offerProductName;
  final Value<String?> offerPrice;
  final Value<String?> paymentInvoiceStatus;
  final Value<String?> trackingLink;
  final Value<DateTime?> lastAgentMessageAt;
  final Value<String?> feeTicketNumber;
  final Value<List<TicketMessage>> messages;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastReadAt;
  const ShopInBitTicketsCompanion({
    this.apiTicketId = const Value.absent(),
    this.customerKey = const Value.absent(),
    this.ticketNumber = const Value.absent(),
    this.category = const Value.absent(),
    this.requestDescription = const Value.absent(),
    this.deliveryCountry = const Value.absent(),
    this.status = const Value.absent(),
    this.statusRaw = const Value.absent(),
    this.offerProductName = const Value.absent(),
    this.offerPrice = const Value.absent(),
    this.paymentInvoiceStatus = const Value.absent(),
    this.trackingLink = const Value.absent(),
    this.lastAgentMessageAt = const Value.absent(),
    this.feeTicketNumber = const Value.absent(),
    this.messages = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastReadAt = const Value.absent(),
  });
  ShopInBitTicketsCompanion.insert({
    required int apiTicketId,
    required String customerKey,
    required String ticketNumber,
    required ShopInBitCategory category,
    required String requestDescription,
    required String deliveryCountry,
    required ShopInBitOrderStatus status,
    required String statusRaw,
    this.offerProductName = const Value.absent(),
    this.offerPrice = const Value.absent(),
    this.paymentInvoiceStatus = const Value.absent(),
    this.trackingLink = const Value.absent(),
    this.lastAgentMessageAt = const Value.absent(),
    this.feeTicketNumber = const Value.absent(),
    this.messages = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastReadAt = const Value.absent(),
  }) : apiTicketId = Value(apiTicketId),
       customerKey = Value(customerKey),
       ticketNumber = Value(ticketNumber),
       category = Value(category),
       requestDescription = Value(requestDescription),
       deliveryCountry = Value(deliveryCountry),
       status = Value(status),
       statusRaw = Value(statusRaw);
  static Insertable<ShopInBitTicket> custom({
    Expression<int>? apiTicketId,
    Expression<String>? customerKey,
    Expression<String>? ticketNumber,
    Expression<String>? category,
    Expression<String>? requestDescription,
    Expression<String>? deliveryCountry,
    Expression<String>? status,
    Expression<String>? statusRaw,
    Expression<String>? offerProductName,
    Expression<String>? offerPrice,
    Expression<String>? paymentInvoiceStatus,
    Expression<String>? trackingLink,
    Expression<String>? lastAgentMessageAt,
    Expression<String>? feeTicketNumber,
    Expression<String>? messages,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? lastReadAt,
  }) {
    return RawValuesInsertable({
      if (apiTicketId != null) 'api_ticket_id': apiTicketId,
      if (customerKey != null) 'customer_key': customerKey,
      if (ticketNumber != null) 'ticket_number': ticketNumber,
      if (category != null) 'category': category,
      if (requestDescription != null) 'request_description': requestDescription,
      if (deliveryCountry != null) 'delivery_country': deliveryCountry,
      if (status != null) 'status': status,
      if (statusRaw != null) 'status_raw': statusRaw,
      if (offerProductName != null) 'offer_product_name': offerProductName,
      if (offerPrice != null) 'offer_price': offerPrice,
      if (paymentInvoiceStatus != null)
        'payment_invoice_status': paymentInvoiceStatus,
      if (trackingLink != null) 'tracking_link': trackingLink,
      if (lastAgentMessageAt != null)
        'last_agent_message_at': lastAgentMessageAt,
      if (feeTicketNumber != null) 'fee_ticket_number': feeTicketNumber,
      if (messages != null) 'messages': messages,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
    });
  }

  ShopInBitTicketsCompanion copyWith({
    Value<int>? apiTicketId,
    Value<String>? customerKey,
    Value<String>? ticketNumber,
    Value<ShopInBitCategory>? category,
    Value<String>? requestDescription,
    Value<String>? deliveryCountry,
    Value<ShopInBitOrderStatus>? status,
    Value<String>? statusRaw,
    Value<String?>? offerProductName,
    Value<String?>? offerPrice,
    Value<String?>? paymentInvoiceStatus,
    Value<String?>? trackingLink,
    Value<DateTime?>? lastAgentMessageAt,
    Value<String?>? feeTicketNumber,
    Value<List<TicketMessage>>? messages,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastReadAt,
  }) {
    return ShopInBitTicketsCompanion(
      apiTicketId: apiTicketId ?? this.apiTicketId,
      customerKey: customerKey ?? this.customerKey,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      category: category ?? this.category,
      requestDescription: requestDescription ?? this.requestDescription,
      deliveryCountry: deliveryCountry ?? this.deliveryCountry,
      status: status ?? this.status,
      statusRaw: statusRaw ?? this.statusRaw,
      offerProductName: offerProductName ?? this.offerProductName,
      offerPrice: offerPrice ?? this.offerPrice,
      paymentInvoiceStatus: paymentInvoiceStatus ?? this.paymentInvoiceStatus,
      trackingLink: trackingLink ?? this.trackingLink,
      lastAgentMessageAt: lastAgentMessageAt ?? this.lastAgentMessageAt,
      feeTicketNumber: feeTicketNumber ?? this.feeTicketNumber,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (apiTicketId.present) {
      map['api_ticket_id'] = Variable<int>(apiTicketId.value);
    }
    if (customerKey.present) {
      map['customer_key'] = Variable<String>(customerKey.value);
    }
    if (ticketNumber.present) {
      map['ticket_number'] = Variable<String>(ticketNumber.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $ShopInBitTicketsTable.$convertercategory.toSql(category.value),
      );
    }
    if (requestDescription.present) {
      map['request_description'] = Variable<String>(requestDescription.value);
    }
    if (deliveryCountry.present) {
      map['delivery_country'] = Variable<String>(deliveryCountry.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ShopInBitTicketsTable.$converterstatus.toSql(status.value),
      );
    }
    if (statusRaw.present) {
      map['status_raw'] = Variable<String>(statusRaw.value);
    }
    if (offerProductName.present) {
      map['offer_product_name'] = Variable<String>(offerProductName.value);
    }
    if (offerPrice.present) {
      map['offer_price'] = Variable<String>(offerPrice.value);
    }
    if (paymentInvoiceStatus.present) {
      map['payment_invoice_status'] = Variable<String>(
        paymentInvoiceStatus.value,
      );
    }
    if (trackingLink.present) {
      map['tracking_link'] = Variable<String>(trackingLink.value);
    }
    if (lastAgentMessageAt.present) {
      map['last_agent_message_at'] = Variable<String>(
        $ShopInBitTicketsTable.$converterlastAgentMessageAtn.toSql(
          lastAgentMessageAt.value,
        ),
      );
    }
    if (feeTicketNumber.present) {
      map['fee_ticket_number'] = Variable<String>(feeTicketNumber.value);
    }
    if (messages.present) {
      map['messages'] = Variable<String>(
        $ShopInBitTicketsTable.$convertermessages.toSql(messages.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $ShopInBitTicketsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(
        $ShopInBitTicketsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<String>(
        $ShopInBitTicketsTable.$converterlastReadAtn.toSql(lastReadAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopInBitTicketsCompanion(')
          ..write('apiTicketId: $apiTicketId, ')
          ..write('customerKey: $customerKey, ')
          ..write('ticketNumber: $ticketNumber, ')
          ..write('category: $category, ')
          ..write('requestDescription: $requestDescription, ')
          ..write('deliveryCountry: $deliveryCountry, ')
          ..write('status: $status, ')
          ..write('statusRaw: $statusRaw, ')
          ..write('offerProductName: $offerProductName, ')
          ..write('offerPrice: $offerPrice, ')
          ..write('paymentInvoiceStatus: $paymentInvoiceStatus, ')
          ..write('trackingLink: $trackingLink, ')
          ..write('lastAgentMessageAt: $lastAgentMessageAt, ')
          ..write('feeTicketNumber: $feeTicketNumber, ')
          ..write('messages: $messages, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }
}

class $AppNotificationsTable extends AppNotifications
    with TableInfo<$AppNotificationsTable, AppNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppNotificationsTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<AppNotificationType, String>
  type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<AppNotificationType>($AppNotificationsTable.$convertertype);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(""),
  );
  static const VerificationMeta _iconAssetMeta = const VerificationMeta(
    'iconAsset',
  );
  @override
  late final GeneratedColumn<String> iconAsset = GeneratedColumn<String>(
    'icon_asset',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () =>
            ShopInBitTickets.dateConverter.toSql(DateTime.now()),
      ).withConverter<DateTime>($AppNotificationsTable.$convertercreatedAt);
  static const VerificationMeta _readMeta = const VerificationMeta('read');
  @override
  late final GeneratedColumn<bool> read = GeneratedColumn<bool>(
    'read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    body,
    iconAsset,
    createdAt,
    read,
    scopeId,
    targetId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppNotification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('icon_asset')) {
      context.handle(
        _iconAssetMeta,
        iconAsset.isAcceptableOrUnknown(data['icon_asset']!, _iconAssetMeta),
      );
    }
    if (data.containsKey('read')) {
      context.handle(
        _readMeta,
        read.isAcceptableOrUnknown(data['read']!, _readMeta),
      );
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppNotification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: $AppNotificationsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      iconAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_asset'],
      ),
      createdAt: $AppNotificationsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      read: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}read'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      ),
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      ),
    );
  }

  @override
  $AppNotificationsTable createAlias(String alias) {
    return $AppNotificationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AppNotificationType, String, String>
  $convertertype = const EnumNameConverter<AppNotificationType>(
    AppNotificationType.values,
  );
  static TypeConverter<DateTime, String> $convertercreatedAt =
      ShopInBitTickets.dateConverter;
}

class AppNotification extends DataClass implements Insertable<AppNotification> {
  final int id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? iconAsset;
  final DateTime createdAt;
  final bool read;
  final String? scopeId;
  final String? targetId;
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.iconAsset,
    required this.createdAt,
    required this.read,
    this.scopeId,
    this.targetId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['type'] = Variable<String>(
        $AppNotificationsTable.$convertertype.toSql(type),
      );
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || iconAsset != null) {
      map['icon_asset'] = Variable<String>(iconAsset);
    }
    {
      map['created_at'] = Variable<String>(
        $AppNotificationsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    map['read'] = Variable<bool>(read);
    if (!nullToAbsent || scopeId != null) {
      map['scope_id'] = Variable<String>(scopeId);
    }
    if (!nullToAbsent || targetId != null) {
      map['target_id'] = Variable<String>(targetId);
    }
    return map;
  }

  AppNotificationsCompanion toCompanion(bool nullToAbsent) {
    return AppNotificationsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      body: Value(body),
      iconAsset: iconAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(iconAsset),
      createdAt: Value(createdAt),
      read: Value(read),
      scopeId: scopeId == null && nullToAbsent
          ? const Value.absent()
          : Value(scopeId),
      targetId: targetId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetId),
    );
  }

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppNotification(
      id: serializer.fromJson<int>(json['id']),
      type: $AppNotificationsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      iconAsset: serializer.fromJson<String?>(json['iconAsset']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      read: serializer.fromJson<bool>(json['read']),
      scopeId: serializer.fromJson<String?>(json['scopeId']),
      targetId: serializer.fromJson<String?>(json['targetId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(
        $AppNotificationsTable.$convertertype.toJson(type),
      ),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'iconAsset': serializer.toJson<String?>(iconAsset),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'read': serializer.toJson<bool>(read),
      'scopeId': serializer.toJson<String?>(scopeId),
      'targetId': serializer.toJson<String?>(targetId),
    };
  }

  AppNotification copyWith({
    int? id,
    AppNotificationType? type,
    String? title,
    String? body,
    Value<String?> iconAsset = const Value.absent(),
    DateTime? createdAt,
    bool? read,
    Value<String?> scopeId = const Value.absent(),
    Value<String?> targetId = const Value.absent(),
  }) => AppNotification(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    iconAsset: iconAsset.present ? iconAsset.value : this.iconAsset,
    createdAt: createdAt ?? this.createdAt,
    read: read ?? this.read,
    scopeId: scopeId.present ? scopeId.value : this.scopeId,
    targetId: targetId.present ? targetId.value : this.targetId,
  );
  AppNotification copyWithCompanion(AppNotificationsCompanion data) {
    return AppNotification(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      iconAsset: data.iconAsset.present ? data.iconAsset.value : this.iconAsset,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      read: data.read.present ? data.read.value : this.read,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppNotification(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('iconAsset: $iconAsset, ')
          ..write('createdAt: $createdAt, ')
          ..write('read: $read, ')
          ..write('scopeId: $scopeId, ')
          ..write('targetId: $targetId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    body,
    iconAsset,
    createdAt,
    read,
    scopeId,
    targetId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotification &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.body == this.body &&
          other.iconAsset == this.iconAsset &&
          other.createdAt == this.createdAt &&
          other.read == this.read &&
          other.scopeId == this.scopeId &&
          other.targetId == this.targetId);
}

class AppNotificationsCompanion extends UpdateCompanion<AppNotification> {
  final Value<int> id;
  final Value<AppNotificationType> type;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> iconAsset;
  final Value<DateTime> createdAt;
  final Value<bool> read;
  final Value<String?> scopeId;
  final Value<String?> targetId;
  const AppNotificationsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.iconAsset = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.read = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.targetId = const Value.absent(),
  });
  AppNotificationsCompanion.insert({
    this.id = const Value.absent(),
    required AppNotificationType type,
    required String title,
    this.body = const Value.absent(),
    this.iconAsset = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.read = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.targetId = const Value.absent(),
  }) : type = Value(type),
       title = Value(title);
  static Insertable<AppNotification> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? iconAsset,
    Expression<String>? createdAt,
    Expression<bool>? read,
    Expression<String>? scopeId,
    Expression<String>? targetId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (iconAsset != null) 'icon_asset': iconAsset,
      if (createdAt != null) 'created_at': createdAt,
      if (read != null) 'read': read,
      if (scopeId != null) 'scope_id': scopeId,
      if (targetId != null) 'target_id': targetId,
    });
  }

  AppNotificationsCompanion copyWith({
    Value<int>? id,
    Value<AppNotificationType>? type,
    Value<String>? title,
    Value<String>? body,
    Value<String?>? iconAsset,
    Value<DateTime>? createdAt,
    Value<bool>? read,
    Value<String?>? scopeId,
    Value<String?>? targetId,
  }) {
    return AppNotificationsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      iconAsset: iconAsset ?? this.iconAsset,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      scopeId: scopeId ?? this.scopeId,
      targetId: targetId ?? this.targetId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AppNotificationsTable.$convertertype.toSql(type.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (iconAsset.present) {
      map['icon_asset'] = Variable<String>(iconAsset.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $AppNotificationsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (read.present) {
      map['read'] = Variable<bool>(read.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('iconAsset: $iconAsset, ')
          ..write('createdAt: $createdAt, ')
          ..write('read: $read, ')
          ..write('scopeId: $scopeId, ')
          ..write('targetId: $targetId')
          ..write(')'))
        .toString();
  }
}

abstract class _$SharedDatabase extends GeneratedDatabase {
  _$SharedDatabase(QueryExecutor e) : super(e);
  $SharedDatabaseManager get managers => $SharedDatabaseManager(this);
  late final $CakepayOrdersTable cakepayOrders = $CakepayOrdersTable(this);
  late final $ShopInBitSettingsTable shopInBitSettings =
      $ShopInBitSettingsTable(this);
  late final $ShopInBitTicketsTable shopInBitTickets = $ShopInBitTicketsTable(
    this,
  );
  late final $AppNotificationsTable appNotifications = $AppNotificationsTable(
    this,
  );
  late final Index appNotificationsScope = Index(
    'app_notifications_scope',
    'CREATE INDEX app_notifications_scope ON app_notifications (type, scope_id, read)',
  );
  late final Index appNotificationsTarget = Index(
    'app_notifications_target',
    'CREATE INDEX app_notifications_target ON app_notifications (type, target_id)',
  );
  late final ShopInBitSettingsDao shopInBitSettingsDao = ShopInBitSettingsDao(
    this as SharedDatabase,
  );
  late final ShopInBitTicketsDao shopInBitTicketsDao = ShopInBitTicketsDao(
    this as SharedDatabase,
  );
  late final AppNotificationsDao appNotificationsDao = AppNotificationsDao(
    this as SharedDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cakepayOrders,
    shopInBitSettings,
    shopInBitTickets,
    appNotifications,
    appNotificationsScope,
    appNotificationsTarget,
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
typedef $$ShopInBitSettingsTableCreateCompanionBuilder =
    ShopInBitSettingsCompanion Function({
      required String customerKey,
      Value<bool> privacyAccepted,
      Value<bool> conciergeGuidelinesAccepted,
      Value<bool> travelGuidelinesAccepted,
      Value<bool> carGuidelinesAccepted,
      Value<bool> setupComplete,
      Value<DateTime> createdAt,
      Value<DateTime> lastUsedAt,
    });
typedef $$ShopInBitSettingsTableUpdateCompanionBuilder =
    ShopInBitSettingsCompanion Function({
      Value<String> customerKey,
      Value<bool> privacyAccepted,
      Value<bool> conciergeGuidelinesAccepted,
      Value<bool> travelGuidelinesAccepted,
      Value<bool> carGuidelinesAccepted,
      Value<bool> setupComplete,
      Value<DateTime> createdAt,
      Value<DateTime> lastUsedAt,
    });

class $$ShopInBitSettingsTableFilterComposer
    extends Composer<_$SharedDatabase, $ShopInBitSettingsTable> {
  $$ShopInBitSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get customerKey => $composableBuilder(
    column: $table.customerKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get privacyAccepted => $composableBuilder(
    column: $table.privacyAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get conciergeGuidelinesAccepted => $composableBuilder(
    column: $table.conciergeGuidelinesAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get travelGuidelinesAccepted => $composableBuilder(
    column: $table.travelGuidelinesAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get carGuidelinesAccepted => $composableBuilder(
    column: $table.carGuidelinesAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get setupComplete => $composableBuilder(
    column: $table.setupComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShopInBitSettingsTableOrderingComposer
    extends Composer<_$SharedDatabase, $ShopInBitSettingsTable> {
  $$ShopInBitSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get customerKey => $composableBuilder(
    column: $table.customerKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get privacyAccepted => $composableBuilder(
    column: $table.privacyAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get conciergeGuidelinesAccepted => $composableBuilder(
    column: $table.conciergeGuidelinesAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get travelGuidelinesAccepted => $composableBuilder(
    column: $table.travelGuidelinesAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get carGuidelinesAccepted => $composableBuilder(
    column: $table.carGuidelinesAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get setupComplete => $composableBuilder(
    column: $table.setupComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShopInBitSettingsTableAnnotationComposer
    extends Composer<_$SharedDatabase, $ShopInBitSettingsTable> {
  $$ShopInBitSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get customerKey => $composableBuilder(
    column: $table.customerKey,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get privacyAccepted => $composableBuilder(
    column: $table.privacyAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get conciergeGuidelinesAccepted => $composableBuilder(
    column: $table.conciergeGuidelinesAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get travelGuidelinesAccepted => $composableBuilder(
    column: $table.travelGuidelinesAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get carGuidelinesAccepted => $composableBuilder(
    column: $table.carGuidelinesAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get setupComplete => $composableBuilder(
    column: $table.setupComplete,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$ShopInBitSettingsTableTableManager
    extends
        RootTableManager<
          _$SharedDatabase,
          $ShopInBitSettingsTable,
          ShopInBitSetting,
          $$ShopInBitSettingsTableFilterComposer,
          $$ShopInBitSettingsTableOrderingComposer,
          $$ShopInBitSettingsTableAnnotationComposer,
          $$ShopInBitSettingsTableCreateCompanionBuilder,
          $$ShopInBitSettingsTableUpdateCompanionBuilder,
          (
            ShopInBitSetting,
            BaseReferences<
              _$SharedDatabase,
              $ShopInBitSettingsTable,
              ShopInBitSetting
            >,
          ),
          ShopInBitSetting,
          PrefetchHooks Function()
        > {
  $$ShopInBitSettingsTableTableManager(
    _$SharedDatabase db,
    $ShopInBitSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShopInBitSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShopInBitSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShopInBitSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> customerKey = const Value.absent(),
                Value<bool> privacyAccepted = const Value.absent(),
                Value<bool> conciergeGuidelinesAccepted = const Value.absent(),
                Value<bool> travelGuidelinesAccepted = const Value.absent(),
                Value<bool> carGuidelinesAccepted = const Value.absent(),
                Value<bool> setupComplete = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
              }) => ShopInBitSettingsCompanion(
                customerKey: customerKey,
                privacyAccepted: privacyAccepted,
                conciergeGuidelinesAccepted: conciergeGuidelinesAccepted,
                travelGuidelinesAccepted: travelGuidelinesAccepted,
                carGuidelinesAccepted: carGuidelinesAccepted,
                setupComplete: setupComplete,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
              ),
          createCompanionCallback:
              ({
                required String customerKey,
                Value<bool> privacyAccepted = const Value.absent(),
                Value<bool> conciergeGuidelinesAccepted = const Value.absent(),
                Value<bool> travelGuidelinesAccepted = const Value.absent(),
                Value<bool> carGuidelinesAccepted = const Value.absent(),
                Value<bool> setupComplete = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
              }) => ShopInBitSettingsCompanion.insert(
                customerKey: customerKey,
                privacyAccepted: privacyAccepted,
                conciergeGuidelinesAccepted: conciergeGuidelinesAccepted,
                travelGuidelinesAccepted: travelGuidelinesAccepted,
                carGuidelinesAccepted: carGuidelinesAccepted,
                setupComplete: setupComplete,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShopInBitSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$SharedDatabase,
      $ShopInBitSettingsTable,
      ShopInBitSetting,
      $$ShopInBitSettingsTableFilterComposer,
      $$ShopInBitSettingsTableOrderingComposer,
      $$ShopInBitSettingsTableAnnotationComposer,
      $$ShopInBitSettingsTableCreateCompanionBuilder,
      $$ShopInBitSettingsTableUpdateCompanionBuilder,
      (
        ShopInBitSetting,
        BaseReferences<
          _$SharedDatabase,
          $ShopInBitSettingsTable,
          ShopInBitSetting
        >,
      ),
      ShopInBitSetting,
      PrefetchHooks Function()
    >;
typedef $$ShopInBitTicketsTableCreateCompanionBuilder =
    ShopInBitTicketsCompanion Function({
      required int apiTicketId,
      required String customerKey,
      required String ticketNumber,
      required ShopInBitCategory category,
      required String requestDescription,
      required String deliveryCountry,
      required ShopInBitOrderStatus status,
      required String statusRaw,
      Value<String?> offerProductName,
      Value<String?> offerPrice,
      Value<String?> paymentInvoiceStatus,
      Value<String?> trackingLink,
      Value<DateTime?> lastAgentMessageAt,
      Value<String?> feeTicketNumber,
      Value<List<TicketMessage>> messages,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastReadAt,
    });
typedef $$ShopInBitTicketsTableUpdateCompanionBuilder =
    ShopInBitTicketsCompanion Function({
      Value<int> apiTicketId,
      Value<String> customerKey,
      Value<String> ticketNumber,
      Value<ShopInBitCategory> category,
      Value<String> requestDescription,
      Value<String> deliveryCountry,
      Value<ShopInBitOrderStatus> status,
      Value<String> statusRaw,
      Value<String?> offerProductName,
      Value<String?> offerPrice,
      Value<String?> paymentInvoiceStatus,
      Value<String?> trackingLink,
      Value<DateTime?> lastAgentMessageAt,
      Value<String?> feeTicketNumber,
      Value<List<TicketMessage>> messages,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastReadAt,
    });

class $$ShopInBitTicketsTableFilterComposer
    extends Composer<_$SharedDatabase, $ShopInBitTicketsTable> {
  $$ShopInBitTicketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get apiTicketId => $composableBuilder(
    column: $table.apiTicketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerKey => $composableBuilder(
    column: $table.customerKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ticketNumber => $composableBuilder(
    column: $table.ticketNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ShopInBitCategory, ShopInBitCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get requestDescription => $composableBuilder(
    column: $table.requestDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryCountry => $composableBuilder(
    column: $table.deliveryCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ShopInBitOrderStatus,
    ShopInBitOrderStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get statusRaw => $composableBuilder(
    column: $table.statusRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get offerProductName => $composableBuilder(
    column: $table.offerProductName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get offerPrice => $composableBuilder(
    column: $table.offerPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentInvoiceStatus => $composableBuilder(
    column: $table.paymentInvoiceStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackingLink => $composableBuilder(
    column: $table.trackingLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get lastAgentMessageAt => $composableBuilder(
    column: $table.lastAgentMessageAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get feeTicketNumber => $composableBuilder(
    column: $table.feeTicketNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<TicketMessage>,
    List<TicketMessage>,
    String
  >
  get messages => $composableBuilder(
    column: $table.messages,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get lastReadAt =>
      $composableBuilder(
        column: $table.lastReadAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ShopInBitTicketsTableOrderingComposer
    extends Composer<_$SharedDatabase, $ShopInBitTicketsTable> {
  $$ShopInBitTicketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get apiTicketId => $composableBuilder(
    column: $table.apiTicketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerKey => $composableBuilder(
    column: $table.customerKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ticketNumber => $composableBuilder(
    column: $table.ticketNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestDescription => $composableBuilder(
    column: $table.requestDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryCountry => $composableBuilder(
    column: $table.deliveryCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusRaw => $composableBuilder(
    column: $table.statusRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get offerProductName => $composableBuilder(
    column: $table.offerProductName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get offerPrice => $composableBuilder(
    column: $table.offerPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentInvoiceStatus => $composableBuilder(
    column: $table.paymentInvoiceStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackingLink => $composableBuilder(
    column: $table.trackingLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAgentMessageAt => $composableBuilder(
    column: $table.lastAgentMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feeTicketNumber => $composableBuilder(
    column: $table.feeTicketNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messages => $composableBuilder(
    column: $table.messages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShopInBitTicketsTableAnnotationComposer
    extends Composer<_$SharedDatabase, $ShopInBitTicketsTable> {
  $$ShopInBitTicketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get apiTicketId => $composableBuilder(
    column: $table.apiTicketId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerKey => $composableBuilder(
    column: $table.customerKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ticketNumber => $composableBuilder(
    column: $table.ticketNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ShopInBitCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get requestDescription => $composableBuilder(
    column: $table.requestDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryCountry => $composableBuilder(
    column: $table.deliveryCountry,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ShopInBitOrderStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get statusRaw =>
      $composableBuilder(column: $table.statusRaw, builder: (column) => column);

  GeneratedColumn<String> get offerProductName => $composableBuilder(
    column: $table.offerProductName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get offerPrice => $composableBuilder(
    column: $table.offerPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentInvoiceStatus => $composableBuilder(
    column: $table.paymentInvoiceStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackingLink => $composableBuilder(
    column: $table.trackingLink,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, String> get lastAgentMessageAt =>
      $composableBuilder(
        column: $table.lastAgentMessageAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get feeTicketNumber => $composableBuilder(
    column: $table.feeTicketNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<TicketMessage>, String> get messages =>
      $composableBuilder(column: $table.messages, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get lastReadAt =>
      $composableBuilder(
        column: $table.lastReadAt,
        builder: (column) => column,
      );
}

class $$ShopInBitTicketsTableTableManager
    extends
        RootTableManager<
          _$SharedDatabase,
          $ShopInBitTicketsTable,
          ShopInBitTicket,
          $$ShopInBitTicketsTableFilterComposer,
          $$ShopInBitTicketsTableOrderingComposer,
          $$ShopInBitTicketsTableAnnotationComposer,
          $$ShopInBitTicketsTableCreateCompanionBuilder,
          $$ShopInBitTicketsTableUpdateCompanionBuilder,
          (
            ShopInBitTicket,
            BaseReferences<
              _$SharedDatabase,
              $ShopInBitTicketsTable,
              ShopInBitTicket
            >,
          ),
          ShopInBitTicket,
          PrefetchHooks Function()
        > {
  $$ShopInBitTicketsTableTableManager(
    _$SharedDatabase db,
    $ShopInBitTicketsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShopInBitTicketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShopInBitTicketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShopInBitTicketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> apiTicketId = const Value.absent(),
                Value<String> customerKey = const Value.absent(),
                Value<String> ticketNumber = const Value.absent(),
                Value<ShopInBitCategory> category = const Value.absent(),
                Value<String> requestDescription = const Value.absent(),
                Value<String> deliveryCountry = const Value.absent(),
                Value<ShopInBitOrderStatus> status = const Value.absent(),
                Value<String> statusRaw = const Value.absent(),
                Value<String?> offerProductName = const Value.absent(),
                Value<String?> offerPrice = const Value.absent(),
                Value<String?> paymentInvoiceStatus = const Value.absent(),
                Value<String?> trackingLink = const Value.absent(),
                Value<DateTime?> lastAgentMessageAt = const Value.absent(),
                Value<String?> feeTicketNumber = const Value.absent(),
                Value<List<TicketMessage>> messages = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
              }) => ShopInBitTicketsCompanion(
                apiTicketId: apiTicketId,
                customerKey: customerKey,
                ticketNumber: ticketNumber,
                category: category,
                requestDescription: requestDescription,
                deliveryCountry: deliveryCountry,
                status: status,
                statusRaw: statusRaw,
                offerProductName: offerProductName,
                offerPrice: offerPrice,
                paymentInvoiceStatus: paymentInvoiceStatus,
                trackingLink: trackingLink,
                lastAgentMessageAt: lastAgentMessageAt,
                feeTicketNumber: feeTicketNumber,
                messages: messages,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastReadAt: lastReadAt,
              ),
          createCompanionCallback:
              ({
                required int apiTicketId,
                required String customerKey,
                required String ticketNumber,
                required ShopInBitCategory category,
                required String requestDescription,
                required String deliveryCountry,
                required ShopInBitOrderStatus status,
                required String statusRaw,
                Value<String?> offerProductName = const Value.absent(),
                Value<String?> offerPrice = const Value.absent(),
                Value<String?> paymentInvoiceStatus = const Value.absent(),
                Value<String?> trackingLink = const Value.absent(),
                Value<DateTime?> lastAgentMessageAt = const Value.absent(),
                Value<String?> feeTicketNumber = const Value.absent(),
                Value<List<TicketMessage>> messages = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
              }) => ShopInBitTicketsCompanion.insert(
                apiTicketId: apiTicketId,
                customerKey: customerKey,
                ticketNumber: ticketNumber,
                category: category,
                requestDescription: requestDescription,
                deliveryCountry: deliveryCountry,
                status: status,
                statusRaw: statusRaw,
                offerProductName: offerProductName,
                offerPrice: offerPrice,
                paymentInvoiceStatus: paymentInvoiceStatus,
                trackingLink: trackingLink,
                lastAgentMessageAt: lastAgentMessageAt,
                feeTicketNumber: feeTicketNumber,
                messages: messages,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastReadAt: lastReadAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShopInBitTicketsTableProcessedTableManager =
    ProcessedTableManager<
      _$SharedDatabase,
      $ShopInBitTicketsTable,
      ShopInBitTicket,
      $$ShopInBitTicketsTableFilterComposer,
      $$ShopInBitTicketsTableOrderingComposer,
      $$ShopInBitTicketsTableAnnotationComposer,
      $$ShopInBitTicketsTableCreateCompanionBuilder,
      $$ShopInBitTicketsTableUpdateCompanionBuilder,
      (
        ShopInBitTicket,
        BaseReferences<
          _$SharedDatabase,
          $ShopInBitTicketsTable,
          ShopInBitTicket
        >,
      ),
      ShopInBitTicket,
      PrefetchHooks Function()
    >;
typedef $$AppNotificationsTableCreateCompanionBuilder =
    AppNotificationsCompanion Function({
      Value<int> id,
      required AppNotificationType type,
      required String title,
      Value<String> body,
      Value<String?> iconAsset,
      Value<DateTime> createdAt,
      Value<bool> read,
      Value<String?> scopeId,
      Value<String?> targetId,
    });
typedef $$AppNotificationsTableUpdateCompanionBuilder =
    AppNotificationsCompanion Function({
      Value<int> id,
      Value<AppNotificationType> type,
      Value<String> title,
      Value<String> body,
      Value<String?> iconAsset,
      Value<DateTime> createdAt,
      Value<bool> read,
      Value<String?> scopeId,
      Value<String?> targetId,
    });

class $$AppNotificationsTableFilterComposer
    extends Composer<_$SharedDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<
    AppNotificationType,
    AppNotificationType,
    String
  >
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconAsset => $composableBuilder(
    column: $table.iconAsset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppNotificationsTableOrderingComposer
    extends Composer<_$SharedDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconAsset => $composableBuilder(
    column: $table.iconAsset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get read => $composableBuilder(
    column: $table.read,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppNotificationsTableAnnotationComposer
    extends Composer<_$SharedDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AppNotificationType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get iconAsset =>
      $composableBuilder(column: $table.iconAsset, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get read =>
      $composableBuilder(column: $table.read, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);
}

class $$AppNotificationsTableTableManager
    extends
        RootTableManager<
          _$SharedDatabase,
          $AppNotificationsTable,
          AppNotification,
          $$AppNotificationsTableFilterComposer,
          $$AppNotificationsTableOrderingComposer,
          $$AppNotificationsTableAnnotationComposer,
          $$AppNotificationsTableCreateCompanionBuilder,
          $$AppNotificationsTableUpdateCompanionBuilder,
          (
            AppNotification,
            BaseReferences<
              _$SharedDatabase,
              $AppNotificationsTable,
              AppNotification
            >,
          ),
          AppNotification,
          PrefetchHooks Function()
        > {
  $$AppNotificationsTableTableManager(
    _$SharedDatabase db,
    $AppNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppNotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<AppNotificationType> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> iconAsset = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> read = const Value.absent(),
                Value<String?> scopeId = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
              }) => AppNotificationsCompanion(
                id: id,
                type: type,
                title: title,
                body: body,
                iconAsset: iconAsset,
                createdAt: createdAt,
                read: read,
                scopeId: scopeId,
                targetId: targetId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required AppNotificationType type,
                required String title,
                Value<String> body = const Value.absent(),
                Value<String?> iconAsset = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> read = const Value.absent(),
                Value<String?> scopeId = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
              }) => AppNotificationsCompanion.insert(
                id: id,
                type: type,
                title: title,
                body: body,
                iconAsset: iconAsset,
                createdAt: createdAt,
                read: read,
                scopeId: scopeId,
                targetId: targetId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$SharedDatabase,
      $AppNotificationsTable,
      AppNotification,
      $$AppNotificationsTableFilterComposer,
      $$AppNotificationsTableOrderingComposer,
      $$AppNotificationsTableAnnotationComposer,
      $$AppNotificationsTableCreateCompanionBuilder,
      $$AppNotificationsTableUpdateCompanionBuilder,
      (
        AppNotification,
        BaseReferences<
          _$SharedDatabase,
          $AppNotificationsTable,
          AppNotification
        >,
      ),
      AppNotification,
      PrefetchHooks Function()
    >;

class $SharedDatabaseManager {
  final _$SharedDatabase _db;
  $SharedDatabaseManager(this._db);
  $$CakepayOrdersTableTableManager get cakepayOrders =>
      $$CakepayOrdersTableTableManager(_db, _db.cakepayOrders);
  $$ShopInBitSettingsTableTableManager get shopInBitSettings =>
      $$ShopInBitSettingsTableTableManager(_db, _db.shopInBitSettings);
  $$ShopInBitTicketsTableTableManager get shopInBitTickets =>
      $$ShopInBitTicketsTableTableManager(_db, _db.shopInBitTickets);
  $$AppNotificationsTableTableManager get appNotifications =>
      $$AppNotificationsTableTableManager(_db, _db.appNotifications);
}

mixin _$ShopInBitSettingsDaoMixin on DatabaseAccessor<SharedDatabase> {
  $ShopInBitSettingsTable get shopInBitSettings =>
      attachedDatabase.shopInBitSettings;
  ShopInBitSettingsDaoManager get managers => ShopInBitSettingsDaoManager(this);
}

class ShopInBitSettingsDaoManager {
  final _$ShopInBitSettingsDaoMixin _db;
  ShopInBitSettingsDaoManager(this._db);
  $$ShopInBitSettingsTableTableManager get shopInBitSettings =>
      $$ShopInBitSettingsTableTableManager(
        _db.attachedDatabase,
        _db.shopInBitSettings,
      );
}

mixin _$ShopInBitTicketsDaoMixin on DatabaseAccessor<SharedDatabase> {
  $ShopInBitTicketsTable get shopInBitTickets =>
      attachedDatabase.shopInBitTickets;
  ShopInBitTicketsDaoManager get managers => ShopInBitTicketsDaoManager(this);
}

class ShopInBitTicketsDaoManager {
  final _$ShopInBitTicketsDaoMixin _db;
  ShopInBitTicketsDaoManager(this._db);
  $$ShopInBitTicketsTableTableManager get shopInBitTickets =>
      $$ShopInBitTicketsTableTableManager(
        _db.attachedDatabase,
        _db.shopInBitTickets,
      );
}

mixin _$AppNotificationsDaoMixin on DatabaseAccessor<SharedDatabase> {
  $AppNotificationsTable get appNotifications =>
      attachedDatabase.appNotifications;
  AppNotificationsDaoManager get managers => AppNotificationsDaoManager(this);
}

class AppNotificationsDaoManager {
  final _$AppNotificationsDaoMixin _db;
  AppNotificationsDaoManager(this._db);
  $$AppNotificationsTableTableManager get appNotifications =>
      $$AppNotificationsTableTableManager(
        _db.attachedDatabase,
        _db.appNotifications,
      );
}

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

class $ShopInBitTicketsTable extends ShopInBitTickets
    with TableInfo<$ShopInBitTicketsTable, ShopInBitTicket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopInBitTicketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ticketIdMeta = const VerificationMeta(
    'ticketId',
  );
  @override
  late final GeneratedColumn<String> ticketId = GeneratedColumn<String>(
    'ticket_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ShopInBitCategory, int> category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ShopInBitCategory>(
        $ShopInBitTicketsTable.$convertercategory,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ShopInBitOrderStatus, int>
  status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ShopInBitOrderStatus>(
        $ShopInBitTicketsTable.$converterstatus,
      );
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
  static const VerificationMeta _shippingNameMeta = const VerificationMeta(
    'shippingName',
  );
  @override
  late final GeneratedColumn<String> shippingName = GeneratedColumn<String>(
    'shipping_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shippingStreetMeta = const VerificationMeta(
    'shippingStreet',
  );
  @override
  late final GeneratedColumn<String> shippingStreet = GeneratedColumn<String>(
    'shipping_street',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shippingCityMeta = const VerificationMeta(
    'shippingCity',
  );
  @override
  late final GeneratedColumn<String> shippingCity = GeneratedColumn<String>(
    'shipping_city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shippingPostalCodeMeta =
      const VerificationMeta('shippingPostalCode');
  @override
  late final GeneratedColumn<String> shippingPostalCode =
      GeneratedColumn<String>(
        'shipping_postal_code',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _shippingCountryMeta = const VerificationMeta(
    'shippingCountry',
  );
  @override
  late final GeneratedColumn<String> shippingCountry = GeneratedColumn<String>(
    'shipping_country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    List<ShopInBitTicketMessage>,
    String
  >
  messages =
      GeneratedColumn<String>(
        'messages',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<ShopInBitTicketMessage>>(
        $ShopInBitTicketsTable.$convertermessages,
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
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _carResearchInvoiceIdMeta =
      const VerificationMeta('carResearchInvoiceId');
  @override
  late final GeneratedColumn<String> carResearchInvoiceId =
      GeneratedColumn<String>(
        'car_research_invoice_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
  static const VerificationMeta _needsCreateRequestMeta =
      const VerificationMeta('needsCreateRequest');
  @override
  late final GeneratedColumn<bool> needsCreateRequest = GeneratedColumn<bool>(
    'needs_create_request',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_create_request" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isPendingPaymentMeta = const VerificationMeta(
    'isPendingPayment',
  );
  @override
  late final GeneratedColumn<bool> isPendingPayment = GeneratedColumn<bool>(
    'is_pending_payment',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_payment" IN (0, 1))',
    ),
  );
  static const VerificationMeta _carResearchExpiresAtMeta =
      const VerificationMeta('carResearchExpiresAt');
  @override
  late final GeneratedColumn<DateTime> carResearchExpiresAt =
      GeneratedColumn<DateTime>(
        'car_research_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _carResearchPaymentLinksMeta =
      const VerificationMeta('carResearchPaymentLinks');
  @override
  late final GeneratedColumn<String> carResearchPaymentLinks =
      GeneratedColumn<String>(
        'car_research_payment_links',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    ticketId,
    displayName,
    category,
    status,
    requestDescription,
    deliveryCountry,
    offerProductName,
    offerPrice,
    shippingName,
    shippingStreet,
    shippingCity,
    shippingPostalCode,
    shippingCountry,
    paymentMethod,
    messages,
    createdAt,
    apiTicketId,
    carResearchInvoiceId,
    feeTicketNumber,
    needsCreateRequest,
    isPendingPayment,
    carResearchExpiresAt,
    carResearchPaymentLinks,
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
    if (data.containsKey('ticket_id')) {
      context.handle(
        _ticketIdMeta,
        ticketId.isAcceptableOrUnknown(data['ticket_id']!, _ticketIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ticketIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
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
    if (data.containsKey('shipping_name')) {
      context.handle(
        _shippingNameMeta,
        shippingName.isAcceptableOrUnknown(
          data['shipping_name']!,
          _shippingNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shippingNameMeta);
    }
    if (data.containsKey('shipping_street')) {
      context.handle(
        _shippingStreetMeta,
        shippingStreet.isAcceptableOrUnknown(
          data['shipping_street']!,
          _shippingStreetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shippingStreetMeta);
    }
    if (data.containsKey('shipping_city')) {
      context.handle(
        _shippingCityMeta,
        shippingCity.isAcceptableOrUnknown(
          data['shipping_city']!,
          _shippingCityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shippingCityMeta);
    }
    if (data.containsKey('shipping_postal_code')) {
      context.handle(
        _shippingPostalCodeMeta,
        shippingPostalCode.isAcceptableOrUnknown(
          data['shipping_postal_code']!,
          _shippingPostalCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shippingPostalCodeMeta);
    }
    if (data.containsKey('shipping_country')) {
      context.handle(
        _shippingCountryMeta,
        shippingCountry.isAcceptableOrUnknown(
          data['shipping_country']!,
          _shippingCountryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shippingCountryMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
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
    if (data.containsKey('car_research_invoice_id')) {
      context.handle(
        _carResearchInvoiceIdMeta,
        carResearchInvoiceId.isAcceptableOrUnknown(
          data['car_research_invoice_id']!,
          _carResearchInvoiceIdMeta,
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
    if (data.containsKey('needs_create_request')) {
      context.handle(
        _needsCreateRequestMeta,
        needsCreateRequest.isAcceptableOrUnknown(
          data['needs_create_request']!,
          _needsCreateRequestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_needsCreateRequestMeta);
    }
    if (data.containsKey('is_pending_payment')) {
      context.handle(
        _isPendingPaymentMeta,
        isPendingPayment.isAcceptableOrUnknown(
          data['is_pending_payment']!,
          _isPendingPaymentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isPendingPaymentMeta);
    }
    if (data.containsKey('car_research_expires_at')) {
      context.handle(
        _carResearchExpiresAtMeta,
        carResearchExpiresAt.isAcceptableOrUnknown(
          data['car_research_expires_at']!,
          _carResearchExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('car_research_payment_links')) {
      context.handle(
        _carResearchPaymentLinksMeta,
        carResearchPaymentLinks.isAcceptableOrUnknown(
          data['car_research_payment_links']!,
          _carResearchPaymentLinksMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ticketId};
  @override
  ShopInBitTicket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShopInBitTicket(
      ticketId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      category: $ShopInBitTicketsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      status: $ShopInBitTicketsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
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
      offerProductName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offer_product_name'],
      ),
      offerPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offer_price'],
      ),
      shippingName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shipping_name'],
      )!,
      shippingStreet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shipping_street'],
      )!,
      shippingCity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shipping_city'],
      )!,
      shippingPostalCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shipping_postal_code'],
      )!,
      shippingCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shipping_country'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      messages: $ShopInBitTicketsTable.$convertermessages.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}messages'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      apiTicketId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}api_ticket_id'],
      )!,
      carResearchInvoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}car_research_invoice_id'],
      ),
      feeTicketNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fee_ticket_number'],
      ),
      needsCreateRequest: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_create_request'],
      )!,
      isPendingPayment: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_payment'],
      )!,
      carResearchExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}car_research_expires_at'],
      ),
      carResearchPaymentLinks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}car_research_payment_links'],
      ),
    );
  }

  @override
  $ShopInBitTicketsTable createAlias(String alias) {
    return $ShopInBitTicketsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ShopInBitCategory, int, int> $convertercategory =
      const EnumIndexConverter<ShopInBitCategory>(ShopInBitCategory.values);
  static JsonTypeConverter2<ShopInBitOrderStatus, int, int> $converterstatus =
      const EnumIndexConverter<ShopInBitOrderStatus>(
        ShopInBitOrderStatus.values,
      );
  static JsonTypeConverter2<List<ShopInBitTicketMessage>, String, List<dynamic>>
  $convertermessages = const ShopInBitTicketMessagesConverter();
}

class ShopInBitTicket extends DataClass implements Insertable<ShopInBitTicket> {
  final String ticketId;
  final String displayName;
  final ShopInBitCategory category;
  final ShopInBitOrderStatus status;
  final String requestDescription;
  final String deliveryCountry;
  final String? offerProductName;
  final String? offerPrice;
  final String shippingName;
  final String shippingStreet;
  final String shippingCity;
  final String shippingPostalCode;
  final String shippingCountry;
  final String? paymentMethod;
  final List<ShopInBitTicketMessage> messages;
  final DateTime createdAt;
  final int apiTicketId;
  final String? carResearchInvoiceId;
  final String? feeTicketNumber;
  final bool needsCreateRequest;
  final bool isPendingPayment;
  final DateTime? carResearchExpiresAt;
  final String? carResearchPaymentLinks;
  const ShopInBitTicket({
    required this.ticketId,
    required this.displayName,
    required this.category,
    required this.status,
    required this.requestDescription,
    required this.deliveryCountry,
    this.offerProductName,
    this.offerPrice,
    required this.shippingName,
    required this.shippingStreet,
    required this.shippingCity,
    required this.shippingPostalCode,
    required this.shippingCountry,
    this.paymentMethod,
    required this.messages,
    required this.createdAt,
    required this.apiTicketId,
    this.carResearchInvoiceId,
    this.feeTicketNumber,
    required this.needsCreateRequest,
    required this.isPendingPayment,
    this.carResearchExpiresAt,
    this.carResearchPaymentLinks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ticket_id'] = Variable<String>(ticketId);
    map['display_name'] = Variable<String>(displayName);
    {
      map['category'] = Variable<int>(
        $ShopInBitTicketsTable.$convertercategory.toSql(category),
      );
    }
    {
      map['status'] = Variable<int>(
        $ShopInBitTicketsTable.$converterstatus.toSql(status),
      );
    }
    map['request_description'] = Variable<String>(requestDescription);
    map['delivery_country'] = Variable<String>(deliveryCountry);
    if (!nullToAbsent || offerProductName != null) {
      map['offer_product_name'] = Variable<String>(offerProductName);
    }
    if (!nullToAbsent || offerPrice != null) {
      map['offer_price'] = Variable<String>(offerPrice);
    }
    map['shipping_name'] = Variable<String>(shippingName);
    map['shipping_street'] = Variable<String>(shippingStreet);
    map['shipping_city'] = Variable<String>(shippingCity);
    map['shipping_postal_code'] = Variable<String>(shippingPostalCode);
    map['shipping_country'] = Variable<String>(shippingCountry);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    {
      map['messages'] = Variable<String>(
        $ShopInBitTicketsTable.$convertermessages.toSql(messages),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['api_ticket_id'] = Variable<int>(apiTicketId);
    if (!nullToAbsent || carResearchInvoiceId != null) {
      map['car_research_invoice_id'] = Variable<String>(carResearchInvoiceId);
    }
    if (!nullToAbsent || feeTicketNumber != null) {
      map['fee_ticket_number'] = Variable<String>(feeTicketNumber);
    }
    map['needs_create_request'] = Variable<bool>(needsCreateRequest);
    map['is_pending_payment'] = Variable<bool>(isPendingPayment);
    if (!nullToAbsent || carResearchExpiresAt != null) {
      map['car_research_expires_at'] = Variable<DateTime>(carResearchExpiresAt);
    }
    if (!nullToAbsent || carResearchPaymentLinks != null) {
      map['car_research_payment_links'] = Variable<String>(
        carResearchPaymentLinks,
      );
    }
    return map;
  }

  ShopInBitTicketsCompanion toCompanion(bool nullToAbsent) {
    return ShopInBitTicketsCompanion(
      ticketId: Value(ticketId),
      displayName: Value(displayName),
      category: Value(category),
      status: Value(status),
      requestDescription: Value(requestDescription),
      deliveryCountry: Value(deliveryCountry),
      offerProductName: offerProductName == null && nullToAbsent
          ? const Value.absent()
          : Value(offerProductName),
      offerPrice: offerPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(offerPrice),
      shippingName: Value(shippingName),
      shippingStreet: Value(shippingStreet),
      shippingCity: Value(shippingCity),
      shippingPostalCode: Value(shippingPostalCode),
      shippingCountry: Value(shippingCountry),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      messages: Value(messages),
      createdAt: Value(createdAt),
      apiTicketId: Value(apiTicketId),
      carResearchInvoiceId: carResearchInvoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(carResearchInvoiceId),
      feeTicketNumber: feeTicketNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(feeTicketNumber),
      needsCreateRequest: Value(needsCreateRequest),
      isPendingPayment: Value(isPendingPayment),
      carResearchExpiresAt: carResearchExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(carResearchExpiresAt),
      carResearchPaymentLinks: carResearchPaymentLinks == null && nullToAbsent
          ? const Value.absent()
          : Value(carResearchPaymentLinks),
    );
  }

  factory ShopInBitTicket.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShopInBitTicket(
      ticketId: serializer.fromJson<String>(json['ticketId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      category: $ShopInBitTicketsTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      status: $ShopInBitTicketsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      requestDescription: serializer.fromJson<String>(
        json['requestDescription'],
      ),
      deliveryCountry: serializer.fromJson<String>(json['deliveryCountry']),
      offerProductName: serializer.fromJson<String?>(json['offerProductName']),
      offerPrice: serializer.fromJson<String?>(json['offerPrice']),
      shippingName: serializer.fromJson<String>(json['shippingName']),
      shippingStreet: serializer.fromJson<String>(json['shippingStreet']),
      shippingCity: serializer.fromJson<String>(json['shippingCity']),
      shippingPostalCode: serializer.fromJson<String>(
        json['shippingPostalCode'],
      ),
      shippingCountry: serializer.fromJson<String>(json['shippingCountry']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      messages: $ShopInBitTicketsTable.$convertermessages.fromJson(
        serializer.fromJson<List<dynamic>>(json['messages']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      apiTicketId: serializer.fromJson<int>(json['apiTicketId']),
      carResearchInvoiceId: serializer.fromJson<String?>(
        json['carResearchInvoiceId'],
      ),
      feeTicketNumber: serializer.fromJson<String?>(json['feeTicketNumber']),
      needsCreateRequest: serializer.fromJson<bool>(json['needsCreateRequest']),
      isPendingPayment: serializer.fromJson<bool>(json['isPendingPayment']),
      carResearchExpiresAt: serializer.fromJson<DateTime?>(
        json['carResearchExpiresAt'],
      ),
      carResearchPaymentLinks: serializer.fromJson<String?>(
        json['carResearchPaymentLinks'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ticketId': serializer.toJson<String>(ticketId),
      'displayName': serializer.toJson<String>(displayName),
      'category': serializer.toJson<int>(
        $ShopInBitTicketsTable.$convertercategory.toJson(category),
      ),
      'status': serializer.toJson<int>(
        $ShopInBitTicketsTable.$converterstatus.toJson(status),
      ),
      'requestDescription': serializer.toJson<String>(requestDescription),
      'deliveryCountry': serializer.toJson<String>(deliveryCountry),
      'offerProductName': serializer.toJson<String?>(offerProductName),
      'offerPrice': serializer.toJson<String?>(offerPrice),
      'shippingName': serializer.toJson<String>(shippingName),
      'shippingStreet': serializer.toJson<String>(shippingStreet),
      'shippingCity': serializer.toJson<String>(shippingCity),
      'shippingPostalCode': serializer.toJson<String>(shippingPostalCode),
      'shippingCountry': serializer.toJson<String>(shippingCountry),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'messages': serializer.toJson<List<dynamic>>(
        $ShopInBitTicketsTable.$convertermessages.toJson(messages),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'apiTicketId': serializer.toJson<int>(apiTicketId),
      'carResearchInvoiceId': serializer.toJson<String?>(carResearchInvoiceId),
      'feeTicketNumber': serializer.toJson<String?>(feeTicketNumber),
      'needsCreateRequest': serializer.toJson<bool>(needsCreateRequest),
      'isPendingPayment': serializer.toJson<bool>(isPendingPayment),
      'carResearchExpiresAt': serializer.toJson<DateTime?>(
        carResearchExpiresAt,
      ),
      'carResearchPaymentLinks': serializer.toJson<String?>(
        carResearchPaymentLinks,
      ),
    };
  }

  ShopInBitTicket copyWith({
    String? ticketId,
    String? displayName,
    ShopInBitCategory? category,
    ShopInBitOrderStatus? status,
    String? requestDescription,
    String? deliveryCountry,
    Value<String?> offerProductName = const Value.absent(),
    Value<String?> offerPrice = const Value.absent(),
    String? shippingName,
    String? shippingStreet,
    String? shippingCity,
    String? shippingPostalCode,
    String? shippingCountry,
    Value<String?> paymentMethod = const Value.absent(),
    List<ShopInBitTicketMessage>? messages,
    DateTime? createdAt,
    int? apiTicketId,
    Value<String?> carResearchInvoiceId = const Value.absent(),
    Value<String?> feeTicketNumber = const Value.absent(),
    bool? needsCreateRequest,
    bool? isPendingPayment,
    Value<DateTime?> carResearchExpiresAt = const Value.absent(),
    Value<String?> carResearchPaymentLinks = const Value.absent(),
  }) => ShopInBitTicket(
    ticketId: ticketId ?? this.ticketId,
    displayName: displayName ?? this.displayName,
    category: category ?? this.category,
    status: status ?? this.status,
    requestDescription: requestDescription ?? this.requestDescription,
    deliveryCountry: deliveryCountry ?? this.deliveryCountry,
    offerProductName: offerProductName.present
        ? offerProductName.value
        : this.offerProductName,
    offerPrice: offerPrice.present ? offerPrice.value : this.offerPrice,
    shippingName: shippingName ?? this.shippingName,
    shippingStreet: shippingStreet ?? this.shippingStreet,
    shippingCity: shippingCity ?? this.shippingCity,
    shippingPostalCode: shippingPostalCode ?? this.shippingPostalCode,
    shippingCountry: shippingCountry ?? this.shippingCountry,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    messages: messages ?? this.messages,
    createdAt: createdAt ?? this.createdAt,
    apiTicketId: apiTicketId ?? this.apiTicketId,
    carResearchInvoiceId: carResearchInvoiceId.present
        ? carResearchInvoiceId.value
        : this.carResearchInvoiceId,
    feeTicketNumber: feeTicketNumber.present
        ? feeTicketNumber.value
        : this.feeTicketNumber,
    needsCreateRequest: needsCreateRequest ?? this.needsCreateRequest,
    isPendingPayment: isPendingPayment ?? this.isPendingPayment,
    carResearchExpiresAt: carResearchExpiresAt.present
        ? carResearchExpiresAt.value
        : this.carResearchExpiresAt,
    carResearchPaymentLinks: carResearchPaymentLinks.present
        ? carResearchPaymentLinks.value
        : this.carResearchPaymentLinks,
  );
  ShopInBitTicket copyWithCompanion(ShopInBitTicketsCompanion data) {
    return ShopInBitTicket(
      ticketId: data.ticketId.present ? data.ticketId.value : this.ticketId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
      requestDescription: data.requestDescription.present
          ? data.requestDescription.value
          : this.requestDescription,
      deliveryCountry: data.deliveryCountry.present
          ? data.deliveryCountry.value
          : this.deliveryCountry,
      offerProductName: data.offerProductName.present
          ? data.offerProductName.value
          : this.offerProductName,
      offerPrice: data.offerPrice.present
          ? data.offerPrice.value
          : this.offerPrice,
      shippingName: data.shippingName.present
          ? data.shippingName.value
          : this.shippingName,
      shippingStreet: data.shippingStreet.present
          ? data.shippingStreet.value
          : this.shippingStreet,
      shippingCity: data.shippingCity.present
          ? data.shippingCity.value
          : this.shippingCity,
      shippingPostalCode: data.shippingPostalCode.present
          ? data.shippingPostalCode.value
          : this.shippingPostalCode,
      shippingCountry: data.shippingCountry.present
          ? data.shippingCountry.value
          : this.shippingCountry,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      messages: data.messages.present ? data.messages.value : this.messages,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      apiTicketId: data.apiTicketId.present
          ? data.apiTicketId.value
          : this.apiTicketId,
      carResearchInvoiceId: data.carResearchInvoiceId.present
          ? data.carResearchInvoiceId.value
          : this.carResearchInvoiceId,
      feeTicketNumber: data.feeTicketNumber.present
          ? data.feeTicketNumber.value
          : this.feeTicketNumber,
      needsCreateRequest: data.needsCreateRequest.present
          ? data.needsCreateRequest.value
          : this.needsCreateRequest,
      isPendingPayment: data.isPendingPayment.present
          ? data.isPendingPayment.value
          : this.isPendingPayment,
      carResearchExpiresAt: data.carResearchExpiresAt.present
          ? data.carResearchExpiresAt.value
          : this.carResearchExpiresAt,
      carResearchPaymentLinks: data.carResearchPaymentLinks.present
          ? data.carResearchPaymentLinks.value
          : this.carResearchPaymentLinks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShopInBitTicket(')
          ..write('ticketId: $ticketId, ')
          ..write('displayName: $displayName, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('requestDescription: $requestDescription, ')
          ..write('deliveryCountry: $deliveryCountry, ')
          ..write('offerProductName: $offerProductName, ')
          ..write('offerPrice: $offerPrice, ')
          ..write('shippingName: $shippingName, ')
          ..write('shippingStreet: $shippingStreet, ')
          ..write('shippingCity: $shippingCity, ')
          ..write('shippingPostalCode: $shippingPostalCode, ')
          ..write('shippingCountry: $shippingCountry, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('messages: $messages, ')
          ..write('createdAt: $createdAt, ')
          ..write('apiTicketId: $apiTicketId, ')
          ..write('carResearchInvoiceId: $carResearchInvoiceId, ')
          ..write('feeTicketNumber: $feeTicketNumber, ')
          ..write('needsCreateRequest: $needsCreateRequest, ')
          ..write('isPendingPayment: $isPendingPayment, ')
          ..write('carResearchExpiresAt: $carResearchExpiresAt, ')
          ..write('carResearchPaymentLinks: $carResearchPaymentLinks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    ticketId,
    displayName,
    category,
    status,
    requestDescription,
    deliveryCountry,
    offerProductName,
    offerPrice,
    shippingName,
    shippingStreet,
    shippingCity,
    shippingPostalCode,
    shippingCountry,
    paymentMethod,
    messages,
    createdAt,
    apiTicketId,
    carResearchInvoiceId,
    feeTicketNumber,
    needsCreateRequest,
    isPendingPayment,
    carResearchExpiresAt,
    carResearchPaymentLinks,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShopInBitTicket &&
          other.ticketId == this.ticketId &&
          other.displayName == this.displayName &&
          other.category == this.category &&
          other.status == this.status &&
          other.requestDescription == this.requestDescription &&
          other.deliveryCountry == this.deliveryCountry &&
          other.offerProductName == this.offerProductName &&
          other.offerPrice == this.offerPrice &&
          other.shippingName == this.shippingName &&
          other.shippingStreet == this.shippingStreet &&
          other.shippingCity == this.shippingCity &&
          other.shippingPostalCode == this.shippingPostalCode &&
          other.shippingCountry == this.shippingCountry &&
          other.paymentMethod == this.paymentMethod &&
          other.messages == this.messages &&
          other.createdAt == this.createdAt &&
          other.apiTicketId == this.apiTicketId &&
          other.carResearchInvoiceId == this.carResearchInvoiceId &&
          other.feeTicketNumber == this.feeTicketNumber &&
          other.needsCreateRequest == this.needsCreateRequest &&
          other.isPendingPayment == this.isPendingPayment &&
          other.carResearchExpiresAt == this.carResearchExpiresAt &&
          other.carResearchPaymentLinks == this.carResearchPaymentLinks);
}

class ShopInBitTicketsCompanion extends UpdateCompanion<ShopInBitTicket> {
  final Value<String> ticketId;
  final Value<String> displayName;
  final Value<ShopInBitCategory> category;
  final Value<ShopInBitOrderStatus> status;
  final Value<String> requestDescription;
  final Value<String> deliveryCountry;
  final Value<String?> offerProductName;
  final Value<String?> offerPrice;
  final Value<String> shippingName;
  final Value<String> shippingStreet;
  final Value<String> shippingCity;
  final Value<String> shippingPostalCode;
  final Value<String> shippingCountry;
  final Value<String?> paymentMethod;
  final Value<List<ShopInBitTicketMessage>> messages;
  final Value<DateTime> createdAt;
  final Value<int> apiTicketId;
  final Value<String?> carResearchInvoiceId;
  final Value<String?> feeTicketNumber;
  final Value<bool> needsCreateRequest;
  final Value<bool> isPendingPayment;
  final Value<DateTime?> carResearchExpiresAt;
  final Value<String?> carResearchPaymentLinks;
  final Value<int> rowid;
  const ShopInBitTicketsCompanion({
    this.ticketId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.requestDescription = const Value.absent(),
    this.deliveryCountry = const Value.absent(),
    this.offerProductName = const Value.absent(),
    this.offerPrice = const Value.absent(),
    this.shippingName = const Value.absent(),
    this.shippingStreet = const Value.absent(),
    this.shippingCity = const Value.absent(),
    this.shippingPostalCode = const Value.absent(),
    this.shippingCountry = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.messages = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.apiTicketId = const Value.absent(),
    this.carResearchInvoiceId = const Value.absent(),
    this.feeTicketNumber = const Value.absent(),
    this.needsCreateRequest = const Value.absent(),
    this.isPendingPayment = const Value.absent(),
    this.carResearchExpiresAt = const Value.absent(),
    this.carResearchPaymentLinks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShopInBitTicketsCompanion.insert({
    required String ticketId,
    required String displayName,
    required ShopInBitCategory category,
    required ShopInBitOrderStatus status,
    required String requestDescription,
    required String deliveryCountry,
    this.offerProductName = const Value.absent(),
    this.offerPrice = const Value.absent(),
    required String shippingName,
    required String shippingStreet,
    required String shippingCity,
    required String shippingPostalCode,
    required String shippingCountry,
    this.paymentMethod = const Value.absent(),
    required List<ShopInBitTicketMessage> messages,
    required DateTime createdAt,
    required int apiTicketId,
    this.carResearchInvoiceId = const Value.absent(),
    this.feeTicketNumber = const Value.absent(),
    required bool needsCreateRequest,
    required bool isPendingPayment,
    this.carResearchExpiresAt = const Value.absent(),
    this.carResearchPaymentLinks = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ticketId = Value(ticketId),
       displayName = Value(displayName),
       category = Value(category),
       status = Value(status),
       requestDescription = Value(requestDescription),
       deliveryCountry = Value(deliveryCountry),
       shippingName = Value(shippingName),
       shippingStreet = Value(shippingStreet),
       shippingCity = Value(shippingCity),
       shippingPostalCode = Value(shippingPostalCode),
       shippingCountry = Value(shippingCountry),
       messages = Value(messages),
       createdAt = Value(createdAt),
       apiTicketId = Value(apiTicketId),
       needsCreateRequest = Value(needsCreateRequest),
       isPendingPayment = Value(isPendingPayment);
  static Insertable<ShopInBitTicket> custom({
    Expression<String>? ticketId,
    Expression<String>? displayName,
    Expression<int>? category,
    Expression<int>? status,
    Expression<String>? requestDescription,
    Expression<String>? deliveryCountry,
    Expression<String>? offerProductName,
    Expression<String>? offerPrice,
    Expression<String>? shippingName,
    Expression<String>? shippingStreet,
    Expression<String>? shippingCity,
    Expression<String>? shippingPostalCode,
    Expression<String>? shippingCountry,
    Expression<String>? paymentMethod,
    Expression<String>? messages,
    Expression<DateTime>? createdAt,
    Expression<int>? apiTicketId,
    Expression<String>? carResearchInvoiceId,
    Expression<String>? feeTicketNumber,
    Expression<bool>? needsCreateRequest,
    Expression<bool>? isPendingPayment,
    Expression<DateTime>? carResearchExpiresAt,
    Expression<String>? carResearchPaymentLinks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ticketId != null) 'ticket_id': ticketId,
      if (displayName != null) 'display_name': displayName,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (requestDescription != null) 'request_description': requestDescription,
      if (deliveryCountry != null) 'delivery_country': deliveryCountry,
      if (offerProductName != null) 'offer_product_name': offerProductName,
      if (offerPrice != null) 'offer_price': offerPrice,
      if (shippingName != null) 'shipping_name': shippingName,
      if (shippingStreet != null) 'shipping_street': shippingStreet,
      if (shippingCity != null) 'shipping_city': shippingCity,
      if (shippingPostalCode != null)
        'shipping_postal_code': shippingPostalCode,
      if (shippingCountry != null) 'shipping_country': shippingCountry,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (messages != null) 'messages': messages,
      if (createdAt != null) 'created_at': createdAt,
      if (apiTicketId != null) 'api_ticket_id': apiTicketId,
      if (carResearchInvoiceId != null)
        'car_research_invoice_id': carResearchInvoiceId,
      if (feeTicketNumber != null) 'fee_ticket_number': feeTicketNumber,
      if (needsCreateRequest != null)
        'needs_create_request': needsCreateRequest,
      if (isPendingPayment != null) 'is_pending_payment': isPendingPayment,
      if (carResearchExpiresAt != null)
        'car_research_expires_at': carResearchExpiresAt,
      if (carResearchPaymentLinks != null)
        'car_research_payment_links': carResearchPaymentLinks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShopInBitTicketsCompanion copyWith({
    Value<String>? ticketId,
    Value<String>? displayName,
    Value<ShopInBitCategory>? category,
    Value<ShopInBitOrderStatus>? status,
    Value<String>? requestDescription,
    Value<String>? deliveryCountry,
    Value<String?>? offerProductName,
    Value<String?>? offerPrice,
    Value<String>? shippingName,
    Value<String>? shippingStreet,
    Value<String>? shippingCity,
    Value<String>? shippingPostalCode,
    Value<String>? shippingCountry,
    Value<String?>? paymentMethod,
    Value<List<ShopInBitTicketMessage>>? messages,
    Value<DateTime>? createdAt,
    Value<int>? apiTicketId,
    Value<String?>? carResearchInvoiceId,
    Value<String?>? feeTicketNumber,
    Value<bool>? needsCreateRequest,
    Value<bool>? isPendingPayment,
    Value<DateTime?>? carResearchExpiresAt,
    Value<String?>? carResearchPaymentLinks,
    Value<int>? rowid,
  }) {
    return ShopInBitTicketsCompanion(
      ticketId: ticketId ?? this.ticketId,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      status: status ?? this.status,
      requestDescription: requestDescription ?? this.requestDescription,
      deliveryCountry: deliveryCountry ?? this.deliveryCountry,
      offerProductName: offerProductName ?? this.offerProductName,
      offerPrice: offerPrice ?? this.offerPrice,
      shippingName: shippingName ?? this.shippingName,
      shippingStreet: shippingStreet ?? this.shippingStreet,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingPostalCode: shippingPostalCode ?? this.shippingPostalCode,
      shippingCountry: shippingCountry ?? this.shippingCountry,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      apiTicketId: apiTicketId ?? this.apiTicketId,
      carResearchInvoiceId: carResearchInvoiceId ?? this.carResearchInvoiceId,
      feeTicketNumber: feeTicketNumber ?? this.feeTicketNumber,
      needsCreateRequest: needsCreateRequest ?? this.needsCreateRequest,
      isPendingPayment: isPendingPayment ?? this.isPendingPayment,
      carResearchExpiresAt: carResearchExpiresAt ?? this.carResearchExpiresAt,
      carResearchPaymentLinks:
          carResearchPaymentLinks ?? this.carResearchPaymentLinks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ticketId.present) {
      map['ticket_id'] = Variable<String>(ticketId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $ShopInBitTicketsTable.$convertercategory.toSql(category.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $ShopInBitTicketsTable.$converterstatus.toSql(status.value),
      );
    }
    if (requestDescription.present) {
      map['request_description'] = Variable<String>(requestDescription.value);
    }
    if (deliveryCountry.present) {
      map['delivery_country'] = Variable<String>(deliveryCountry.value);
    }
    if (offerProductName.present) {
      map['offer_product_name'] = Variable<String>(offerProductName.value);
    }
    if (offerPrice.present) {
      map['offer_price'] = Variable<String>(offerPrice.value);
    }
    if (shippingName.present) {
      map['shipping_name'] = Variable<String>(shippingName.value);
    }
    if (shippingStreet.present) {
      map['shipping_street'] = Variable<String>(shippingStreet.value);
    }
    if (shippingCity.present) {
      map['shipping_city'] = Variable<String>(shippingCity.value);
    }
    if (shippingPostalCode.present) {
      map['shipping_postal_code'] = Variable<String>(shippingPostalCode.value);
    }
    if (shippingCountry.present) {
      map['shipping_country'] = Variable<String>(shippingCountry.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (messages.present) {
      map['messages'] = Variable<String>(
        $ShopInBitTicketsTable.$convertermessages.toSql(messages.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (apiTicketId.present) {
      map['api_ticket_id'] = Variable<int>(apiTicketId.value);
    }
    if (carResearchInvoiceId.present) {
      map['car_research_invoice_id'] = Variable<String>(
        carResearchInvoiceId.value,
      );
    }
    if (feeTicketNumber.present) {
      map['fee_ticket_number'] = Variable<String>(feeTicketNumber.value);
    }
    if (needsCreateRequest.present) {
      map['needs_create_request'] = Variable<bool>(needsCreateRequest.value);
    }
    if (isPendingPayment.present) {
      map['is_pending_payment'] = Variable<bool>(isPendingPayment.value);
    }
    if (carResearchExpiresAt.present) {
      map['car_research_expires_at'] = Variable<DateTime>(
        carResearchExpiresAt.value,
      );
    }
    if (carResearchPaymentLinks.present) {
      map['car_research_payment_links'] = Variable<String>(
        carResearchPaymentLinks.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopInBitTicketsCompanion(')
          ..write('ticketId: $ticketId, ')
          ..write('displayName: $displayName, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('requestDescription: $requestDescription, ')
          ..write('deliveryCountry: $deliveryCountry, ')
          ..write('offerProductName: $offerProductName, ')
          ..write('offerPrice: $offerPrice, ')
          ..write('shippingName: $shippingName, ')
          ..write('shippingStreet: $shippingStreet, ')
          ..write('shippingCity: $shippingCity, ')
          ..write('shippingPostalCode: $shippingPostalCode, ')
          ..write('shippingCountry: $shippingCountry, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('messages: $messages, ')
          ..write('createdAt: $createdAt, ')
          ..write('apiTicketId: $apiTicketId, ')
          ..write('carResearchInvoiceId: $carResearchInvoiceId, ')
          ..write('feeTicketNumber: $feeTicketNumber, ')
          ..write('needsCreateRequest: $needsCreateRequest, ')
          ..write('isPendingPayment: $isPendingPayment, ')
          ..write('carResearchExpiresAt: $carResearchExpiresAt, ')
          ..write('carResearchPaymentLinks: $carResearchPaymentLinks, ')
          ..write('rowid: $rowid')
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
  late final $ShopInBitTicketsTable shopInBitTickets = $ShopInBitTicketsTable(
    this,
  );
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
    shopInBitTickets,
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
typedef $$ShopInBitTicketsTableCreateCompanionBuilder =
    ShopInBitTicketsCompanion Function({
      required String ticketId,
      required String displayName,
      required ShopInBitCategory category,
      required ShopInBitOrderStatus status,
      required String requestDescription,
      required String deliveryCountry,
      Value<String?> offerProductName,
      Value<String?> offerPrice,
      required String shippingName,
      required String shippingStreet,
      required String shippingCity,
      required String shippingPostalCode,
      required String shippingCountry,
      Value<String?> paymentMethod,
      required List<ShopInBitTicketMessage> messages,
      required DateTime createdAt,
      required int apiTicketId,
      Value<String?> carResearchInvoiceId,
      Value<String?> feeTicketNumber,
      required bool needsCreateRequest,
      required bool isPendingPayment,
      Value<DateTime?> carResearchExpiresAt,
      Value<String?> carResearchPaymentLinks,
      Value<int> rowid,
    });
typedef $$ShopInBitTicketsTableUpdateCompanionBuilder =
    ShopInBitTicketsCompanion Function({
      Value<String> ticketId,
      Value<String> displayName,
      Value<ShopInBitCategory> category,
      Value<ShopInBitOrderStatus> status,
      Value<String> requestDescription,
      Value<String> deliveryCountry,
      Value<String?> offerProductName,
      Value<String?> offerPrice,
      Value<String> shippingName,
      Value<String> shippingStreet,
      Value<String> shippingCity,
      Value<String> shippingPostalCode,
      Value<String> shippingCountry,
      Value<String?> paymentMethod,
      Value<List<ShopInBitTicketMessage>> messages,
      Value<DateTime> createdAt,
      Value<int> apiTicketId,
      Value<String?> carResearchInvoiceId,
      Value<String?> feeTicketNumber,
      Value<bool> needsCreateRequest,
      Value<bool> isPendingPayment,
      Value<DateTime?> carResearchExpiresAt,
      Value<String?> carResearchPaymentLinks,
      Value<int> rowid,
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
  ColumnFilters<String> get ticketId => $composableBuilder(
    column: $table.ticketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ShopInBitCategory, ShopInBitCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ShopInBitOrderStatus,
    ShopInBitOrderStatus,
    int
  >
  get status => $composableBuilder(
    column: $table.status,
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

  ColumnFilters<String> get offerProductName => $composableBuilder(
    column: $table.offerProductName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get offerPrice => $composableBuilder(
    column: $table.offerPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shippingName => $composableBuilder(
    column: $table.shippingName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shippingStreet => $composableBuilder(
    column: $table.shippingStreet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shippingCity => $composableBuilder(
    column: $table.shippingCity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shippingPostalCode => $composableBuilder(
    column: $table.shippingPostalCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shippingCountry => $composableBuilder(
    column: $table.shippingCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<ShopInBitTicketMessage>,
    List<ShopInBitTicketMessage>,
    String
  >
  get messages => $composableBuilder(
    column: $table.messages,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get apiTicketId => $composableBuilder(
    column: $table.apiTicketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carResearchInvoiceId => $composableBuilder(
    column: $table.carResearchInvoiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feeTicketNumber => $composableBuilder(
    column: $table.feeTicketNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsCreateRequest => $composableBuilder(
    column: $table.needsCreateRequest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingPayment => $composableBuilder(
    column: $table.isPendingPayment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get carResearchExpiresAt => $composableBuilder(
    column: $table.carResearchExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carResearchPaymentLinks => $composableBuilder(
    column: $table.carResearchPaymentLinks,
    builder: (column) => ColumnFilters(column),
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
  ColumnOrderings<String> get ticketId => $composableBuilder(
    column: $table.ticketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
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

  ColumnOrderings<String> get offerProductName => $composableBuilder(
    column: $table.offerProductName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get offerPrice => $composableBuilder(
    column: $table.offerPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shippingName => $composableBuilder(
    column: $table.shippingName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shippingStreet => $composableBuilder(
    column: $table.shippingStreet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shippingCity => $composableBuilder(
    column: $table.shippingCity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shippingPostalCode => $composableBuilder(
    column: $table.shippingPostalCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shippingCountry => $composableBuilder(
    column: $table.shippingCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messages => $composableBuilder(
    column: $table.messages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get apiTicketId => $composableBuilder(
    column: $table.apiTicketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carResearchInvoiceId => $composableBuilder(
    column: $table.carResearchInvoiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feeTicketNumber => $composableBuilder(
    column: $table.feeTicketNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsCreateRequest => $composableBuilder(
    column: $table.needsCreateRequest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingPayment => $composableBuilder(
    column: $table.isPendingPayment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get carResearchExpiresAt => $composableBuilder(
    column: $table.carResearchExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carResearchPaymentLinks => $composableBuilder(
    column: $table.carResearchPaymentLinks,
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
  GeneratedColumn<String> get ticketId =>
      $composableBuilder(column: $table.ticketId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ShopInBitCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ShopInBitOrderStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get requestDescription => $composableBuilder(
    column: $table.requestDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryCountry => $composableBuilder(
    column: $table.deliveryCountry,
    builder: (column) => column,
  );

  GeneratedColumn<String> get offerProductName => $composableBuilder(
    column: $table.offerProductName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get offerPrice => $composableBuilder(
    column: $table.offerPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shippingName => $composableBuilder(
    column: $table.shippingName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shippingStreet => $composableBuilder(
    column: $table.shippingStreet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shippingCity => $composableBuilder(
    column: $table.shippingCity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shippingPostalCode => $composableBuilder(
    column: $table.shippingPostalCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shippingCountry => $composableBuilder(
    column: $table.shippingCountry,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<ShopInBitTicketMessage>, String>
  get messages =>
      $composableBuilder(column: $table.messages, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get apiTicketId => $composableBuilder(
    column: $table.apiTicketId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get carResearchInvoiceId => $composableBuilder(
    column: $table.carResearchInvoiceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feeTicketNumber => $composableBuilder(
    column: $table.feeTicketNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsCreateRequest => $composableBuilder(
    column: $table.needsCreateRequest,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingPayment => $composableBuilder(
    column: $table.isPendingPayment,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get carResearchExpiresAt => $composableBuilder(
    column: $table.carResearchExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get carResearchPaymentLinks => $composableBuilder(
    column: $table.carResearchPaymentLinks,
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
                Value<String> ticketId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<ShopInBitCategory> category = const Value.absent(),
                Value<ShopInBitOrderStatus> status = const Value.absent(),
                Value<String> requestDescription = const Value.absent(),
                Value<String> deliveryCountry = const Value.absent(),
                Value<String?> offerProductName = const Value.absent(),
                Value<String?> offerPrice = const Value.absent(),
                Value<String> shippingName = const Value.absent(),
                Value<String> shippingStreet = const Value.absent(),
                Value<String> shippingCity = const Value.absent(),
                Value<String> shippingPostalCode = const Value.absent(),
                Value<String> shippingCountry = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<List<ShopInBitTicketMessage>> messages =
                    const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> apiTicketId = const Value.absent(),
                Value<String?> carResearchInvoiceId = const Value.absent(),
                Value<String?> feeTicketNumber = const Value.absent(),
                Value<bool> needsCreateRequest = const Value.absent(),
                Value<bool> isPendingPayment = const Value.absent(),
                Value<DateTime?> carResearchExpiresAt = const Value.absent(),
                Value<String?> carResearchPaymentLinks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShopInBitTicketsCompanion(
                ticketId: ticketId,
                displayName: displayName,
                category: category,
                status: status,
                requestDescription: requestDescription,
                deliveryCountry: deliveryCountry,
                offerProductName: offerProductName,
                offerPrice: offerPrice,
                shippingName: shippingName,
                shippingStreet: shippingStreet,
                shippingCity: shippingCity,
                shippingPostalCode: shippingPostalCode,
                shippingCountry: shippingCountry,
                paymentMethod: paymentMethod,
                messages: messages,
                createdAt: createdAt,
                apiTicketId: apiTicketId,
                carResearchInvoiceId: carResearchInvoiceId,
                feeTicketNumber: feeTicketNumber,
                needsCreateRequest: needsCreateRequest,
                isPendingPayment: isPendingPayment,
                carResearchExpiresAt: carResearchExpiresAt,
                carResearchPaymentLinks: carResearchPaymentLinks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ticketId,
                required String displayName,
                required ShopInBitCategory category,
                required ShopInBitOrderStatus status,
                required String requestDescription,
                required String deliveryCountry,
                Value<String?> offerProductName = const Value.absent(),
                Value<String?> offerPrice = const Value.absent(),
                required String shippingName,
                required String shippingStreet,
                required String shippingCity,
                required String shippingPostalCode,
                required String shippingCountry,
                Value<String?> paymentMethod = const Value.absent(),
                required List<ShopInBitTicketMessage> messages,
                required DateTime createdAt,
                required int apiTicketId,
                Value<String?> carResearchInvoiceId = const Value.absent(),
                Value<String?> feeTicketNumber = const Value.absent(),
                required bool needsCreateRequest,
                required bool isPendingPayment,
                Value<DateTime?> carResearchExpiresAt = const Value.absent(),
                Value<String?> carResearchPaymentLinks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShopInBitTicketsCompanion.insert(
                ticketId: ticketId,
                displayName: displayName,
                category: category,
                status: status,
                requestDescription: requestDescription,
                deliveryCountry: deliveryCountry,
                offerProductName: offerProductName,
                offerPrice: offerPrice,
                shippingName: shippingName,
                shippingStreet: shippingStreet,
                shippingCity: shippingCity,
                shippingPostalCode: shippingPostalCode,
                shippingCountry: shippingCountry,
                paymentMethod: paymentMethod,
                messages: messages,
                createdAt: createdAt,
                apiTicketId: apiTicketId,
                carResearchInvoiceId: carResearchInvoiceId,
                feeTicketNumber: feeTicketNumber,
                needsCreateRequest: needsCreateRequest,
                isPendingPayment: isPendingPayment,
                carResearchExpiresAt: carResearchExpiresAt,
                carResearchPaymentLinks: carResearchPaymentLinks,
                rowid: rowid,
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

class $SharedDatabaseManager {
  final _$SharedDatabase _db;
  $SharedDatabaseManager(this._db);
  $$CakepayOrdersTableTableManager get cakepayOrders =>
      $$CakepayOrdersTableTableManager(_db, _db.cakepayOrders);
  $$ShopinBitSettingsTableTableManager get shopinBitSettings =>
      $$ShopinBitSettingsTableTableManager(_db, _db.shopinBitSettings);
  $$ShopInBitTicketsTableTableManager get shopInBitTickets =>
      $$ShopInBitTicketsTableTableManager(_db, _db.shopInBitTickets);
}

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

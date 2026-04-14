// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopinbit_ticket.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetShopInBitTicketCollection on Isar {
  IsarCollection<ShopInBitTicket> get shopInBitTickets => this.collection();
}

const ShopInBitTicketSchema = CollectionSchema(
  name: r'ShopInBitTicket',
  id: 1968691807160517649,
  properties: {
    r'apiTicketId': PropertySchema(
      id: 0,
      name: r'apiTicketId',
      type: IsarType.long,
    ),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.byte,
      enumMap: _ShopInBitTicketcategoryEnumValueMap,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deliveryCountry': PropertySchema(
      id: 3,
      name: r'deliveryCountry',
      type: IsarType.string,
    ),
    r'displayName': PropertySchema(
      id: 4,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'messages': PropertySchema(
      id: 5,
      name: r'messages',
      type: IsarType.objectList,

      target: r'ShopInBitTicketMessage',
    ),
    r'offerPrice': PropertySchema(
      id: 6,
      name: r'offerPrice',
      type: IsarType.string,
    ),
    r'offerProductName': PropertySchema(
      id: 7,
      name: r'offerProductName',
      type: IsarType.string,
    ),
    r'paymentMethod': PropertySchema(
      id: 8,
      name: r'paymentMethod',
      type: IsarType.string,
    ),
    r'requestDescription': PropertySchema(
      id: 9,
      name: r'requestDescription',
      type: IsarType.string,
    ),
    r'shippingCity': PropertySchema(
      id: 10,
      name: r'shippingCity',
      type: IsarType.string,
    ),
    r'shippingCountry': PropertySchema(
      id: 11,
      name: r'shippingCountry',
      type: IsarType.string,
    ),
    r'shippingName': PropertySchema(
      id: 12,
      name: r'shippingName',
      type: IsarType.string,
    ),
    r'shippingPostalCode': PropertySchema(
      id: 13,
      name: r'shippingPostalCode',
      type: IsarType.string,
    ),
    r'shippingStreet': PropertySchema(
      id: 14,
      name: r'shippingStreet',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 15,
      name: r'status',
      type: IsarType.byte,
      enumMap: _ShopInBitTicketstatusEnumValueMap,
    ),
    r'ticketId': PropertySchema(
      id: 16,
      name: r'ticketId',
      type: IsarType.string,
    ),
    r'carResearchInvoiceId': PropertySchema(
      id: 17,
      name: r'carResearchInvoiceId',
      type: IsarType.string,
    ),
    r'feeTicketNumber': PropertySchema(
      id: 18,
      name: r'feeTicketNumber',
      type: IsarType.string,
    ),
    r'needsCreateRequest': PropertySchema(
      id: 19,
      name: r'needsCreateRequest',
      type: IsarType.bool,
    ),
    r'isPendingPayment': PropertySchema(
      id: 20,
      name: r'isPendingPayment',
      type: IsarType.bool,
    ),
    r'carResearchExpiresAt': PropertySchema(
      id: 21,
      name: r'carResearchExpiresAt',
      type: IsarType.dateTime,
    ),
    r'carResearchPaymentLinks': PropertySchema(
      id: 22,
      name: r'carResearchPaymentLinks',
      type: IsarType.string,
    ),
  },

  estimateSize: _shopInBitTicketEstimateSize,
  serialize: _shopInBitTicketSerialize,
  deserialize: _shopInBitTicketDeserialize,
  deserializeProp: _shopInBitTicketDeserializeProp,
  idName: r'id',
  indexes: {
    r'ticketId': IndexSchema(
      id: -6483959237056329942,
      name: r'ticketId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'ticketId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {r'ShopInBitTicketMessage': ShopInBitTicketMessageSchema},

  getId: _shopInBitTicketGetId,
  getLinks: _shopInBitTicketGetLinks,
  attach: _shopInBitTicketAttach,
  version: '3.3.0-dev.2',
);

int _shopInBitTicketEstimateSize(
  ShopInBitTicket object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deliveryCountry.length * 3;
  bytesCount += 3 + object.displayName.length * 3;
  bytesCount += 3 + object.messages.length * 3;
  {
    final offsets = allOffsets[ShopInBitTicketMessage]!;
    for (var i = 0; i < object.messages.length; i++) {
      final value = object.messages[i];
      bytesCount += ShopInBitTicketMessageSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  {
    final value = object.offerPrice;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.offerProductName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentMethod;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.requestDescription.length * 3;
  bytesCount += 3 + object.shippingCity.length * 3;
  bytesCount += 3 + object.shippingCountry.length * 3;
  bytesCount += 3 + object.shippingName.length * 3;
  bytesCount += 3 + object.shippingPostalCode.length * 3;
  bytesCount += 3 + object.shippingStreet.length * 3;
  bytesCount += 3 + object.ticketId.length * 3;
  {
    final value = object.carResearchInvoiceId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.feeTicketNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.carResearchPaymentLinks;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _shopInBitTicketSerialize(
  ShopInBitTicket object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.apiTicketId);
  writer.writeByte(offsets[1], object.category.index);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.deliveryCountry);
  writer.writeString(offsets[4], object.displayName);
  writer.writeObjectList<ShopInBitTicketMessage>(
    offsets[5],
    allOffsets,
    ShopInBitTicketMessageSchema.serialize,
    object.messages,
  );
  writer.writeString(offsets[6], object.offerPrice);
  writer.writeString(offsets[7], object.offerProductName);
  writer.writeString(offsets[8], object.paymentMethod);
  writer.writeString(offsets[9], object.requestDescription);
  writer.writeString(offsets[10], object.shippingCity);
  writer.writeString(offsets[11], object.shippingCountry);
  writer.writeString(offsets[12], object.shippingName);
  writer.writeString(offsets[13], object.shippingPostalCode);
  writer.writeString(offsets[14], object.shippingStreet);
  writer.writeByte(offsets[15], object.status.index);
  writer.writeString(offsets[16], object.ticketId);
  writer.writeString(offsets[17], object.carResearchInvoiceId);
  writer.writeString(offsets[18], object.feeTicketNumber);
  writer.writeBool(offsets[19], object.needsCreateRequest);
  writer.writeBool(offsets[20], object.isPendingPayment);
  writer.writeDateTime(offsets[21], object.carResearchExpiresAt);
  writer.writeString(offsets[22], object.carResearchPaymentLinks);
}

ShopInBitTicket _shopInBitTicketDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ShopInBitTicket();
  object.apiTicketId = reader.readLong(offsets[0]);
  object.category =
      _ShopInBitTicketcategoryValueEnumMap[reader.readByteOrNull(offsets[1])] ??
      ShopInBitCategory.concierge;
  object.createdAt = reader.readDateTime(offsets[2]);
  object.deliveryCountry = reader.readString(offsets[3]);
  object.displayName = reader.readString(offsets[4]);
  object.id = id;
  object.messages =
      reader.readObjectList<ShopInBitTicketMessage>(
        offsets[5],
        ShopInBitTicketMessageSchema.deserialize,
        allOffsets,
        ShopInBitTicketMessage(),
      ) ??
      [];
  object.offerPrice = reader.readStringOrNull(offsets[6]);
  object.offerProductName = reader.readStringOrNull(offsets[7]);
  object.paymentMethod = reader.readStringOrNull(offsets[8]);
  object.requestDescription = reader.readString(offsets[9]);
  object.shippingCity = reader.readString(offsets[10]);
  object.shippingCountry = reader.readString(offsets[11]);
  object.shippingName = reader.readString(offsets[12]);
  object.shippingPostalCode = reader.readString(offsets[13]);
  object.shippingStreet = reader.readString(offsets[14]);
  object.status =
      _ShopInBitTicketstatusValueEnumMap[reader.readByteOrNull(offsets[15])] ??
      ShopInBitOrderStatus.pending;
  object.ticketId = reader.readString(offsets[16]);
  object.carResearchInvoiceId = reader.readStringOrNull(offsets[17]);
  object.feeTicketNumber = reader.readStringOrNull(offsets[18]);
  object.needsCreateRequest = reader.readBool(offsets[19]);
  object.isPendingPayment = reader.readBool(offsets[20]);
  object.carResearchExpiresAt = reader.readDateTimeOrNull(offsets[21]);
  object.carResearchPaymentLinks = reader.readStringOrNull(offsets[22]);
  return object;
}

P _shopInBitTicketDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (_ShopInBitTicketcategoryValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              ShopInBitCategory.concierge)
          as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readObjectList<ShopInBitTicketMessage>(
                offset,
                ShopInBitTicketMessageSchema.deserialize,
                allOffsets,
                ShopInBitTicketMessage(),
              ) ??
              [])
          as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (_ShopInBitTicketstatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              ShopInBitOrderStatus.pending)
          as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readBool(offset)) as P;
    case 20:
      return (reader.readBool(offset)) as P;
    case 21:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ShopInBitTicketcategoryEnumValueMap = {
  'concierge': 0,
  'travel': 1,
  'car': 2,
};
const _ShopInBitTicketcategoryValueEnumMap = {
  0: ShopInBitCategory.concierge,
  1: ShopInBitCategory.travel,
  2: ShopInBitCategory.car,
};
const _ShopInBitTicketstatusEnumValueMap = {
  'pending': 0,
  'reviewing': 1,
  'offerAvailable': 2,
  'accepted': 3,
  'paymentPending': 4,
  'paid': 5,
  'shipping': 6,
  'delivered': 7,
  'closed': 8,
  'cancelled': 9,
  'refunded': 10,
};
const _ShopInBitTicketstatusValueEnumMap = {
  0: ShopInBitOrderStatus.pending,
  1: ShopInBitOrderStatus.reviewing,
  2: ShopInBitOrderStatus.offerAvailable,
  3: ShopInBitOrderStatus.accepted,
  4: ShopInBitOrderStatus.paymentPending,
  5: ShopInBitOrderStatus.paid,
  6: ShopInBitOrderStatus.shipping,
  7: ShopInBitOrderStatus.delivered,
  8: ShopInBitOrderStatus.closed,
  9: ShopInBitOrderStatus.cancelled,
  10: ShopInBitOrderStatus.refunded,
};

Id _shopInBitTicketGetId(ShopInBitTicket object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _shopInBitTicketGetLinks(ShopInBitTicket object) {
  return [];
}

void _shopInBitTicketAttach(
  IsarCollection<dynamic> col,
  Id id,
  ShopInBitTicket object,
) {
  object.id = id;
}

extension ShopInBitTicketByIndex on IsarCollection<ShopInBitTicket> {
  Future<ShopInBitTicket?> getByTicketId(String ticketId) {
    return getByIndex(r'ticketId', [ticketId]);
  }

  ShopInBitTicket? getByTicketIdSync(String ticketId) {
    return getByIndexSync(r'ticketId', [ticketId]);
  }

  Future<bool> deleteByTicketId(String ticketId) {
    return deleteByIndex(r'ticketId', [ticketId]);
  }

  bool deleteByTicketIdSync(String ticketId) {
    return deleteByIndexSync(r'ticketId', [ticketId]);
  }

  Future<List<ShopInBitTicket?>> getAllByTicketId(List<String> ticketIdValues) {
    final values = ticketIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'ticketId', values);
  }

  List<ShopInBitTicket?> getAllByTicketIdSync(List<String> ticketIdValues) {
    final values = ticketIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'ticketId', values);
  }

  Future<int> deleteAllByTicketId(List<String> ticketIdValues) {
    final values = ticketIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'ticketId', values);
  }

  int deleteAllByTicketIdSync(List<String> ticketIdValues) {
    final values = ticketIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'ticketId', values);
  }

  Future<Id> putByTicketId(ShopInBitTicket object) {
    return putByIndex(r'ticketId', object);
  }

  Id putByTicketIdSync(ShopInBitTicket object, {bool saveLinks = true}) {
    return putByIndexSync(r'ticketId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTicketId(List<ShopInBitTicket> objects) {
    return putAllByIndex(r'ticketId', objects);
  }

  List<Id> putAllByTicketIdSync(
    List<ShopInBitTicket> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'ticketId', objects, saveLinks: saveLinks);
  }
}

extension ShopInBitTicketQueryWhereSort
    on QueryBuilder<ShopInBitTicket, ShopInBitTicket, QWhere> {
  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ShopInBitTicketQueryWhere
    on QueryBuilder<ShopInBitTicket, ShopInBitTicket, QWhereClause> {
  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterWhereClause>
  ticketIdEqualTo(String ticketId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'ticketId', value: [ticketId]),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterWhereClause>
  ticketIdNotEqualTo(String ticketId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ticketId',
                lower: [],
                upper: [ticketId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ticketId',
                lower: [ticketId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ticketId',
                lower: [ticketId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ticketId',
                lower: [],
                upper: [ticketId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension ShopInBitTicketQueryFilter
    on QueryBuilder<ShopInBitTicket, ShopInBitTicket, QFilterCondition> {
  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  apiTicketIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'apiTicketId', value: value),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  apiTicketIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'apiTicketId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  apiTicketIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'apiTicketId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  apiTicketIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'apiTicketId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  categoryEqualTo(ShopInBitCategory value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: value),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  categoryGreaterThan(ShopInBitCategory value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  categoryLessThan(ShopInBitCategory value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  categoryBetween(
    ShopInBitCategory lower,
    ShopInBitCategory upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'deliveryCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deliveryCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deliveryCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deliveryCountry',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'deliveryCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'deliveryCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'deliveryCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'deliveryCountry',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deliveryCountry', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  deliveryCountryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deliveryCountry', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'displayName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'displayName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'displayName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'displayName', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  messagesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'messages', length, true, length, true);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  messagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'messages', 0, true, 0, true);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  messagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'messages', 0, false, 999999, true);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  messagesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'messages', 0, true, length, include);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  messagesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'messages', length, include, 999999, true);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  messagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'messages',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'offerPrice'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'offerPrice'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'offerPrice',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'offerPrice',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'offerPrice',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'offerPrice',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'offerPrice',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'offerPrice',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'offerPrice',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'offerPrice',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'offerPrice', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerPriceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'offerPrice', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'offerProductName'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'offerProductName'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'offerProductName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'offerProductName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'offerProductName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'offerProductName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'offerProductName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'offerProductName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'offerProductName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'offerProductName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'offerProductName', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  offerProductNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'offerProductName', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'paymentMethod'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'paymentMethod'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paymentMethod',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'paymentMethod',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paymentMethod', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  paymentMethodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'paymentMethod', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'requestDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'requestDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'requestDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'requestDescription',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'requestDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'requestDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'requestDescription',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'requestDescription',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'requestDescription', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  requestDescriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'requestDescription', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shippingCity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shippingCity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shippingCity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shippingCity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shippingCity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shippingCity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shippingCity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shippingCity',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shippingCity', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shippingCity', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shippingCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shippingCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shippingCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shippingCountry',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shippingCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shippingCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shippingCountry',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shippingCountry',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shippingCountry', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingCountryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shippingCountry', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shippingName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shippingName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shippingName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shippingName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shippingName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shippingName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shippingName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shippingName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shippingName', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shippingName', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shippingPostalCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shippingPostalCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shippingPostalCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shippingPostalCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shippingPostalCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shippingPostalCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shippingPostalCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shippingPostalCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shippingPostalCode', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingPostalCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shippingPostalCode', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'shippingStreet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'shippingStreet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'shippingStreet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'shippingStreet',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'shippingStreet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'shippingStreet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'shippingStreet',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'shippingStreet',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'shippingStreet', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  shippingStreetIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'shippingStreet', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  statusEqualTo(ShopInBitOrderStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  statusGreaterThan(ShopInBitOrderStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  statusLessThan(ShopInBitOrderStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  statusBetween(
    ShopInBitOrderStatus lower,
    ShopInBitOrderStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ticketId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ticketId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ticketId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ticketId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ticketId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ticketId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ticketId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ticketId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ticketId', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  ticketIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ticketId', value: ''),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  carResearchInvoiceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'carResearchInvoiceId'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  carResearchInvoiceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'carResearchInvoiceId'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  carResearchInvoiceIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'carResearchInvoiceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  feeTicketNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'feeTicketNumber'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  feeTicketNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'feeTicketNumber'),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  feeTicketNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'feeTicketNumber',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  needsCreateRequestEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'needsCreateRequest', value: value),
      );
    });
  }
}

extension ShopInBitTicketQueryObject
    on QueryBuilder<ShopInBitTicket, ShopInBitTicket, QFilterCondition> {
  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterFilterCondition>
  messagesElement(FilterQuery<ShopInBitTicketMessage> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'messages');
    });
  }
}

extension ShopInBitTicketQueryLinks
    on QueryBuilder<ShopInBitTicket, ShopInBitTicket, QFilterCondition> {}

extension ShopInBitTicketQuerySortBy
    on QueryBuilder<ShopInBitTicket, ShopInBitTicket, QSortBy> {
  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByApiTicketId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiTicketId', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByApiTicketIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiTicketId', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByDeliveryCountry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryCountry', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByDeliveryCountryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryCountry', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByOfferPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerPrice', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByOfferPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerPrice', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByOfferProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerProductName', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByOfferProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerProductName', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByRequestDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestDescription', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByRequestDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestDescription', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingCity', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingCity', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingCountry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingCountry', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingCountryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingCountry', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingName', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingName', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingPostalCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingPostalCode', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingPostalCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingPostalCode', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingStreet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingStreet', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByShippingStreetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingStreet', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByTicketId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketId', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByTicketIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketId', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByNeedsCreateRequest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsCreateRequest', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  sortByNeedsCreateRequestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsCreateRequest', Sort.desc);
    });
  }
}

extension ShopInBitTicketQuerySortThenBy
    on QueryBuilder<ShopInBitTicket, ShopInBitTicket, QSortThenBy> {
  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByApiTicketId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiTicketId', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByApiTicketIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiTicketId', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByDeliveryCountry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryCountry', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByDeliveryCountryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryCountry', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByOfferPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerPrice', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByOfferPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerPrice', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByOfferProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerProductName', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByOfferProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerProductName', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByRequestDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestDescription', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByRequestDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'requestDescription', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingCity', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingCity', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingCountry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingCountry', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingCountryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingCountry', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingName', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingName', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingPostalCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingPostalCode', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingPostalCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingPostalCode', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingStreet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingStreet', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByShippingStreetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shippingStreet', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByTicketId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketId', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByTicketIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketId', Sort.desc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByNeedsCreateRequest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsCreateRequest', Sort.asc);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QAfterSortBy>
  thenByNeedsCreateRequestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsCreateRequest', Sort.desc);
    });
  }
}

extension ShopInBitTicketQueryWhereDistinct
    on QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct> {
  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByApiTicketId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apiTicketId');
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category');
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByDeliveryCountry({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'deliveryCountry',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByDisplayName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByOfferPrice({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offerPrice', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByOfferProductName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'offerProductName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByPaymentMethod({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'paymentMethod',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByRequestDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'requestDescription',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByShippingCity({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shippingCity', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByShippingCountry({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'shippingCountry',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByShippingName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shippingName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByShippingPostalCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'shippingPostalCode',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByShippingStreet({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'shippingStreet',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct> distinctByTicketId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ticketId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByCarResearchInvoiceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'carResearchInvoiceId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByFeeTicketNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'feeTicketNumber',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitTicket, QDistinct>
  distinctByNeedsCreateRequest() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsCreateRequest');
    });
  }
}

extension ShopInBitTicketQueryProperty
    on QueryBuilder<ShopInBitTicket, ShopInBitTicket, QQueryProperty> {
  QueryBuilder<ShopInBitTicket, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ShopInBitTicket, int, QQueryOperations> apiTicketIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apiTicketId');
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitCategory, QQueryOperations>
  categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<ShopInBitTicket, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ShopInBitTicket, String, QQueryOperations>
  deliveryCountryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveryCountry');
    });
  }

  QueryBuilder<ShopInBitTicket, String, QQueryOperations>
  displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<ShopInBitTicket, List<ShopInBitTicketMessage>, QQueryOperations>
  messagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messages');
    });
  }

  QueryBuilder<ShopInBitTicket, String?, QQueryOperations>
  offerPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offerPrice');
    });
  }

  QueryBuilder<ShopInBitTicket, String?, QQueryOperations>
  offerProductNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offerProductName');
    });
  }

  QueryBuilder<ShopInBitTicket, String?, QQueryOperations>
  paymentMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMethod');
    });
  }

  QueryBuilder<ShopInBitTicket, String, QQueryOperations>
  requestDescriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'requestDescription');
    });
  }

  QueryBuilder<ShopInBitTicket, String, QQueryOperations>
  shippingCityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shippingCity');
    });
  }

  QueryBuilder<ShopInBitTicket, String, QQueryOperations>
  shippingCountryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shippingCountry');
    });
  }

  QueryBuilder<ShopInBitTicket, String, QQueryOperations>
  shippingNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shippingName');
    });
  }

  QueryBuilder<ShopInBitTicket, String, QQueryOperations>
  shippingPostalCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shippingPostalCode');
    });
  }

  QueryBuilder<ShopInBitTicket, String, QQueryOperations>
  shippingStreetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shippingStreet');
    });
  }

  QueryBuilder<ShopInBitTicket, ShopInBitOrderStatus, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<ShopInBitTicket, String, QQueryOperations> ticketIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ticketId');
    });
  }

  QueryBuilder<ShopInBitTicket, String?, QQueryOperations>
  carResearchInvoiceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carResearchInvoiceId');
    });
  }

  QueryBuilder<ShopInBitTicket, String?, QQueryOperations>
  feeTicketNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'feeTicketNumber');
    });
  }

  QueryBuilder<ShopInBitTicket, bool, QQueryOperations>
  needsCreateRequestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsCreateRequest');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ShopInBitTicketMessageSchema = Schema(
  name: r'ShopInBitTicketMessage',
  id: -6797752334657665095,
  properties: {
    r'isFromUser': PropertySchema(
      id: 0,
      name: r'isFromUser',
      type: IsarType.bool,
    ),
    r'text': PropertySchema(id: 1, name: r'text', type: IsarType.string),
    r'timestamp': PropertySchema(
      id: 2,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _shopInBitTicketMessageEstimateSize,
  serialize: _shopInBitTicketMessageSerialize,
  deserialize: _shopInBitTicketMessageDeserialize,
  deserializeProp: _shopInBitTicketMessageDeserializeProp,
);

int _shopInBitTicketMessageEstimateSize(
  ShopInBitTicketMessage object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _shopInBitTicketMessageSerialize(
  ShopInBitTicketMessage object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isFromUser);
  writer.writeString(offsets[1], object.text);
  writer.writeDateTime(offsets[2], object.timestamp);
}

ShopInBitTicketMessage _shopInBitTicketMessageDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ShopInBitTicketMessage();
  object.isFromUser = reader.readBool(offsets[0]);
  object.text = reader.readString(offsets[1]);
  object.timestamp = reader.readDateTime(offsets[2]);
  return object;
}

P _shopInBitTicketMessageDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ShopInBitTicketMessageQueryFilter
    on
        QueryBuilder<
          ShopInBitTicketMessage,
          ShopInBitTicketMessage,
          QFilterCondition
        > {
  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  isFromUserEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFromUser', value: value),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  timestampLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ShopInBitTicketMessage,
    ShopInBitTicketMessage,
    QAfterFilterCondition
  >
  timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ShopInBitTicketMessageQueryObject
    on
        QueryBuilder<
          ShopInBitTicketMessage,
          ShopInBitTicketMessage,
          QFilterCondition
        > {}

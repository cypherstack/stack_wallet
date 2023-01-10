// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetTransactionCollection on Isar {
  IsarCollection<Transaction> get transactions => this.collection();
}

const TransactionSchema = CollectionSchema(
  name: r'Transaction',
  id: 5320225499417954855,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'amount': PropertySchema(
      id: 1,
      name: r'amount',
      type: IsarType.long,
    ),
    r'cancelled': PropertySchema(
      id: 2,
      name: r'cancelled',
      type: IsarType.bool,
    ),
    r'fee': PropertySchema(
      id: 3,
      name: r'fee',
      type: IsarType.long,
    ),
    r'height': PropertySchema(
      id: 4,
      name: r'height',
      type: IsarType.long,
    ),
    r'otherData': PropertySchema(
      id: 5,
      name: r'otherData',
      type: IsarType.string,
    ),
    r'slateId': PropertySchema(
      id: 6,
      name: r'slateId',
      type: IsarType.string,
    ),
    r'subType': PropertySchema(
      id: 7,
      name: r'subType',
      type: IsarType.byte,
      enumMap: _TransactionsubTypeEnumValueMap,
    ),
    r'timestamp': PropertySchema(
      id: 8,
      name: r'timestamp',
      type: IsarType.long,
    ),
    r'txid': PropertySchema(
      id: 9,
      name: r'txid',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 10,
      name: r'type',
      type: IsarType.byte,
      enumMap: _TransactiontypeEnumValueMap,
    )
  },
  estimateSize: _transactionEstimateSize,
  serialize: _transactionSerialize,
  deserialize: _transactionDeserialize,
  deserializeProp: _transactionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'inputs': LinkSchema(
      id: 4634425919890543640,
      name: r'inputs',
      target: r'Input',
      single: false,
    ),
    r'outputs': LinkSchema(
      id: 1341997944984495532,
      name: r'outputs',
      target: r'Output',
      single: false,
    ),
    r'note': LinkSchema(
      id: 1009915346265072213,
      name: r'note',
      target: r'TransactionNote',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _transactionGetId,
  getLinks: _transactionGetLinks,
  attach: _transactionAttach,
  version: '3.0.5',
);

int _transactionEstimateSize(
  Transaction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.address.length * 3;
  {
    final value = object.otherData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.slateId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.txid.length * 3;
  return bytesCount;
}

void _transactionSerialize(
  Transaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeLong(offsets[1], object.amount);
  writer.writeBool(offsets[2], object.cancelled);
  writer.writeLong(offsets[3], object.fee);
  writer.writeLong(offsets[4], object.height);
  writer.writeString(offsets[5], object.otherData);
  writer.writeString(offsets[6], object.slateId);
  writer.writeByte(offsets[7], object.subType.index);
  writer.writeLong(offsets[8], object.timestamp);
  writer.writeString(offsets[9], object.txid);
  writer.writeByte(offsets[10], object.type.index);
}

Transaction _transactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Transaction();
  object.address = reader.readString(offsets[0]);
  object.amount = reader.readLong(offsets[1]);
  object.cancelled = reader.readBool(offsets[2]);
  object.fee = reader.readLong(offsets[3]);
  object.height = reader.readLong(offsets[4]);
  object.id = id;
  object.otherData = reader.readStringOrNull(offsets[5]);
  object.slateId = reader.readStringOrNull(offsets[6]);
  object.subType =
      _TransactionsubTypeValueEnumMap[reader.readByteOrNull(offsets[7])] ??
          TransactionSubType.none;
  object.timestamp = reader.readLong(offsets[8]);
  object.txid = reader.readString(offsets[9]);
  object.type =
      _TransactiontypeValueEnumMap[reader.readByteOrNull(offsets[10])] ??
          TransactionType.outgoing;
  return object;
}

P _transactionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (_TransactionsubTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          TransactionSubType.none) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (_TransactiontypeValueEnumMap[reader.readByteOrNull(offset)] ??
          TransactionType.outgoing) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TransactionsubTypeEnumValueMap = {
  'none': 0,
  'bip47Notification': 1,
  'mint': 2,
};
const _TransactionsubTypeValueEnumMap = {
  0: TransactionSubType.none,
  1: TransactionSubType.bip47Notification,
  2: TransactionSubType.mint,
};
const _TransactiontypeEnumValueMap = {
  'outgoing': 0,
  'incoming': 1,
  'sendToSelf': 2,
  'unknown': 3,
  'anonymize': 4,
};
const _TransactiontypeValueEnumMap = {
  0: TransactionType.outgoing,
  1: TransactionType.incoming,
  2: TransactionType.sendToSelf,
  3: TransactionType.unknown,
  4: TransactionType.anonymize,
};

Id _transactionGetId(Transaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _transactionGetLinks(Transaction object) {
  return [object.inputs, object.outputs, object.note];
}

void _transactionAttach(
    IsarCollection<dynamic> col, Id id, Transaction object) {
  object.id = id;
  object.inputs.attach(col, col.isar.collection<Input>(), r'inputs', id);
  object.outputs.attach(col, col.isar.collection<Output>(), r'outputs', id);
  object.note.attach(col, col.isar.collection<TransactionNote>(), r'note', id);
}

extension TransactionQueryWhereSort
    on QueryBuilder<Transaction, Transaction, QWhere> {
  QueryBuilder<Transaction, Transaction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TransactionQueryWhere
    on QueryBuilder<Transaction, Transaction, QWhereClause> {
  QueryBuilder<Transaction, Transaction, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<Transaction, Transaction, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TransactionQueryFilter
    on QueryBuilder<Transaction, Transaction, QFilterCondition> {
  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> addressEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      addressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> addressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> addressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'address',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> addressContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> addressMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> amountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      amountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> amountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> amountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      cancelledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancelled',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> feeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fee',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> feeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fee',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> feeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fee',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> feeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fee',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> heightEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      heightGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> heightLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> heightBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'otherData',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'otherData',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'otherData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'otherData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'otherData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'otherData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'otherData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'otherData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'otherData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherData',
        value: '',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      otherDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'otherData',
        value: '',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      slateIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'slateId',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      slateIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'slateId',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> slateIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      slateIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'slateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> slateIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'slateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> slateIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'slateId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      slateIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'slateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> slateIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'slateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> slateIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'slateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> slateIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'slateId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      slateIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slateId',
        value: '',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      slateIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'slateId',
        value: '',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> subTypeEqualTo(
      TransactionSubType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subType',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      subTypeGreaterThan(
    TransactionSubType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subType',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> subTypeLessThan(
    TransactionSubType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subType',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> subTypeBetween(
    TransactionSubType lower,
    TransactionSubType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      timestampEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      timestampGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      timestampLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      timestampBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'txid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'txid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      txidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> typeEqualTo(
      TransactionType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> typeGreaterThan(
    TransactionType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> typeLessThan(
    TransactionType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> typeBetween(
    TransactionType lower,
    TransactionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TransactionQueryObject
    on QueryBuilder<Transaction, Transaction, QFilterCondition> {}

extension TransactionQueryLinks
    on QueryBuilder<Transaction, Transaction, QFilterCondition> {
  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> inputs(
      FilterQuery<Input> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'inputs');
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      inputsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'inputs', length, true, length, true);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      inputsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'inputs', 0, true, 0, true);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      inputsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'inputs', 0, false, 999999, true);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      inputsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'inputs', 0, true, length, include);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      inputsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'inputs', length, include, 999999, true);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      inputsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'inputs', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> outputs(
      FilterQuery<Output> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'outputs');
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      outputsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'outputs', length, true, length, true);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      outputsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'outputs', 0, true, 0, true);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      outputsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'outputs', 0, false, 999999, true);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      outputsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'outputs', 0, true, length, include);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      outputsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'outputs', length, include, 999999, true);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition>
      outputsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'outputs', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> note(
      FilterQuery<TransactionNote> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'note');
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'note', 0, true, 0, true);
    });
  }
}

extension TransactionQuerySortBy
    on QueryBuilder<Transaction, Transaction, QSortBy> {
  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelled', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByCancelledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelled', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByOtherData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByOtherDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortBySlateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slateId', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortBySlateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slateId', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortBySubTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension TransactionQuerySortThenBy
    on QueryBuilder<Transaction, Transaction, QSortThenBy> {
  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelled', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByCancelledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelled', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByOtherData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByOtherDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenBySlateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slateId', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenBySlateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slateId', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenBySubTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Transaction, Transaction, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension TransactionQueryWhereDistinct
    on QueryBuilder<Transaction, Transaction, QDistinct> {
  QueryBuilder<Transaction, Transaction, QDistinct> distinctByAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctByCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cancelled');
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fee');
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctByOtherData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctBySlateId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'slateId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subType');
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctByTxid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'txid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Transaction, Transaction, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }
}

extension TransactionQueryProperty
    on QueryBuilder<Transaction, Transaction, QQueryProperty> {
  QueryBuilder<Transaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Transaction, String, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<Transaction, int, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<Transaction, bool, QQueryOperations> cancelledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cancelled');
    });
  }

  QueryBuilder<Transaction, int, QQueryOperations> feeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fee');
    });
  }

  QueryBuilder<Transaction, int, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<Transaction, String?, QQueryOperations> otherDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherData');
    });
  }

  QueryBuilder<Transaction, String?, QQueryOperations> slateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slateId');
    });
  }

  QueryBuilder<Transaction, TransactionSubType, QQueryOperations>
      subTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subType');
    });
  }

  QueryBuilder<Transaction, int, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<Transaction, String, QQueryOperations> txidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'txid');
    });
  }

  QueryBuilder<Transaction, TransactionType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}

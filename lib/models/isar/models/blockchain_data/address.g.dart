// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetAddressCollection on Isar {
  IsarCollection<Address> get addresses => this.collection();
}

const AddressSchema = CollectionSchema(
  name: r'Address',
  id: 3544600503126319553,
  properties: {
    r'derivationIndex': PropertySchema(
      id: 0,
      name: r'derivationIndex',
      type: IsarType.long,
    ),
    r'derivationPath': PropertySchema(
      id: 1,
      name: r'derivationPath',
      type: IsarType.object,
      target: r'DerivationPath',
    ),
    r'otherData': PropertySchema(
      id: 2,
      name: r'otherData',
      type: IsarType.string,
    ),
    r'publicKey': PropertySchema(
      id: 3,
      name: r'publicKey',
      type: IsarType.byteList,
    ),
    r'subType': PropertySchema(
      id: 4,
      name: r'subType',
      type: IsarType.byte,
      enumMap: _AddresssubTypeEnumValueMap,
    ),
    r'type': PropertySchema(
      id: 5,
      name: r'type',
      type: IsarType.byte,
      enumMap: _AddresstypeEnumValueMap,
    ),
    r'value': PropertySchema(
      id: 6,
      name: r'value',
      type: IsarType.string,
    ),
    r'walletId': PropertySchema(
      id: 7,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _addressEstimateSize,
  serialize: _addressSerialize,
  deserialize: _addressDeserialize,
  deserializeProp: _addressDeserializeProp,
  idName: r'id',
  indexes: {
    r'walletId': IndexSchema(
      id: -1783113319798776304,
      name: r'walletId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'walletId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'value_walletId': IndexSchema(
      id: -7332188919457190704,
      name: r'value_walletId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'value',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'walletId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'derivationIndex': IndexSchema(
      id: -6950711977521998012,
      name: r'derivationIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'derivationIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'transactions': LinkSchema(
      id: -20231914767662480,
      name: r'transactions',
      target: r'Transaction',
      single: false,
    )
  },
  embeddedSchemas: {r'DerivationPath': DerivationPathSchema},
  getId: _addressGetId,
  getLinks: _addressGetLinks,
  attach: _addressAttach,
  version: '3.0.5',
);

int _addressEstimateSize(
  Address object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.derivationPath;
    if (value != null) {
      bytesCount += 3 +
          DerivationPathSchema.estimateSize(
              value, allOffsets[DerivationPath]!, allOffsets);
    }
  }
  {
    final value = object.otherData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.publicKey.length;
  bytesCount += 3 + object.value.length * 3;
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _addressSerialize(
  Address object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.derivationIndex);
  writer.writeObject<DerivationPath>(
    offsets[1],
    allOffsets,
    DerivationPathSchema.serialize,
    object.derivationPath,
  );
  writer.writeString(offsets[2], object.otherData);
  writer.writeByteList(offsets[3], object.publicKey);
  writer.writeByte(offsets[4], object.subType.index);
  writer.writeByte(offsets[5], object.type.index);
  writer.writeString(offsets[6], object.value);
  writer.writeString(offsets[7], object.walletId);
}

Address _addressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Address(
    derivationIndex: reader.readLong(offsets[0]),
    derivationPath: reader.readObjectOrNull<DerivationPath>(
      offsets[1],
      DerivationPathSchema.deserialize,
      allOffsets,
    ),
    otherData: reader.readStringOrNull(offsets[2]),
    publicKey: reader.readByteList(offsets[3]) ?? [],
    subType: _AddresssubTypeValueEnumMap[reader.readByteOrNull(offsets[4])] ??
        AddressSubType.receiving,
    type: _AddresstypeValueEnumMap[reader.readByteOrNull(offsets[5])] ??
        AddressType.p2pkh,
    value: reader.readString(offsets[6]),
    walletId: reader.readString(offsets[7]),
  );
  object.id = id;
  return object;
}

P _addressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readObjectOrNull<DerivationPath>(
        offset,
        DerivationPathSchema.deserialize,
        allOffsets,
      )) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readByteList(offset) ?? []) as P;
    case 4:
      return (_AddresssubTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          AddressSubType.receiving) as P;
    case 5:
      return (_AddresstypeValueEnumMap[reader.readByteOrNull(offset)] ??
          AddressType.p2pkh) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AddresssubTypeEnumValueMap = {
  'receiving': 0,
  'change': 1,
  'paynymNotification': 2,
  'paynymSend': 3,
  'paynymReceive': 4,
  'unknown': 5,
  'nonWallet': 6,
};
const _AddresssubTypeValueEnumMap = {
  0: AddressSubType.receiving,
  1: AddressSubType.change,
  2: AddressSubType.paynymNotification,
  3: AddressSubType.paynymSend,
  4: AddressSubType.paynymReceive,
  5: AddressSubType.unknown,
  6: AddressSubType.nonWallet,
};
const _AddresstypeEnumValueMap = {
  'p2pkh': 0,
  'p2sh': 1,
  'p2wpkh': 2,
  'cryptonote': 3,
  'mimbleWimble': 4,
  'unknown': 5,
  'nonWallet': 6,
  'ethereum': 7,
};
const _AddresstypeValueEnumMap = {
  0: AddressType.p2pkh,
  1: AddressType.p2sh,
  2: AddressType.p2wpkh,
  3: AddressType.cryptonote,
  4: AddressType.mimbleWimble,
  5: AddressType.unknown,
  6: AddressType.nonWallet,
  7: AddressType.ethereum,
};

Id _addressGetId(Address object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _addressGetLinks(Address object) {
  return [object.transactions];
}

void _addressAttach(IsarCollection<dynamic> col, Id id, Address object) {
  object.id = id;
  object.transactions
      .attach(col, col.isar.collection<Transaction>(), r'transactions', id);
}

extension AddressByIndex on IsarCollection<Address> {
  Future<Address?> getByValueWalletId(String value, String walletId) {
    return getByIndex(r'value_walletId', [value, walletId]);
  }

  Address? getByValueWalletIdSync(String value, String walletId) {
    return getByIndexSync(r'value_walletId', [value, walletId]);
  }

  Future<bool> deleteByValueWalletId(String value, String walletId) {
    return deleteByIndex(r'value_walletId', [value, walletId]);
  }

  bool deleteByValueWalletIdSync(String value, String walletId) {
    return deleteByIndexSync(r'value_walletId', [value, walletId]);
  }

  Future<List<Address?>> getAllByValueWalletId(
      List<String> valueValues, List<String> walletIdValues) {
    final len = valueValues.length;
    assert(walletIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([valueValues[i], walletIdValues[i]]);
    }

    return getAllByIndex(r'value_walletId', values);
  }

  List<Address?> getAllByValueWalletIdSync(
      List<String> valueValues, List<String> walletIdValues) {
    final len = valueValues.length;
    assert(walletIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([valueValues[i], walletIdValues[i]]);
    }

    return getAllByIndexSync(r'value_walletId', values);
  }

  Future<int> deleteAllByValueWalletId(
      List<String> valueValues, List<String> walletIdValues) {
    final len = valueValues.length;
    assert(walletIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([valueValues[i], walletIdValues[i]]);
    }

    return deleteAllByIndex(r'value_walletId', values);
  }

  int deleteAllByValueWalletIdSync(
      List<String> valueValues, List<String> walletIdValues) {
    final len = valueValues.length;
    assert(walletIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([valueValues[i], walletIdValues[i]]);
    }

    return deleteAllByIndexSync(r'value_walletId', values);
  }

  Future<Id> putByValueWalletId(Address object) {
    return putByIndex(r'value_walletId', object);
  }

  Id putByValueWalletIdSync(Address object, {bool saveLinks = true}) {
    return putByIndexSync(r'value_walletId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByValueWalletId(List<Address> objects) {
    return putAllByIndex(r'value_walletId', objects);
  }

  List<Id> putAllByValueWalletIdSync(List<Address> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'value_walletId', objects, saveLinks: saveLinks);
  }
}

extension AddressQueryWhereSort on QueryBuilder<Address, Address, QWhere> {
  QueryBuilder<Address, Address, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Address, Address, QAfterWhere> anyDerivationIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'derivationIndex'),
      );
    });
  }
}

extension AddressQueryWhere on QueryBuilder<Address, Address, QWhereClause> {
  QueryBuilder<Address, Address, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Address, Address, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> idBetween(
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

  QueryBuilder<Address, Address, QAfterWhereClause> walletIdEqualTo(
      String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> walletIdNotEqualTo(
      String walletId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId',
              lower: [],
              upper: [walletId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId',
              lower: [walletId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId',
              lower: [walletId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId',
              lower: [],
              upper: [walletId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> valueEqualToAnyWalletId(
      String value) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'value_walletId',
        value: [value],
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> valueNotEqualToAnyWalletId(
      String value) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value_walletId',
              lower: [],
              upper: [value],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value_walletId',
              lower: [value],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value_walletId',
              lower: [value],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value_walletId',
              lower: [],
              upper: [value],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> valueWalletIdEqualTo(
      String value, String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'value_walletId',
        value: [value, walletId],
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause>
      valueEqualToWalletIdNotEqualTo(String value, String walletId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value_walletId',
              lower: [value],
              upper: [value, walletId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value_walletId',
              lower: [value, walletId],
              includeLower: false,
              upper: [value],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value_walletId',
              lower: [value, walletId],
              includeLower: false,
              upper: [value],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value_walletId',
              lower: [value],
              upper: [value, walletId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexEqualTo(
      int derivationIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'derivationIndex',
        value: [derivationIndex],
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexNotEqualTo(
      int derivationIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'derivationIndex',
              lower: [],
              upper: [derivationIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'derivationIndex',
              lower: [derivationIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'derivationIndex',
              lower: [derivationIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'derivationIndex',
              lower: [],
              upper: [derivationIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexGreaterThan(
    int derivationIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'derivationIndex',
        lower: [derivationIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexLessThan(
    int derivationIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'derivationIndex',
        lower: [],
        upper: [derivationIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexBetween(
    int lowerDerivationIndex,
    int upperDerivationIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'derivationIndex',
        lower: [lowerDerivationIndex],
        includeLower: includeLower,
        upper: [upperDerivationIndex],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AddressQueryFilter
    on QueryBuilder<Address, Address, QFilterCondition> {
  QueryBuilder<Address, Address, QAfterFilterCondition> derivationIndexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'derivationIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      derivationIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'derivationIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> derivationIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'derivationIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> derivationIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'derivationIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> derivationPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'derivationPath',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      derivationPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'derivationPath',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'otherData',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'otherData',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataEqualTo(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataGreaterThan(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataLessThan(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataBetween(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataStartsWith(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataEndsWith(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'otherData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'otherData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherData',
        value: '',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> otherDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'otherData',
        value: '',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyElementEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'publicKey',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      publicKeyElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'publicKey',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      publicKeyElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'publicKey',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'publicKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      publicKeyLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> subTypeEqualTo(
      AddressSubType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subType',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> subTypeGreaterThan(
    AddressSubType value, {
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

  QueryBuilder<Address, Address, QAfterFilterCondition> subTypeLessThan(
    AddressSubType value, {
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

  QueryBuilder<Address, Address, QAfterFilterCondition> subTypeBetween(
    AddressSubType lower,
    AddressSubType upper, {
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

  QueryBuilder<Address, Address, QAfterFilterCondition> typeEqualTo(
      AddressType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> typeGreaterThan(
    AddressType value, {
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

  QueryBuilder<Address, Address, QAfterFilterCondition> typeLessThan(
    AddressType value, {
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

  QueryBuilder<Address, Address, QAfterFilterCondition> typeBetween(
    AddressType lower,
    AddressType upper, {
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

  QueryBuilder<Address, Address, QAfterFilterCondition> valueEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'value',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'value',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'walletId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension AddressQueryObject
    on QueryBuilder<Address, Address, QFilterCondition> {
  QueryBuilder<Address, Address, QAfterFilterCondition> derivationPath(
      FilterQuery<DerivationPath> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'derivationPath');
    });
  }
}

extension AddressQueryLinks
    on QueryBuilder<Address, Address, QFilterCondition> {
  QueryBuilder<Address, Address, QAfterFilterCondition> transactions(
      FilterQuery<Transaction> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'transactions');
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      transactionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'transactions', length, true, length, true);
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> transactionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'transactions', 0, true, 0, true);
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      transactionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'transactions', 0, false, 999999, true);
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      transactionsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'transactions', 0, true, length, include);
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      transactionsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'transactions', length, include, 999999, true);
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      transactionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'transactions', lower, includeLower, upper, includeUpper);
    });
  }
}

extension AddressQuerySortBy on QueryBuilder<Address, Address, QSortBy> {
  QueryBuilder<Address, Address, QAfterSortBy> sortByDerivationIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'derivationIndex', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByDerivationIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'derivationIndex', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByOtherData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByOtherDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortBySubTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension AddressQuerySortThenBy
    on QueryBuilder<Address, Address, QSortThenBy> {
  QueryBuilder<Address, Address, QAfterSortBy> thenByDerivationIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'derivationIndex', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByDerivationIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'derivationIndex', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByOtherData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByOtherDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenBySubTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension AddressQueryWhereDistinct
    on QueryBuilder<Address, Address, QDistinct> {
  QueryBuilder<Address, Address, QDistinct> distinctByDerivationIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'derivationIndex');
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctByOtherData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctByPublicKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'publicKey');
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subType');
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctByValue(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctByWalletId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension AddressQueryProperty
    on QueryBuilder<Address, Address, QQueryProperty> {
  QueryBuilder<Address, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Address, int, QQueryOperations> derivationIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'derivationIndex');
    });
  }

  QueryBuilder<Address, DerivationPath?, QQueryOperations>
      derivationPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'derivationPath');
    });
  }

  QueryBuilder<Address, String?, QQueryOperations> otherDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherData');
    });
  }

  QueryBuilder<Address, List<int>, QQueryOperations> publicKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'publicKey');
    });
  }

  QueryBuilder<Address, AddressSubType, QQueryOperations> subTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subType');
    });
  }

  QueryBuilder<Address, AddressType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<Address, String, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }

  QueryBuilder<Address, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

const DerivationPathSchema = Schema(
  name: r'DerivationPath',
  id: -7377061614393881103,
  properties: {
    r'value': PropertySchema(
      id: 0,
      name: r'value',
      type: IsarType.string,
    )
  },
  estimateSize: _derivationPathEstimateSize,
  serialize: _derivationPathSerialize,
  deserialize: _derivationPathDeserialize,
  deserializeProp: _derivationPathDeserializeProp,
);

int _derivationPathEstimateSize(
  DerivationPath object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.value.length * 3;
  return bytesCount;
}

void _derivationPathSerialize(
  DerivationPath object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.value);
}

DerivationPath _derivationPathDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DerivationPath();
  object.value = reader.readString(offsets[0]);
  return object;
}

P _derivationPathDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension DerivationPathQueryFilter
    on QueryBuilder<DerivationPath, DerivationPath, QFilterCondition> {
  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'value',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'value',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<DerivationPath, DerivationPath, QAfterFilterCondition>
      valueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'value',
        value: '',
      ));
    });
  }
}

extension DerivationPathQueryObject
    on QueryBuilder<DerivationPath, DerivationPath, QFilterCondition> {}

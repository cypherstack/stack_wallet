// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_info.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetWalletInfoCollection on Isar {
  IsarCollection<WalletInfo> get walletInfo => this.collection();
}

const WalletInfoSchema = CollectionSchema(
  name: r'WalletInfo',
  id: -2861501434900022153,
  properties: {
    r'cachedBalanceSecondaryString': PropertySchema(
      id: 0,
      name: r'cachedBalanceSecondaryString',
      type: IsarType.string,
    ),
    r'cachedBalanceString': PropertySchema(
      id: 1,
      name: r'cachedBalanceString',
      type: IsarType.string,
    ),
    r'cachedBalanceTertiaryString': PropertySchema(
      id: 2,
      name: r'cachedBalanceTertiaryString',
      type: IsarType.string,
    ),
    r'cachedChainHeight': PropertySchema(
      id: 3,
      name: r'cachedChainHeight',
      type: IsarType.long,
    ),
    r'cachedReceivingAddress': PropertySchema(
      id: 4,
      name: r'cachedReceivingAddress',
      type: IsarType.string,
    ),
    r'coinName': PropertySchema(
      id: 5,
      name: r'coinName',
      type: IsarType.string,
    ),
    r'favouriteOrderIndex': PropertySchema(
      id: 6,
      name: r'favouriteOrderIndex',
      type: IsarType.long,
    ),
    r'isFavourite': PropertySchema(
      id: 7,
      name: r'isFavourite',
      type: IsarType.bool,
    ),
    r'mainAddressType': PropertySchema(
      id: 8,
      name: r'mainAddressType',
      type: IsarType.byte,
      enumMap: _WalletInfomainAddressTypeEnumValueMap,
    ),
    r'name': PropertySchema(
      id: 9,
      name: r'name',
      type: IsarType.string,
    ),
    r'otherDataJsonString': PropertySchema(
      id: 10,
      name: r'otherDataJsonString',
      type: IsarType.string,
    ),
    r'restoreHeight': PropertySchema(
      id: 11,
      name: r'restoreHeight',
      type: IsarType.long,
    ),
    r'tokenContractAddresses': PropertySchema(
      id: 12,
      name: r'tokenContractAddresses',
      type: IsarType.stringList,
    ),
    r'walletId': PropertySchema(
      id: 13,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _walletInfoEstimateSize,
  serialize: _walletInfoSerialize,
  deserialize: _walletInfoDeserialize,
  deserializeProp: _walletInfoDeserializeProp,
  idName: r'id',
  indexes: {
    r'walletId': IndexSchema(
      id: -1783113319798776304,
      name: r'walletId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'walletId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _walletInfoGetId,
  getLinks: _walletInfoGetLinks,
  attach: _walletInfoAttach,
  version: '3.0.5',
);

int _walletInfoEstimateSize(
  WalletInfo object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cachedBalanceSecondaryString;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cachedBalanceString;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cachedBalanceTertiaryString;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.cachedReceivingAddress.length * 3;
  bytesCount += 3 + object.coinName.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.otherDataJsonString;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tokenContractAddresses.length * 3;
  {
    for (var i = 0; i < object.tokenContractAddresses.length; i++) {
      final value = object.tokenContractAddresses[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _walletInfoSerialize(
  WalletInfo object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cachedBalanceSecondaryString);
  writer.writeString(offsets[1], object.cachedBalanceString);
  writer.writeString(offsets[2], object.cachedBalanceTertiaryString);
  writer.writeLong(offsets[3], object.cachedChainHeight);
  writer.writeString(offsets[4], object.cachedReceivingAddress);
  writer.writeString(offsets[5], object.coinName);
  writer.writeLong(offsets[6], object.favouriteOrderIndex);
  writer.writeBool(offsets[7], object.isFavourite);
  writer.writeByte(offsets[8], object.mainAddressType.index);
  writer.writeString(offsets[9], object.name);
  writer.writeString(offsets[10], object.otherDataJsonString);
  writer.writeLong(offsets[11], object.restoreHeight);
  writer.writeStringList(offsets[12], object.tokenContractAddresses);
  writer.writeString(offsets[13], object.walletId);
}

WalletInfo _walletInfoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WalletInfo(
    cachedBalanceSecondaryString: reader.readStringOrNull(offsets[0]),
    cachedBalanceString: reader.readStringOrNull(offsets[1]),
    cachedBalanceTertiaryString: reader.readStringOrNull(offsets[2]),
    cachedChainHeight: reader.readLongOrNull(offsets[3]) ?? 0,
    cachedReceivingAddress: reader.readStringOrNull(offsets[4]) ?? "",
    coinName: reader.readString(offsets[5]),
    favouriteOrderIndex: reader.readLongOrNull(offsets[6]) ?? -1,
    mainAddressType: _WalletInfomainAddressTypeValueEnumMap[
            reader.readByteOrNull(offsets[8])] ??
        AddressType.p2pkh,
    name: reader.readString(offsets[9]),
    otherDataJsonString: reader.readStringOrNull(offsets[10]),
    restoreHeight: reader.readLongOrNull(offsets[11]) ?? 0,
    walletId: reader.readString(offsets[13]),
  );
  object.id = id;
  return object;
}

P _walletInfoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 4:
      return (reader.readStringOrNull(offset) ?? "") as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset) ?? -1) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (_WalletInfomainAddressTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          AddressType.p2pkh) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 12:
      return (reader.readStringList(offset) ?? []) as P;
    case 13:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _WalletInfomainAddressTypeEnumValueMap = {
  'p2pkh': 0,
  'p2sh': 1,
  'p2wpkh': 2,
  'cryptonote': 3,
  'mimbleWimble': 4,
  'unknown': 5,
  'nonWallet': 6,
  'ethereum': 7,
  'nano': 8,
  'banano': 9,
  'spark': 10,
};
const _WalletInfomainAddressTypeValueEnumMap = {
  0: AddressType.p2pkh,
  1: AddressType.p2sh,
  2: AddressType.p2wpkh,
  3: AddressType.cryptonote,
  4: AddressType.mimbleWimble,
  5: AddressType.unknown,
  6: AddressType.nonWallet,
  7: AddressType.ethereum,
  8: AddressType.nano,
  9: AddressType.banano,
  10: AddressType.spark,
};

Id _walletInfoGetId(WalletInfo object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _walletInfoGetLinks(WalletInfo object) {
  return [];
}

void _walletInfoAttach(IsarCollection<dynamic> col, Id id, WalletInfo object) {
  object.id = id;
}

extension WalletInfoByIndex on IsarCollection<WalletInfo> {
  Future<WalletInfo?> getByWalletId(String walletId) {
    return getByIndex(r'walletId', [walletId]);
  }

  WalletInfo? getByWalletIdSync(String walletId) {
    return getByIndexSync(r'walletId', [walletId]);
  }

  Future<bool> deleteByWalletId(String walletId) {
    return deleteByIndex(r'walletId', [walletId]);
  }

  bool deleteByWalletIdSync(String walletId) {
    return deleteByIndexSync(r'walletId', [walletId]);
  }

  Future<List<WalletInfo?>> getAllByWalletId(List<String> walletIdValues) {
    final values = walletIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'walletId', values);
  }

  List<WalletInfo?> getAllByWalletIdSync(List<String> walletIdValues) {
    final values = walletIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'walletId', values);
  }

  Future<int> deleteAllByWalletId(List<String> walletIdValues) {
    final values = walletIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'walletId', values);
  }

  int deleteAllByWalletIdSync(List<String> walletIdValues) {
    final values = walletIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'walletId', values);
  }

  Future<Id> putByWalletId(WalletInfo object) {
    return putByIndex(r'walletId', object);
  }

  Id putByWalletIdSync(WalletInfo object, {bool saveLinks = true}) {
    return putByIndexSync(r'walletId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByWalletId(List<WalletInfo> objects) {
    return putAllByIndex(r'walletId', objects);
  }

  List<Id> putAllByWalletIdSync(List<WalletInfo> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'walletId', objects, saveLinks: saveLinks);
  }
}

extension WalletInfoQueryWhereSort
    on QueryBuilder<WalletInfo, WalletInfo, QWhere> {
  QueryBuilder<WalletInfo, WalletInfo, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WalletInfoQueryWhere
    on QueryBuilder<WalletInfo, WalletInfo, QWhereClause> {
  QueryBuilder<WalletInfo, WalletInfo, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterWhereClause> idBetween(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterWhereClause> walletIdEqualTo(
      String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterWhereClause> walletIdNotEqualTo(
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
}

extension WalletInfoQueryFilter
    on QueryBuilder<WalletInfo, WalletInfo, QFilterCondition> {
  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cachedBalanceSecondaryString',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cachedBalanceSecondaryString',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedBalanceSecondaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedBalanceSecondaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedBalanceSecondaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedBalanceSecondaryString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cachedBalanceSecondaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cachedBalanceSecondaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cachedBalanceSecondaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cachedBalanceSecondaryString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedBalanceSecondaryString',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceSecondaryStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cachedBalanceSecondaryString',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cachedBalanceString',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cachedBalanceString',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedBalanceString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedBalanceString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedBalanceString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedBalanceString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cachedBalanceString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cachedBalanceString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cachedBalanceString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cachedBalanceString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedBalanceString',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cachedBalanceString',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cachedBalanceTertiaryString',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cachedBalanceTertiaryString',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedBalanceTertiaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedBalanceTertiaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedBalanceTertiaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedBalanceTertiaryString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cachedBalanceTertiaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cachedBalanceTertiaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cachedBalanceTertiaryString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cachedBalanceTertiaryString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedBalanceTertiaryString',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedBalanceTertiaryStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cachedBalanceTertiaryString',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedChainHeightEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedChainHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedChainHeightGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedChainHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedChainHeightLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedChainHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedChainHeightBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedChainHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedReceivingAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedReceivingAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedReceivingAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedReceivingAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cachedReceivingAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cachedReceivingAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cachedReceivingAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cachedReceivingAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedReceivingAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      cachedReceivingAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cachedReceivingAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> coinNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      coinNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> coinNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> coinNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coinName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      coinNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> coinNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> coinNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> coinNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'coinName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      coinNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coinName',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      coinNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'coinName',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      favouriteOrderIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favouriteOrderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      favouriteOrderIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'favouriteOrderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      favouriteOrderIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'favouriteOrderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      favouriteOrderIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'favouriteOrderIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> idBetween(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      isFavouriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavourite',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      mainAddressTypeEqualTo(AddressType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mainAddressType',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      mainAddressTypeGreaterThan(
    AddressType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mainAddressType',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      mainAddressTypeLessThan(
    AddressType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mainAddressType',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      mainAddressTypeBetween(
    AddressType lower,
    AddressType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mainAddressType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'otherDataJsonString',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'otherDataJsonString',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherDataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'otherDataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'otherDataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'otherDataJsonString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'otherDataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'otherDataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'otherDataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'otherDataJsonString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherDataJsonString',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      otherDataJsonStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'otherDataJsonString',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      restoreHeightEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restoreHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      restoreHeightGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'restoreHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      restoreHeightLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'restoreHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      restoreHeightBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'restoreHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokenContractAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tokenContractAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tokenContractAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tokenContractAddresses',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tokenContractAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tokenContractAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tokenContractAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tokenContractAddresses',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokenContractAddresses',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tokenContractAddresses',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tokenContractAddresses',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tokenContractAddresses',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tokenContractAddresses',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tokenContractAddresses',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tokenContractAddresses',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      tokenContractAddressesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tokenContractAddresses',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> walletIdEqualTo(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      walletIdGreaterThan(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> walletIdLessThan(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> walletIdBetween(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      walletIdStartsWith(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> walletIdEndsWith(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> walletIdContains(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition> walletIdMatches(
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

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterFilterCondition>
      walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension WalletInfoQueryObject
    on QueryBuilder<WalletInfo, WalletInfo, QFilterCondition> {}

extension WalletInfoQueryLinks
    on QueryBuilder<WalletInfo, WalletInfo, QFilterCondition> {}

extension WalletInfoQuerySortBy
    on QueryBuilder<WalletInfo, WalletInfo, QSortBy> {
  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByCachedBalanceSecondaryString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceSecondaryString', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByCachedBalanceSecondaryStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceSecondaryString', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByCachedBalanceString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceString', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByCachedBalanceStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceString', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByCachedBalanceTertiaryString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceTertiaryString', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByCachedBalanceTertiaryStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceTertiaryString', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByCachedChainHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedChainHeight', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByCachedChainHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedChainHeight', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByCachedReceivingAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedReceivingAddress', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByCachedReceivingAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedReceivingAddress', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByCoinName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coinName', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByCoinNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coinName', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByFavouriteOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'favouriteOrderIndex', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByFavouriteOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'favouriteOrderIndex', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByIsFavourite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavourite', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByIsFavouriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavourite', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByMainAddressType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainAddressType', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByMainAddressTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainAddressType', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByOtherDataJsonString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherDataJsonString', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      sortByOtherDataJsonStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherDataJsonString', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByRestoreHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restoreHeight', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByRestoreHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restoreHeight', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension WalletInfoQuerySortThenBy
    on QueryBuilder<WalletInfo, WalletInfo, QSortThenBy> {
  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByCachedBalanceSecondaryString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceSecondaryString', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByCachedBalanceSecondaryStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceSecondaryString', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByCachedBalanceString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceString', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByCachedBalanceStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceString', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByCachedBalanceTertiaryString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceTertiaryString', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByCachedBalanceTertiaryStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceTertiaryString', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByCachedChainHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedChainHeight', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByCachedChainHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedChainHeight', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByCachedReceivingAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedReceivingAddress', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByCachedReceivingAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedReceivingAddress', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByCoinName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coinName', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByCoinNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coinName', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByFavouriteOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'favouriteOrderIndex', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByFavouriteOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'favouriteOrderIndex', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByIsFavourite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavourite', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByIsFavouriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavourite', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByMainAddressType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainAddressType', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByMainAddressTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainAddressType', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByOtherDataJsonString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherDataJsonString', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy>
      thenByOtherDataJsonStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherDataJsonString', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByRestoreHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restoreHeight', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByRestoreHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restoreHeight', Sort.desc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QAfterSortBy> thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension WalletInfoQueryWhereDistinct
    on QueryBuilder<WalletInfo, WalletInfo, QDistinct> {
  QueryBuilder<WalletInfo, WalletInfo, QDistinct>
      distinctByCachedBalanceSecondaryString({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedBalanceSecondaryString',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct> distinctByCachedBalanceString(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedBalanceString',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct>
      distinctByCachedBalanceTertiaryString({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedBalanceTertiaryString',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct>
      distinctByCachedChainHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedChainHeight');
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct>
      distinctByCachedReceivingAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedReceivingAddress',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct> distinctByCoinName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coinName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct>
      distinctByFavouriteOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'favouriteOrderIndex');
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct> distinctByIsFavourite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavourite');
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct> distinctByMainAddressType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mainAddressType');
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct> distinctByOtherDataJsonString(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherDataJsonString',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct> distinctByRestoreHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restoreHeight');
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct>
      distinctByTokenContractAddresses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tokenContractAddresses');
    });
  }

  QueryBuilder<WalletInfo, WalletInfo, QDistinct> distinctByWalletId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension WalletInfoQueryProperty
    on QueryBuilder<WalletInfo, WalletInfo, QQueryProperty> {
  QueryBuilder<WalletInfo, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WalletInfo, String?, QQueryOperations>
      cachedBalanceSecondaryStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedBalanceSecondaryString');
    });
  }

  QueryBuilder<WalletInfo, String?, QQueryOperations>
      cachedBalanceStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedBalanceString');
    });
  }

  QueryBuilder<WalletInfo, String?, QQueryOperations>
      cachedBalanceTertiaryStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedBalanceTertiaryString');
    });
  }

  QueryBuilder<WalletInfo, int, QQueryOperations> cachedChainHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedChainHeight');
    });
  }

  QueryBuilder<WalletInfo, String, QQueryOperations>
      cachedReceivingAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedReceivingAddress');
    });
  }

  QueryBuilder<WalletInfo, String, QQueryOperations> coinNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coinName');
    });
  }

  QueryBuilder<WalletInfo, int, QQueryOperations>
      favouriteOrderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'favouriteOrderIndex');
    });
  }

  QueryBuilder<WalletInfo, bool, QQueryOperations> isFavouriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavourite');
    });
  }

  QueryBuilder<WalletInfo, AddressType, QQueryOperations>
      mainAddressTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mainAddressType');
    });
  }

  QueryBuilder<WalletInfo, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<WalletInfo, String?, QQueryOperations>
      otherDataJsonStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherDataJsonString');
    });
  }

  QueryBuilder<WalletInfo, int, QQueryOperations> restoreHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restoreHeight');
    });
  }

  QueryBuilder<WalletInfo, List<String>, QQueryOperations>
      tokenContractAddressesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tokenContractAddresses');
    });
  }

  QueryBuilder<WalletInfo, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

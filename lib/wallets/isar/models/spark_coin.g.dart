// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spark_coin.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSparkCoinCollection on Isar {
  IsarCollection<SparkCoin> get sparkCoins => this.collection();
}

const SparkCoinSchema = CollectionSchema(
  name: r'SparkCoin',
  id: -187103855721793545,
  properties: {
    r'address': PropertySchema(id: 0, name: r'address', type: IsarType.string),
    r'contextB64': PropertySchema(
      id: 1,
      name: r'contextB64',
      type: IsarType.string,
    ),
    r'diversifierIntString': PropertySchema(
      id: 2,
      name: r'diversifierIntString',
      type: IsarType.string,
    ),
    r'encryptedDiversifier': PropertySchema(
      id: 3,
      name: r'encryptedDiversifier',
      type: IsarType.longList,
    ),
    r'groupId': PropertySchema(id: 4, name: r'groupId', type: IsarType.long),
    r'height': PropertySchema(id: 5, name: r'height', type: IsarType.long),
    r'isUsed': PropertySchema(id: 6, name: r'isUsed', type: IsarType.bool),
    r'lTagHash': PropertySchema(
      id: 7,
      name: r'lTagHash',
      type: IsarType.string,
    ),
    r'memo': PropertySchema(id: 8, name: r'memo', type: IsarType.string),
    r'nonce': PropertySchema(id: 9, name: r'nonce', type: IsarType.longList),
    r'serial': PropertySchema(id: 10, name: r'serial', type: IsarType.longList),
    r'serialContext': PropertySchema(
      id: 11,
      name: r'serialContext',
      type: IsarType.longList,
    ),
    r'serializedCoinB64': PropertySchema(
      id: 12,
      name: r'serializedCoinB64',
      type: IsarType.string,
    ),
    r'tag': PropertySchema(id: 13, name: r'tag', type: IsarType.longList),
    r'txHash': PropertySchema(id: 14, name: r'txHash', type: IsarType.string),
    r'type': PropertySchema(
      id: 15,
      name: r'type',
      type: IsarType.byte,
      enumMap: _SparkCointypeEnumValueMap,
    ),
    r'valueIntString': PropertySchema(
      id: 16,
      name: r'valueIntString',
      type: IsarType.string,
    ),
    r'walletId': PropertySchema(
      id: 17,
      name: r'walletId',
      type: IsarType.string,
    ),
    r'zzzIsLocked': PropertySchema(
      id: 18,
      name: r'zzzIsLocked',
      type: IsarType.bool,
    ),
  },

  estimateSize: _sparkCoinEstimateSize,
  serialize: _sparkCoinSerialize,
  deserialize: _sparkCoinDeserialize,
  deserializeProp: _sparkCoinDeserializeProp,
  idName: r'id',
  indexes: {
    r'walletId_lTagHash': IndexSchema(
      id: 3478068730295484116,
      name: r'walletId_lTagHash',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'walletId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'lTagHash',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _sparkCoinGetId,
  getLinks: _sparkCoinGetLinks,
  attach: _sparkCoinAttach,
  version: '3.3.0-dev.2',
);

int _sparkCoinEstimateSize(
  SparkCoin object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.address.length * 3;
  {
    final value = object.contextB64;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.diversifierIntString.length * 3;
  {
    final value = object.encryptedDiversifier;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.lTagHash.length * 3;
  {
    final value = object.memo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.nonce;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.serial;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.serialContext;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.serializedCoinB64;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.tag;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.txHash.length * 3;
  bytesCount += 3 + object.valueIntString.length * 3;
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _sparkCoinSerialize(
  SparkCoin object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeString(offsets[1], object.contextB64);
  writer.writeString(offsets[2], object.diversifierIntString);
  writer.writeLongList(offsets[3], object.encryptedDiversifier);
  writer.writeLong(offsets[4], object.groupId);
  writer.writeLong(offsets[5], object.height);
  writer.writeBool(offsets[6], object.isUsed);
  writer.writeString(offsets[7], object.lTagHash);
  writer.writeString(offsets[8], object.memo);
  writer.writeLongList(offsets[9], object.nonce);
  writer.writeLongList(offsets[10], object.serial);
  writer.writeLongList(offsets[11], object.serialContext);
  writer.writeString(offsets[12], object.serializedCoinB64);
  writer.writeLongList(offsets[13], object.tag);
  writer.writeString(offsets[14], object.txHash);
  writer.writeByte(offsets[15], object.type.index);
  writer.writeString(offsets[16], object.valueIntString);
  writer.writeString(offsets[17], object.walletId);
  writer.writeBool(offsets[18], object.isLocked);
}

SparkCoin _sparkCoinDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SparkCoin(
    address: reader.readString(offsets[0]),
    contextB64: reader.readStringOrNull(offsets[1]),
    diversifierIntString: reader.readString(offsets[2]),
    encryptedDiversifier: reader.readLongList(offsets[3]),
    groupId: reader.readLong(offsets[4]),
    height: reader.readLongOrNull(offsets[5]),
    isUsed: reader.readBool(offsets[6]),
    lTagHash: reader.readString(offsets[7]),
    memo: reader.readStringOrNull(offsets[8]),
    nonce: reader.readLongList(offsets[9]),
    serial: reader.readLongList(offsets[10]),
    serialContext: reader.readLongList(offsets[11]),
    serializedCoinB64: reader.readStringOrNull(offsets[12]),
    tag: reader.readLongList(offsets[13]),
    txHash: reader.readString(offsets[14]),
    type:
        _SparkCointypeValueEnumMap[reader.readByteOrNull(offsets[15])] ??
        SparkCoinType.mint,
    valueIntString: reader.readString(offsets[16]),
    walletId: reader.readString(offsets[17]),
    isLocked: reader.readBoolOrNull(offsets[18]),
  );
  object.id = id;
  return object;
}

P _sparkCoinDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLongList(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLongList(offset)) as P;
    case 10:
      return (reader.readLongList(offset)) as P;
    case 11:
      return (reader.readLongList(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readLongList(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (_SparkCointypeValueEnumMap[reader.readByteOrNull(offset)] ??
              SparkCoinType.mint)
          as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readBoolOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SparkCointypeEnumValueMap = {'mint': 0, 'spend': 1};
const _SparkCointypeValueEnumMap = {
  0: SparkCoinType.mint,
  1: SparkCoinType.spend,
};

Id _sparkCoinGetId(SparkCoin object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _sparkCoinGetLinks(SparkCoin object) {
  return [];
}

void _sparkCoinAttach(IsarCollection<dynamic> col, Id id, SparkCoin object) {
  object.id = id;
}

extension SparkCoinByIndex on IsarCollection<SparkCoin> {
  Future<SparkCoin?> getByWalletIdLTagHash(String walletId, String lTagHash) {
    return getByIndex(r'walletId_lTagHash', [walletId, lTagHash]);
  }

  SparkCoin? getByWalletIdLTagHashSync(String walletId, String lTagHash) {
    return getByIndexSync(r'walletId_lTagHash', [walletId, lTagHash]);
  }

  Future<bool> deleteByWalletIdLTagHash(String walletId, String lTagHash) {
    return deleteByIndex(r'walletId_lTagHash', [walletId, lTagHash]);
  }

  bool deleteByWalletIdLTagHashSync(String walletId, String lTagHash) {
    return deleteByIndexSync(r'walletId_lTagHash', [walletId, lTagHash]);
  }

  Future<List<SparkCoin?>> getAllByWalletIdLTagHash(
    List<String> walletIdValues,
    List<String> lTagHashValues,
  ) {
    final len = walletIdValues.length;
    assert(
      lTagHashValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([walletIdValues[i], lTagHashValues[i]]);
    }

    return getAllByIndex(r'walletId_lTagHash', values);
  }

  List<SparkCoin?> getAllByWalletIdLTagHashSync(
    List<String> walletIdValues,
    List<String> lTagHashValues,
  ) {
    final len = walletIdValues.length;
    assert(
      lTagHashValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([walletIdValues[i], lTagHashValues[i]]);
    }

    return getAllByIndexSync(r'walletId_lTagHash', values);
  }

  Future<int> deleteAllByWalletIdLTagHash(
    List<String> walletIdValues,
    List<String> lTagHashValues,
  ) {
    final len = walletIdValues.length;
    assert(
      lTagHashValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([walletIdValues[i], lTagHashValues[i]]);
    }

    return deleteAllByIndex(r'walletId_lTagHash', values);
  }

  int deleteAllByWalletIdLTagHashSync(
    List<String> walletIdValues,
    List<String> lTagHashValues,
  ) {
    final len = walletIdValues.length;
    assert(
      lTagHashValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([walletIdValues[i], lTagHashValues[i]]);
    }

    return deleteAllByIndexSync(r'walletId_lTagHash', values);
  }

  Future<Id> putByWalletIdLTagHash(SparkCoin object) {
    return putByIndex(r'walletId_lTagHash', object);
  }

  Id putByWalletIdLTagHashSync(SparkCoin object, {bool saveLinks = true}) {
    return putByIndexSync(r'walletId_lTagHash', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByWalletIdLTagHash(List<SparkCoin> objects) {
    return putAllByIndex(r'walletId_lTagHash', objects);
  }

  List<Id> putAllByWalletIdLTagHashSync(
    List<SparkCoin> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'walletId_lTagHash',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension SparkCoinQueryWhereSort
    on QueryBuilder<SparkCoin, SparkCoin, QWhere> {
  QueryBuilder<SparkCoin, SparkCoin, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SparkCoinQueryWhere
    on QueryBuilder<SparkCoin, SparkCoin, QWhereClause> {
  QueryBuilder<SparkCoin, SparkCoin, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<SparkCoin, SparkCoin, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterWhereClause> idBetween(
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

  QueryBuilder<SparkCoin, SparkCoin, QAfterWhereClause>
  walletIdEqualToAnyLTagHash(String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'walletId_lTagHash',
          value: [walletId],
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterWhereClause>
  walletIdNotEqualToAnyLTagHash(String walletId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId_lTagHash',
                lower: [],
                upper: [walletId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId_lTagHash',
                lower: [walletId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId_lTagHash',
                lower: [walletId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId_lTagHash',
                lower: [],
                upper: [walletId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterWhereClause> walletIdLTagHashEqualTo(
    String walletId,
    String lTagHash,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'walletId_lTagHash',
          value: [walletId, lTagHash],
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterWhereClause>
  walletIdEqualToLTagHashNotEqualTo(String walletId, String lTagHash) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId_lTagHash',
                lower: [walletId],
                upper: [walletId, lTagHash],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId_lTagHash',
                lower: [walletId, lTagHash],
                includeLower: false,
                upper: [walletId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId_lTagHash',
                lower: [walletId, lTagHash],
                includeLower: false,
                upper: [walletId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId_lTagHash',
                lower: [walletId],
                upper: [walletId, lTagHash],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SparkCoinQueryFilter
    on QueryBuilder<SparkCoin, SparkCoin, QFilterCondition> {
  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> addressEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> addressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> addressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> addressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'address',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> addressContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> addressMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'address',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> contextB64IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'contextB64'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  contextB64IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'contextB64'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> contextB64EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contextB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  contextB64GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contextB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> contextB64LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contextB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> contextB64Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contextB64',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  contextB64StartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contextB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> contextB64EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contextB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> contextB64Contains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contextB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> contextB64Matches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contextB64',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  contextB64IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contextB64', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  contextB64IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contextB64', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'diversifierIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'diversifierIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'diversifierIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'diversifierIntString',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'diversifierIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'diversifierIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'diversifierIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'diversifierIntString',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'diversifierIntString', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  diversifierIntStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'diversifierIntString',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'encryptedDiversifier'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'encryptedDiversifier'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'encryptedDiversifier',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'encryptedDiversifier',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'encryptedDiversifier',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'encryptedDiversifier',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedDiversifier',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'encryptedDiversifier', 0, true, 0, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'encryptedDiversifier', 0, false, 999999, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedDiversifier',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedDiversifier',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  encryptedDiversifierLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedDiversifier',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> groupIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'groupId', value: value),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> groupIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'groupId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> groupIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'groupId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> groupIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'groupId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'height'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'height'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> heightEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'height', value: value),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> heightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'height',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> heightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'height',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> heightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'height',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> isUsedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isUsed', value: value),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> lTagHashEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lTagHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> lTagHashGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lTagHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> lTagHashLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lTagHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> lTagHashBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lTagHash',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> lTagHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lTagHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> lTagHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lTagHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> lTagHashContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lTagHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> lTagHashMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lTagHash',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> lTagHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lTagHash', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  lTagHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lTagHash', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'memo'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'memo'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'memo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'memo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'memo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'memo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'memo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'memo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'memo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'memo',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'memo', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> memoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'memo', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> nonceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'nonce'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> nonceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'nonce'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> nonceElementEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nonce', value: value),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  nonceElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nonce',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  nonceElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nonce',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> nonceElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nonce',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> nonceLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'nonce', length, true, length, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> nonceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'nonce', 0, true, 0, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> nonceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'nonce', 0, false, 999999, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> nonceLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'nonce', 0, true, length, include);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  nonceLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'nonce', length, include, 999999, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> nonceLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'nonce',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> serialIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serial'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> serialIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serial'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serial', value: value),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serial',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serial',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serial',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> serialLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serial', length, true, length, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> serialIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serial', 0, true, 0, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> serialIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serial', 0, false, 999999, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serial', 0, true, length, include);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serial', length, include, 999999, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> serialLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'serial',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serialContext'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serialContext'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serialContext', value: value),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serialContext',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serialContext',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serialContext',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serialContext', length, true, length, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serialContext', 0, true, 0, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serialContext', 0, false, 999999, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serialContext', 0, true, length, include);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'serialContext', length, include, 999999, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serialContextLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'serialContext',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serializedCoinB64'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serializedCoinB64'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64EqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'serializedCoinB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serializedCoinB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serializedCoinB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serializedCoinB64',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64StartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'serializedCoinB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64EndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'serializedCoinB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'serializedCoinB64',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'serializedCoinB64',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serializedCoinB64', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  serializedCoinB64IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serializedCoinB64', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'tag'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'tag'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagElementEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tag', value: value),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  tagElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tag',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tag',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tag',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tag', length, true, length, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tag', 0, true, 0, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tag', 0, false, 999999, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tag', 0, true, length, include);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  tagLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tag', length, include, 999999, true);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> tagLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tag', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'txHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'txHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'txHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'txHash',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'txHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'txHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'txHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'txHash',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'txHash', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> txHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'txHash', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> typeEqualTo(
    SparkCoinType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: value),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> typeGreaterThan(
    SparkCoinType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> typeLessThan(
    SparkCoinType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> typeBetween(
    SparkCoinType lower,
    SparkCoinType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'valueIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'valueIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'valueIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'valueIntString',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'valueIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'valueIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'valueIntString',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'valueIntString',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'valueIntString', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  valueIntStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'valueIntString', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> walletIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'walletId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> walletIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'walletId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> walletIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'walletId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> walletIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'walletId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> walletIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'walletId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> walletIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'walletId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> walletIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'walletId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> walletIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'walletId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'walletId', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'walletId', value: ''),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> isLockedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'zzzIsLocked'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition>
  isLockedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'zzzIsLocked'),
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterFilterCondition> isLockedEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'zzzIsLocked', value: value),
      );
    });
  }
}

extension SparkCoinQueryObject
    on QueryBuilder<SparkCoin, SparkCoin, QFilterCondition> {}

extension SparkCoinQueryLinks
    on QueryBuilder<SparkCoin, SparkCoin, QFilterCondition> {}

extension SparkCoinQuerySortBy on QueryBuilder<SparkCoin, SparkCoin, QSortBy> {
  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByContextB64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextB64', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByContextB64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextB64', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy>
  sortByDiversifierIntString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diversifierIntString', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy>
  sortByDiversifierIntStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diversifierIntString', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByIsUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUsed', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByIsUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUsed', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByLTagHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lTagHash', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByLTagHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lTagHash', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByMemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memo', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByMemoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memo', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortBySerializedCoinB64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedCoinB64', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy>
  sortBySerializedCoinB64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedCoinB64', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByTxHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txHash', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByTxHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txHash', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByValueIntString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueIntString', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByValueIntStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueIntString', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zzzIsLocked', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> sortByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zzzIsLocked', Sort.desc);
    });
  }
}

extension SparkCoinQuerySortThenBy
    on QueryBuilder<SparkCoin, SparkCoin, QSortThenBy> {
  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByContextB64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextB64', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByContextB64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contextB64', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy>
  thenByDiversifierIntString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diversifierIntString', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy>
  thenByDiversifierIntStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diversifierIntString', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupId', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByIsUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUsed', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByIsUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUsed', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByLTagHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lTagHash', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByLTagHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lTagHash', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByMemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memo', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByMemoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memo', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenBySerializedCoinB64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedCoinB64', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy>
  thenBySerializedCoinB64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serializedCoinB64', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByTxHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txHash', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByTxHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txHash', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByValueIntString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueIntString', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByValueIntStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueIntString', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zzzIsLocked', Sort.asc);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QAfterSortBy> thenByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zzzIsLocked', Sort.desc);
    });
  }
}

extension SparkCoinQueryWhereDistinct
    on QueryBuilder<SparkCoin, SparkCoin, QDistinct> {
  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByAddress({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByContextB64({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contextB64', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByDiversifierIntString({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'diversifierIntString',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct>
  distinctByEncryptedDiversifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encryptedDiversifier');
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupId');
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByIsUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUsed');
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByLTagHash({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lTagHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByMemo({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nonce');
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctBySerial() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serial');
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctBySerialContext() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serialContext');
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctBySerializedCoinB64({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'serializedCoinB64',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tag');
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByTxHash({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'txHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByValueIntString({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'valueIntString',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByWalletId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SparkCoin, SparkCoin, QDistinct> distinctByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'zzzIsLocked');
    });
  }
}

extension SparkCoinQueryProperty
    on QueryBuilder<SparkCoin, SparkCoin, QQueryProperty> {
  QueryBuilder<SparkCoin, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SparkCoin, String, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<SparkCoin, String?, QQueryOperations> contextB64Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contextB64');
    });
  }

  QueryBuilder<SparkCoin, String, QQueryOperations>
  diversifierIntStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'diversifierIntString');
    });
  }

  QueryBuilder<SparkCoin, List<int>?, QQueryOperations>
  encryptedDiversifierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encryptedDiversifier');
    });
  }

  QueryBuilder<SparkCoin, int, QQueryOperations> groupIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupId');
    });
  }

  QueryBuilder<SparkCoin, int?, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<SparkCoin, bool, QQueryOperations> isUsedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUsed');
    });
  }

  QueryBuilder<SparkCoin, String, QQueryOperations> lTagHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lTagHash');
    });
  }

  QueryBuilder<SparkCoin, String?, QQueryOperations> memoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memo');
    });
  }

  QueryBuilder<SparkCoin, List<int>?, QQueryOperations> nonceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nonce');
    });
  }

  QueryBuilder<SparkCoin, List<int>?, QQueryOperations> serialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serial');
    });
  }

  QueryBuilder<SparkCoin, List<int>?, QQueryOperations>
  serialContextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serialContext');
    });
  }

  QueryBuilder<SparkCoin, String?, QQueryOperations>
  serializedCoinB64Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serializedCoinB64');
    });
  }

  QueryBuilder<SparkCoin, List<int>?, QQueryOperations> tagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tag');
    });
  }

  QueryBuilder<SparkCoin, String, QQueryOperations> txHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'txHash');
    });
  }

  QueryBuilder<SparkCoin, SparkCoinType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<SparkCoin, String, QQueryOperations> valueIntStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valueIntString');
    });
  }

  QueryBuilder<SparkCoin, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }

  QueryBuilder<SparkCoin, bool?, QQueryOperations> isLockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'zzzIsLocked');
    });
  }
}

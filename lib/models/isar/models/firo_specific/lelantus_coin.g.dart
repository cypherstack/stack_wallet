// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lelantus_coin.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetLelantusCoinCollection on Isar {
  IsarCollection<LelantusCoin> get lelantusCoins => this.collection();
}

const LelantusCoinSchema = CollectionSchema(
  name: r'LelantusCoin',
  id: -6795633185033299066,
  properties: {
    r'anonymitySetId': PropertySchema(
      id: 0,
      name: r'anonymitySetId',
      type: IsarType.long,
    ),
    r'index': PropertySchema(
      id: 1,
      name: r'index',
      type: IsarType.long,
    ),
    r'isUsed': PropertySchema(
      id: 2,
      name: r'isUsed',
      type: IsarType.bool,
    ),
    r'publicCoin': PropertySchema(
      id: 3,
      name: r'publicCoin',
      type: IsarType.string,
    ),
    r'txid': PropertySchema(
      id: 4,
      name: r'txid',
      type: IsarType.string,
    ),
    r'value': PropertySchema(
      id: 5,
      name: r'value',
      type: IsarType.string,
    ),
    r'walletId': PropertySchema(
      id: 6,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _lelantusCoinEstimateSize,
  serialize: _lelantusCoinSerialize,
  deserialize: _lelantusCoinDeserialize,
  deserializeProp: _lelantusCoinDeserializeProp,
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
    r'publicCoin_walletId_txid': IndexSchema(
      id: 5610740154835640070,
      name: r'publicCoin_walletId_txid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'publicCoin',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'walletId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'txid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _lelantusCoinGetId,
  getLinks: _lelantusCoinGetLinks,
  attach: _lelantusCoinAttach,
  version: '3.0.5',
);

int _lelantusCoinEstimateSize(
  LelantusCoin object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.publicCoin.length * 3;
  bytesCount += 3 + object.txid.length * 3;
  bytesCount += 3 + object.value.length * 3;
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _lelantusCoinSerialize(
  LelantusCoin object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.anonymitySetId);
  writer.writeLong(offsets[1], object.index);
  writer.writeBool(offsets[2], object.isUsed);
  writer.writeString(offsets[3], object.publicCoin);
  writer.writeString(offsets[4], object.txid);
  writer.writeString(offsets[5], object.value);
  writer.writeString(offsets[6], object.walletId);
}

LelantusCoin _lelantusCoinDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LelantusCoin(
    anonymitySetId: reader.readLong(offsets[0]),
    index: reader.readLong(offsets[1]),
    isUsed: reader.readBool(offsets[2]),
    publicCoin: reader.readString(offsets[3]),
    txid: reader.readString(offsets[4]),
    value: reader.readString(offsets[5]),
    walletId: reader.readString(offsets[6]),
  );
  object.id = id;
  return object;
}

P _lelantusCoinDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _lelantusCoinGetId(LelantusCoin object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _lelantusCoinGetLinks(LelantusCoin object) {
  return [];
}

void _lelantusCoinAttach(
    IsarCollection<dynamic> col, Id id, LelantusCoin object) {
  object.id = id;
}

extension LelantusCoinByIndex on IsarCollection<LelantusCoin> {
  Future<LelantusCoin?> getByPublicCoinWalletIdTxid(
      String publicCoin, String walletId, String txid) {
    return getByIndex(
        r'publicCoin_walletId_txid', [publicCoin, walletId, txid]);
  }

  LelantusCoin? getByPublicCoinWalletIdTxidSync(
      String publicCoin, String walletId, String txid) {
    return getByIndexSync(
        r'publicCoin_walletId_txid', [publicCoin, walletId, txid]);
  }

  Future<bool> deleteByPublicCoinWalletIdTxid(
      String publicCoin, String walletId, String txid) {
    return deleteByIndex(
        r'publicCoin_walletId_txid', [publicCoin, walletId, txid]);
  }

  bool deleteByPublicCoinWalletIdTxidSync(
      String publicCoin, String walletId, String txid) {
    return deleteByIndexSync(
        r'publicCoin_walletId_txid', [publicCoin, walletId, txid]);
  }

  Future<List<LelantusCoin?>> getAllByPublicCoinWalletIdTxid(
      List<String> publicCoinValues,
      List<String> walletIdValues,
      List<String> txidValues) {
    final len = publicCoinValues.length;
    assert(walletIdValues.length == len && txidValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([publicCoinValues[i], walletIdValues[i], txidValues[i]]);
    }

    return getAllByIndex(r'publicCoin_walletId_txid', values);
  }

  List<LelantusCoin?> getAllByPublicCoinWalletIdTxidSync(
      List<String> publicCoinValues,
      List<String> walletIdValues,
      List<String> txidValues) {
    final len = publicCoinValues.length;
    assert(walletIdValues.length == len && txidValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([publicCoinValues[i], walletIdValues[i], txidValues[i]]);
    }

    return getAllByIndexSync(r'publicCoin_walletId_txid', values);
  }

  Future<int> deleteAllByPublicCoinWalletIdTxid(List<String> publicCoinValues,
      List<String> walletIdValues, List<String> txidValues) {
    final len = publicCoinValues.length;
    assert(walletIdValues.length == len && txidValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([publicCoinValues[i], walletIdValues[i], txidValues[i]]);
    }

    return deleteAllByIndex(r'publicCoin_walletId_txid', values);
  }

  int deleteAllByPublicCoinWalletIdTxidSync(List<String> publicCoinValues,
      List<String> walletIdValues, List<String> txidValues) {
    final len = publicCoinValues.length;
    assert(walletIdValues.length == len && txidValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([publicCoinValues[i], walletIdValues[i], txidValues[i]]);
    }

    return deleteAllByIndexSync(r'publicCoin_walletId_txid', values);
  }

  Future<Id> putByPublicCoinWalletIdTxid(LelantusCoin object) {
    return putByIndex(r'publicCoin_walletId_txid', object);
  }

  Id putByPublicCoinWalletIdTxidSync(LelantusCoin object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'publicCoin_walletId_txid', object,
        saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPublicCoinWalletIdTxid(List<LelantusCoin> objects) {
    return putAllByIndex(r'publicCoin_walletId_txid', objects);
  }

  List<Id> putAllByPublicCoinWalletIdTxidSync(List<LelantusCoin> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'publicCoin_walletId_txid', objects,
        saveLinks: saveLinks);
  }
}

extension LelantusCoinQueryWhereSort
    on QueryBuilder<LelantusCoin, LelantusCoin, QWhere> {
  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LelantusCoinQueryWhere
    on QueryBuilder<LelantusCoin, LelantusCoin, QWhereClause> {
  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause> idBetween(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause> walletIdEqualTo(
      String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause>
      walletIdNotEqualTo(String walletId) {
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause>
      publicCoinEqualToAnyWalletIdTxid(String publicCoin) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'publicCoin_walletId_txid',
        value: [publicCoin],
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause>
      publicCoinNotEqualToAnyWalletIdTxid(String publicCoin) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [],
              upper: [publicCoin],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [],
              upper: [publicCoin],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause>
      publicCoinWalletIdEqualToAnyTxid(String publicCoin, String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'publicCoin_walletId_txid',
        value: [publicCoin, walletId],
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause>
      publicCoinEqualToWalletIdNotEqualToAnyTxid(
          String publicCoin, String walletId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin],
              upper: [publicCoin, walletId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin, walletId],
              includeLower: false,
              upper: [publicCoin],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin, walletId],
              includeLower: false,
              upper: [publicCoin],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin],
              upper: [publicCoin, walletId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause>
      publicCoinWalletIdTxidEqualTo(
          String publicCoin, String walletId, String txid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'publicCoin_walletId_txid',
        value: [publicCoin, walletId, txid],
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterWhereClause>
      publicCoinWalletIdEqualToTxidNotEqualTo(
          String publicCoin, String walletId, String txid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin, walletId],
              upper: [publicCoin, walletId, txid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin, walletId, txid],
              includeLower: false,
              upper: [publicCoin, walletId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin, walletId, txid],
              includeLower: false,
              upper: [publicCoin, walletId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'publicCoin_walletId_txid',
              lower: [publicCoin, walletId],
              upper: [publicCoin, walletId, txid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LelantusCoinQueryFilter
    on QueryBuilder<LelantusCoin, LelantusCoin, QFilterCondition> {
  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      anonymitySetIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'anonymitySetId',
        value: value,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      anonymitySetIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'anonymitySetId',
        value: value,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      anonymitySetIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'anonymitySetId',
        value: value,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      anonymitySetIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'anonymitySetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> idBetween(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> indexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      indexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> indexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> indexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'index',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> isUsedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'publicCoin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'publicCoin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'publicCoin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'publicCoin',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'publicCoin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'publicCoin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'publicCoin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'publicCoin',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'publicCoin',
        value: '',
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      publicCoinIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'publicCoin',
        value: '',
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> txidEqualTo(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      txidGreaterThan(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> txidLessThan(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> txidBetween(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      txidStartsWith(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> txidEndsWith(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> txidContains(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> txidMatches(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      txidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      txidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> valueEqualTo(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> valueLessThan(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> valueBetween(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> valueEndsWith(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> valueContains(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition> valueMatches(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      valueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      valueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      walletIdEqualTo(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      walletIdLessThan(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      walletIdBetween(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      walletIdEndsWith(
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

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      walletIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      walletIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterFilterCondition>
      walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension LelantusCoinQueryObject
    on QueryBuilder<LelantusCoin, LelantusCoin, QFilterCondition> {}

extension LelantusCoinQueryLinks
    on QueryBuilder<LelantusCoin, LelantusCoin, QFilterCondition> {}

extension LelantusCoinQuerySortBy
    on QueryBuilder<LelantusCoin, LelantusCoin, QSortBy> {
  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy>
      sortByAnonymitySetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anonymitySetId', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy>
      sortByAnonymitySetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anonymitySetId', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByIsUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUsed', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByIsUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUsed', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByPublicCoin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicCoin', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy>
      sortByPublicCoinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicCoin', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension LelantusCoinQuerySortThenBy
    on QueryBuilder<LelantusCoin, LelantusCoin, QSortThenBy> {
  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy>
      thenByAnonymitySetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anonymitySetId', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy>
      thenByAnonymitySetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anonymitySetId', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByIsUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUsed', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByIsUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isUsed', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByPublicCoin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicCoin', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy>
      thenByPublicCoinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'publicCoin', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QAfterSortBy> thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension LelantusCoinQueryWhereDistinct
    on QueryBuilder<LelantusCoin, LelantusCoin, QDistinct> {
  QueryBuilder<LelantusCoin, LelantusCoin, QDistinct>
      distinctByAnonymitySetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'anonymitySetId');
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QDistinct> distinctByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'index');
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QDistinct> distinctByIsUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isUsed');
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QDistinct> distinctByPublicCoin(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'publicCoin', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QDistinct> distinctByTxid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'txid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QDistinct> distinctByValue(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LelantusCoin, LelantusCoin, QDistinct> distinctByWalletId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension LelantusCoinQueryProperty
    on QueryBuilder<LelantusCoin, LelantusCoin, QQueryProperty> {
  QueryBuilder<LelantusCoin, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LelantusCoin, int, QQueryOperations> anonymitySetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'anonymitySetId');
    });
  }

  QueryBuilder<LelantusCoin, int, QQueryOperations> indexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'index');
    });
  }

  QueryBuilder<LelantusCoin, bool, QQueryOperations> isUsedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isUsed');
    });
  }

  QueryBuilder<LelantusCoin, String, QQueryOperations> publicCoinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'publicCoin');
    });
  }

  QueryBuilder<LelantusCoin, String, QQueryOperations> txidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'txid');
    });
  }

  QueryBuilder<LelantusCoin, String, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }

  QueryBuilder<LelantusCoin, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

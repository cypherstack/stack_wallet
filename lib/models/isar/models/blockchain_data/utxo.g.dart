// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'utxo.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetUTXOCollection on Isar {
  IsarCollection<UTXO> get utxos => this.collection();
}

const UTXOSchema = CollectionSchema(
  name: r'UTXO',
  id: 5934032492047519621,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'blockHash': PropertySchema(
      id: 1,
      name: r'blockHash',
      type: IsarType.string,
    ),
    r'blockHeight': PropertySchema(
      id: 2,
      name: r'blockHeight',
      type: IsarType.long,
    ),
    r'blockTime': PropertySchema(
      id: 3,
      name: r'blockTime',
      type: IsarType.long,
    ),
    r'blockedReason': PropertySchema(
      id: 4,
      name: r'blockedReason',
      type: IsarType.string,
    ),
    r'isBlocked': PropertySchema(
      id: 5,
      name: r'isBlocked',
      type: IsarType.bool,
    ),
    r'isCoinbase': PropertySchema(
      id: 6,
      name: r'isCoinbase',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 7,
      name: r'name',
      type: IsarType.string,
    ),
    r'otherData': PropertySchema(
      id: 8,
      name: r'otherData',
      type: IsarType.string,
    ),
    r'txid': PropertySchema(
      id: 9,
      name: r'txid',
      type: IsarType.string,
    ),
    r'value': PropertySchema(
      id: 10,
      name: r'value',
      type: IsarType.long,
    ),
    r'vout': PropertySchema(
      id: 11,
      name: r'vout',
      type: IsarType.long,
    ),
    r'walletId': PropertySchema(
      id: 12,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _uTXOEstimateSize,
  serialize: _uTXOSerialize,
  deserialize: _uTXODeserialize,
  deserializeProp: _uTXODeserializeProp,
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
    r'txid_walletId_vout': IndexSchema(
      id: -2984264099359759359,
      name: r'txid_walletId_vout',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'txid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'walletId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'vout',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isBlocked': IndexSchema(
      id: 4270553749242334751,
      name: r'isBlocked',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isBlocked',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _uTXOGetId,
  getLinks: _uTXOGetLinks,
  attach: _uTXOAttach,
  version: '3.0.5',
);

int _uTXOEstimateSize(
  UTXO object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.address;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.blockHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.blockedReason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.otherData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.txid.length * 3;
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _uTXOSerialize(
  UTXO object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeString(offsets[1], object.blockHash);
  writer.writeLong(offsets[2], object.blockHeight);
  writer.writeLong(offsets[3], object.blockTime);
  writer.writeString(offsets[4], object.blockedReason);
  writer.writeBool(offsets[5], object.isBlocked);
  writer.writeBool(offsets[6], object.isCoinbase);
  writer.writeString(offsets[7], object.name);
  writer.writeString(offsets[8], object.otherData);
  writer.writeString(offsets[9], object.txid);
  writer.writeLong(offsets[10], object.value);
  writer.writeLong(offsets[11], object.vout);
  writer.writeString(offsets[12], object.walletId);
}

UTXO _uTXODeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UTXO(
    address: reader.readStringOrNull(offsets[0]),
    blockHash: reader.readStringOrNull(offsets[1]),
    blockHeight: reader.readLongOrNull(offsets[2]),
    blockTime: reader.readLongOrNull(offsets[3]),
    blockedReason: reader.readStringOrNull(offsets[4]),
    isBlocked: reader.readBool(offsets[5]),
    isCoinbase: reader.readBool(offsets[6]),
    name: reader.readString(offsets[7]),
    otherData: reader.readStringOrNull(offsets[8]),
    txid: reader.readString(offsets[9]),
    value: reader.readLong(offsets[10]),
    vout: reader.readLong(offsets[11]),
    walletId: reader.readString(offsets[12]),
  );
  object.id = id;
  return object;
}

P _uTXODeserializeProp<P>(
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
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _uTXOGetId(UTXO object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _uTXOGetLinks(UTXO object) {
  return [];
}

void _uTXOAttach(IsarCollection<dynamic> col, Id id, UTXO object) {
  object.id = id;
}

extension UTXOByIndex on IsarCollection<UTXO> {
  Future<UTXO?> getByTxidWalletIdVout(String txid, String walletId, int vout) {
    return getByIndex(r'txid_walletId_vout', [txid, walletId, vout]);
  }

  UTXO? getByTxidWalletIdVoutSync(String txid, String walletId, int vout) {
    return getByIndexSync(r'txid_walletId_vout', [txid, walletId, vout]);
  }

  Future<bool> deleteByTxidWalletIdVout(
      String txid, String walletId, int vout) {
    return deleteByIndex(r'txid_walletId_vout', [txid, walletId, vout]);
  }

  bool deleteByTxidWalletIdVoutSync(String txid, String walletId, int vout) {
    return deleteByIndexSync(r'txid_walletId_vout', [txid, walletId, vout]);
  }

  Future<List<UTXO?>> getAllByTxidWalletIdVout(List<String> txidValues,
      List<String> walletIdValues, List<int> voutValues) {
    final len = txidValues.length;
    assert(walletIdValues.length == len && voutValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([txidValues[i], walletIdValues[i], voutValues[i]]);
    }

    return getAllByIndex(r'txid_walletId_vout', values);
  }

  List<UTXO?> getAllByTxidWalletIdVoutSync(List<String> txidValues,
      List<String> walletIdValues, List<int> voutValues) {
    final len = txidValues.length;
    assert(walletIdValues.length == len && voutValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([txidValues[i], walletIdValues[i], voutValues[i]]);
    }

    return getAllByIndexSync(r'txid_walletId_vout', values);
  }

  Future<int> deleteAllByTxidWalletIdVout(List<String> txidValues,
      List<String> walletIdValues, List<int> voutValues) {
    final len = txidValues.length;
    assert(walletIdValues.length == len && voutValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([txidValues[i], walletIdValues[i], voutValues[i]]);
    }

    return deleteAllByIndex(r'txid_walletId_vout', values);
  }

  int deleteAllByTxidWalletIdVoutSync(List<String> txidValues,
      List<String> walletIdValues, List<int> voutValues) {
    final len = txidValues.length;
    assert(walletIdValues.length == len && voutValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([txidValues[i], walletIdValues[i], voutValues[i]]);
    }

    return deleteAllByIndexSync(r'txid_walletId_vout', values);
  }

  Future<Id> putByTxidWalletIdVout(UTXO object) {
    return putByIndex(r'txid_walletId_vout', object);
  }

  Id putByTxidWalletIdVoutSync(UTXO object, {bool saveLinks = true}) {
    return putByIndexSync(r'txid_walletId_vout', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTxidWalletIdVout(List<UTXO> objects) {
    return putAllByIndex(r'txid_walletId_vout', objects);
  }

  List<Id> putAllByTxidWalletIdVoutSync(List<UTXO> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'txid_walletId_vout', objects,
        saveLinks: saveLinks);
  }
}

extension UTXOQueryWhereSort on QueryBuilder<UTXO, UTXO, QWhere> {
  QueryBuilder<UTXO, UTXO, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhere> anyIsBlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isBlocked'),
      );
    });
  }
}

extension UTXOQueryWhere on QueryBuilder<UTXO, UTXO, QWhereClause> {
  QueryBuilder<UTXO, UTXO, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> idBetween(
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

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> walletIdEqualTo(String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> walletIdNotEqualTo(
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

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> txidEqualToAnyWalletIdVout(
      String txid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'txid_walletId_vout',
        value: [txid],
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> txidNotEqualToAnyWalletIdVout(
      String txid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [],
              upper: [txid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [],
              upper: [txid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> txidWalletIdEqualToAnyVout(
      String txid, String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'txid_walletId_vout',
        value: [txid, walletId],
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause>
      txidEqualToWalletIdNotEqualToAnyVout(String txid, String walletId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid],
              upper: [txid, walletId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid, walletId],
              includeLower: false,
              upper: [txid],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid, walletId],
              includeLower: false,
              upper: [txid],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid],
              upper: [txid, walletId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> txidWalletIdVoutEqualTo(
      String txid, String walletId, int vout) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'txid_walletId_vout',
        value: [txid, walletId, vout],
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> txidWalletIdEqualToVoutNotEqualTo(
      String txid, String walletId, int vout) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid, walletId],
              upper: [txid, walletId, vout],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid, walletId, vout],
              includeLower: false,
              upper: [txid, walletId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid, walletId, vout],
              includeLower: false,
              upper: [txid, walletId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId_vout',
              lower: [txid, walletId],
              upper: [txid, walletId, vout],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause>
      txidWalletIdEqualToVoutGreaterThan(
    String txid,
    String walletId,
    int vout, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'txid_walletId_vout',
        lower: [txid, walletId, vout],
        includeLower: include,
        upper: [txid, walletId],
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> txidWalletIdEqualToVoutLessThan(
    String txid,
    String walletId,
    int vout, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'txid_walletId_vout',
        lower: [txid, walletId],
        upper: [txid, walletId, vout],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> txidWalletIdEqualToVoutBetween(
    String txid,
    String walletId,
    int lowerVout,
    int upperVout, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'txid_walletId_vout',
        lower: [txid, walletId, lowerVout],
        includeLower: includeLower,
        upper: [txid, walletId, upperVout],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> isBlockedEqualTo(bool isBlocked) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isBlocked',
        value: [isBlocked],
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterWhereClause> isBlockedNotEqualTo(
      bool isBlocked) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isBlocked',
              lower: [],
              upper: [isBlocked],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isBlocked',
              lower: [isBlocked],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isBlocked',
              lower: [isBlocked],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isBlocked',
              lower: [],
              upper: [isBlocked],
              includeUpper: false,
            ));
      }
    });
  }
}

extension UTXOQueryFilter on QueryBuilder<UTXO, UTXO, QFilterCondition> {
  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressEqualTo(
    String? value, {
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressGreaterThan(
    String? value, {
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressLessThan(
    String? value, {
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressStartsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressEndsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'blockHash',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'blockHash',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'blockHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'blockHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'blockHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'blockHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockHash',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'blockHash',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'blockHeight',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'blockHeight',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHeightEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHeightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHeightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockHeightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'blockTime',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'blockTime',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockTimeEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockTimeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockTimeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockTimeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'blockedReason',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'blockedReason',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockedReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockedReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockedReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockedReason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'blockedReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'blockedReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'blockedReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'blockedReason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockedReason',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> blockedReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'blockedReason',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> isBlockedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isBlocked',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> isCoinbaseEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCoinbase',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'otherData',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'otherData',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataEqualTo(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataGreaterThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataLessThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataBetween(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataStartsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataEndsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataContains(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataMatches(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherData',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> otherDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'otherData',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidEqualTo(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidGreaterThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidLessThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidBetween(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidStartsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidEndsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'txid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> txidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> valueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> valueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'value',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> valueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'value',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> valueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'value',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> voutEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vout',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> voutGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vout',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> voutLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vout',
        value: value,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> voutBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vout',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdEqualTo(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdGreaterThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdLessThan(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdBetween(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdStartsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdEndsWith(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdMatches(
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

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterFilterCondition> walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension UTXOQueryObject on QueryBuilder<UTXO, UTXO, QFilterCondition> {}

extension UTXOQueryLinks on QueryBuilder<UTXO, UTXO, QFilterCondition> {}

extension UTXOQuerySortBy on QueryBuilder<UTXO, UTXO, QSortBy> {
  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByBlockHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHash', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByBlockHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHash', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByBlockHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHeight', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByBlockHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHeight', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByBlockTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockTime', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByBlockTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockTime', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByBlockedReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedReason', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByBlockedReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedReason', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByIsBlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBlocked', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByIsBlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBlocked', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByIsCoinbase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCoinbase', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByIsCoinbaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCoinbase', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByOtherData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByOtherDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByVout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByVoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension UTXOQuerySortThenBy on QueryBuilder<UTXO, UTXO, QSortThenBy> {
  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByBlockHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHash', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByBlockHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHash', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByBlockHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHeight', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByBlockHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHeight', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByBlockTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockTime', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByBlockTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockTime', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByBlockedReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedReason', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByBlockedReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedReason', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByIsBlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBlocked', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByIsBlockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBlocked', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByIsCoinbase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCoinbase', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByIsCoinbaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCoinbase', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByOtherData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByOtherDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByVout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByVoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.desc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<UTXO, UTXO, QAfterSortBy> thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension UTXOQueryWhereDistinct on QueryBuilder<UTXO, UTXO, QDistinct> {
  QueryBuilder<UTXO, UTXO, QDistinct> distinctByAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByBlockHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByBlockHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockHeight');
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByBlockTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockTime');
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByBlockedReason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockedReason',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByIsBlocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isBlocked');
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByIsCoinbase() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCoinbase');
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByOtherData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByTxid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'txid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value');
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByVout() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vout');
    });
  }

  QueryBuilder<UTXO, UTXO, QDistinct> distinctByWalletId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension UTXOQueryProperty on QueryBuilder<UTXO, UTXO, QQueryProperty> {
  QueryBuilder<UTXO, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UTXO, String?, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<UTXO, String?, QQueryOperations> blockHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockHash');
    });
  }

  QueryBuilder<UTXO, int?, QQueryOperations> blockHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockHeight');
    });
  }

  QueryBuilder<UTXO, int?, QQueryOperations> blockTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockTime');
    });
  }

  QueryBuilder<UTXO, String?, QQueryOperations> blockedReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockedReason');
    });
  }

  QueryBuilder<UTXO, bool, QQueryOperations> isBlockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isBlocked');
    });
  }

  QueryBuilder<UTXO, bool, QQueryOperations> isCoinbaseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCoinbase');
    });
  }

  QueryBuilder<UTXO, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<UTXO, String?, QQueryOperations> otherDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherData');
    });
  }

  QueryBuilder<UTXO, String, QQueryOperations> txidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'txid');
    });
  }

  QueryBuilder<UTXO, int, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }

  QueryBuilder<UTXO, int, QQueryOperations> voutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vout');
    });
  }

  QueryBuilder<UTXO, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

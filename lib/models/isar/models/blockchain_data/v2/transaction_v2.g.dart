// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_v2.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetTransactionV2Collection on Isar {
  IsarCollection<TransactionV2> get transactionV2s => this.collection();
}

const TransactionV2Schema = CollectionSchema(
  name: r'TransactionV2',
  id: -4280912949179256257,
  properties: {
    r'blockHash': PropertySchema(
      id: 0,
      name: r'blockHash',
      type: IsarType.string,
    ),
    r'hash': PropertySchema(
      id: 1,
      name: r'hash',
      type: IsarType.string,
    ),
    r'height': PropertySchema(
      id: 2,
      name: r'height',
      type: IsarType.long,
    ),
    r'inputs': PropertySchema(
      id: 3,
      name: r'inputs',
      type: IsarType.objectList,
      target: r'InputV2',
    ),
    r'isCancelled': PropertySchema(
      id: 4,
      name: r'isCancelled',
      type: IsarType.bool,
    ),
    r'isEpiccashTransaction': PropertySchema(
      id: 5,
      name: r'isEpiccashTransaction',
      type: IsarType.bool,
    ),
    r'numberOfMessages': PropertySchema(
      id: 6,
      name: r'numberOfMessages',
      type: IsarType.long,
    ),
    r'onChainNote': PropertySchema(
      id: 7,
      name: r'onChainNote',
      type: IsarType.string,
    ),
    r'otherData': PropertySchema(
      id: 8,
      name: r'otherData',
      type: IsarType.string,
    ),
    r'outputs': PropertySchema(
      id: 9,
      name: r'outputs',
      type: IsarType.objectList,
      target: r'OutputV2',
    ),
    r'slateId': PropertySchema(
      id: 10,
      name: r'slateId',
      type: IsarType.string,
    ),
    r'subType': PropertySchema(
      id: 11,
      name: r'subType',
      type: IsarType.byte,
      enumMap: _TransactionV2subTypeEnumValueMap,
    ),
    r'timestamp': PropertySchema(
      id: 12,
      name: r'timestamp',
      type: IsarType.long,
    ),
    r'txid': PropertySchema(
      id: 13,
      name: r'txid',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 14,
      name: r'type',
      type: IsarType.byte,
      enumMap: _TransactionV2typeEnumValueMap,
    ),
    r'version': PropertySchema(
      id: 15,
      name: r'version',
      type: IsarType.long,
    ),
    r'walletId': PropertySchema(
      id: 16,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _transactionV2EstimateSize,
  serialize: _transactionV2Serialize,
  deserialize: _transactionV2Deserialize,
  deserializeProp: _transactionV2DeserializeProp,
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
    r'txid_walletId': IndexSchema(
      id: -2771771174176035985,
      name: r'txid_walletId',
      unique: true,
      replace: false,
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
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'InputV2': InputV2Schema,
    r'OutpointV2': OutpointV2Schema,
    r'OutputV2': OutputV2Schema
  },
  getId: _transactionV2GetId,
  getLinks: _transactionV2GetLinks,
  attach: _transactionV2Attach,
  version: '3.0.5',
);

int _transactionV2EstimateSize(
  TransactionV2 object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.blockHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.hash.length * 3;
  bytesCount += 3 + object.inputs.length * 3;
  {
    final offsets = allOffsets[InputV2]!;
    for (var i = 0; i < object.inputs.length; i++) {
      final value = object.inputs[i];
      bytesCount += InputV2Schema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.onChainNote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.otherData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.outputs.length * 3;
  {
    final offsets = allOffsets[OutputV2]!;
    for (var i = 0; i < object.outputs.length; i++) {
      final value = object.outputs[i];
      bytesCount += OutputV2Schema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.slateId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.txid.length * 3;
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _transactionV2Serialize(
  TransactionV2 object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.blockHash);
  writer.writeString(offsets[1], object.hash);
  writer.writeLong(offsets[2], object.height);
  writer.writeObjectList<InputV2>(
    offsets[3],
    allOffsets,
    InputV2Schema.serialize,
    object.inputs,
  );
  writer.writeBool(offsets[4], object.isCancelled);
  writer.writeBool(offsets[5], object.isEpiccashTransaction);
  writer.writeLong(offsets[6], object.numberOfMessages);
  writer.writeString(offsets[7], object.onChainNote);
  writer.writeString(offsets[8], object.otherData);
  writer.writeObjectList<OutputV2>(
    offsets[9],
    allOffsets,
    OutputV2Schema.serialize,
    object.outputs,
  );
  writer.writeString(offsets[10], object.slateId);
  writer.writeByte(offsets[11], object.subType.index);
  writer.writeLong(offsets[12], object.timestamp);
  writer.writeString(offsets[13], object.txid);
  writer.writeByte(offsets[14], object.type.index);
  writer.writeLong(offsets[15], object.version);
  writer.writeString(offsets[16], object.walletId);
}

TransactionV2 _transactionV2Deserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TransactionV2(
    blockHash: reader.readStringOrNull(offsets[0]),
    hash: reader.readString(offsets[1]),
    height: reader.readLongOrNull(offsets[2]),
    inputs: reader.readObjectList<InputV2>(
          offsets[3],
          InputV2Schema.deserialize,
          allOffsets,
          InputV2(),
        ) ??
        [],
    otherData: reader.readStringOrNull(offsets[8]),
    outputs: reader.readObjectList<OutputV2>(
          offsets[9],
          OutputV2Schema.deserialize,
          allOffsets,
          OutputV2(),
        ) ??
        [],
    subType:
        _TransactionV2subTypeValueEnumMap[reader.readByteOrNull(offsets[11])] ??
            TransactionSubType.none,
    timestamp: reader.readLong(offsets[12]),
    txid: reader.readString(offsets[13]),
    type: _TransactionV2typeValueEnumMap[reader.readByteOrNull(offsets[14])] ??
        TransactionType.outgoing,
    version: reader.readLong(offsets[15]),
    walletId: reader.readString(offsets[16]),
  );
  object.id = id;
  return object;
}

P _transactionV2DeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readObjectList<InputV2>(
            offset,
            InputV2Schema.deserialize,
            allOffsets,
            InputV2(),
          ) ??
          []) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readObjectList<OutputV2>(
            offset,
            OutputV2Schema.deserialize,
            allOffsets,
            OutputV2(),
          ) ??
          []) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (_TransactionV2subTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          TransactionSubType.none) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (_TransactionV2typeValueEnumMap[reader.readByteOrNull(offset)] ??
          TransactionType.outgoing) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TransactionV2subTypeEnumValueMap = {
  'none': 0,
  'bip47Notification': 1,
  'mint': 2,
  'join': 3,
  'ethToken': 4,
  'cashFusion': 5,
  'sparkMint': 6,
  'sparkSpend': 7,
};
const _TransactionV2subTypeValueEnumMap = {
  0: TransactionSubType.none,
  1: TransactionSubType.bip47Notification,
  2: TransactionSubType.mint,
  3: TransactionSubType.join,
  4: TransactionSubType.ethToken,
  5: TransactionSubType.cashFusion,
  6: TransactionSubType.sparkMint,
  7: TransactionSubType.sparkSpend,
};
const _TransactionV2typeEnumValueMap = {
  'outgoing': 0,
  'incoming': 1,
  'sentToSelf': 2,
  'unknown': 3,
};
const _TransactionV2typeValueEnumMap = {
  0: TransactionType.outgoing,
  1: TransactionType.incoming,
  2: TransactionType.sentToSelf,
  3: TransactionType.unknown,
};

Id _transactionV2GetId(TransactionV2 object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _transactionV2GetLinks(TransactionV2 object) {
  return [];
}

void _transactionV2Attach(
    IsarCollection<dynamic> col, Id id, TransactionV2 object) {
  object.id = id;
}

extension TransactionV2ByIndex on IsarCollection<TransactionV2> {
  Future<TransactionV2?> getByTxidWalletId(String txid, String walletId) {
    return getByIndex(r'txid_walletId', [txid, walletId]);
  }

  TransactionV2? getByTxidWalletIdSync(String txid, String walletId) {
    return getByIndexSync(r'txid_walletId', [txid, walletId]);
  }

  Future<bool> deleteByTxidWalletId(String txid, String walletId) {
    return deleteByIndex(r'txid_walletId', [txid, walletId]);
  }

  bool deleteByTxidWalletIdSync(String txid, String walletId) {
    return deleteByIndexSync(r'txid_walletId', [txid, walletId]);
  }

  Future<List<TransactionV2?>> getAllByTxidWalletId(
      List<String> txidValues, List<String> walletIdValues) {
    final len = txidValues.length;
    assert(walletIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([txidValues[i], walletIdValues[i]]);
    }

    return getAllByIndex(r'txid_walletId', values);
  }

  List<TransactionV2?> getAllByTxidWalletIdSync(
      List<String> txidValues, List<String> walletIdValues) {
    final len = txidValues.length;
    assert(walletIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([txidValues[i], walletIdValues[i]]);
    }

    return getAllByIndexSync(r'txid_walletId', values);
  }

  Future<int> deleteAllByTxidWalletId(
      List<String> txidValues, List<String> walletIdValues) {
    final len = txidValues.length;
    assert(walletIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([txidValues[i], walletIdValues[i]]);
    }

    return deleteAllByIndex(r'txid_walletId', values);
  }

  int deleteAllByTxidWalletIdSync(
      List<String> txidValues, List<String> walletIdValues) {
    final len = txidValues.length;
    assert(walletIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([txidValues[i], walletIdValues[i]]);
    }

    return deleteAllByIndexSync(r'txid_walletId', values);
  }

  Future<Id> putByTxidWalletId(TransactionV2 object) {
    return putByIndex(r'txid_walletId', object);
  }

  Id putByTxidWalletIdSync(TransactionV2 object, {bool saveLinks = true}) {
    return putByIndexSync(r'txid_walletId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTxidWalletId(List<TransactionV2> objects) {
    return putAllByIndex(r'txid_walletId', objects);
  }

  List<Id> putAllByTxidWalletIdSync(List<TransactionV2> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'txid_walletId', objects, saveLinks: saveLinks);
  }
}

extension TransactionV2QueryWhereSort
    on QueryBuilder<TransactionV2, TransactionV2, QWhere> {
  QueryBuilder<TransactionV2, TransactionV2, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension TransactionV2QueryWhere
    on QueryBuilder<TransactionV2, TransactionV2, QWhereClause> {
  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause> idBetween(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause> walletIdEqualTo(
      String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
      txidEqualToAnyWalletId(String txid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'txid_walletId',
        value: [txid],
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
      txidNotEqualToAnyWalletId(String txid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId',
              lower: [],
              upper: [txid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId',
              lower: [txid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId',
              lower: [txid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId',
              lower: [],
              upper: [txid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
      txidWalletIdEqualTo(String txid, String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'txid_walletId',
        value: [txid, walletId],
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
      txidEqualToWalletIdNotEqualTo(String txid, String walletId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId',
              lower: [txid],
              upper: [txid, walletId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId',
              lower: [txid, walletId],
              includeLower: false,
              upper: [txid],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId',
              lower: [txid, walletId],
              includeLower: false,
              upper: [txid],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid_walletId',
              lower: [txid],
              upper: [txid, walletId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
      timestampEqualTo(int timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
      timestampNotEqualTo(int timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
      timestampGreaterThan(
    int timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
      timestampLessThan(
    int timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterWhereClause>
      timestampBetween(
    int lowerTimestamp,
    int upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TransactionV2QueryFilter
    on QueryBuilder<TransactionV2, TransactionV2, QFilterCondition> {
  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'blockHash',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'blockHash',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashEqualTo(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashGreaterThan(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashLessThan(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashBetween(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashStartsWith(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashEndsWith(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'blockHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'blockHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockHash',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      blockHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'blockHash',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> hashEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      hashGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      hashLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> hashBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      hashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      hashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      hashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> hashMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      hashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hash',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      hashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hash',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      heightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      heightGreaterThan(
    int? value, {
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      heightLessThan(
    int? value, {
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      heightBetween(
    int? lower,
    int? upper, {
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> idBetween(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      inputsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inputs',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      inputsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inputs',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      inputsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inputs',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      inputsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inputs',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      inputsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inputs',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      inputsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inputs',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      isCancelledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCancelled',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      isEpiccashTransactionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEpiccashTransaction',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      numberOfMessagesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'numberOfMessages',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      numberOfMessagesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'numberOfMessages',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      numberOfMessagesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numberOfMessages',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      numberOfMessagesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numberOfMessages',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      numberOfMessagesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numberOfMessages',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      numberOfMessagesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numberOfMessages',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onChainNote',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onChainNote',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onChainNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onChainNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onChainNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onChainNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'onChainNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'onChainNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'onChainNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'onChainNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onChainNote',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      onChainNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'onChainNote',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      otherDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'otherData',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      otherDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'otherData',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      otherDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'otherData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      otherDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'otherData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      otherDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'otherData',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      otherDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'otherData',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      outputsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outputs',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      outputsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outputs',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      outputsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outputs',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      outputsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outputs',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      outputsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outputs',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      outputsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'outputs',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'slateId',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'slateId',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdEqualTo(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdLessThan(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdBetween(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdEndsWith(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'slateId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'slateId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slateId',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      slateIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'slateId',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      subTypeEqualTo(TransactionSubType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subType',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      subTypeLessThan(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      subTypeBetween(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      timestampEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> txidEqualTo(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      txidLessThan(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> txidBetween(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      txidEndsWith(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      txidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> txidMatches(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      txidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      txidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> typeEqualTo(
      TransactionType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      typeGreaterThan(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      typeLessThan(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition> typeBetween(
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      versionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
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

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      walletIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      walletIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension TransactionV2QueryObject
    on QueryBuilder<TransactionV2, TransactionV2, QFilterCondition> {
  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      inputsElement(FilterQuery<InputV2> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'inputs');
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterFilterCondition>
      outputsElement(FilterQuery<OutputV2> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'outputs');
    });
  }
}

extension TransactionV2QueryLinks
    on QueryBuilder<TransactionV2, TransactionV2, QFilterCondition> {}

extension TransactionV2QuerySortBy
    on QueryBuilder<TransactionV2, TransactionV2, QSortBy> {
  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByBlockHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHash', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByBlockHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHash', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByIsCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByIsCancelledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByIsEpiccashTransaction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEpiccashTransaction', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByIsEpiccashTransactionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEpiccashTransaction', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByNumberOfMessages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfMessages', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByNumberOfMessagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfMessages', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByOnChainNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onChainNote', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByOnChainNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onChainNote', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByOtherData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByOtherDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortBySlateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slateId', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortBySlateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slateId', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortBySubTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension TransactionV2QuerySortThenBy
    on QueryBuilder<TransactionV2, TransactionV2, QSortThenBy> {
  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByBlockHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHash', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByBlockHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHash', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByIsCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByIsCancelledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCancelled', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByIsEpiccashTransaction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEpiccashTransaction', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByIsEpiccashTransactionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEpiccashTransaction', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByNumberOfMessages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfMessages', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByNumberOfMessagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfMessages', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByOnChainNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onChainNote', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByOnChainNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onChainNote', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByOtherData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByOtherDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherData', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenBySlateId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slateId', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenBySlateIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slateId', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenBySubTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QAfterSortBy>
      thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension TransactionV2QueryWhereDistinct
    on QueryBuilder<TransactionV2, TransactionV2, QDistinct> {
  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByBlockHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct>
      distinctByIsCancelled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCancelled');
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct>
      distinctByIsEpiccashTransaction() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEpiccashTransaction');
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct>
      distinctByNumberOfMessages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numberOfMessages');
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByOnChainNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onChainNote', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByOtherData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctBySlateId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'slateId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subType');
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByTxid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'txid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }

  QueryBuilder<TransactionV2, TransactionV2, QDistinct> distinctByWalletId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension TransactionV2QueryProperty
    on QueryBuilder<TransactionV2, TransactionV2, QQueryProperty> {
  QueryBuilder<TransactionV2, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TransactionV2, String?, QQueryOperations> blockHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockHash');
    });
  }

  QueryBuilder<TransactionV2, String, QQueryOperations> hashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hash');
    });
  }

  QueryBuilder<TransactionV2, int?, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<TransactionV2, List<InputV2>, QQueryOperations>
      inputsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inputs');
    });
  }

  QueryBuilder<TransactionV2, bool, QQueryOperations> isCancelledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCancelled');
    });
  }

  QueryBuilder<TransactionV2, bool, QQueryOperations>
      isEpiccashTransactionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEpiccashTransaction');
    });
  }

  QueryBuilder<TransactionV2, int?, QQueryOperations>
      numberOfMessagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numberOfMessages');
    });
  }

  QueryBuilder<TransactionV2, String?, QQueryOperations> onChainNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onChainNote');
    });
  }

  QueryBuilder<TransactionV2, String?, QQueryOperations> otherDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherData');
    });
  }

  QueryBuilder<TransactionV2, List<OutputV2>, QQueryOperations>
      outputsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputs');
    });
  }

  QueryBuilder<TransactionV2, String?, QQueryOperations> slateIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slateId');
    });
  }

  QueryBuilder<TransactionV2, TransactionSubType, QQueryOperations>
      subTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subType');
    });
  }

  QueryBuilder<TransactionV2, int, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<TransactionV2, String, QQueryOperations> txidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'txid');
    });
  }

  QueryBuilder<TransactionV2, TransactionType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<TransactionV2, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }

  QueryBuilder<TransactionV2, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

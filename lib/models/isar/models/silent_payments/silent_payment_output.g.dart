// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'silent_payment_output.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSilentPaymentOutputCollection on Isar {
  IsarCollection<SilentPaymentOutput> get silentPaymentOutputs =>
      this.collection();
}

const SilentPaymentOutputSchema = CollectionSchema(
  name: r'SilentPaymentOutput',
  id: 7199689495392272388,
  properties: {
    r'ageInDays': PropertySchema(
      id: 0,
      name: r'ageInDays',
      type: IsarType.double,
    ),
    r'amount': PropertySchema(
      id: 1,
      name: r'amount',
      type: IsarType.long,
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
    r'confirmations': PropertySchema(
      id: 4,
      name: r'confirmations',
      type: IsarType.long,
    ),
    r'isConfirmedSpent': PropertySchema(
      id: 5,
      name: r'isConfirmedSpent',
      type: IsarType.bool,
    ),
    r'isSpent': PropertySchema(
      id: 6,
      name: r'isSpent',
      type: IsarType.bool,
    ),
    r'label': PropertySchema(
      id: 7,
      name: r'label',
      type: IsarType.string,
    ),
    r'outpoint': PropertySchema(
      id: 8,
      name: r'outpoint',
      type: IsarType.string,
    ),
    r'outputScript': PropertySchema(
      id: 9,
      name: r'outputScript',
      type: IsarType.string,
    ),
    r'privKeyTweak': PropertySchema(
      id: 10,
      name: r'privKeyTweak',
      type: IsarType.string,
    ),
    r'spentBlockHeight': PropertySchema(
      id: 11,
      name: r'spentBlockHeight',
      type: IsarType.long,
    ),
    r'spentBlockTime': PropertySchema(
      id: 12,
      name: r'spentBlockTime',
      type: IsarType.long,
    ),
    r'spentTxid': PropertySchema(
      id: 13,
      name: r'spentTxid',
      type: IsarType.string,
    ),
    r'txid': PropertySchema(
      id: 14,
      name: r'txid',
      type: IsarType.string,
    ),
    r'vout': PropertySchema(
      id: 15,
      name: r'vout',
      type: IsarType.long,
    ),
    r'walletId': PropertySchema(
      id: 16,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _silentPaymentOutputEstimateSize,
  serialize: _silentPaymentOutputSerialize,
  deserialize: _silentPaymentOutputDeserialize,
  deserializeProp: _silentPaymentOutputDeserializeProp,
  idName: r'id',
  indexes: {
    r'walletId_outputScript': IndexSchema(
      id: -4581886294710132914,
      name: r'walletId_outputScript',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'walletId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'outputScript',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _silentPaymentOutputGetId,
  getLinks: _silentPaymentOutputGetLinks,
  attach: _silentPaymentOutputAttach,
  version: '3.1.8',
);

int _silentPaymentOutputEstimateSize(
  SilentPaymentOutput object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.label;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.outpoint.length * 3;
  bytesCount += 3 + object.outputScript.length * 3;
  bytesCount += 3 + object.privKeyTweak.length * 3;
  {
    final value = object.spentTxid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.txid.length * 3;
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _silentPaymentOutputSerialize(
  SilentPaymentOutput object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.ageInDays);
  writer.writeLong(offsets[1], object.amount);
  writer.writeLong(offsets[2], object.blockHeight);
  writer.writeLong(offsets[3], object.blockTime);
  writer.writeLong(offsets[4], object.confirmations);
  writer.writeBool(offsets[5], object.isConfirmedSpent);
  writer.writeBool(offsets[6], object.isSpent);
  writer.writeString(offsets[7], object.label);
  writer.writeString(offsets[8], object.outpoint);
  writer.writeString(offsets[9], object.outputScript);
  writer.writeString(offsets[10], object.privKeyTweak);
  writer.writeLong(offsets[11], object.spentBlockHeight);
  writer.writeLong(offsets[12], object.spentBlockTime);
  writer.writeString(offsets[13], object.spentTxid);
  writer.writeString(offsets[14], object.txid);
  writer.writeLong(offsets[15], object.vout);
  writer.writeString(offsets[16], object.walletId);
}

SilentPaymentOutput _silentPaymentOutputDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SilentPaymentOutput(
    amount: reader.readLong(offsets[1]),
    blockHeight: reader.readLong(offsets[2]),
    blockTime: reader.readLong(offsets[3]),
    isSpent: reader.readBoolOrNull(offsets[6]) ?? false,
    label: reader.readStringOrNull(offsets[7]),
    outputScript: reader.readString(offsets[9]),
    privKeyTweak: reader.readString(offsets[10]),
    spentBlockHeight: reader.readLongOrNull(offsets[11]),
    spentBlockTime: reader.readLongOrNull(offsets[12]),
    spentTxid: reader.readStringOrNull(offsets[13]),
    txid: reader.readString(offsets[14]),
    vout: reader.readLong(offsets[15]),
    walletId: reader.readString(offsets[16]),
  );
  object.id = id;
  return object;
}

P _silentPaymentOutputDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _silentPaymentOutputGetId(SilentPaymentOutput object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _silentPaymentOutputGetLinks(
    SilentPaymentOutput object) {
  return [];
}

void _silentPaymentOutputAttach(
    IsarCollection<dynamic> col, Id id, SilentPaymentOutput object) {
  object.id = id;
}

extension SilentPaymentOutputQueryWhereSort
    on QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QWhere> {
  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SilentPaymentOutputQueryWhere
    on QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QWhereClause> {
  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhereClause>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhereClause>
      walletIdEqualToAnyOutputScript(String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId_outputScript',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhereClause>
      walletIdNotEqualToAnyOutputScript(String walletId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_outputScript',
              lower: [],
              upper: [walletId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_outputScript',
              lower: [walletId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_outputScript',
              lower: [walletId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_outputScript',
              lower: [],
              upper: [walletId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhereClause>
      walletIdOutputScriptEqualTo(String walletId, String outputScript) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId_outputScript',
        value: [walletId, outputScript],
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterWhereClause>
      walletIdEqualToOutputScriptNotEqualTo(
          String walletId, String outputScript) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_outputScript',
              lower: [walletId],
              upper: [walletId, outputScript],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_outputScript',
              lower: [walletId, outputScript],
              includeLower: false,
              upper: [walletId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_outputScript',
              lower: [walletId, outputScript],
              includeLower: false,
              upper: [walletId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_outputScript',
              lower: [walletId],
              upper: [walletId, outputScript],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SilentPaymentOutputQueryFilter on QueryBuilder<SilentPaymentOutput,
    SilentPaymentOutput, QFilterCondition> {
  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      ageInDaysEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ageInDays',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      ageInDaysGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ageInDays',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      ageInDaysLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ageInDays',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      ageInDaysBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ageInDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      amountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      amountLessThan(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      amountBetween(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      blockHeightEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      blockHeightGreaterThan(
    int value, {
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      blockHeightLessThan(
    int value, {
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      blockHeightBetween(
    int lower,
    int upper, {
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      blockTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      blockTimeGreaterThan(
    int value, {
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      blockTimeLessThan(
    int value, {
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      blockTimeBetween(
    int lower,
    int upper, {
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      confirmationsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confirmations',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      confirmationsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confirmations',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      confirmationsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confirmations',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      confirmationsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confirmations',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      isConfirmedSpentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isConfirmedSpent',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      isSpentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSpent',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'label',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'label',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outpoint',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'outpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'outpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outpoint',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outpoint',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outpointIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outpoint',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputScript',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outputScript',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outputScript',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outputScript',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'outputScript',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'outputScript',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outputScript',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outputScript',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputScript',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      outputScriptIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outputScript',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privKeyTweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'privKeyTweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'privKeyTweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'privKeyTweak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'privKeyTweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'privKeyTweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'privKeyTweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'privKeyTweak',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privKeyTweak',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      privKeyTweakIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'privKeyTweak',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockHeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'spentBlockHeight',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockHeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'spentBlockHeight',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockHeightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spentBlockHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockHeightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spentBlockHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockHeightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spentBlockHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockHeightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spentBlockHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'spentBlockTime',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'spentBlockTime',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockTimeEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spentBlockTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockTimeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spentBlockTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockTimeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spentBlockTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentBlockTimeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spentBlockTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'spentTxid',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'spentTxid',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spentTxid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spentTxid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spentTxid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spentTxid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'spentTxid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'spentTxid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'spentTxid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'spentTxid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spentTxid',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      spentTxidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'spentTxid',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      txidEqualTo(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      txidBetween(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      txidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      txidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'txid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      txidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      txidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      voutEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vout',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      voutGreaterThan(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      voutLessThan(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      voutBetween(
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      walletIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      walletIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterFilterCondition>
      walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension SilentPaymentOutputQueryObject on QueryBuilder<SilentPaymentOutput,
    SilentPaymentOutput, QFilterCondition> {}

extension SilentPaymentOutputQueryLinks on QueryBuilder<SilentPaymentOutput,
    SilentPaymentOutput, QFilterCondition> {}

extension SilentPaymentOutputQuerySortBy
    on QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QSortBy> {
  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByAgeInDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageInDays', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByAgeInDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageInDays', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByBlockHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHeight', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByBlockHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHeight', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByBlockTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockTime', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByBlockTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockTime', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByConfirmations() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmations', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByConfirmationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmations', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByIsConfirmedSpent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmedSpent', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByIsConfirmedSpentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmedSpent', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByIsSpent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSpent', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByIsSpentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSpent', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByOutpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outpoint', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByOutpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outpoint', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByOutputScript() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputScript', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByOutputScriptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputScript', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByPrivKeyTweak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privKeyTweak', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByPrivKeyTweakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privKeyTweak', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortBySpentBlockHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentBlockHeight', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortBySpentBlockHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentBlockHeight', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortBySpentBlockTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentBlockTime', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortBySpentBlockTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentBlockTime', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortBySpentTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentTxid', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortBySpentTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentTxid', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByVout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByVoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension SilentPaymentOutputQuerySortThenBy
    on QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QSortThenBy> {
  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByAgeInDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageInDays', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByAgeInDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ageInDays', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByBlockHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHeight', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByBlockHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockHeight', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByBlockTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockTime', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByBlockTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockTime', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByConfirmations() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmations', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByConfirmationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'confirmations', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByIsConfirmedSpent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmedSpent', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByIsConfirmedSpentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConfirmedSpent', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByIsSpent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSpent', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByIsSpentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSpent', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByOutpoint() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outpoint', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByOutpointDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outpoint', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByOutputScript() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputScript', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByOutputScriptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputScript', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByPrivKeyTweak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privKeyTweak', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByPrivKeyTweakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privKeyTweak', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenBySpentBlockHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentBlockHeight', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenBySpentBlockHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentBlockHeight', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenBySpentBlockTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentBlockTime', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenBySpentBlockTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentBlockTime', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenBySpentTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentTxid', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenBySpentTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spentTxid', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByVout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByVoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QAfterSortBy>
      thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension SilentPaymentOutputQueryWhereDistinct
    on QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct> {
  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByAgeInDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ageInDays');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByBlockHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockHeight');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByBlockTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockTime');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByConfirmations() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'confirmations');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByIsConfirmedSpent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isConfirmedSpent');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByIsSpent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSpent');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByLabel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'label', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByOutpoint({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outpoint', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByOutputScript({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputScript', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByPrivKeyTweak({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privKeyTweak', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctBySpentBlockHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spentBlockHeight');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctBySpentBlockTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spentBlockTime');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctBySpentTxid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spentTxid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByTxid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'txid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByVout() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vout');
    });
  }

  QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QDistinct>
      distinctByWalletId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension SilentPaymentOutputQueryProperty
    on QueryBuilder<SilentPaymentOutput, SilentPaymentOutput, QQueryProperty> {
  QueryBuilder<SilentPaymentOutput, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SilentPaymentOutput, double, QQueryOperations>
      ageInDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ageInDays');
    });
  }

  QueryBuilder<SilentPaymentOutput, int, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<SilentPaymentOutput, int, QQueryOperations>
      blockHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockHeight');
    });
  }

  QueryBuilder<SilentPaymentOutput, int, QQueryOperations> blockTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockTime');
    });
  }

  QueryBuilder<SilentPaymentOutput, int, QQueryOperations>
      confirmationsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'confirmations');
    });
  }

  QueryBuilder<SilentPaymentOutput, bool, QQueryOperations>
      isConfirmedSpentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isConfirmedSpent');
    });
  }

  QueryBuilder<SilentPaymentOutput, bool, QQueryOperations> isSpentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSpent');
    });
  }

  QueryBuilder<SilentPaymentOutput, String?, QQueryOperations> labelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'label');
    });
  }

  QueryBuilder<SilentPaymentOutput, String, QQueryOperations>
      outpointProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outpoint');
    });
  }

  QueryBuilder<SilentPaymentOutput, String, QQueryOperations>
      outputScriptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputScript');
    });
  }

  QueryBuilder<SilentPaymentOutput, String, QQueryOperations>
      privKeyTweakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privKeyTweak');
    });
  }

  QueryBuilder<SilentPaymentOutput, int?, QQueryOperations>
      spentBlockHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spentBlockHeight');
    });
  }

  QueryBuilder<SilentPaymentOutput, int?, QQueryOperations>
      spentBlockTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spentBlockTime');
    });
  }

  QueryBuilder<SilentPaymentOutput, String?, QQueryOperations>
      spentTxidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spentTxid');
    });
  }

  QueryBuilder<SilentPaymentOutput, String, QQueryOperations> txidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'txid');
    });
  }

  QueryBuilder<SilentPaymentOutput, int, QQueryOperations> voutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vout');
    });
  }

  QueryBuilder<SilentPaymentOutput, String, QQueryOperations>
      walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

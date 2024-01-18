// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ordinal.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetOrdinalCollection on Isar {
  IsarCollection<Ordinal> get ordinals => this.collection();
}

const OrdinalSchema = CollectionSchema(
  name: r'Ordinal',
  id: -7772149326141951436,
  properties: {
    r'content': PropertySchema(
      id: 0,
      name: r'content',
      type: IsarType.string,
    ),
    r'inscriptionId': PropertySchema(
      id: 1,
      name: r'inscriptionId',
      type: IsarType.string,
    ),
    r'inscriptionNumber': PropertySchema(
      id: 2,
      name: r'inscriptionNumber',
      type: IsarType.long,
    ),
    r'utxoTXID': PropertySchema(
      id: 3,
      name: r'utxoTXID',
      type: IsarType.string,
    ),
    r'utxoVOUT': PropertySchema(
      id: 4,
      name: r'utxoVOUT',
      type: IsarType.long,
    ),
    r'walletId': PropertySchema(
      id: 5,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _ordinalEstimateSize,
  serialize: _ordinalSerialize,
  deserialize: _ordinalDeserialize,
  deserializeProp: _ordinalDeserializeProp,
  idName: r'id',
  indexes: {
    r'inscriptionId_utxoTXID_utxoVOUT': IndexSchema(
      id: 2138008085066605381,
      name: r'inscriptionId_utxoTXID_utxoVOUT',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'inscriptionId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'utxoTXID',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'utxoVOUT',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _ordinalGetId,
  getLinks: _ordinalGetLinks,
  attach: _ordinalAttach,
  version: '3.0.5',
);

int _ordinalEstimateSize(
  Ordinal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.inscriptionId.length * 3;
  bytesCount += 3 + object.utxoTXID.length * 3;
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _ordinalSerialize(
  Ordinal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.content);
  writer.writeString(offsets[1], object.inscriptionId);
  writer.writeLong(offsets[2], object.inscriptionNumber);
  writer.writeString(offsets[3], object.utxoTXID);
  writer.writeLong(offsets[4], object.utxoVOUT);
  writer.writeString(offsets[5], object.walletId);
}

Ordinal _ordinalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Ordinal(
    content: reader.readString(offsets[0]),
    inscriptionId: reader.readString(offsets[1]),
    inscriptionNumber: reader.readLong(offsets[2]),
    utxoTXID: reader.readString(offsets[3]),
    utxoVOUT: reader.readLong(offsets[4]),
    walletId: reader.readString(offsets[5]),
  );
  object.id = id;
  return object;
}

P _ordinalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ordinalGetId(Ordinal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _ordinalGetLinks(Ordinal object) {
  return [];
}

void _ordinalAttach(IsarCollection<dynamic> col, Id id, Ordinal object) {
  object.id = id;
}

extension OrdinalByIndex on IsarCollection<Ordinal> {
  Future<Ordinal?> getByInscriptionIdUtxoTXIDUtxoVOUT(
      String inscriptionId, String utxoTXID, int utxoVOUT) {
    return getByIndex(r'inscriptionId_utxoTXID_utxoVOUT',
        [inscriptionId, utxoTXID, utxoVOUT]);
  }

  Ordinal? getByInscriptionIdUtxoTXIDUtxoVOUTSync(
      String inscriptionId, String utxoTXID, int utxoVOUT) {
    return getByIndexSync(r'inscriptionId_utxoTXID_utxoVOUT',
        [inscriptionId, utxoTXID, utxoVOUT]);
  }

  Future<bool> deleteByInscriptionIdUtxoTXIDUtxoVOUT(
      String inscriptionId, String utxoTXID, int utxoVOUT) {
    return deleteByIndex(r'inscriptionId_utxoTXID_utxoVOUT',
        [inscriptionId, utxoTXID, utxoVOUT]);
  }

  bool deleteByInscriptionIdUtxoTXIDUtxoVOUTSync(
      String inscriptionId, String utxoTXID, int utxoVOUT) {
    return deleteByIndexSync(r'inscriptionId_utxoTXID_utxoVOUT',
        [inscriptionId, utxoTXID, utxoVOUT]);
  }

  Future<List<Ordinal?>> getAllByInscriptionIdUtxoTXIDUtxoVOUT(
      List<String> inscriptionIdValues,
      List<String> utxoTXIDValues,
      List<int> utxoVOUTValues) {
    final len = inscriptionIdValues.length;
    assert(utxoTXIDValues.length == len && utxoVOUTValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values
          .add([inscriptionIdValues[i], utxoTXIDValues[i], utxoVOUTValues[i]]);
    }

    return getAllByIndex(r'inscriptionId_utxoTXID_utxoVOUT', values);
  }

  List<Ordinal?> getAllByInscriptionIdUtxoTXIDUtxoVOUTSync(
      List<String> inscriptionIdValues,
      List<String> utxoTXIDValues,
      List<int> utxoVOUTValues) {
    final len = inscriptionIdValues.length;
    assert(utxoTXIDValues.length == len && utxoVOUTValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values
          .add([inscriptionIdValues[i], utxoTXIDValues[i], utxoVOUTValues[i]]);
    }

    return getAllByIndexSync(r'inscriptionId_utxoTXID_utxoVOUT', values);
  }

  Future<int> deleteAllByInscriptionIdUtxoTXIDUtxoVOUT(
      List<String> inscriptionIdValues,
      List<String> utxoTXIDValues,
      List<int> utxoVOUTValues) {
    final len = inscriptionIdValues.length;
    assert(utxoTXIDValues.length == len && utxoVOUTValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values
          .add([inscriptionIdValues[i], utxoTXIDValues[i], utxoVOUTValues[i]]);
    }

    return deleteAllByIndex(r'inscriptionId_utxoTXID_utxoVOUT', values);
  }

  int deleteAllByInscriptionIdUtxoTXIDUtxoVOUTSync(
      List<String> inscriptionIdValues,
      List<String> utxoTXIDValues,
      List<int> utxoVOUTValues) {
    final len = inscriptionIdValues.length;
    assert(utxoTXIDValues.length == len && utxoVOUTValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values
          .add([inscriptionIdValues[i], utxoTXIDValues[i], utxoVOUTValues[i]]);
    }

    return deleteAllByIndexSync(r'inscriptionId_utxoTXID_utxoVOUT', values);
  }

  Future<Id> putByInscriptionIdUtxoTXIDUtxoVOUT(Ordinal object) {
    return putByIndex(r'inscriptionId_utxoTXID_utxoVOUT', object);
  }

  Id putByInscriptionIdUtxoTXIDUtxoVOUTSync(Ordinal object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'inscriptionId_utxoTXID_utxoVOUT', object,
        saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByInscriptionIdUtxoTXIDUtxoVOUT(
      List<Ordinal> objects) {
    return putAllByIndex(r'inscriptionId_utxoTXID_utxoVOUT', objects);
  }

  List<Id> putAllByInscriptionIdUtxoTXIDUtxoVOUTSync(List<Ordinal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'inscriptionId_utxoTXID_utxoVOUT', objects,
        saveLinks: saveLinks);
  }
}

extension OrdinalQueryWhereSort on QueryBuilder<Ordinal, Ordinal, QWhere> {
  QueryBuilder<Ordinal, Ordinal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OrdinalQueryWhere on QueryBuilder<Ordinal, Ordinal, QWhereClause> {
  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause> idBetween(
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

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause>
      inscriptionIdEqualToAnyUtxoTXIDUtxoVOUT(String inscriptionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'inscriptionId_utxoTXID_utxoVOUT',
        value: [inscriptionId],
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause>
      inscriptionIdNotEqualToAnyUtxoTXIDUtxoVOUT(String inscriptionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [],
              upper: [inscriptionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [],
              upper: [inscriptionId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause>
      inscriptionIdUtxoTXIDEqualToAnyUtxoVOUT(
          String inscriptionId, String utxoTXID) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'inscriptionId_utxoTXID_utxoVOUT',
        value: [inscriptionId, utxoTXID],
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause>
      inscriptionIdEqualToUtxoTXIDNotEqualToAnyUtxoVOUT(
          String inscriptionId, String utxoTXID) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId],
              upper: [inscriptionId, utxoTXID],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId, utxoTXID],
              includeLower: false,
              upper: [inscriptionId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId, utxoTXID],
              includeLower: false,
              upper: [inscriptionId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId],
              upper: [inscriptionId, utxoTXID],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause>
      inscriptionIdUtxoTXIDUtxoVOUTEqualTo(
          String inscriptionId, String utxoTXID, int utxoVOUT) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'inscriptionId_utxoTXID_utxoVOUT',
        value: [inscriptionId, utxoTXID, utxoVOUT],
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause>
      inscriptionIdUtxoTXIDEqualToUtxoVOUTNotEqualTo(
          String inscriptionId, String utxoTXID, int utxoVOUT) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId, utxoTXID],
              upper: [inscriptionId, utxoTXID, utxoVOUT],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId, utxoTXID, utxoVOUT],
              includeLower: false,
              upper: [inscriptionId, utxoTXID],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId, utxoTXID, utxoVOUT],
              includeLower: false,
              upper: [inscriptionId, utxoTXID],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'inscriptionId_utxoTXID_utxoVOUT',
              lower: [inscriptionId, utxoTXID],
              upper: [inscriptionId, utxoTXID, utxoVOUT],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause>
      inscriptionIdUtxoTXIDEqualToUtxoVOUTGreaterThan(
    String inscriptionId,
    String utxoTXID,
    int utxoVOUT, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'inscriptionId_utxoTXID_utxoVOUT',
        lower: [inscriptionId, utxoTXID, utxoVOUT],
        includeLower: include,
        upper: [inscriptionId, utxoTXID],
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause>
      inscriptionIdUtxoTXIDEqualToUtxoVOUTLessThan(
    String inscriptionId,
    String utxoTXID,
    int utxoVOUT, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'inscriptionId_utxoTXID_utxoVOUT',
        lower: [inscriptionId, utxoTXID],
        upper: [inscriptionId, utxoTXID, utxoVOUT],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterWhereClause>
      inscriptionIdUtxoTXIDEqualToUtxoVOUTBetween(
    String inscriptionId,
    String utxoTXID,
    int lowerUtxoVOUT,
    int upperUtxoVOUT, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'inscriptionId_utxoTXID_utxoVOUT',
        lower: [inscriptionId, utxoTXID, lowerUtxoVOUT],
        includeLower: includeLower,
        upper: [inscriptionId, utxoTXID, upperUtxoVOUT],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OrdinalQueryFilter
    on QueryBuilder<Ordinal, Ordinal, QFilterCondition> {
  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> inscriptionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition>
      inscriptionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> inscriptionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> inscriptionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inscriptionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> inscriptionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'inscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> inscriptionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'inscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> inscriptionIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'inscriptionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> inscriptionIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'inscriptionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> inscriptionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inscriptionId',
        value: '',
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition>
      inscriptionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'inscriptionId',
        value: '',
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition>
      inscriptionNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inscriptionNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition>
      inscriptionNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inscriptionNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition>
      inscriptionNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inscriptionNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition>
      inscriptionNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inscriptionNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'utxoTXID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'utxoTXID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'utxoTXID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'utxoTXID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'utxoTXID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'utxoTXID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'utxoTXID',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'utxoTXID',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'utxoTXID',
        value: '',
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoTXIDIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'utxoTXID',
        value: '',
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoVOUTEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'utxoVOUT',
        value: value,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoVOUTGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'utxoVOUT',
        value: value,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoVOUTLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'utxoVOUT',
        value: value,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> utxoVOUTBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'utxoVOUT',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdEqualTo(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdGreaterThan(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdLessThan(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdBetween(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdStartsWith(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdEndsWith(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdContains(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdMatches(
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

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterFilterCondition> walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension OrdinalQueryObject
    on QueryBuilder<Ordinal, Ordinal, QFilterCondition> {}

extension OrdinalQueryLinks
    on QueryBuilder<Ordinal, Ordinal, QFilterCondition> {}

extension OrdinalQuerySortBy on QueryBuilder<Ordinal, Ordinal, QSortBy> {
  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByInscriptionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inscriptionId', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByInscriptionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inscriptionId', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByInscriptionNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inscriptionNumber', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByInscriptionNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inscriptionNumber', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByUtxoTXID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoTXID', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByUtxoTXIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoTXID', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByUtxoVOUT() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoVOUT', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByUtxoVOUTDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoVOUT', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension OrdinalQuerySortThenBy
    on QueryBuilder<Ordinal, Ordinal, QSortThenBy> {
  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByInscriptionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inscriptionId', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByInscriptionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inscriptionId', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByInscriptionNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inscriptionNumber', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByInscriptionNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inscriptionNumber', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByUtxoTXID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoTXID', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByUtxoTXIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoTXID', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByUtxoVOUT() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoVOUT', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByUtxoVOUTDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoVOUT', Sort.desc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QAfterSortBy> thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension OrdinalQueryWhereDistinct
    on QueryBuilder<Ordinal, Ordinal, QDistinct> {
  QueryBuilder<Ordinal, Ordinal, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QDistinct> distinctByInscriptionId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inscriptionId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QDistinct> distinctByInscriptionNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inscriptionNumber');
    });
  }

  QueryBuilder<Ordinal, Ordinal, QDistinct> distinctByUtxoTXID(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'utxoTXID', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ordinal, Ordinal, QDistinct> distinctByUtxoVOUT() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'utxoVOUT');
    });
  }

  QueryBuilder<Ordinal, Ordinal, QDistinct> distinctByWalletId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension OrdinalQueryProperty
    on QueryBuilder<Ordinal, Ordinal, QQueryProperty> {
  QueryBuilder<Ordinal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Ordinal, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<Ordinal, String, QQueryOperations> inscriptionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inscriptionId');
    });
  }

  QueryBuilder<Ordinal, int, QQueryOperations> inscriptionNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inscriptionNumber');
    });
  }

  QueryBuilder<Ordinal, String, QQueryOperations> utxoTXIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'utxoTXID');
    });
  }

  QueryBuilder<Ordinal, int, QQueryOperations> utxoVOUTProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'utxoVOUT');
    });
  }

  QueryBuilder<Ordinal, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

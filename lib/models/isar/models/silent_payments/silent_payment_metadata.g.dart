// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'silent_payment_metadata.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSilentPaymentMetadataCollection on Isar {
  IsarCollection<SilentPaymentMetadata> get silentPaymentMetadata =>
      this.collection();
}

const SilentPaymentMetadataSchema = CollectionSchema(
  name: r'SilentPaymentMetadata',
  id: -6055173424802135633,
  properties: {
    r'label': PropertySchema(
      id: 0,
      name: r'label',
      type: IsarType.string,
    ),
    r'outputIndex': PropertySchema(
      id: 1,
      name: r'outputIndex',
      type: IsarType.long,
    ),
    r'privKeyTweak': PropertySchema(
      id: 2,
      name: r'privKeyTweak',
      type: IsarType.string,
    ),
    r'sharedSecret': PropertySchema(
      id: 3,
      name: r'sharedSecret',
      type: IsarType.string,
    ),
    r'utxoId': PropertySchema(
      id: 4,
      name: r'utxoId',
      type: IsarType.long,
    ),
    r'walletId': PropertySchema(
      id: 5,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _silentPaymentMetadataEstimateSize,
  serialize: _silentPaymentMetadataSerialize,
  deserialize: _silentPaymentMetadataDeserialize,
  deserializeProp: _silentPaymentMetadataDeserializeProp,
  idName: r'id',
  indexes: {
    r'utxoId': IndexSchema(
      id: 5379991336603932725,
      name: r'utxoId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'utxoId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _silentPaymentMetadataGetId,
  getLinks: _silentPaymentMetadataGetLinks,
  attach: _silentPaymentMetadataAttach,
  version: '3.1.8',
);

int _silentPaymentMetadataEstimateSize(
  SilentPaymentMetadata object,
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
  bytesCount += 3 + object.privKeyTweak.length * 3;
  {
    final value = object.sharedSecret;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _silentPaymentMetadataSerialize(
  SilentPaymentMetadata object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.label);
  writer.writeLong(offsets[1], object.outputIndex);
  writer.writeString(offsets[2], object.privKeyTweak);
  writer.writeString(offsets[3], object.sharedSecret);
  writer.writeLong(offsets[4], object.utxoId);
  writer.writeString(offsets[5], object.walletId);
}

SilentPaymentMetadata _silentPaymentMetadataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SilentPaymentMetadata(
    label: reader.readStringOrNull(offsets[0]),
    outputIndex: reader.readLong(offsets[1]),
    privKeyTweak: reader.readString(offsets[2]),
    sharedSecret: reader.readStringOrNull(offsets[3]),
    utxoId: reader.readLong(offsets[4]),
    walletId: reader.readString(offsets[5]),
  );
  object.id = id;
  return object;
}

P _silentPaymentMetadataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _silentPaymentMetadataGetId(SilentPaymentMetadata object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _silentPaymentMetadataGetLinks(
    SilentPaymentMetadata object) {
  return [];
}

void _silentPaymentMetadataAttach(
    IsarCollection<dynamic> col, Id id, SilentPaymentMetadata object) {
  object.id = id;
}

extension SilentPaymentMetadataByIndex
    on IsarCollection<SilentPaymentMetadata> {
  Future<SilentPaymentMetadata?> getByUtxoId(int utxoId) {
    return getByIndex(r'utxoId', [utxoId]);
  }

  SilentPaymentMetadata? getByUtxoIdSync(int utxoId) {
    return getByIndexSync(r'utxoId', [utxoId]);
  }

  Future<bool> deleteByUtxoId(int utxoId) {
    return deleteByIndex(r'utxoId', [utxoId]);
  }

  bool deleteByUtxoIdSync(int utxoId) {
    return deleteByIndexSync(r'utxoId', [utxoId]);
  }

  Future<List<SilentPaymentMetadata?>> getAllByUtxoId(List<int> utxoIdValues) {
    final values = utxoIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'utxoId', values);
  }

  List<SilentPaymentMetadata?> getAllByUtxoIdSync(List<int> utxoIdValues) {
    final values = utxoIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'utxoId', values);
  }

  Future<int> deleteAllByUtxoId(List<int> utxoIdValues) {
    final values = utxoIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'utxoId', values);
  }

  int deleteAllByUtxoIdSync(List<int> utxoIdValues) {
    final values = utxoIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'utxoId', values);
  }

  Future<Id> putByUtxoId(SilentPaymentMetadata object) {
    return putByIndex(r'utxoId', object);
  }

  Id putByUtxoIdSync(SilentPaymentMetadata object, {bool saveLinks = true}) {
    return putByIndexSync(r'utxoId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUtxoId(List<SilentPaymentMetadata> objects) {
    return putAllByIndex(r'utxoId', objects);
  }

  List<Id> putAllByUtxoIdSync(List<SilentPaymentMetadata> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'utxoId', objects, saveLinks: saveLinks);
  }
}

extension SilentPaymentMetadataQueryWhereSort
    on QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QWhere> {
  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhere>
      anyUtxoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'utxoId'),
      );
    });
  }
}

extension SilentPaymentMetadataQueryWhere on QueryBuilder<SilentPaymentMetadata,
    SilentPaymentMetadata, QWhereClause> {
  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
      utxoIdEqualTo(int utxoId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'utxoId',
        value: [utxoId],
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
      utxoIdNotEqualTo(int utxoId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'utxoId',
              lower: [],
              upper: [utxoId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'utxoId',
              lower: [utxoId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'utxoId',
              lower: [utxoId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'utxoId',
              lower: [],
              upper: [utxoId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
      utxoIdGreaterThan(
    int utxoId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'utxoId',
        lower: [utxoId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
      utxoIdLessThan(
    int utxoId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'utxoId',
        lower: [],
        upper: [utxoId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
      utxoIdBetween(
    int lowerUtxoId,
    int upperUtxoId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'utxoId',
        lower: [lowerUtxoId],
        includeLower: includeLower,
        upper: [upperUtxoId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
      walletIdEqualTo(String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhereClause>
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
}

extension SilentPaymentMetadataQueryFilter on QueryBuilder<
    SilentPaymentMetadata, SilentPaymentMetadata, QFilterCondition> {
  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelEqualTo(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelGreaterThan(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelLessThan(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelBetween(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelStartsWith(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelEndsWith(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      labelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      labelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'label',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> outputIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> outputIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outputIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> outputIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outputIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> outputIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outputIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> privKeyTweakEqualTo(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> privKeyTweakGreaterThan(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> privKeyTweakLessThan(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> privKeyTweakBetween(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> privKeyTweakStartsWith(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> privKeyTweakEndsWith(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      privKeyTweakContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'privKeyTweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      privKeyTweakMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'privKeyTweak',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> privKeyTweakIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privKeyTweak',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> privKeyTweakIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'privKeyTweak',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sharedSecret',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sharedSecret',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sharedSecret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sharedSecret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sharedSecret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sharedSecret',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sharedSecret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sharedSecret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      sharedSecretContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sharedSecret',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      sharedSecretMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sharedSecret',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sharedSecret',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> sharedSecretIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sharedSecret',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> utxoIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'utxoId',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> utxoIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'utxoId',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> utxoIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'utxoId',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> utxoIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'utxoId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> walletIdEqualTo(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> walletIdGreaterThan(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> walletIdLessThan(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> walletIdBetween(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> walletIdStartsWith(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> walletIdEndsWith(
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

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      walletIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      walletIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension SilentPaymentMetadataQueryObject on QueryBuilder<
    SilentPaymentMetadata, SilentPaymentMetadata, QFilterCondition> {}

extension SilentPaymentMetadataQueryLinks on QueryBuilder<SilentPaymentMetadata,
    SilentPaymentMetadata, QFilterCondition> {}

extension SilentPaymentMetadataQuerySortBy
    on QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QSortBy> {
  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByOutputIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputIndex', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByOutputIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputIndex', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByPrivKeyTweak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privKeyTweak', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByPrivKeyTweakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privKeyTweak', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortBySharedSecret() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedSecret', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortBySharedSecretDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedSecret', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByUtxoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByUtxoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoId', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension SilentPaymentMetadataQuerySortThenBy
    on QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QSortThenBy> {
  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByOutputIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputIndex', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByOutputIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputIndex', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByPrivKeyTweak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privKeyTweak', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByPrivKeyTweakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privKeyTweak', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenBySharedSecret() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedSecret', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenBySharedSecretDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sharedSecret', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByUtxoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByUtxoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'utxoId', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension SilentPaymentMetadataQueryWhereDistinct
    on QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QDistinct> {
  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QDistinct>
      distinctByLabel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'label', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QDistinct>
      distinctByOutputIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputIndex');
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QDistinct>
      distinctByPrivKeyTweak({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privKeyTweak', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QDistinct>
      distinctBySharedSecret({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sharedSecret', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QDistinct>
      distinctByUtxoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'utxoId');
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QDistinct>
      distinctByWalletId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension SilentPaymentMetadataQueryProperty on QueryBuilder<
    SilentPaymentMetadata, SilentPaymentMetadata, QQueryProperty> {
  QueryBuilder<SilentPaymentMetadata, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SilentPaymentMetadata, String?, QQueryOperations>
      labelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'label');
    });
  }

  QueryBuilder<SilentPaymentMetadata, int, QQueryOperations>
      outputIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputIndex');
    });
  }

  QueryBuilder<SilentPaymentMetadata, String, QQueryOperations>
      privKeyTweakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privKeyTweak');
    });
  }

  QueryBuilder<SilentPaymentMetadata, String?, QQueryOperations>
      sharedSecretProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sharedSecret');
    });
  }

  QueryBuilder<SilentPaymentMetadata, int, QQueryOperations> utxoIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'utxoId');
    });
  }

  QueryBuilder<SilentPaymentMetadata, String, QQueryOperations>
      walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

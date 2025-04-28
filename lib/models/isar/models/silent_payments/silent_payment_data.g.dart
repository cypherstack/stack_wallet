// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'silent_payment_data.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSilentPaymentDataCollection on Isar {
  IsarCollection<SilentPaymentData> get silentPaymentData => this.collection();
}

const SilentPaymentDataSchema = CollectionSchema(
  name: r'SilentPaymentData',
  id: -2677381250855078109,
  properties: {
    r'isEnabled': PropertySchema(
      id: 0,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'lastScannedHeight': PropertySchema(
      id: 1,
      name: r'lastScannedHeight',
      type: IsarType.long,
    ),
    r'metadataJsonString': PropertySchema(
      id: 2,
      name: r'metadataJsonString',
      type: IsarType.string,
    ),
    r'walletId': PropertySchema(
      id: 3,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _silentPaymentDataEstimateSize,
  serialize: _silentPaymentDataSerialize,
  deserialize: _silentPaymentDataDeserialize,
  deserializeProp: _silentPaymentDataDeserializeProp,
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
  getId: _silentPaymentDataGetId,
  getLinks: _silentPaymentDataGetLinks,
  attach: _silentPaymentDataAttach,
  version: '3.1.8',
);

int _silentPaymentDataEstimateSize(
  SilentPaymentData object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.metadataJsonString;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _silentPaymentDataSerialize(
  SilentPaymentData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isEnabled);
  writer.writeLong(offsets[1], object.lastScannedHeight);
  writer.writeString(offsets[2], object.metadataJsonString);
  writer.writeString(offsets[3], object.walletId);
}

SilentPaymentData _silentPaymentDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SilentPaymentData(
    isEnabled: reader.readBoolOrNull(offsets[0]) ?? false,
    lastScannedHeight: reader.readLongOrNull(offsets[1]) ?? 0,
    metadataJsonString: reader.readStringOrNull(offsets[2]),
    walletId: reader.readString(offsets[3]),
  );
  object.id = id;
  return object;
}

P _silentPaymentDataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _silentPaymentDataGetId(SilentPaymentData object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _silentPaymentDataGetLinks(
    SilentPaymentData object) {
  return [];
}

void _silentPaymentDataAttach(
    IsarCollection<dynamic> col, Id id, SilentPaymentData object) {
  object.id = id;
}

extension SilentPaymentDataByIndex on IsarCollection<SilentPaymentData> {
  Future<SilentPaymentData?> getByWalletId(String walletId) {
    return getByIndex(r'walletId', [walletId]);
  }

  SilentPaymentData? getByWalletIdSync(String walletId) {
    return getByIndexSync(r'walletId', [walletId]);
  }

  Future<bool> deleteByWalletId(String walletId) {
    return deleteByIndex(r'walletId', [walletId]);
  }

  bool deleteByWalletIdSync(String walletId) {
    return deleteByIndexSync(r'walletId', [walletId]);
  }

  Future<List<SilentPaymentData?>> getAllByWalletId(
      List<String> walletIdValues) {
    final values = walletIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'walletId', values);
  }

  List<SilentPaymentData?> getAllByWalletIdSync(List<String> walletIdValues) {
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

  Future<Id> putByWalletId(SilentPaymentData object) {
    return putByIndex(r'walletId', object);
  }

  Id putByWalletIdSync(SilentPaymentData object, {bool saveLinks = true}) {
    return putByIndexSync(r'walletId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByWalletId(List<SilentPaymentData> objects) {
    return putAllByIndex(r'walletId', objects);
  }

  List<Id> putAllByWalletIdSync(List<SilentPaymentData> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'walletId', objects, saveLinks: saveLinks);
  }
}

extension SilentPaymentDataQueryWhereSort
    on QueryBuilder<SilentPaymentData, SilentPaymentData, QWhere> {
  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SilentPaymentDataQueryWhere
    on QueryBuilder<SilentPaymentData, SilentPaymentData, QWhereClause> {
  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterWhereClause>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterWhereClause>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterWhereClause>
      walletIdEqualTo(String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterWhereClause>
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

extension SilentPaymentDataQueryFilter
    on QueryBuilder<SilentPaymentData, SilentPaymentData, QFilterCondition> {
  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      isEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      lastScannedHeightEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastScannedHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      lastScannedHeightGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastScannedHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      lastScannedHeightLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastScannedHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      lastScannedHeightBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastScannedHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'metadataJsonString',
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'metadataJsonString',
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'metadataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'metadataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'metadataJsonString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'metadataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'metadataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'metadataJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'metadataJsonString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'metadataJsonString',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      metadataJsonStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'metadataJsonString',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      walletIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      walletIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterFilterCondition>
      walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension SilentPaymentDataQueryObject
    on QueryBuilder<SilentPaymentData, SilentPaymentData, QFilterCondition> {}

extension SilentPaymentDataQueryLinks
    on QueryBuilder<SilentPaymentData, SilentPaymentData, QFilterCondition> {}

extension SilentPaymentDataQuerySortBy
    on QueryBuilder<SilentPaymentData, SilentPaymentData, QSortBy> {
  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      sortByLastScannedHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastScannedHeight', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      sortByLastScannedHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastScannedHeight', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      sortByMetadataJsonString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJsonString', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      sortByMetadataJsonStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJsonString', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension SilentPaymentDataQuerySortThenBy
    on QueryBuilder<SilentPaymentData, SilentPaymentData, QSortThenBy> {
  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      thenByLastScannedHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastScannedHeight', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      thenByLastScannedHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastScannedHeight', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      thenByMetadataJsonString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJsonString', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      thenByMetadataJsonStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'metadataJsonString', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QAfterSortBy>
      thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension SilentPaymentDataQueryWhereDistinct
    on QueryBuilder<SilentPaymentData, SilentPaymentData, QDistinct> {
  QueryBuilder<SilentPaymentData, SilentPaymentData, QDistinct>
      distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QDistinct>
      distinctByLastScannedHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastScannedHeight');
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QDistinct>
      distinctByMetadataJsonString({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'metadataJsonString',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentData, SilentPaymentData, QDistinct>
      distinctByWalletId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension SilentPaymentDataQueryProperty
    on QueryBuilder<SilentPaymentData, SilentPaymentData, QQueryProperty> {
  QueryBuilder<SilentPaymentData, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SilentPaymentData, bool, QQueryOperations> isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<SilentPaymentData, int, QQueryOperations>
      lastScannedHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastScannedHeight');
    });
  }

  QueryBuilder<SilentPaymentData, String?, QQueryOperations>
      metadataJsonStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'metadataJsonString');
    });
  }

  QueryBuilder<SilentPaymentData, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

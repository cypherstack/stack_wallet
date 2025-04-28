// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'silent_payment_config.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSilentPaymentConfigCollection on Isar {
  IsarCollection<SilentPaymentConfig> get silentPaymentConfig =>
      this.collection();
}

const SilentPaymentConfigSchema = CollectionSchema(
  name: r'SilentPaymentConfig',
  id: 8185245117812277101,
  properties: {
    r'isEnabled': PropertySchema(
      id: 0,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'labelMapJsonString': PropertySchema(
      id: 1,
      name: r'labelMapJsonString',
      type: IsarType.string,
    ),
    r'lastScannedHeight': PropertySchema(
      id: 2,
      name: r'lastScannedHeight',
      type: IsarType.long,
    ),
    r'walletId': PropertySchema(
      id: 3,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _silentPaymentConfigEstimateSize,
  serialize: _silentPaymentConfigSerialize,
  deserialize: _silentPaymentConfigDeserialize,
  deserializeProp: _silentPaymentConfigDeserializeProp,
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
  getId: _silentPaymentConfigGetId,
  getLinks: _silentPaymentConfigGetLinks,
  attach: _silentPaymentConfigAttach,
  version: '3.1.8',
);

int _silentPaymentConfigEstimateSize(
  SilentPaymentConfig object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.labelMapJsonString;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _silentPaymentConfigSerialize(
  SilentPaymentConfig object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isEnabled);
  writer.writeString(offsets[1], object.labelMapJsonString);
  writer.writeLong(offsets[2], object.lastScannedHeight);
  writer.writeString(offsets[3], object.walletId);
}

SilentPaymentConfig _silentPaymentConfigDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SilentPaymentConfig(
    isEnabled: reader.readBoolOrNull(offsets[0]) ?? false,
    labelMapJsonString: reader.readStringOrNull(offsets[1]),
    lastScannedHeight: reader.readLongOrNull(offsets[2]) ?? 0,
    walletId: reader.readString(offsets[3]),
  );
  object.id = id;
  return object;
}

P _silentPaymentConfigDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _silentPaymentConfigGetId(SilentPaymentConfig object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _silentPaymentConfigGetLinks(
    SilentPaymentConfig object) {
  return [];
}

void _silentPaymentConfigAttach(
    IsarCollection<dynamic> col, Id id, SilentPaymentConfig object) {
  object.id = id;
}

extension SilentPaymentConfigByIndex on IsarCollection<SilentPaymentConfig> {
  Future<SilentPaymentConfig?> getByWalletId(String walletId) {
    return getByIndex(r'walletId', [walletId]);
  }

  SilentPaymentConfig? getByWalletIdSync(String walletId) {
    return getByIndexSync(r'walletId', [walletId]);
  }

  Future<bool> deleteByWalletId(String walletId) {
    return deleteByIndex(r'walletId', [walletId]);
  }

  bool deleteByWalletIdSync(String walletId) {
    return deleteByIndexSync(r'walletId', [walletId]);
  }

  Future<List<SilentPaymentConfig?>> getAllByWalletId(
      List<String> walletIdValues) {
    final values = walletIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'walletId', values);
  }

  List<SilentPaymentConfig?> getAllByWalletIdSync(List<String> walletIdValues) {
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

  Future<Id> putByWalletId(SilentPaymentConfig object) {
    return putByIndex(r'walletId', object);
  }

  Id putByWalletIdSync(SilentPaymentConfig object, {bool saveLinks = true}) {
    return putByIndexSync(r'walletId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByWalletId(List<SilentPaymentConfig> objects) {
    return putAllByIndex(r'walletId', objects);
  }

  List<Id> putAllByWalletIdSync(List<SilentPaymentConfig> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'walletId', objects, saveLinks: saveLinks);
  }
}

extension SilentPaymentConfigQueryWhereSort
    on QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QWhere> {
  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SilentPaymentConfigQueryWhere
    on QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QWhereClause> {
  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterWhereClause>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterWhereClause>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterWhereClause>
      walletIdEqualTo(String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterWhereClause>
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

extension SilentPaymentConfigQueryFilter on QueryBuilder<SilentPaymentConfig,
    SilentPaymentConfig, QFilterCondition> {
  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      isEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'labelMapJsonString',
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'labelMapJsonString',
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'labelMapJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'labelMapJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'labelMapJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'labelMapJsonString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'labelMapJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'labelMapJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'labelMapJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'labelMapJsonString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'labelMapJsonString',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      labelMapJsonStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'labelMapJsonString',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      lastScannedHeightEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastScannedHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
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

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      walletIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      walletIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterFilterCondition>
      walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension SilentPaymentConfigQueryObject on QueryBuilder<SilentPaymentConfig,
    SilentPaymentConfig, QFilterCondition> {}

extension SilentPaymentConfigQueryLinks on QueryBuilder<SilentPaymentConfig,
    SilentPaymentConfig, QFilterCondition> {}

extension SilentPaymentConfigQuerySortBy
    on QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QSortBy> {
  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      sortByLabelMapJsonString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'labelMapJsonString', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      sortByLabelMapJsonStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'labelMapJsonString', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      sortByLastScannedHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastScannedHeight', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      sortByLastScannedHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastScannedHeight', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension SilentPaymentConfigQuerySortThenBy
    on QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QSortThenBy> {
  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenByLabelMapJsonString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'labelMapJsonString', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenByLabelMapJsonStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'labelMapJsonString', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenByLastScannedHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastScannedHeight', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenByLastScannedHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastScannedHeight', Sort.desc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QAfterSortBy>
      thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension SilentPaymentConfigQueryWhereDistinct
    on QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QDistinct> {
  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QDistinct>
      distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QDistinct>
      distinctByLabelMapJsonString({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'labelMapJsonString',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QDistinct>
      distinctByLastScannedHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastScannedHeight');
    });
  }

  QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QDistinct>
      distinctByWalletId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension SilentPaymentConfigQueryProperty
    on QueryBuilder<SilentPaymentConfig, SilentPaymentConfig, QQueryProperty> {
  QueryBuilder<SilentPaymentConfig, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SilentPaymentConfig, bool, QQueryOperations>
      isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<SilentPaymentConfig, String?, QQueryOperations>
      labelMapJsonStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'labelMapJsonString');
    });
  }

  QueryBuilder<SilentPaymentConfig, int, QQueryOperations>
      lastScannedHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastScannedHeight');
    });
  }

  QueryBuilder<SilentPaymentConfig, String, QQueryOperations>
      walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

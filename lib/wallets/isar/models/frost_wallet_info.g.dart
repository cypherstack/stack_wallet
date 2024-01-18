// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frost_wallet_info.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetFrostWalletInfoCollection on Isar {
  IsarCollection<FrostWalletInfo> get frostWalletInfo => this.collection();
}

const FrostWalletInfoSchema = CollectionSchema(
  name: r'FrostWalletInfo',
  id: -4182879703273806681,
  properties: {
    r'knownSalts': PropertySchema(
      id: 0,
      name: r'knownSalts',
      type: IsarType.stringList,
    ),
    r'walletId': PropertySchema(
      id: 1,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _frostWalletInfoEstimateSize,
  serialize: _frostWalletInfoSerialize,
  deserialize: _frostWalletInfoDeserialize,
  deserializeProp: _frostWalletInfoDeserializeProp,
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
  getId: _frostWalletInfoGetId,
  getLinks: _frostWalletInfoGetLinks,
  attach: _frostWalletInfoAttach,
  version: '3.0.5',
);

int _frostWalletInfoEstimateSize(
  FrostWalletInfo object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.knownSalts.length * 3;
  {
    for (var i = 0; i < object.knownSalts.length; i++) {
      final value = object.knownSalts[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _frostWalletInfoSerialize(
  FrostWalletInfo object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.knownSalts);
  writer.writeString(offsets[1], object.walletId);
}

FrostWalletInfo _frostWalletInfoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FrostWalletInfo(
    knownSalts: reader.readStringList(offsets[0]) ?? [],
    walletId: reader.readString(offsets[1]),
  );
  object.id = id;
  return object;
}

P _frostWalletInfoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _frostWalletInfoGetId(FrostWalletInfo object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _frostWalletInfoGetLinks(FrostWalletInfo object) {
  return [];
}

void _frostWalletInfoAttach(
    IsarCollection<dynamic> col, Id id, FrostWalletInfo object) {
  object.id = id;
}

extension FrostWalletInfoByIndex on IsarCollection<FrostWalletInfo> {
  Future<FrostWalletInfo?> getByWalletId(String walletId) {
    return getByIndex(r'walletId', [walletId]);
  }

  FrostWalletInfo? getByWalletIdSync(String walletId) {
    return getByIndexSync(r'walletId', [walletId]);
  }

  Future<bool> deleteByWalletId(String walletId) {
    return deleteByIndex(r'walletId', [walletId]);
  }

  bool deleteByWalletIdSync(String walletId) {
    return deleteByIndexSync(r'walletId', [walletId]);
  }

  Future<List<FrostWalletInfo?>> getAllByWalletId(List<String> walletIdValues) {
    final values = walletIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'walletId', values);
  }

  List<FrostWalletInfo?> getAllByWalletIdSync(List<String> walletIdValues) {
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

  Future<Id> putByWalletId(FrostWalletInfo object) {
    return putByIndex(r'walletId', object);
  }

  Id putByWalletIdSync(FrostWalletInfo object, {bool saveLinks = true}) {
    return putByIndexSync(r'walletId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByWalletId(List<FrostWalletInfo> objects) {
    return putAllByIndex(r'walletId', objects);
  }

  List<Id> putAllByWalletIdSync(List<FrostWalletInfo> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'walletId', objects, saveLinks: saveLinks);
  }
}

extension FrostWalletInfoQueryWhereSort
    on QueryBuilder<FrostWalletInfo, FrostWalletInfo, QWhere> {
  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FrostWalletInfoQueryWhere
    on QueryBuilder<FrostWalletInfo, FrostWalletInfo, QWhereClause> {
  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterWhereClause>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterWhereClause> idBetween(
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterWhereClause>
      walletIdEqualTo(String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterWhereClause>
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

extension FrostWalletInfoQueryFilter
    on QueryBuilder<FrostWalletInfo, FrostWalletInfo, QFilterCondition> {
  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'knownSalts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'knownSalts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'knownSalts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'knownSalts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'knownSalts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'knownSalts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'knownSalts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'knownSalts',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'knownSalts',
        value: '',
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'knownSalts',
        value: '',
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownSalts',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownSalts',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownSalts',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownSalts',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownSalts',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      knownSaltsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'knownSalts',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      walletIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      walletIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterFilterCondition>
      walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension FrostWalletInfoQueryObject
    on QueryBuilder<FrostWalletInfo, FrostWalletInfo, QFilterCondition> {}

extension FrostWalletInfoQueryLinks
    on QueryBuilder<FrostWalletInfo, FrostWalletInfo, QFilterCondition> {}

extension FrostWalletInfoQuerySortBy
    on QueryBuilder<FrostWalletInfo, FrostWalletInfo, QSortBy> {
  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterSortBy>
      sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterSortBy>
      sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension FrostWalletInfoQuerySortThenBy
    on QueryBuilder<FrostWalletInfo, FrostWalletInfo, QSortThenBy> {
  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterSortBy>
      thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QAfterSortBy>
      thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension FrostWalletInfoQueryWhereDistinct
    on QueryBuilder<FrostWalletInfo, FrostWalletInfo, QDistinct> {
  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QDistinct>
      distinctByKnownSalts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'knownSalts');
    });
  }

  QueryBuilder<FrostWalletInfo, FrostWalletInfo, QDistinct> distinctByWalletId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension FrostWalletInfoQueryProperty
    on QueryBuilder<FrostWalletInfo, FrostWalletInfo, QQueryProperty> {
  QueryBuilder<FrostWalletInfo, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FrostWalletInfo, List<String>, QQueryOperations>
      knownSaltsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'knownSalts');
    });
  }

  QueryBuilder<FrostWalletInfo, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_info_meta.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWalletInfoMetaCollection on Isar {
  IsarCollection<WalletInfoMeta> get walletInfoMeta => this.collection();
}

const WalletInfoMetaSchema = CollectionSchema(
  name: r'WalletInfoMeta',
  id: -4749826865193299377,
  properties: {
    r'isMnemonicVerified': PropertySchema(
      id: 0,
      name: r'isMnemonicVerified',
      type: IsarType.bool,
    ),
    r'walletId': PropertySchema(
      id: 1,
      name: r'walletId',
      type: IsarType.string,
    ),
  },

  estimateSize: _walletInfoMetaEstimateSize,
  serialize: _walletInfoMetaSerialize,
  deserialize: _walletInfoMetaDeserialize,
  deserializeProp: _walletInfoMetaDeserializeProp,
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
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _walletInfoMetaGetId,
  getLinks: _walletInfoMetaGetLinks,
  attach: _walletInfoMetaAttach,
  version: '3.3.0-dev.2',
);

int _walletInfoMetaEstimateSize(
  WalletInfoMeta object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _walletInfoMetaSerialize(
  WalletInfoMeta object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isMnemonicVerified);
  writer.writeString(offsets[1], object.walletId);
}

WalletInfoMeta _walletInfoMetaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WalletInfoMeta(
    isMnemonicVerified: reader.readBool(offsets[0]),
    walletId: reader.readString(offsets[1]),
  );
  object.id = id;
  return object;
}

P _walletInfoMetaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _walletInfoMetaGetId(WalletInfoMeta object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _walletInfoMetaGetLinks(WalletInfoMeta object) {
  return [];
}

void _walletInfoMetaAttach(
  IsarCollection<dynamic> col,
  Id id,
  WalletInfoMeta object,
) {
  object.id = id;
}

extension WalletInfoMetaByIndex on IsarCollection<WalletInfoMeta> {
  Future<WalletInfoMeta?> getByWalletId(String walletId) {
    return getByIndex(r'walletId', [walletId]);
  }

  WalletInfoMeta? getByWalletIdSync(String walletId) {
    return getByIndexSync(r'walletId', [walletId]);
  }

  Future<bool> deleteByWalletId(String walletId) {
    return deleteByIndex(r'walletId', [walletId]);
  }

  bool deleteByWalletIdSync(String walletId) {
    return deleteByIndexSync(r'walletId', [walletId]);
  }

  Future<List<WalletInfoMeta?>> getAllByWalletId(List<String> walletIdValues) {
    final values = walletIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'walletId', values);
  }

  List<WalletInfoMeta?> getAllByWalletIdSync(List<String> walletIdValues) {
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

  Future<Id> putByWalletId(WalletInfoMeta object) {
    return putByIndex(r'walletId', object);
  }

  Id putByWalletIdSync(WalletInfoMeta object, {bool saveLinks = true}) {
    return putByIndexSync(r'walletId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByWalletId(List<WalletInfoMeta> objects) {
    return putAllByIndex(r'walletId', objects);
  }

  List<Id> putAllByWalletIdSync(
    List<WalletInfoMeta> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'walletId', objects, saveLinks: saveLinks);
  }
}

extension WalletInfoMetaQueryWhereSort
    on QueryBuilder<WalletInfoMeta, WalletInfoMeta, QWhere> {
  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WalletInfoMetaQueryWhere
    on QueryBuilder<WalletInfoMeta, WalletInfoMeta, QWhereClause> {
  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterWhereClause> idBetween(
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterWhereClause>
  walletIdEqualTo(String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'walletId', value: [walletId]),
      );
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterWhereClause>
  walletIdNotEqualTo(String walletId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId',
                lower: [],
                upper: [walletId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId',
                lower: [walletId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId',
                lower: [walletId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'walletId',
                lower: [],
                upper: [walletId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension WalletInfoMetaQueryFilter
    on QueryBuilder<WalletInfoMeta, WalletInfoMeta, QFilterCondition> {
  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition> idBetween(
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  isMnemonicVerifiedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isMnemonicVerified', value: value),
      );
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdGreaterThan(
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdLessThan(
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdBetween(
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'walletId', value: ''),
      );
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterFilterCondition>
  walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'walletId', value: ''),
      );
    });
  }
}

extension WalletInfoMetaQueryObject
    on QueryBuilder<WalletInfoMeta, WalletInfoMeta, QFilterCondition> {}

extension WalletInfoMetaQueryLinks
    on QueryBuilder<WalletInfoMeta, WalletInfoMeta, QFilterCondition> {}

extension WalletInfoMetaQuerySortBy
    on QueryBuilder<WalletInfoMeta, WalletInfoMeta, QSortBy> {
  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy>
  sortByIsMnemonicVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMnemonicVerified', Sort.asc);
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy>
  sortByIsMnemonicVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMnemonicVerified', Sort.desc);
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy>
  sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension WalletInfoMetaQuerySortThenBy
    on QueryBuilder<WalletInfoMeta, WalletInfoMeta, QSortThenBy> {
  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy>
  thenByIsMnemonicVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMnemonicVerified', Sort.asc);
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy>
  thenByIsMnemonicVerifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMnemonicVerified', Sort.desc);
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QAfterSortBy>
  thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension WalletInfoMetaQueryWhereDistinct
    on QueryBuilder<WalletInfoMeta, WalletInfoMeta, QDistinct> {
  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QDistinct>
  distinctByIsMnemonicVerified() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMnemonicVerified');
    });
  }

  QueryBuilder<WalletInfoMeta, WalletInfoMeta, QDistinct> distinctByWalletId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension WalletInfoMetaQueryProperty
    on QueryBuilder<WalletInfoMeta, WalletInfoMeta, QQueryProperty> {
  QueryBuilder<WalletInfoMeta, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WalletInfoMeta, bool, QQueryOperations>
  isMnemonicVerifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMnemonicVerified');
    });
  }

  QueryBuilder<WalletInfoMeta, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

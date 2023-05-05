// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_explorer.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetTransactionBlockExplorerCollection on Isar {
  IsarCollection<TransactionBlockExplorer> get transactionBlockExplorers =>
      this.collection();
}

const TransactionBlockExplorerSchema = CollectionSchema(
  name: r'TransactionBlockExplorer',
  id: 4209077296238413906,
  properties: {
    r'ticker': PropertySchema(
      id: 0,
      name: r'ticker',
      type: IsarType.string,
    ),
    r'url': PropertySchema(
      id: 1,
      name: r'url',
      type: IsarType.string,
    )
  },
  estimateSize: _transactionBlockExplorerEstimateSize,
  serialize: _transactionBlockExplorerSerialize,
  deserialize: _transactionBlockExplorerDeserialize,
  deserializeProp: _transactionBlockExplorerDeserializeProp,
  idName: r'id',
  indexes: {
    r'ticker': IndexSchema(
      id: -8264639257510259247,
      name: r'ticker',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'ticker',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _transactionBlockExplorerGetId,
  getLinks: _transactionBlockExplorerGetLinks,
  attach: _transactionBlockExplorerAttach,
  version: '3.0.5',
);

int _transactionBlockExplorerEstimateSize(
  TransactionBlockExplorer object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.ticker.length * 3;
  bytesCount += 3 + object.url.length * 3;
  return bytesCount;
}

void _transactionBlockExplorerSerialize(
  TransactionBlockExplorer object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.ticker);
  writer.writeString(offsets[1], object.url);
}

TransactionBlockExplorer _transactionBlockExplorerDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TransactionBlockExplorer(
    ticker: reader.readString(offsets[0]),
    url: reader.readString(offsets[1]),
  );
  object.id = id;
  return object;
}

P _transactionBlockExplorerDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _transactionBlockExplorerGetId(TransactionBlockExplorer object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _transactionBlockExplorerGetLinks(
    TransactionBlockExplorer object) {
  return [];
}

void _transactionBlockExplorerAttach(
    IsarCollection<dynamic> col, Id id, TransactionBlockExplorer object) {
  object.id = id;
}

extension TransactionBlockExplorerByIndex
    on IsarCollection<TransactionBlockExplorer> {
  Future<TransactionBlockExplorer?> getByTicker(String ticker) {
    return getByIndex(r'ticker', [ticker]);
  }

  TransactionBlockExplorer? getByTickerSync(String ticker) {
    return getByIndexSync(r'ticker', [ticker]);
  }

  Future<bool> deleteByTicker(String ticker) {
    return deleteByIndex(r'ticker', [ticker]);
  }

  bool deleteByTickerSync(String ticker) {
    return deleteByIndexSync(r'ticker', [ticker]);
  }

  Future<List<TransactionBlockExplorer?>> getAllByTicker(
      List<String> tickerValues) {
    final values = tickerValues.map((e) => [e]).toList();
    return getAllByIndex(r'ticker', values);
  }

  List<TransactionBlockExplorer?> getAllByTickerSync(
      List<String> tickerValues) {
    final values = tickerValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'ticker', values);
  }

  Future<int> deleteAllByTicker(List<String> tickerValues) {
    final values = tickerValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'ticker', values);
  }

  int deleteAllByTickerSync(List<String> tickerValues) {
    final values = tickerValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'ticker', values);
  }

  Future<Id> putByTicker(TransactionBlockExplorer object) {
    return putByIndex(r'ticker', object);
  }

  Id putByTickerSync(TransactionBlockExplorer object, {bool saveLinks = true}) {
    return putByIndexSync(r'ticker', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTicker(List<TransactionBlockExplorer> objects) {
    return putAllByIndex(r'ticker', objects);
  }

  List<Id> putAllByTickerSync(List<TransactionBlockExplorer> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'ticker', objects, saveLinks: saveLinks);
  }
}

extension TransactionBlockExplorerQueryWhereSort on QueryBuilder<
    TransactionBlockExplorer, TransactionBlockExplorer, QWhere> {
  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TransactionBlockExplorerQueryWhere on QueryBuilder<
    TransactionBlockExplorer, TransactionBlockExplorer, QWhereClause> {
  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterWhereClause> idBetween(
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

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterWhereClause> tickerEqualTo(String ticker) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ticker',
        value: [ticker],
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterWhereClause> tickerNotEqualTo(String ticker) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker',
              lower: [],
              upper: [ticker],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker',
              lower: [ticker],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker',
              lower: [ticker],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker',
              lower: [],
              upper: [ticker],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TransactionBlockExplorerQueryFilter on QueryBuilder<
    TransactionBlockExplorer, TransactionBlockExplorer, QFilterCondition> {
  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
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

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
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

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
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

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> tickerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> tickerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> tickerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> tickerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ticker',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> tickerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> tickerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
          QAfterFilterCondition>
      tickerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
          QAfterFilterCondition>
      tickerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ticker',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> tickerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticker',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> tickerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ticker',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
          QAfterFilterCondition>
      urlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
          QAfterFilterCondition>
      urlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer,
      QAfterFilterCondition> urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }
}

extension TransactionBlockExplorerQueryObject on QueryBuilder<
    TransactionBlockExplorer, TransactionBlockExplorer, QFilterCondition> {}

extension TransactionBlockExplorerQueryLinks on QueryBuilder<
    TransactionBlockExplorer, TransactionBlockExplorer, QFilterCondition> {}

extension TransactionBlockExplorerQuerySortBy on QueryBuilder<
    TransactionBlockExplorer, TransactionBlockExplorer, QSortBy> {
  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      sortByTicker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.asc);
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      sortByTickerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.desc);
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension TransactionBlockExplorerQuerySortThenBy on QueryBuilder<
    TransactionBlockExplorer, TransactionBlockExplorer, QSortThenBy> {
  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      thenByTicker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.asc);
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      thenByTickerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.desc);
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QAfterSortBy>
      thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension TransactionBlockExplorerQueryWhereDistinct on QueryBuilder<
    TransactionBlockExplorer, TransactionBlockExplorer, QDistinct> {
  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QDistinct>
      distinctByTicker({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ticker', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionBlockExplorer, TransactionBlockExplorer, QDistinct>
      distinctByUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }
}

extension TransactionBlockExplorerQueryProperty on QueryBuilder<
    TransactionBlockExplorer, TransactionBlockExplorer, QQueryProperty> {
  QueryBuilder<TransactionBlockExplorer, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TransactionBlockExplorer, String, QQueryOperations>
      tickerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ticker');
    });
  }

  QueryBuilder<TransactionBlockExplorer, String, QQueryOperations>
      urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }
}

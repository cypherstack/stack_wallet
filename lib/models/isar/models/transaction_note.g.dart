// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_note.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetTransactionNoteCollection on Isar {
  IsarCollection<TransactionNote> get transactionNotes => this.collection();
}

const TransactionNoteSchema = CollectionSchema(
  name: r'TransactionNote',
  id: 5128348263878806765,
  properties: {
    r'txid': PropertySchema(
      id: 0,
      name: r'txid',
      type: IsarType.string,
    ),
    r'value': PropertySchema(
      id: 1,
      name: r'value',
      type: IsarType.string,
    )
  },
  estimateSize: _transactionNoteEstimateSize,
  serialize: _transactionNoteSerialize,
  deserialize: _transactionNoteDeserialize,
  deserializeProp: _transactionNoteDeserializeProp,
  idName: r'id',
  indexes: {
    r'txid': IndexSchema(
      id: 7339874292043634331,
      name: r'txid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'txid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _transactionNoteGetId,
  getLinks: _transactionNoteGetLinks,
  attach: _transactionNoteAttach,
  version: '3.0.5',
);

int _transactionNoteEstimateSize(
  TransactionNote object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.txid.length * 3;
  bytesCount += 3 + object.value.length * 3;
  return bytesCount;
}

void _transactionNoteSerialize(
  TransactionNote object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.txid);
  writer.writeString(offsets[1], object.value);
}

TransactionNote _transactionNoteDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TransactionNote();
  object.id = id;
  object.txid = reader.readString(offsets[0]);
  object.value = reader.readString(offsets[1]);
  return object;
}

P _transactionNoteDeserializeProp<P>(
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

Id _transactionNoteGetId(TransactionNote object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _transactionNoteGetLinks(TransactionNote object) {
  return [];
}

void _transactionNoteAttach(
    IsarCollection<dynamic> col, Id id, TransactionNote object) {
  object.id = id;
}

extension TransactionNoteByIndex on IsarCollection<TransactionNote> {
  Future<TransactionNote?> getByTxid(String txid) {
    return getByIndex(r'txid', [txid]);
  }

  TransactionNote? getByTxidSync(String txid) {
    return getByIndexSync(r'txid', [txid]);
  }

  Future<bool> deleteByTxid(String txid) {
    return deleteByIndex(r'txid', [txid]);
  }

  bool deleteByTxidSync(String txid) {
    return deleteByIndexSync(r'txid', [txid]);
  }

  Future<List<TransactionNote?>> getAllByTxid(List<String> txidValues) {
    final values = txidValues.map((e) => [e]).toList();
    return getAllByIndex(r'txid', values);
  }

  List<TransactionNote?> getAllByTxidSync(List<String> txidValues) {
    final values = txidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'txid', values);
  }

  Future<int> deleteAllByTxid(List<String> txidValues) {
    final values = txidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'txid', values);
  }

  int deleteAllByTxidSync(List<String> txidValues) {
    final values = txidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'txid', values);
  }

  Future<Id> putByTxid(TransactionNote object) {
    return putByIndex(r'txid', object);
  }

  Id putByTxidSync(TransactionNote object, {bool saveLinks = true}) {
    return putByIndexSync(r'txid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTxid(List<TransactionNote> objects) {
    return putAllByIndex(r'txid', objects);
  }

  List<Id> putAllByTxidSync(List<TransactionNote> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'txid', objects, saveLinks: saveLinks);
  }
}

extension TransactionNoteQueryWhereSort
    on QueryBuilder<TransactionNote, TransactionNote, QWhere> {
  QueryBuilder<TransactionNote, TransactionNote, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TransactionNoteQueryWhere
    on QueryBuilder<TransactionNote, TransactionNote, QWhereClause> {
  QueryBuilder<TransactionNote, TransactionNote, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterWhereClause>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterWhereClause> idBetween(
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterWhereClause> txidEqualTo(
      String txid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'txid',
        value: [txid],
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterWhereClause>
      txidNotEqualTo(String txid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid',
              lower: [],
              upper: [txid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid',
              lower: [txid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid',
              lower: [txid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'txid',
              lower: [],
              upper: [txid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TransactionNoteQueryFilter
    on QueryBuilder<TransactionNote, TransactionNote, QFilterCondition> {
  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
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

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      txidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      txidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'txid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      txidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      txidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'value',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'value',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterFilterCondition>
      valueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'value',
        value: '',
      ));
    });
  }
}

extension TransactionNoteQueryObject
    on QueryBuilder<TransactionNote, TransactionNote, QFilterCondition> {}

extension TransactionNoteQueryLinks
    on QueryBuilder<TransactionNote, TransactionNote, QFilterCondition> {}

extension TransactionNoteQuerySortBy
    on QueryBuilder<TransactionNote, TransactionNote, QSortBy> {
  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy> sortByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy>
      sortByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy>
      sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension TransactionNoteQuerySortThenBy
    on QueryBuilder<TransactionNote, TransactionNote, QSortThenBy> {
  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy> thenByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy>
      thenByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QAfterSortBy>
      thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension TransactionNoteQueryWhereDistinct
    on QueryBuilder<TransactionNote, TransactionNote, QDistinct> {
  QueryBuilder<TransactionNote, TransactionNote, QDistinct> distinctByTxid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'txid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionNote, TransactionNote, QDistinct> distinctByValue(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value', caseSensitive: caseSensitive);
    });
  }
}

extension TransactionNoteQueryProperty
    on QueryBuilder<TransactionNote, TransactionNote, QQueryProperty> {
  QueryBuilder<TransactionNote, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TransactionNote, String, QQueryOperations> txidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'txid');
    });
  }

  QueryBuilder<TransactionNote, String, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }
}

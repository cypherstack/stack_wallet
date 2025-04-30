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
    r'tweak': PropertySchema(
      id: 1,
      name: r'tweak',
      type: IsarType.string,
    )
  },
  estimateSize: _silentPaymentMetadataEstimateSize,
  serialize: _silentPaymentMetadataSerialize,
  deserialize: _silentPaymentMetadataDeserialize,
  deserializeProp: _silentPaymentMetadataDeserializeProp,
  idName: r'id',
  indexes: {},
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
  bytesCount += 3 + object.tweak.length * 3;
  return bytesCount;
}

void _silentPaymentMetadataSerialize(
  SilentPaymentMetadata object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.label);
  writer.writeString(offsets[1], object.tweak);
}

SilentPaymentMetadata _silentPaymentMetadataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SilentPaymentMetadata(
    id: id,
    label: reader.readStringOrNull(offsets[0]),
    tweak: reader.readString(offsets[1]),
  );
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

extension SilentPaymentMetadataQueryWhereSort
    on QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QWhere> {
  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
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
      QAfterFilterCondition> tweakEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> tweakGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> tweakLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> tweakBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tweak',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> tweakStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> tweakEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      tweakContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tweak',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
          QAfterFilterCondition>
      tweakMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tweak',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> tweakIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tweak',
        value: '',
      ));
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata,
      QAfterFilterCondition> tweakIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tweak',
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
      sortByTweak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tweak', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      sortByTweakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tweak', Sort.desc);
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
      thenByTweak() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tweak', Sort.asc);
    });
  }

  QueryBuilder<SilentPaymentMetadata, SilentPaymentMetadata, QAfterSortBy>
      thenByTweakDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tweak', Sort.desc);
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
      distinctByTweak({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tweak', caseSensitive: caseSensitive);
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

  QueryBuilder<SilentPaymentMetadata, String, QQueryOperations>
      tweakProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tweak');
    });
  }
}

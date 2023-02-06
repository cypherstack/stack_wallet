// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pair.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetPairCollection on Isar {
  IsarCollection<Pair> get pairs => this.collection();
}

const PairSchema = CollectionSchema(
  name: r'Pair',
  id: -3124465371488267306,
  properties: {
    r'exchangeName': PropertySchema(
      id: 0,
      name: r'exchangeName',
      type: IsarType.string,
    ),
    r'from': PropertySchema(
      id: 1,
      name: r'from',
      type: IsarType.string,
    ),
    r'hashCode': PropertySchema(
      id: 2,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'rateType': PropertySchema(
      id: 3,
      name: r'rateType',
      type: IsarType.byte,
      enumMap: _PairrateTypeEnumValueMap,
    ),
    r'to': PropertySchema(
      id: 4,
      name: r'to',
      type: IsarType.string,
    )
  },
  estimateSize: _pairEstimateSize,
  serialize: _pairSerialize,
  deserialize: _pairDeserialize,
  deserializeProp: _pairDeserializeProp,
  idName: r'id',
  indexes: {
    r'exchangeName': IndexSchema(
      id: 3599278165711581955,
      name: r'exchangeName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'exchangeName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'from_exchangeName_to': IndexSchema(
      id: 817716734160134079,
      name: r'from_exchangeName_to',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'from',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'exchangeName',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'to',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _pairGetId,
  getLinks: _pairGetLinks,
  attach: _pairAttach,
  version: '3.0.5',
);

int _pairEstimateSize(
  Pair object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exchangeName.length * 3;
  bytesCount += 3 + object.from.length * 3;
  bytesCount += 3 + object.to.length * 3;
  return bytesCount;
}

void _pairSerialize(
  Pair object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.exchangeName);
  writer.writeString(offsets[1], object.from);
  writer.writeLong(offsets[2], object.hashCode);
  writer.writeByte(offsets[3], object.rateType.index);
  writer.writeString(offsets[4], object.to);
}

Pair _pairDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Pair(
    exchangeName: reader.readString(offsets[0]),
    from: reader.readString(offsets[1]),
    rateType: _PairrateTypeValueEnumMap[reader.readByteOrNull(offsets[3])] ??
        SupportedRateType.fixed,
    to: reader.readString(offsets[4]),
  );
  object.id = id;
  return object;
}

P _pairDeserializeProp<P>(
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
      return (_PairrateTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          SupportedRateType.fixed) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PairrateTypeEnumValueMap = {
  'fixed': 0,
  'estimated': 1,
  'both': 2,
};
const _PairrateTypeValueEnumMap = {
  0: SupportedRateType.fixed,
  1: SupportedRateType.estimated,
  2: SupportedRateType.both,
};

Id _pairGetId(Pair object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _pairGetLinks(Pair object) {
  return [];
}

void _pairAttach(IsarCollection<dynamic> col, Id id, Pair object) {
  object.id = id;
}

extension PairQueryWhereSort on QueryBuilder<Pair, Pair, QWhere> {
  QueryBuilder<Pair, Pair, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PairQueryWhere on QueryBuilder<Pair, Pair, QWhereClause> {
  QueryBuilder<Pair, Pair, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Pair, Pair, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause> idBetween(
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

  QueryBuilder<Pair, Pair, QAfterWhereClause> exchangeNameEqualTo(
      String exchangeName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'exchangeName',
        value: [exchangeName],
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause> exchangeNameNotEqualTo(
      String exchangeName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exchangeName',
              lower: [],
              upper: [exchangeName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exchangeName',
              lower: [exchangeName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exchangeName',
              lower: [exchangeName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exchangeName',
              lower: [],
              upper: [exchangeName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause> fromEqualToAnyExchangeNameTo(
      String from) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'from_exchangeName_to',
        value: [from],
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause> fromNotEqualToAnyExchangeNameTo(
      String from) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [],
              upper: [from],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [],
              upper: [from],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause> fromExchangeNameEqualToAnyTo(
      String from, String exchangeName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'from_exchangeName_to',
        value: [from, exchangeName],
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause>
      fromEqualToExchangeNameNotEqualToAnyTo(String from, String exchangeName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from],
              upper: [from, exchangeName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from, exchangeName],
              includeLower: false,
              upper: [from],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from, exchangeName],
              includeLower: false,
              upper: [from],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from],
              upper: [from, exchangeName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause> fromExchangeNameToEqualTo(
      String from, String exchangeName, String to) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'from_exchangeName_to',
        value: [from, exchangeName, to],
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterWhereClause>
      fromExchangeNameEqualToToNotEqualTo(
          String from, String exchangeName, String to) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from, exchangeName],
              upper: [from, exchangeName, to],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from, exchangeName, to],
              includeLower: false,
              upper: [from, exchangeName],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from, exchangeName, to],
              includeLower: false,
              upper: [from, exchangeName],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'from_exchangeName_to',
              lower: [from, exchangeName],
              upper: [from, exchangeName, to],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PairQueryFilter on QueryBuilder<Pair, Pair, QFilterCondition> {
  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exchangeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exchangeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exchangeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exchangeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exchangeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exchangeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exchangeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exchangeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exchangeName',
        value: '',
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> exchangeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exchangeName',
        value: '',
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'from',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'from',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'from',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'from',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'from',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'from',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'from',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'from',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'from',
        value: '',
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> fromIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'from',
        value: '',
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> idGreaterThan(
    Id? value, {
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

  QueryBuilder<Pair, Pair, QAfterFilterCondition> idLessThan(
    Id? value, {
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

  QueryBuilder<Pair, Pair, QAfterFilterCondition> idBetween(
    Id? lower,
    Id? upper, {
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

  QueryBuilder<Pair, Pair, QAfterFilterCondition> rateTypeEqualTo(
      SupportedRateType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rateType',
        value: value,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> rateTypeGreaterThan(
    SupportedRateType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rateType',
        value: value,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> rateTypeLessThan(
    SupportedRateType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rateType',
        value: value,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> rateTypeBetween(
    SupportedRateType lower,
    SupportedRateType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rateType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'to',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'to',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'to',
        value: '',
      ));
    });
  }

  QueryBuilder<Pair, Pair, QAfterFilterCondition> toIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'to',
        value: '',
      ));
    });
  }
}

extension PairQueryObject on QueryBuilder<Pair, Pair, QFilterCondition> {}

extension PairQueryLinks on QueryBuilder<Pair, Pair, QFilterCondition> {}

extension PairQuerySortBy on QueryBuilder<Pair, Pair, QSortBy> {
  QueryBuilder<Pair, Pair, QAfterSortBy> sortByExchangeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeName', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> sortByExchangeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeName', Sort.desc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> sortByFrom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'from', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> sortByFromDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'from', Sort.desc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> sortByRateType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateType', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> sortByRateTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateType', Sort.desc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> sortByTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'to', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> sortByToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'to', Sort.desc);
    });
  }
}

extension PairQuerySortThenBy on QueryBuilder<Pair, Pair, QSortThenBy> {
  QueryBuilder<Pair, Pair, QAfterSortBy> thenByExchangeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeName', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByExchangeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeName', Sort.desc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByFrom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'from', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByFromDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'from', Sort.desc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByRateType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateType', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByRateTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rateType', Sort.desc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'to', Sort.asc);
    });
  }

  QueryBuilder<Pair, Pair, QAfterSortBy> thenByToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'to', Sort.desc);
    });
  }
}

extension PairQueryWhereDistinct on QueryBuilder<Pair, Pair, QDistinct> {
  QueryBuilder<Pair, Pair, QDistinct> distinctByExchangeName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exchangeName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pair, Pair, QDistinct> distinctByFrom(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'from', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pair, Pair, QDistinct> distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<Pair, Pair, QDistinct> distinctByRateType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rateType');
    });
  }

  QueryBuilder<Pair, Pair, QDistinct> distinctByTo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'to', caseSensitive: caseSensitive);
    });
  }
}

extension PairQueryProperty on QueryBuilder<Pair, Pair, QQueryProperty> {
  QueryBuilder<Pair, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Pair, String, QQueryOperations> exchangeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exchangeName');
    });
  }

  QueryBuilder<Pair, String, QQueryOperations> fromProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'from');
    });
  }

  QueryBuilder<Pair, int, QQueryOperations> hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<Pair, SupportedRateType, QQueryOperations> rateTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rateType');
    });
  }

  QueryBuilder<Pair, String, QQueryOperations> toProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'to');
    });
  }
}

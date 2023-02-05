// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetCurrencyCollection on Isar {
  IsarCollection<Currency> get currencies => this.collection();
}

const CurrencySchema = CollectionSchema(
  name: r'Currency',
  id: 8290149502090171821,
  properties: {
    r'exchangeName': PropertySchema(
      id: 0,
      name: r'exchangeName',
      type: IsarType.string,
    ),
    r'externalId': PropertySchema(
      id: 1,
      name: r'externalId',
      type: IsarType.string,
    ),
    r'image': PropertySchema(
      id: 2,
      name: r'image',
      type: IsarType.string,
    ),
    r'isAvailable': PropertySchema(
      id: 3,
      name: r'isAvailable',
      type: IsarType.bool,
    ),
    r'isFiat': PropertySchema(
      id: 4,
      name: r'isFiat',
      type: IsarType.bool,
    ),
    r'isStackCoin': PropertySchema(
      id: 5,
      name: r'isStackCoin',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'network': PropertySchema(
      id: 7,
      name: r'network',
      type: IsarType.string,
    ),
    r'supportsEstimatedRate': PropertySchema(
      id: 8,
      name: r'supportsEstimatedRate',
      type: IsarType.bool,
    ),
    r'supportsFixedRate': PropertySchema(
      id: 9,
      name: r'supportsFixedRate',
      type: IsarType.bool,
    ),
    r'ticker': PropertySchema(
      id: 10,
      name: r'ticker',
      type: IsarType.string,
    )
  },
  estimateSize: _currencyEstimateSize,
  serialize: _currencySerialize,
  deserialize: _currencyDeserialize,
  deserializeProp: _currencyDeserializeProp,
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
    r'ticker_exchangeName_name': IndexSchema(
      id: 6345943517929964748,
      name: r'ticker_exchangeName_name',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ticker',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'exchangeName',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'supportsFixedRate': IndexSchema(
      id: 444054599534256333,
      name: r'supportsFixedRate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'supportsFixedRate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'supportsEstimatedRate': IndexSchema(
      id: 4184033449468624530,
      name: r'supportsEstimatedRate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'supportsEstimatedRate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isStackCoin': IndexSchema(
      id: 1994111521912746776,
      name: r'isStackCoin',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isStackCoin',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _currencyGetId,
  getLinks: _currencyGetLinks,
  attach: _currencyAttach,
  version: '3.0.5',
);

int _currencyEstimateSize(
  Currency object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exchangeName.length * 3;
  {
    final value = object.externalId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.image.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.network.length * 3;
  bytesCount += 3 + object.ticker.length * 3;
  return bytesCount;
}

void _currencySerialize(
  Currency object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.exchangeName);
  writer.writeString(offsets[1], object.externalId);
  writer.writeString(offsets[2], object.image);
  writer.writeBool(offsets[3], object.isAvailable);
  writer.writeBool(offsets[4], object.isFiat);
  writer.writeBool(offsets[5], object.isStackCoin);
  writer.writeString(offsets[6], object.name);
  writer.writeString(offsets[7], object.network);
  writer.writeBool(offsets[8], object.supportsEstimatedRate);
  writer.writeBool(offsets[9], object.supportsFixedRate);
  writer.writeString(offsets[10], object.ticker);
}

Currency _currencyDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Currency(
    exchangeName: reader.readString(offsets[0]),
    externalId: reader.readStringOrNull(offsets[1]),
    image: reader.readString(offsets[2]),
    isAvailable: reader.readBoolOrNull(offsets[3]),
    isFiat: reader.readBool(offsets[4]),
    isStackCoin: reader.readBool(offsets[5]),
    name: reader.readString(offsets[6]),
    network: reader.readString(offsets[7]),
    supportsEstimatedRate: reader.readBool(offsets[8]),
    supportsFixedRate: reader.readBool(offsets[9]),
    ticker: reader.readString(offsets[10]),
  );
  object.id = id;
  return object;
}

P _currencyDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _currencyGetId(Currency object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _currencyGetLinks(Currency object) {
  return [];
}

void _currencyAttach(IsarCollection<dynamic> col, Id id, Currency object) {
  object.id = id;
}

extension CurrencyQueryWhereSort on QueryBuilder<Currency, Currency, QWhere> {
  QueryBuilder<Currency, Currency, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhere> anySupportsFixedRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'supportsFixedRate'),
      );
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhere> anySupportsEstimatedRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'supportsEstimatedRate'),
      );
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhere> anyIsStackCoin() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isStackCoin'),
      );
    });
  }
}

extension CurrencyQueryWhere on QueryBuilder<Currency, Currency, QWhereClause> {
  QueryBuilder<Currency, Currency, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Currency, Currency, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause> idBetween(
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

  QueryBuilder<Currency, Currency, QAfterWhereClause> exchangeNameEqualTo(
      String exchangeName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'exchangeName',
        value: [exchangeName],
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause> exchangeNameNotEqualTo(
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

  QueryBuilder<Currency, Currency, QAfterWhereClause>
      tickerEqualToAnyExchangeNameName(String ticker) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ticker_exchangeName_name',
        value: [ticker],
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause>
      tickerNotEqualToAnyExchangeNameName(String ticker) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [],
              upper: [ticker],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [],
              upper: [ticker],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause>
      tickerExchangeNameEqualToAnyName(String ticker, String exchangeName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ticker_exchangeName_name',
        value: [ticker, exchangeName],
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause>
      tickerEqualToExchangeNameNotEqualToAnyName(
          String ticker, String exchangeName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker],
              upper: [ticker, exchangeName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker, exchangeName],
              includeLower: false,
              upper: [ticker],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker, exchangeName],
              includeLower: false,
              upper: [ticker],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker],
              upper: [ticker, exchangeName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause>
      tickerExchangeNameNameEqualTo(
          String ticker, String exchangeName, String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ticker_exchangeName_name',
        value: [ticker, exchangeName, name],
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause>
      tickerExchangeNameEqualToNameNotEqualTo(
          String ticker, String exchangeName, String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker, exchangeName],
              upper: [ticker, exchangeName, name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker, exchangeName, name],
              includeLower: false,
              upper: [ticker, exchangeName],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker, exchangeName, name],
              includeLower: false,
              upper: [ticker, exchangeName],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ticker_exchangeName_name',
              lower: [ticker, exchangeName],
              upper: [ticker, exchangeName, name],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause> supportsFixedRateEqualTo(
      bool supportsFixedRate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'supportsFixedRate',
        value: [supportsFixedRate],
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause>
      supportsFixedRateNotEqualTo(bool supportsFixedRate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supportsFixedRate',
              lower: [],
              upper: [supportsFixedRate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supportsFixedRate',
              lower: [supportsFixedRate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supportsFixedRate',
              lower: [supportsFixedRate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supportsFixedRate',
              lower: [],
              upper: [supportsFixedRate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause>
      supportsEstimatedRateEqualTo(bool supportsEstimatedRate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'supportsEstimatedRate',
        value: [supportsEstimatedRate],
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause>
      supportsEstimatedRateNotEqualTo(bool supportsEstimatedRate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supportsEstimatedRate',
              lower: [],
              upper: [supportsEstimatedRate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supportsEstimatedRate',
              lower: [supportsEstimatedRate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supportsEstimatedRate',
              lower: [supportsEstimatedRate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supportsEstimatedRate',
              lower: [],
              upper: [supportsEstimatedRate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause> isStackCoinEqualTo(
      bool isStackCoin) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isStackCoin',
        value: [isStackCoin],
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterWhereClause> isStackCoinNotEqualTo(
      bool isStackCoin) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isStackCoin',
              lower: [],
              upper: [isStackCoin],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isStackCoin',
              lower: [isStackCoin],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isStackCoin',
              lower: [isStackCoin],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isStackCoin',
              lower: [],
              upper: [isStackCoin],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CurrencyQueryFilter
    on QueryBuilder<Currency, Currency, QFilterCondition> {
  QueryBuilder<Currency, Currency, QAfterFilterCondition> exchangeNameEqualTo(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition>
      exchangeNameGreaterThan(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> exchangeNameLessThan(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> exchangeNameBetween(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition>
      exchangeNameStartsWith(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> exchangeNameEndsWith(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> exchangeNameContains(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> exchangeNameMatches(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition>
      exchangeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exchangeName',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition>
      exchangeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exchangeName',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'externalId',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition>
      externalIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'externalId',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'externalId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'externalId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'externalId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> externalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'externalId',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition>
      externalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'externalId',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'image',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'image',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'image',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> imageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'image',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> isAvailableIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isAvailable',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition>
      isAvailableIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isAvailable',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> isAvailableEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> isFiatEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFiat',
        value: value,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> isStackCoinEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isStackCoin',
        value: value,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'network',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'network',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'network',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> networkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'network',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition>
      supportsEstimatedRateEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supportsEstimatedRate',
        value: value,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition>
      supportsFixedRateEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supportsFixedRate',
        value: value,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerEqualTo(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerGreaterThan(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerLessThan(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerBetween(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerStartsWith(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerEndsWith(
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

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ticker',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ticker',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticker',
        value: '',
      ));
    });
  }

  QueryBuilder<Currency, Currency, QAfterFilterCondition> tickerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ticker',
        value: '',
      ));
    });
  }
}

extension CurrencyQueryObject
    on QueryBuilder<Currency, Currency, QFilterCondition> {}

extension CurrencyQueryLinks
    on QueryBuilder<Currency, Currency, QFilterCondition> {}

extension CurrencyQuerySortBy on QueryBuilder<Currency, Currency, QSortBy> {
  QueryBuilder<Currency, Currency, QAfterSortBy> sortByExchangeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeName', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByExchangeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeName', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByExternalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalId', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByExternalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalId', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByIsAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAvailable', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByIsAvailableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAvailable', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByIsFiat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFiat', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByIsFiatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFiat', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByIsStackCoin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStackCoin', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByIsStackCoinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStackCoin', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByNetwork() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'network', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByNetworkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'network', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortBySupportsEstimatedRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsEstimatedRate', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy>
      sortBySupportsEstimatedRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsEstimatedRate', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortBySupportsFixedRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsFixedRate', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortBySupportsFixedRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsFixedRate', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByTicker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> sortByTickerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.desc);
    });
  }
}

extension CurrencyQuerySortThenBy
    on QueryBuilder<Currency, Currency, QSortThenBy> {
  QueryBuilder<Currency, Currency, QAfterSortBy> thenByExchangeName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeName', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByExchangeNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exchangeName', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByExternalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalId', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByExternalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalId', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByIsAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAvailable', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByIsAvailableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAvailable', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByIsFiat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFiat', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByIsFiatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFiat', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByIsStackCoin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStackCoin', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByIsStackCoinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStackCoin', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByNetwork() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'network', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByNetworkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'network', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenBySupportsEstimatedRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsEstimatedRate', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy>
      thenBySupportsEstimatedRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsEstimatedRate', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenBySupportsFixedRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsFixedRate', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenBySupportsFixedRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supportsFixedRate', Sort.desc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByTicker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.asc);
    });
  }

  QueryBuilder<Currency, Currency, QAfterSortBy> thenByTickerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticker', Sort.desc);
    });
  }
}

extension CurrencyQueryWhereDistinct
    on QueryBuilder<Currency, Currency, QDistinct> {
  QueryBuilder<Currency, Currency, QDistinct> distinctByExchangeName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exchangeName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Currency, Currency, QDistinct> distinctByExternalId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'externalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Currency, Currency, QDistinct> distinctByImage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'image', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Currency, Currency, QDistinct> distinctByIsAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAvailable');
    });
  }

  QueryBuilder<Currency, Currency, QDistinct> distinctByIsFiat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFiat');
    });
  }

  QueryBuilder<Currency, Currency, QDistinct> distinctByIsStackCoin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isStackCoin');
    });
  }

  QueryBuilder<Currency, Currency, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Currency, Currency, QDistinct> distinctByNetwork(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'network', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Currency, Currency, QDistinct>
      distinctBySupportsEstimatedRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supportsEstimatedRate');
    });
  }

  QueryBuilder<Currency, Currency, QDistinct> distinctBySupportsFixedRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supportsFixedRate');
    });
  }

  QueryBuilder<Currency, Currency, QDistinct> distinctByTicker(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ticker', caseSensitive: caseSensitive);
    });
  }
}

extension CurrencyQueryProperty
    on QueryBuilder<Currency, Currency, QQueryProperty> {
  QueryBuilder<Currency, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Currency, String, QQueryOperations> exchangeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exchangeName');
    });
  }

  QueryBuilder<Currency, String?, QQueryOperations> externalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'externalId');
    });
  }

  QueryBuilder<Currency, String, QQueryOperations> imageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'image');
    });
  }

  QueryBuilder<Currency, bool?, QQueryOperations> isAvailableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAvailable');
    });
  }

  QueryBuilder<Currency, bool, QQueryOperations> isFiatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFiat');
    });
  }

  QueryBuilder<Currency, bool, QQueryOperations> isStackCoinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isStackCoin');
    });
  }

  QueryBuilder<Currency, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Currency, String, QQueryOperations> networkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'network');
    });
  }

  QueryBuilder<Currency, bool, QQueryOperations>
      supportsEstimatedRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supportsEstimatedRate');
    });
  }

  QueryBuilder<Currency, bool, QQueryOperations> supportsFixedRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supportsFixedRate');
    });
  }

  QueryBuilder<Currency, String, QQueryOperations> tickerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ticker');
    });
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_wallet_info.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTokenWalletInfoCollection on Isar {
  IsarCollection<TokenWalletInfo> get tokenWalletInfo => this.collection();
}

const TokenWalletInfoSchema = CollectionSchema(
  name: r'TokenWalletInfo',
  id: -2566407308847951136,
  properties: {
    r'cachedBalanceJsonString': PropertySchema(
      id: 0,
      name: r'cachedBalanceJsonString',
      type: IsarType.string,
    ),
    r'tokenAddress': PropertySchema(
      id: 1,
      name: r'tokenAddress',
      type: IsarType.string,
    ),
    r'tokenFractionDigits': PropertySchema(
      id: 2,
      name: r'tokenFractionDigits',
      type: IsarType.long,
    ),
    r'walletId': PropertySchema(
      id: 3,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _tokenWalletInfoEstimateSize,
  serialize: _tokenWalletInfoSerialize,
  deserialize: _tokenWalletInfoDeserialize,
  deserializeProp: _tokenWalletInfoDeserializeProp,
  idName: r'id',
  indexes: {
    r'walletId_tokenAddress': IndexSchema(
      id: -7747794843092592407,
      name: r'walletId_tokenAddress',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'walletId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'tokenAddress',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _tokenWalletInfoGetId,
  getLinks: _tokenWalletInfoGetLinks,
  attach: _tokenWalletInfoAttach,
  version: '3.1.8',
);

int _tokenWalletInfoEstimateSize(
  TokenWalletInfo object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cachedBalanceJsonString;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tokenAddress.length * 3;
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _tokenWalletInfoSerialize(
  TokenWalletInfo object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cachedBalanceJsonString);
  writer.writeString(offsets[1], object.tokenAddress);
  writer.writeLong(offsets[2], object.tokenFractionDigits);
  writer.writeString(offsets[3], object.walletId);
}

TokenWalletInfo _tokenWalletInfoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TokenWalletInfo(
    cachedBalanceJsonString: reader.readStringOrNull(offsets[0]),
    tokenAddress: reader.readString(offsets[1]),
    tokenFractionDigits: reader.readLong(offsets[2]),
    walletId: reader.readString(offsets[3]),
  );
  object.id = id;
  return object;
}

P _tokenWalletInfoDeserializeProp<P>(
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
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _tokenWalletInfoGetId(TokenWalletInfo object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _tokenWalletInfoGetLinks(TokenWalletInfo object) {
  return [];
}

void _tokenWalletInfoAttach(
    IsarCollection<dynamic> col, Id id, TokenWalletInfo object) {
  object.id = id;
}

extension TokenWalletInfoByIndex on IsarCollection<TokenWalletInfo> {
  Future<TokenWalletInfo?> getByWalletIdTokenAddress(
      String walletId, String tokenAddress) {
    return getByIndex(r'walletId_tokenAddress', [walletId, tokenAddress]);
  }

  TokenWalletInfo? getByWalletIdTokenAddressSync(
      String walletId, String tokenAddress) {
    return getByIndexSync(r'walletId_tokenAddress', [walletId, tokenAddress]);
  }

  Future<bool> deleteByWalletIdTokenAddress(
      String walletId, String tokenAddress) {
    return deleteByIndex(r'walletId_tokenAddress', [walletId, tokenAddress]);
  }

  bool deleteByWalletIdTokenAddressSync(String walletId, String tokenAddress) {
    return deleteByIndexSync(
        r'walletId_tokenAddress', [walletId, tokenAddress]);
  }

  Future<List<TokenWalletInfo?>> getAllByWalletIdTokenAddress(
      List<String> walletIdValues, List<String> tokenAddressValues) {
    final len = walletIdValues.length;
    assert(tokenAddressValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([walletIdValues[i], tokenAddressValues[i]]);
    }

    return getAllByIndex(r'walletId_tokenAddress', values);
  }

  List<TokenWalletInfo?> getAllByWalletIdTokenAddressSync(
      List<String> walletIdValues, List<String> tokenAddressValues) {
    final len = walletIdValues.length;
    assert(tokenAddressValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([walletIdValues[i], tokenAddressValues[i]]);
    }

    return getAllByIndexSync(r'walletId_tokenAddress', values);
  }

  Future<int> deleteAllByWalletIdTokenAddress(
      List<String> walletIdValues, List<String> tokenAddressValues) {
    final len = walletIdValues.length;
    assert(tokenAddressValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([walletIdValues[i], tokenAddressValues[i]]);
    }

    return deleteAllByIndex(r'walletId_tokenAddress', values);
  }

  int deleteAllByWalletIdTokenAddressSync(
      List<String> walletIdValues, List<String> tokenAddressValues) {
    final len = walletIdValues.length;
    assert(tokenAddressValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([walletIdValues[i], tokenAddressValues[i]]);
    }

    return deleteAllByIndexSync(r'walletId_tokenAddress', values);
  }

  Future<Id> putByWalletIdTokenAddress(TokenWalletInfo object) {
    return putByIndex(r'walletId_tokenAddress', object);
  }

  Id putByWalletIdTokenAddressSync(TokenWalletInfo object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'walletId_tokenAddress', object,
        saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByWalletIdTokenAddress(List<TokenWalletInfo> objects) {
    return putAllByIndex(r'walletId_tokenAddress', objects);
  }

  List<Id> putAllByWalletIdTokenAddressSync(List<TokenWalletInfo> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'walletId_tokenAddress', objects,
        saveLinks: saveLinks);
  }
}

extension TokenWalletInfoQueryWhereSort
    on QueryBuilder<TokenWalletInfo, TokenWalletInfo, QWhere> {
  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TokenWalletInfoQueryWhere
    on QueryBuilder<TokenWalletInfo, TokenWalletInfo, QWhereClause> {
  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhereClause>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhereClause> idBetween(
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhereClause>
      walletIdEqualToAnyTokenAddress(String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId_tokenAddress',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhereClause>
      walletIdNotEqualToAnyTokenAddress(String walletId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_tokenAddress',
              lower: [],
              upper: [walletId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_tokenAddress',
              lower: [walletId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_tokenAddress',
              lower: [walletId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_tokenAddress',
              lower: [],
              upper: [walletId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhereClause>
      walletIdTokenAddressEqualTo(String walletId, String tokenAddress) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId_tokenAddress',
        value: [walletId, tokenAddress],
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterWhereClause>
      walletIdEqualToTokenAddressNotEqualTo(
          String walletId, String tokenAddress) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_tokenAddress',
              lower: [walletId],
              upper: [walletId, tokenAddress],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_tokenAddress',
              lower: [walletId, tokenAddress],
              includeLower: false,
              upper: [walletId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_tokenAddress',
              lower: [walletId, tokenAddress],
              includeLower: false,
              upper: [walletId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'walletId_tokenAddress',
              lower: [walletId],
              upper: [walletId, tokenAddress],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TokenWalletInfoQueryFilter
    on QueryBuilder<TokenWalletInfo, TokenWalletInfo, QFilterCondition> {
  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cachedBalanceJsonString',
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cachedBalanceJsonString',
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedBalanceJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedBalanceJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedBalanceJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedBalanceJsonString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cachedBalanceJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cachedBalanceJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cachedBalanceJsonString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cachedBalanceJsonString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedBalanceJsonString',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      cachedBalanceJsonStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cachedBalanceJsonString',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokenAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tokenAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tokenAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tokenAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tokenAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tokenAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tokenAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tokenAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokenAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tokenAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenFractionDigitsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tokenFractionDigits',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenFractionDigitsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tokenFractionDigits',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenFractionDigitsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tokenFractionDigits',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      tokenFractionDigitsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tokenFractionDigits',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
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

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      walletIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      walletIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterFilterCondition>
      walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension TokenWalletInfoQueryObject
    on QueryBuilder<TokenWalletInfo, TokenWalletInfo, QFilterCondition> {}

extension TokenWalletInfoQueryLinks
    on QueryBuilder<TokenWalletInfo, TokenWalletInfo, QFilterCondition> {}

extension TokenWalletInfoQuerySortBy
    on QueryBuilder<TokenWalletInfo, TokenWalletInfo, QSortBy> {
  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      sortByCachedBalanceJsonString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceJsonString', Sort.asc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      sortByCachedBalanceJsonStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceJsonString', Sort.desc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      sortByTokenAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenAddress', Sort.asc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      sortByTokenAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenAddress', Sort.desc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      sortByTokenFractionDigits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenFractionDigits', Sort.asc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      sortByTokenFractionDigitsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenFractionDigits', Sort.desc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension TokenWalletInfoQuerySortThenBy
    on QueryBuilder<TokenWalletInfo, TokenWalletInfo, QSortThenBy> {
  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      thenByCachedBalanceJsonString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceJsonString', Sort.asc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      thenByCachedBalanceJsonStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedBalanceJsonString', Sort.desc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      thenByTokenAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenAddress', Sort.asc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      thenByTokenAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenAddress', Sort.desc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      thenByTokenFractionDigits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenFractionDigits', Sort.asc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      thenByTokenFractionDigitsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenFractionDigits', Sort.desc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QAfterSortBy>
      thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension TokenWalletInfoQueryWhereDistinct
    on QueryBuilder<TokenWalletInfo, TokenWalletInfo, QDistinct> {
  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QDistinct>
      distinctByCachedBalanceJsonString({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedBalanceJsonString',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QDistinct>
      distinctByTokenAddress({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tokenAddress', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QDistinct>
      distinctByTokenFractionDigits() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tokenFractionDigits');
    });
  }

  QueryBuilder<TokenWalletInfo, TokenWalletInfo, QDistinct> distinctByWalletId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension TokenWalletInfoQueryProperty
    on QueryBuilder<TokenWalletInfo, TokenWalletInfo, QQueryProperty> {
  QueryBuilder<TokenWalletInfo, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TokenWalletInfo, String?, QQueryOperations>
      cachedBalanceJsonStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedBalanceJsonString');
    });
  }

  QueryBuilder<TokenWalletInfo, String, QQueryOperations>
      tokenAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tokenAddress');
    });
  }

  QueryBuilder<TokenWalletInfo, int, QQueryOperations>
      tokenFractionDigitsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tokenFractionDigits');
    });
  }

  QueryBuilder<TokenWalletInfo, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetOutputCollection on Isar {
  IsarCollection<Output> get outputs => this.collection();
}

const OutputSchema = CollectionSchema(
  name: r'Output',
  id: 3359341097909611106,
  properties: {
    r'scriptPubKey': PropertySchema(
      id: 0,
      name: r'scriptPubKey',
      type: IsarType.string,
    ),
    r'scriptPubKeyAddress': PropertySchema(
      id: 1,
      name: r'scriptPubKeyAddress',
      type: IsarType.string,
    ),
    r'scriptPubKeyAsm': PropertySchema(
      id: 2,
      name: r'scriptPubKeyAsm',
      type: IsarType.string,
    ),
    r'scriptPubKeyType': PropertySchema(
      id: 3,
      name: r'scriptPubKeyType',
      type: IsarType.string,
    ),
    r'value': PropertySchema(
      id: 4,
      name: r'value',
      type: IsarType.long,
    ),
    r'walletId': PropertySchema(
      id: 5,
      name: r'walletId',
      type: IsarType.string,
    )
  },
  estimateSize: _outputEstimateSize,
  serialize: _outputSerialize,
  deserialize: _outputDeserialize,
  deserializeProp: _outputDeserializeProp,
  idName: r'id',
  indexes: {
    r'walletId': IndexSchema(
      id: -1783113319798776304,
      name: r'walletId',
      unique: false,
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
  links: {
    r'transaction': LinkSchema(
      id: -2089310750171432135,
      name: r'transaction',
      target: r'Transaction',
      single: true,
      linkName: r'outputs',
    )
  },
  embeddedSchemas: {},
  getId: _outputGetId,
  getLinks: _outputGetLinks,
  attach: _outputAttach,
  version: '3.0.5',
);

int _outputEstimateSize(
  Output object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.scriptPubKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.scriptPubKeyAddress.length * 3;
  {
    final value = object.scriptPubKeyAsm;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.scriptPubKeyType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.walletId.length * 3;
  return bytesCount;
}

void _outputSerialize(
  Output object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.scriptPubKey);
  writer.writeString(offsets[1], object.scriptPubKeyAddress);
  writer.writeString(offsets[2], object.scriptPubKeyAsm);
  writer.writeString(offsets[3], object.scriptPubKeyType);
  writer.writeLong(offsets[4], object.value);
  writer.writeString(offsets[5], object.walletId);
}

Output _outputDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Output();
  object.id = id;
  object.scriptPubKey = reader.readStringOrNull(offsets[0]);
  object.scriptPubKeyAddress = reader.readString(offsets[1]);
  object.scriptPubKeyAsm = reader.readStringOrNull(offsets[2]);
  object.scriptPubKeyType = reader.readStringOrNull(offsets[3]);
  object.value = reader.readLong(offsets[4]);
  object.walletId = reader.readString(offsets[5]);
  return object;
}

P _outputDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _outputGetId(Output object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _outputGetLinks(Output object) {
  return [object.transaction];
}

void _outputAttach(IsarCollection<dynamic> col, Id id, Output object) {
  object.id = id;
  object.transaction
      .attach(col, col.isar.collection<Transaction>(), r'transaction', id);
}

extension OutputQueryWhereSort on QueryBuilder<Output, Output, QWhere> {
  QueryBuilder<Output, Output, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OutputQueryWhere on QueryBuilder<Output, Output, QWhereClause> {
  QueryBuilder<Output, Output, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Output, Output, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Output, Output, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Output, Output, QAfterWhereClause> idBetween(
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

  QueryBuilder<Output, Output, QAfterWhereClause> walletIdEqualTo(
      String walletId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'walletId',
        value: [walletId],
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterWhereClause> walletIdNotEqualTo(
      String walletId) {
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

extension OutputQueryFilter on QueryBuilder<Output, Output, QFilterCondition> {
  QueryBuilder<Output, Output, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Output, Output, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Output, Output, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scriptPubKey',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scriptPubKey',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scriptPubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scriptPubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scriptPubKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scriptPubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scriptPubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scriptPubKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scriptPubKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKey',
        value: '',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scriptPubKey',
        value: '',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKeyAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scriptPubKeyAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scriptPubKeyAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scriptPubKeyAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scriptPubKeyAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scriptPubKeyAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scriptPubKeyAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scriptPubKeyAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKeyAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scriptPubKeyAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyAsmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scriptPubKeyAsm',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAsmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scriptPubKeyAsm',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyAsmEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKeyAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAsmGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scriptPubKeyAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyAsmLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scriptPubKeyAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyAsmBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scriptPubKeyAsm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyAsmStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scriptPubKeyAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyAsmEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scriptPubKeyAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyAsmContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scriptPubKeyAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyAsmMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scriptPubKeyAsm',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyAsmIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKeyAsm',
        value: '',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyAsmIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scriptPubKeyAsm',
        value: '',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scriptPubKeyType',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scriptPubKeyType',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKeyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scriptPubKeyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scriptPubKeyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scriptPubKeyType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scriptPubKeyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scriptPubKeyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyTypeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scriptPubKeyType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> scriptPubKeyTypeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scriptPubKeyType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKeyType',
        value: '',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition>
      scriptPubKeyTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scriptPubKeyType',
        value: '',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> valueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: value,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> valueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'value',
        value: value,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> valueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'value',
        value: value,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> valueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'value',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdEqualTo(
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

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdGreaterThan(
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

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdLessThan(
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

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdBetween(
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

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdStartsWith(
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

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdEndsWith(
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

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'walletId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'walletId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletId',
        value: '',
      ));
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> walletIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'walletId',
        value: '',
      ));
    });
  }
}

extension OutputQueryObject on QueryBuilder<Output, Output, QFilterCondition> {}

extension OutputQueryLinks on QueryBuilder<Output, Output, QFilterCondition> {
  QueryBuilder<Output, Output, QAfterFilterCondition> transaction(
      FilterQuery<Transaction> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'transaction');
    });
  }

  QueryBuilder<Output, Output, QAfterFilterCondition> transactionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'transaction', 0, true, 0, true);
    });
  }
}

extension OutputQuerySortBy on QueryBuilder<Output, Output, QSortBy> {
  QueryBuilder<Output, Output, QAfterSortBy> sortByScriptPubKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKey', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByScriptPubKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKey', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByScriptPubKeyAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyAddress', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByScriptPubKeyAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyAddress', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByScriptPubKeyAsm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyAsm', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByScriptPubKeyAsmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyAsm', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByScriptPubKeyType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyType', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByScriptPubKeyTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyType', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> sortByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension OutputQuerySortThenBy on QueryBuilder<Output, Output, QSortThenBy> {
  QueryBuilder<Output, Output, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByScriptPubKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKey', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByScriptPubKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKey', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByScriptPubKeyAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyAddress', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByScriptPubKeyAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyAddress', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByScriptPubKeyAsm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyAsm', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByScriptPubKeyAsmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyAsm', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByScriptPubKeyType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyType', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByScriptPubKeyTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptPubKeyType', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByWalletId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.asc);
    });
  }

  QueryBuilder<Output, Output, QAfterSortBy> thenByWalletIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletId', Sort.desc);
    });
  }
}

extension OutputQueryWhereDistinct on QueryBuilder<Output, Output, QDistinct> {
  QueryBuilder<Output, Output, QDistinct> distinctByScriptPubKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scriptPubKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Output, Output, QDistinct> distinctByScriptPubKeyAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scriptPubKeyAddress',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Output, Output, QDistinct> distinctByScriptPubKeyAsm(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scriptPubKeyAsm',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Output, Output, QDistinct> distinctByScriptPubKeyType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scriptPubKeyType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Output, Output, QDistinct> distinctByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value');
    });
  }

  QueryBuilder<Output, Output, QDistinct> distinctByWalletId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walletId', caseSensitive: caseSensitive);
    });
  }
}

extension OutputQueryProperty on QueryBuilder<Output, Output, QQueryProperty> {
  QueryBuilder<Output, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Output, String?, QQueryOperations> scriptPubKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scriptPubKey');
    });
  }

  QueryBuilder<Output, String, QQueryOperations> scriptPubKeyAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scriptPubKeyAddress');
    });
  }

  QueryBuilder<Output, String?, QQueryOperations> scriptPubKeyAsmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scriptPubKeyAsm');
    });
  }

  QueryBuilder<Output, String?, QQueryOperations> scriptPubKeyTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scriptPubKeyType');
    });
  }

  QueryBuilder<Output, int, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }

  QueryBuilder<Output, String, QQueryOperations> walletIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletId');
    });
  }
}

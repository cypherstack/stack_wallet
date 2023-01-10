// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetInputCollection on Isar {
  IsarCollection<Input> get inputs => this.collection();
}

const InputSchema = CollectionSchema(
  name: r'Input',
  id: 1962449150546623042,
  properties: {
    r'innerRedeemScriptAsm': PropertySchema(
      id: 0,
      name: r'innerRedeemScriptAsm',
      type: IsarType.string,
    ),
    r'isCoinbase': PropertySchema(
      id: 1,
      name: r'isCoinbase',
      type: IsarType.bool,
    ),
    r'scriptSig': PropertySchema(
      id: 2,
      name: r'scriptSig',
      type: IsarType.string,
    ),
    r'scriptSigAsm': PropertySchema(
      id: 3,
      name: r'scriptSigAsm',
      type: IsarType.string,
    ),
    r'sequence': PropertySchema(
      id: 4,
      name: r'sequence',
      type: IsarType.long,
    ),
    r'txid': PropertySchema(
      id: 5,
      name: r'txid',
      type: IsarType.string,
    ),
    r'vout': PropertySchema(
      id: 6,
      name: r'vout',
      type: IsarType.long,
    )
  },
  estimateSize: _inputEstimateSize,
  serialize: _inputSerialize,
  deserialize: _inputDeserialize,
  deserializeProp: _inputDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'prevOut': LinkSchema(
      id: 2963704715567457192,
      name: r'prevOut',
      target: r'Output',
      single: true,
    ),
    r'transaction': LinkSchema(
      id: -7488914266019463608,
      name: r'transaction',
      target: r'Transaction',
      single: true,
      linkName: r'inputs',
    )
  },
  embeddedSchemas: {},
  getId: _inputGetId,
  getLinks: _inputGetLinks,
  attach: _inputAttach,
  version: '3.0.5',
);

int _inputEstimateSize(
  Input object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.innerRedeemScriptAsm;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.scriptSig;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.scriptSigAsm;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.txid.length * 3;
  return bytesCount;
}

void _inputSerialize(
  Input object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.innerRedeemScriptAsm);
  writer.writeBool(offsets[1], object.isCoinbase);
  writer.writeString(offsets[2], object.scriptSig);
  writer.writeString(offsets[3], object.scriptSigAsm);
  writer.writeLong(offsets[4], object.sequence);
  writer.writeString(offsets[5], object.txid);
  writer.writeLong(offsets[6], object.vout);
}

Input _inputDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Input();
  object.id = id;
  object.innerRedeemScriptAsm = reader.readStringOrNull(offsets[0]);
  object.isCoinbase = reader.readBoolOrNull(offsets[1]);
  object.scriptSig = reader.readStringOrNull(offsets[2]);
  object.scriptSigAsm = reader.readStringOrNull(offsets[3]);
  object.sequence = reader.readLongOrNull(offsets[4]);
  object.txid = reader.readString(offsets[5]);
  object.vout = reader.readLong(offsets[6]);
  return object;
}

P _inputDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _inputGetId(Input object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _inputGetLinks(Input object) {
  return [object.prevOut, object.transaction];
}

void _inputAttach(IsarCollection<dynamic> col, Id id, Input object) {
  object.id = id;
  object.prevOut.attach(col, col.isar.collection<Output>(), r'prevOut', id);
  object.transaction
      .attach(col, col.isar.collection<Transaction>(), r'transaction', id);
}

extension InputQueryWhereSort on QueryBuilder<Input, Input, QWhere> {
  QueryBuilder<Input, Input, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension InputQueryWhere on QueryBuilder<Input, Input, QWhereClause> {
  QueryBuilder<Input, Input, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Input, Input, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Input, Input, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Input, Input, QAfterWhereClause> idBetween(
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

extension InputQueryFilter on QueryBuilder<Input, Input, QFilterCondition> {
  QueryBuilder<Input, Input, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Input, Input, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Input, Input, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Input, Input, QAfterFilterCondition>
      innerRedeemScriptAsmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'innerRedeemScriptAsm',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition>
      innerRedeemScriptAsmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'innerRedeemScriptAsm',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> innerRedeemScriptAsmEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'innerRedeemScriptAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition>
      innerRedeemScriptAsmGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'innerRedeemScriptAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition>
      innerRedeemScriptAsmLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'innerRedeemScriptAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> innerRedeemScriptAsmBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'innerRedeemScriptAsm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition>
      innerRedeemScriptAsmStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'innerRedeemScriptAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition>
      innerRedeemScriptAsmEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'innerRedeemScriptAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition>
      innerRedeemScriptAsmContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'innerRedeemScriptAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> innerRedeemScriptAsmMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'innerRedeemScriptAsm',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition>
      innerRedeemScriptAsmIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'innerRedeemScriptAsm',
        value: '',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition>
      innerRedeemScriptAsmIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'innerRedeemScriptAsm',
        value: '',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> isCoinbaseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isCoinbase',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> isCoinbaseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isCoinbase',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> isCoinbaseEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCoinbase',
        value: value,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scriptSig',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scriptSig',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptSig',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scriptSig',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scriptSig',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scriptSig',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scriptSig',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scriptSig',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scriptSig',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scriptSig',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptSig',
        value: '',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scriptSig',
        value: '',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scriptSigAsm',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scriptSigAsm',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptSigAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scriptSigAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scriptSigAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scriptSigAsm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scriptSigAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scriptSigAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scriptSigAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scriptSigAsm',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptSigAsm',
        value: '',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> scriptSigAsmIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scriptSigAsm',
        value: '',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> sequenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sequence',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> sequenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sequence',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> sequenceEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sequence',
        value: value,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> sequenceGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sequence',
        value: value,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> sequenceLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sequence',
        value: value,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> sequenceBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sequence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> txidEqualTo(
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

  QueryBuilder<Input, Input, QAfterFilterCondition> txidGreaterThan(
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

  QueryBuilder<Input, Input, QAfterFilterCondition> txidLessThan(
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

  QueryBuilder<Input, Input, QAfterFilterCondition> txidBetween(
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

  QueryBuilder<Input, Input, QAfterFilterCondition> txidStartsWith(
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

  QueryBuilder<Input, Input, QAfterFilterCondition> txidEndsWith(
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

  QueryBuilder<Input, Input, QAfterFilterCondition> txidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'txid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> txidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'txid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> txidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> txidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'txid',
        value: '',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> voutEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vout',
        value: value,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> voutGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vout',
        value: value,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> voutLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vout',
        value: value,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> voutBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vout',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension InputQueryObject on QueryBuilder<Input, Input, QFilterCondition> {}

extension InputQueryLinks on QueryBuilder<Input, Input, QFilterCondition> {
  QueryBuilder<Input, Input, QAfterFilterCondition> prevOut(
      FilterQuery<Output> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'prevOut');
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> prevOutIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'prevOut', 0, true, 0, true);
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> transaction(
      FilterQuery<Transaction> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'transaction');
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> transactionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'transaction', 0, true, 0, true);
    });
  }
}

extension InputQuerySortBy on QueryBuilder<Input, Input, QSortBy> {
  QueryBuilder<Input, Input, QAfterSortBy> sortByInnerRedeemScriptAsm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'innerRedeemScriptAsm', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByInnerRedeemScriptAsmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'innerRedeemScriptAsm', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByIsCoinbase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCoinbase', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByIsCoinbaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCoinbase', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByScriptSig() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptSig', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByScriptSigDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptSig', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByScriptSigAsm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptSigAsm', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByScriptSigAsmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptSigAsm', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortBySequenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByVout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> sortByVoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.desc);
    });
  }
}

extension InputQuerySortThenBy on QueryBuilder<Input, Input, QSortThenBy> {
  QueryBuilder<Input, Input, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByInnerRedeemScriptAsm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'innerRedeemScriptAsm', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByInnerRedeemScriptAsmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'innerRedeemScriptAsm', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByIsCoinbase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCoinbase', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByIsCoinbaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCoinbase', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByScriptSig() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptSig', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByScriptSigDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptSig', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByScriptSigAsm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptSigAsm', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByScriptSigAsmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scriptSigAsm', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenBySequenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByTxid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByTxidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'txid', Sort.desc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByVout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.asc);
    });
  }

  QueryBuilder<Input, Input, QAfterSortBy> thenByVoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vout', Sort.desc);
    });
  }
}

extension InputQueryWhereDistinct on QueryBuilder<Input, Input, QDistinct> {
  QueryBuilder<Input, Input, QDistinct> distinctByInnerRedeemScriptAsm(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'innerRedeemScriptAsm',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Input, Input, QDistinct> distinctByIsCoinbase() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCoinbase');
    });
  }

  QueryBuilder<Input, Input, QDistinct> distinctByScriptSig(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scriptSig', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Input, Input, QDistinct> distinctByScriptSigAsm(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scriptSigAsm', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Input, Input, QDistinct> distinctBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sequence');
    });
  }

  QueryBuilder<Input, Input, QDistinct> distinctByTxid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'txid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Input, Input, QDistinct> distinctByVout() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vout');
    });
  }
}

extension InputQueryProperty on QueryBuilder<Input, Input, QQueryProperty> {
  QueryBuilder<Input, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Input, String?, QQueryOperations>
      innerRedeemScriptAsmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'innerRedeemScriptAsm');
    });
  }

  QueryBuilder<Input, bool?, QQueryOperations> isCoinbaseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCoinbase');
    });
  }

  QueryBuilder<Input, String?, QQueryOperations> scriptSigProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scriptSig');
    });
  }

  QueryBuilder<Input, String?, QQueryOperations> scriptSigAsmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scriptSigAsm');
    });
  }

  QueryBuilder<Input, int?, QQueryOperations> sequenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sequence');
    });
  }

  QueryBuilder<Input, String, QQueryOperations> txidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'txid');
    });
  }

  QueryBuilder<Input, int, QQueryOperations> voutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vout');
    });
  }
}

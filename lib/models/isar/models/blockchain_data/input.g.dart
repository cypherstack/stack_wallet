// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

const InputSchema = Schema(
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
    ),
    r'witness': PropertySchema(
      id: 7,
      name: r'witness',
      type: IsarType.string,
    )
  },
  estimateSize: _inputEstimateSize,
  serialize: _inputSerialize,
  deserialize: _inputDeserialize,
  deserializeProp: _inputDeserializeProp,
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
  {
    final value = object.witness;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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
  writer.writeString(offsets[7], object.witness);
}

Input _inputDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Input(
    innerRedeemScriptAsm: reader.readStringOrNull(offsets[0]),
    isCoinbase: reader.readBoolOrNull(offsets[1]),
    scriptSig: reader.readStringOrNull(offsets[2]),
    scriptSigAsm: reader.readStringOrNull(offsets[3]),
    sequence: reader.readLongOrNull(offsets[4]),
    txid: reader.readStringOrNull(offsets[5]) ?? "error",
    vout: reader.readLongOrNull(offsets[6]) ?? -1,
  );
  object.witness = reader.readStringOrNull(offsets[7]);
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
      return (reader.readStringOrNull(offset) ?? "error") as P;
    case 6:
      return (reader.readLongOrNull(offset) ?? -1) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension InputQueryFilter on QueryBuilder<Input, Input, QFilterCondition> {
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

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'witness',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'witness',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'witness',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'witness',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'witness',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'witness',
        value: '',
      ));
    });
  }

  QueryBuilder<Input, Input, QAfterFilterCondition> witnessIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'witness',
        value: '',
      ));
    });
  }
}

extension InputQueryObject on QueryBuilder<Input, Input, QFilterCondition> {}

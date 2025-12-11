// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_v2.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const OutpointV2Schema = Schema(
  name: r'OutpointV2',
  id: 5327663686922028778,
  properties: {
    r'hashCode': PropertySchema(id: 0, name: r'hashCode', type: IsarType.long),
    r'txid': PropertySchema(id: 1, name: r'txid', type: IsarType.string),
    r'vout': PropertySchema(id: 2, name: r'vout', type: IsarType.long),
  },

  estimateSize: _outpointV2EstimateSize,
  serialize: _outpointV2Serialize,
  deserialize: _outpointV2Deserialize,
  deserializeProp: _outpointV2DeserializeProp,
);

int _outpointV2EstimateSize(
  OutpointV2 object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.txid.length * 3;
  return bytesCount;
}

void _outpointV2Serialize(
  OutpointV2 object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.hashCode);
  writer.writeString(offsets[1], object.txid);
  writer.writeLong(offsets[2], object.vout);
}

OutpointV2 _outpointV2Deserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OutpointV2();
  object.txid = reader.readString(offsets[1]);
  object.vout = reader.readLong(offsets[2]);
  return object;
}

P _outpointV2DeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension OutpointV2QueryFilter
    on QueryBuilder<OutpointV2, OutpointV2, QFilterCondition> {
  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> hashCodeEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hashCode', value: value),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition>
  hashCodeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'hashCode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'hashCode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'hashCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'txid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'txid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'txid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'txid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'txid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'txid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'txid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'txid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'txid', value: ''),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> txidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'txid', value: ''),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> voutEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'vout', value: value),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> voutGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'vout',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> voutLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'vout',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutpointV2, OutpointV2, QAfterFilterCondition> voutBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'vout',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension OutpointV2QueryObject
    on QueryBuilder<OutpointV2, OutpointV2, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const InputV2Schema = Schema(
  name: r'InputV2',
  id: 1518255311272544045,
  properties: {
    r'addresses': PropertySchema(
      id: 0,
      name: r'addresses',
      type: IsarType.stringList,
    ),
    r'coinbase': PropertySchema(
      id: 1,
      name: r'coinbase',
      type: IsarType.string,
    ),
    r'innerRedeemScriptAsm': PropertySchema(
      id: 2,
      name: r'innerRedeemScriptAsm',
      type: IsarType.string,
    ),
    r'outpoint': PropertySchema(
      id: 3,
      name: r'outpoint',
      type: IsarType.object,

      target: r'OutpointV2',
    ),
    r'scriptSigAsm': PropertySchema(
      id: 4,
      name: r'scriptSigAsm',
      type: IsarType.string,
    ),
    r'scriptSigHex': PropertySchema(
      id: 5,
      name: r'scriptSigHex',
      type: IsarType.string,
    ),
    r'sequence': PropertySchema(id: 6, name: r'sequence', type: IsarType.long),
    r'valueStringSats': PropertySchema(
      id: 7,
      name: r'valueStringSats',
      type: IsarType.string,
    ),
    r'walletOwns': PropertySchema(
      id: 8,
      name: r'walletOwns',
      type: IsarType.bool,
    ),
    r'witness': PropertySchema(id: 9, name: r'witness', type: IsarType.string),
  },

  estimateSize: _inputV2EstimateSize,
  serialize: _inputV2Serialize,
  deserialize: _inputV2Deserialize,
  deserializeProp: _inputV2DeserializeProp,
);

int _inputV2EstimateSize(
  InputV2 object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.addresses.length * 3;
  {
    for (var i = 0; i < object.addresses.length; i++) {
      final value = object.addresses[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.coinbase;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.innerRedeemScriptAsm;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.outpoint;
    if (value != null) {
      bytesCount +=
          3 +
          OutpointV2Schema.estimateSize(
            value,
            allOffsets[OutpointV2]!,
            allOffsets,
          );
    }
  }
  {
    final value = object.scriptSigAsm;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.scriptSigHex;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.valueStringSats.length * 3;
  {
    final value = object.witness;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _inputV2Serialize(
  InputV2 object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.addresses);
  writer.writeString(offsets[1], object.coinbase);
  writer.writeString(offsets[2], object.innerRedeemScriptAsm);
  writer.writeObject<OutpointV2>(
    offsets[3],
    allOffsets,
    OutpointV2Schema.serialize,
    object.outpoint,
  );
  writer.writeString(offsets[4], object.scriptSigAsm);
  writer.writeString(offsets[5], object.scriptSigHex);
  writer.writeLong(offsets[6], object.sequence);
  writer.writeString(offsets[7], object.valueStringSats);
  writer.writeBool(offsets[8], object.walletOwns);
  writer.writeString(offsets[9], object.witness);
}

InputV2 _inputV2Deserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = InputV2();
  object.addresses = reader.readStringList(offsets[0]) ?? [];
  object.coinbase = reader.readStringOrNull(offsets[1]);
  object.innerRedeemScriptAsm = reader.readStringOrNull(offsets[2]);
  object.outpoint = reader.readObjectOrNull<OutpointV2>(
    offsets[3],
    OutpointV2Schema.deserialize,
    allOffsets,
  );
  object.scriptSigAsm = reader.readStringOrNull(offsets[4]);
  object.scriptSigHex = reader.readStringOrNull(offsets[5]);
  object.sequence = reader.readLongOrNull(offsets[6]);
  object.valueStringSats = reader.readString(offsets[7]);
  object.walletOwns = reader.readBool(offsets[8]);
  object.witness = reader.readStringOrNull(offsets[9]);
  return object;
}

P _inputV2DeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readObjectOrNull<OutpointV2>(
            offset,
            OutpointV2Schema.deserialize,
            allOffsets,
          ))
          as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension InputV2QueryFilter
    on QueryBuilder<InputV2, InputV2, QFilterCondition> {
  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> addressesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'addresses',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  addressesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'addresses',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  addressesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'addresses',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> addressesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'addresses',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  addressesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'addresses',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  addressesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'addresses',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  addressesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'addresses',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> addressesElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'addresses',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  addressesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'addresses', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  addressesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'addresses', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> addressesLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'addresses', length, true, length, true);
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> addressesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'addresses', 0, true, 0, true);
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> addressesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'addresses', 0, false, 999999, true);
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> addressesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'addresses', 0, true, length, include);
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  addressesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'addresses', length, include, 999999, true);
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> addressesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addresses',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'coinbase'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'coinbase'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'coinbase',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'coinbase',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'coinbase',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'coinbase',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'coinbase',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'coinbase',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'coinbase',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'coinbase',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'coinbase', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> coinbaseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'coinbase', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'innerRedeemScriptAsm'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'innerRedeemScriptAsm'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'innerRedeemScriptAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'innerRedeemScriptAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'innerRedeemScriptAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'innerRedeemScriptAsm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'innerRedeemScriptAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'innerRedeemScriptAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'innerRedeemScriptAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'innerRedeemScriptAsm',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'innerRedeemScriptAsm', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  innerRedeemScriptAsmIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'innerRedeemScriptAsm',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> outpointIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'outpoint'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> outpointIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'outpoint'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'scriptSigAsm'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  scriptSigAsmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'scriptSigAsm'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'scriptSigAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scriptSigAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scriptSigAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scriptSigAsm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'scriptSigAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'scriptSigAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'scriptSigAsm',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'scriptSigAsm',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigAsmIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scriptSigAsm', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  scriptSigAsmIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'scriptSigAsm', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'scriptSigHex'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  scriptSigHexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'scriptSigHex'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'scriptSigHex',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'scriptSigHex',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'scriptSigHex',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'scriptSigHex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'scriptSigHex',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'scriptSigHex',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'scriptSigHex',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'scriptSigHex',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> scriptSigHexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'scriptSigHex', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  scriptSigHexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'scriptSigHex', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> sequenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sequence'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> sequenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sequence'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> sequenceEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sequence', value: value),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> sequenceGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sequence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> sequenceLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sequence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> sequenceBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sequence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> valueStringSatsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'valueStringSats',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  valueStringSatsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'valueStringSats',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> valueStringSatsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'valueStringSats',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> valueStringSatsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'valueStringSats',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  valueStringSatsStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'valueStringSats',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> valueStringSatsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'valueStringSats',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> valueStringSatsContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'valueStringSats',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> valueStringSatsMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'valueStringSats',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  valueStringSatsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'valueStringSats', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition>
  valueStringSatsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'valueStringSats', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> walletOwnsEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'walletOwns', value: value),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'witness'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'witness'),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'witness',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'witness',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'witness',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'witness',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'witness',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'witness',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'witness',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'witness',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'witness', value: ''),
      );
    });
  }

  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> witnessIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'witness', value: ''),
      );
    });
  }
}

extension InputV2QueryObject
    on QueryBuilder<InputV2, InputV2, QFilterCondition> {
  QueryBuilder<InputV2, InputV2, QAfterFilterCondition> outpoint(
    FilterQuery<OutpointV2> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'outpoint');
    });
  }
}

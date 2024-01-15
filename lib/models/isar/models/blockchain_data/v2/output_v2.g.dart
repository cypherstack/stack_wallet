// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output_v2.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

const OutputV2Schema = Schema(
  name: r'OutputV2',
  id: -6134367361914065515,
  properties: {
    r'addresses': PropertySchema(
      id: 0,
      name: r'addresses',
      type: IsarType.stringList,
    ),
    r'scriptPubKeyAsm': PropertySchema(
      id: 1,
      name: r'scriptPubKeyAsm',
      type: IsarType.string,
    ),
    r'scriptPubKeyHex': PropertySchema(
      id: 2,
      name: r'scriptPubKeyHex',
      type: IsarType.string,
    ),
    r'valueStringSats': PropertySchema(
      id: 3,
      name: r'valueStringSats',
      type: IsarType.string,
    ),
    r'walletOwns': PropertySchema(
      id: 4,
      name: r'walletOwns',
      type: IsarType.bool,
    )
  },
  estimateSize: _outputV2EstimateSize,
  serialize: _outputV2Serialize,
  deserialize: _outputV2Deserialize,
  deserializeProp: _outputV2DeserializeProp,
);

int _outputV2EstimateSize(
  OutputV2 object,
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
    final value = object.scriptPubKeyAsm;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.scriptPubKeyHex.length * 3;
  bytesCount += 3 + object.valueStringSats.length * 3;
  return bytesCount;
}

void _outputV2Serialize(
  OutputV2 object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.addresses);
  writer.writeString(offsets[1], object.scriptPubKeyAsm);
  writer.writeString(offsets[2], object.scriptPubKeyHex);
  writer.writeString(offsets[3], object.valueStringSats);
  writer.writeBool(offsets[4], object.walletOwns);
}

OutputV2 _outputV2Deserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OutputV2();
  object.addresses = reader.readStringList(offsets[0]) ?? [];
  object.scriptPubKeyAsm = reader.readStringOrNull(offsets[1]);
  object.scriptPubKeyHex = reader.readString(offsets[2]);
  object.valueStringSats = reader.readString(offsets[3]);
  object.walletOwns = reader.readBool(offsets[4]);
  return object;
}

P _outputV2DeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension OutputV2QueryFilter
    on QueryBuilder<OutputV2, OutputV2, QFilterCondition> {
  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'addresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'addresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'addresses',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'addresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'addresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'addresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'addresses',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'addresses',
        value: '',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'addresses',
        value: '',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addresses',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition> addressesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addresses',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addresses',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addresses',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addresses',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      addressesLengthBetween(
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

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scriptPubKeyAsm',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scriptPubKeyAsm',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmEqualTo(
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

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
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

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmLessThan(
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

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmBetween(
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

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmStartsWith(
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

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmEndsWith(
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

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scriptPubKeyAsm',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scriptPubKeyAsm',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKeyAsm',
        value: '',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyAsmIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scriptPubKeyAsm',
        value: '',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKeyHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scriptPubKeyHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scriptPubKeyHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scriptPubKeyHex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'scriptPubKeyHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'scriptPubKeyHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'scriptPubKeyHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'scriptPubKeyHex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scriptPubKeyHex',
        value: '',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      scriptPubKeyHexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'scriptPubKeyHex',
        value: '',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueStringSats',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'valueStringSats',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'valueStringSats',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'valueStringSats',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'valueStringSats',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'valueStringSats',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'valueStringSats',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'valueStringSats',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueStringSats',
        value: '',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition>
      valueStringSatsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'valueStringSats',
        value: '',
      ));
    });
  }

  QueryBuilder<OutputV2, OutputV2, QAfterFilterCondition> walletOwnsEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walletOwns',
        value: value,
      ));
    });
  }
}

extension OutputV2QueryObject
    on QueryBuilder<OutputV2, OutputV2, QFilterCondition> {}

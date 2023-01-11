// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetAddressCollection on Isar {
  IsarCollection<Address> get address => this.collection();
}

const AddressSchema = CollectionSchema(
  name: r'Address',
  id: 3544600503126319553,
  properties: {
    r'derivationIndex': PropertySchema(
      id: 0,
      name: r'derivationIndex',
      type: IsarType.long,
    ),
    r'publicKey': PropertySchema(
      id: 1,
      name: r'publicKey',
      type: IsarType.byteList,
    ),
    r'subType': PropertySchema(
      id: 2,
      name: r'subType',
      type: IsarType.byte,
      enumMap: _AddresssubTypeEnumValueMap,
    ),
    r'type': PropertySchema(
      id: 3,
      name: r'type',
      type: IsarType.byte,
      enumMap: _AddresstypeEnumValueMap,
    ),
    r'value': PropertySchema(
      id: 4,
      name: r'value',
      type: IsarType.string,
    )
  },
  estimateSize: _addressEstimateSize,
  serialize: _addressSerialize,
  deserialize: _addressDeserialize,
  deserializeProp: _addressDeserializeProp,
  idName: r'id',
  indexes: {
    r'value': IndexSchema(
      id: -8658876004265234192,
      name: r'value',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'value',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'derivationIndex': IndexSchema(
      id: -6950711977521998012,
      name: r'derivationIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'derivationIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _addressGetId,
  getLinks: _addressGetLinks,
  attach: _addressAttach,
  version: '3.0.5',
);

int _addressEstimateSize(
  Address object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.publicKey.length;
  bytesCount += 3 + object.value.length * 3;
  return bytesCount;
}

void _addressSerialize(
  Address object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.derivationIndex);
  writer.writeByteList(offsets[1], object.publicKey);
  writer.writeByte(offsets[2], object.subType.index);
  writer.writeByte(offsets[3], object.type.index);
  writer.writeString(offsets[4], object.value);
}

Address _addressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Address();
  object.derivationIndex = reader.readLong(offsets[0]);
  object.id = id;
  object.publicKey = reader.readByteList(offsets[1]) ?? [];
  object.subType =
      _AddresssubTypeValueEnumMap[reader.readByteOrNull(offsets[2])] ??
          AddressSubType.receiving;
  object.type = _AddresstypeValueEnumMap[reader.readByteOrNull(offsets[3])] ??
      AddressType.p2pkh;
  object.value = reader.readString(offsets[4]);
  return object;
}

P _addressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readByteList(offset) ?? []) as P;
    case 2:
      return (_AddresssubTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          AddressSubType.receiving) as P;
    case 3:
      return (_AddresstypeValueEnumMap[reader.readByteOrNull(offset)] ??
          AddressType.p2pkh) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AddresssubTypeEnumValueMap = {
  'receiving': 0,
  'change': 1,
  'paynymNotification': 2,
  'paynymSend': 3,
  'paynymReceive': 4,
};
const _AddresssubTypeValueEnumMap = {
  0: AddressSubType.receiving,
  1: AddressSubType.change,
  2: AddressSubType.paynymNotification,
  3: AddressSubType.paynymSend,
  4: AddressSubType.paynymReceive,
};
const _AddresstypeEnumValueMap = {
  'p2pkh': 0,
  'p2sh': 1,
  'p2wpkh': 2,
};
const _AddresstypeValueEnumMap = {
  0: AddressType.p2pkh,
  1: AddressType.p2sh,
  2: AddressType.p2wpkh,
};

Id _addressGetId(Address object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _addressGetLinks(Address object) {
  return [];
}

void _addressAttach(IsarCollection<dynamic> col, Id id, Address object) {
  object.id = id;
}

extension AddressByIndex on IsarCollection<Address> {
  Future<Address?> getByValue(String value) {
    return getByIndex(r'value', [value]);
  }

  Address? getByValueSync(String value) {
    return getByIndexSync(r'value', [value]);
  }

  Future<bool> deleteByValue(String value) {
    return deleteByIndex(r'value', [value]);
  }

  bool deleteByValueSync(String value) {
    return deleteByIndexSync(r'value', [value]);
  }

  Future<List<Address?>> getAllByValue(List<String> valueValues) {
    final values = valueValues.map((e) => [e]).toList();
    return getAllByIndex(r'value', values);
  }

  List<Address?> getAllByValueSync(List<String> valueValues) {
    final values = valueValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'value', values);
  }

  Future<int> deleteAllByValue(List<String> valueValues) {
    final values = valueValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'value', values);
  }

  int deleteAllByValueSync(List<String> valueValues) {
    final values = valueValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'value', values);
  }

  Future<Id> putByValue(Address object) {
    return putByIndex(r'value', object);
  }

  Id putByValueSync(Address object, {bool saveLinks = true}) {
    return putByIndexSync(r'value', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByValue(List<Address> objects) {
    return putAllByIndex(r'value', objects);
  }

  List<Id> putAllByValueSync(List<Address> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'value', objects, saveLinks: saveLinks);
  }
}

extension AddressQueryWhereSort on QueryBuilder<Address, Address, QWhere> {
  QueryBuilder<Address, Address, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Address, Address, QAfterWhere> anyDerivationIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'derivationIndex'),
      );
    });
  }
}

extension AddressQueryWhere on QueryBuilder<Address, Address, QWhereClause> {
  QueryBuilder<Address, Address, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Address, Address, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> idBetween(
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

  QueryBuilder<Address, Address, QAfterWhereClause> valueEqualTo(String value) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'value',
        value: [value],
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> valueNotEqualTo(
      String value) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value',
              lower: [],
              upper: [value],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value',
              lower: [value],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value',
              lower: [value],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'value',
              lower: [],
              upper: [value],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexEqualTo(
      int derivationIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'derivationIndex',
        value: [derivationIndex],
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexNotEqualTo(
      int derivationIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'derivationIndex',
              lower: [],
              upper: [derivationIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'derivationIndex',
              lower: [derivationIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'derivationIndex',
              lower: [derivationIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'derivationIndex',
              lower: [],
              upper: [derivationIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexGreaterThan(
    int derivationIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'derivationIndex',
        lower: [derivationIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexLessThan(
    int derivationIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'derivationIndex',
        lower: [],
        upper: [derivationIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterWhereClause> derivationIndexBetween(
    int lowerDerivationIndex,
    int upperDerivationIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'derivationIndex',
        lower: [lowerDerivationIndex],
        includeLower: includeLower,
        upper: [upperDerivationIndex],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AddressQueryFilter
    on QueryBuilder<Address, Address, QFilterCondition> {
  QueryBuilder<Address, Address, QAfterFilterCondition> derivationIndexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'derivationIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      derivationIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'derivationIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> derivationIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'derivationIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> derivationIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'derivationIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyElementEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'publicKey',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      publicKeyElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'publicKey',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      publicKeyElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'publicKey',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'publicKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition>
      publicKeyLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> publicKeyLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'publicKey',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> subTypeEqualTo(
      AddressSubType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subType',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> subTypeGreaterThan(
    AddressSubType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subType',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> subTypeLessThan(
    AddressSubType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subType',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> subTypeBetween(
    AddressSubType lower,
    AddressSubType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> typeEqualTo(
      AddressType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> typeGreaterThan(
    AddressType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> typeLessThan(
    AddressType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> typeBetween(
    AddressType lower,
    AddressType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueEqualTo(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> valueGreaterThan(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> valueLessThan(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> valueBetween(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> valueStartsWith(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> valueEndsWith(
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

  QueryBuilder<Address, Address, QAfterFilterCondition> valueContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'value',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<Address, Address, QAfterFilterCondition> valueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'value',
        value: '',
      ));
    });
  }
}

extension AddressQueryObject
    on QueryBuilder<Address, Address, QFilterCondition> {}

extension AddressQueryLinks
    on QueryBuilder<Address, Address, QFilterCondition> {}

extension AddressQuerySortBy on QueryBuilder<Address, Address, QSortBy> {
  QueryBuilder<Address, Address, QAfterSortBy> sortByDerivationIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'derivationIndex', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByDerivationIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'derivationIndex', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortBySubTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension AddressQuerySortThenBy
    on QueryBuilder<Address, Address, QSortThenBy> {
  QueryBuilder<Address, Address, QAfterSortBy> thenByDerivationIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'derivationIndex', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByDerivationIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'derivationIndex', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenBySubTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subType', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<Address, Address, QAfterSortBy> thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension AddressQueryWhereDistinct
    on QueryBuilder<Address, Address, QDistinct> {
  QueryBuilder<Address, Address, QDistinct> distinctByDerivationIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'derivationIndex');
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctByPublicKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'publicKey');
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctBySubType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subType');
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<Address, Address, QDistinct> distinctByValue(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value', caseSensitive: caseSensitive);
    });
  }
}

extension AddressQueryProperty
    on QueryBuilder<Address, Address, QQueryProperty> {
  QueryBuilder<Address, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Address, int, QQueryOperations> derivationIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'derivationIndex');
    });
  }

  QueryBuilder<Address, List<int>, QQueryOperations> publicKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'publicKey');
    });
  }

  QueryBuilder<Address, AddressSubType, QQueryOperations> subTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subType');
    });
  }

  QueryBuilder<Address, AddressType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<Address, String, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetContactEntryCollection on Isar {
  IsarCollection<ContactEntry> get contactEntrys => this.collection();
}

const ContactEntrySchema = CollectionSchema(
  name: r'ContactEntry',
  id: -3248212280610531288,
  properties: {
    r'addresses': PropertySchema(
      id: 0,
      name: r'addresses',
      type: IsarType.objectList,
      target: r'ContactAddressEntry',
    ),
    r'customId': PropertySchema(
      id: 1,
      name: r'customId',
      type: IsarType.string,
    ),
    r'emojiChar': PropertySchema(
      id: 2,
      name: r'emojiChar',
      type: IsarType.string,
    ),
    r'isFavorite': PropertySchema(
      id: 3,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _contactEntryEstimateSize,
  serialize: _contactEntrySerialize,
  deserialize: _contactEntryDeserialize,
  deserializeProp: _contactEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'customId': IndexSchema(
      id: -7523974382886476007,
      name: r'customId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'customId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'ContactAddressEntry': ContactAddressEntrySchema},
  getId: _contactEntryGetId,
  getLinks: _contactEntryGetLinks,
  attach: _contactEntryAttach,
  version: '3.0.5',
);

int _contactEntryEstimateSize(
  ContactEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.addresses.length * 3;
  {
    final offsets = allOffsets[ContactAddressEntry]!;
    for (var i = 0; i < object.addresses.length; i++) {
      final value = object.addresses[i];
      bytesCount +=
          ContactAddressEntrySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.customId.length * 3;
  {
    final value = object.emojiChar;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _contactEntrySerialize(
  ContactEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<ContactAddressEntry>(
    offsets[0],
    allOffsets,
    ContactAddressEntrySchema.serialize,
    object.addresses,
  );
  writer.writeString(offsets[1], object.customId);
  writer.writeString(offsets[2], object.emojiChar);
  writer.writeBool(offsets[3], object.isFavorite);
  writer.writeString(offsets[4], object.name);
}

ContactEntry _contactEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ContactEntry(
    addresses: reader.readObjectList<ContactAddressEntry>(
          offsets[0],
          ContactAddressEntrySchema.deserialize,
          allOffsets,
          ContactAddressEntry(),
        ) ??
        [],
    customId: reader.readString(offsets[1]),
    emojiChar: reader.readStringOrNull(offsets[2]),
    isFavorite: reader.readBool(offsets[3]),
    name: reader.readString(offsets[4]),
  );
  object.id = id;
  return object;
}

P _contactEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<ContactAddressEntry>(
            offset,
            ContactAddressEntrySchema.deserialize,
            allOffsets,
            ContactAddressEntry(),
          ) ??
          []) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _contactEntryGetId(ContactEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _contactEntryGetLinks(ContactEntry object) {
  return [];
}

void _contactEntryAttach(
    IsarCollection<dynamic> col, Id id, ContactEntry object) {
  object.id = id;
}

extension ContactEntryByIndex on IsarCollection<ContactEntry> {
  Future<ContactEntry?> getByCustomId(String customId) {
    return getByIndex(r'customId', [customId]);
  }

  ContactEntry? getByCustomIdSync(String customId) {
    return getByIndexSync(r'customId', [customId]);
  }

  Future<bool> deleteByCustomId(String customId) {
    return deleteByIndex(r'customId', [customId]);
  }

  bool deleteByCustomIdSync(String customId) {
    return deleteByIndexSync(r'customId', [customId]);
  }

  Future<List<ContactEntry?>> getAllByCustomId(List<String> customIdValues) {
    final values = customIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'customId', values);
  }

  List<ContactEntry?> getAllByCustomIdSync(List<String> customIdValues) {
    final values = customIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'customId', values);
  }

  Future<int> deleteAllByCustomId(List<String> customIdValues) {
    final values = customIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'customId', values);
  }

  int deleteAllByCustomIdSync(List<String> customIdValues) {
    final values = customIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'customId', values);
  }

  Future<Id> putByCustomId(ContactEntry object) {
    return putByIndex(r'customId', object);
  }

  Id putByCustomIdSync(ContactEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'customId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCustomId(List<ContactEntry> objects) {
    return putAllByIndex(r'customId', objects);
  }

  List<Id> putAllByCustomIdSync(List<ContactEntry> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'customId', objects, saveLinks: saveLinks);
  }
}

extension ContactEntryQueryWhereSort
    on QueryBuilder<ContactEntry, ContactEntry, QWhere> {
  QueryBuilder<ContactEntry, ContactEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ContactEntryQueryWhere
    on QueryBuilder<ContactEntry, ContactEntry, QWhereClause> {
  QueryBuilder<ContactEntry, ContactEntry, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterWhereClause> customIdEqualTo(
      String customId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'customId',
        value: [customId],
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterWhereClause>
      customIdNotEqualTo(String customId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customId',
              lower: [],
              upper: [customId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customId',
              lower: [customId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customId',
              lower: [customId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customId',
              lower: [],
              upper: [customId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ContactEntryQueryFilter
    on QueryBuilder<ContactEntry, ContactEntry, QFilterCondition> {
  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      addressesIsEmpty() {
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customId',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      customIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customId',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'emojiChar',
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'emojiChar',
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emojiChar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emojiChar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emojiChar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emojiChar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'emojiChar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'emojiChar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'emojiChar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'emojiChar',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emojiChar',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      emojiCharIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'emojiChar',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      nameGreaterThan(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      nameStartsWith(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> nameContains(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension ContactEntryQueryObject
    on QueryBuilder<ContactEntry, ContactEntry, QFilterCondition> {
  QueryBuilder<ContactEntry, ContactEntry, QAfterFilterCondition>
      addressesElement(FilterQuery<ContactAddressEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'addresses');
    });
  }
}

extension ContactEntryQueryLinks
    on QueryBuilder<ContactEntry, ContactEntry, QFilterCondition> {}

extension ContactEntryQuerySortBy
    on QueryBuilder<ContactEntry, ContactEntry, QSortBy> {
  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> sortByCustomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customId', Sort.asc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> sortByCustomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customId', Sort.desc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> sortByEmojiChar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emojiChar', Sort.asc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> sortByEmojiCharDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emojiChar', Sort.desc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy>
      sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension ContactEntryQuerySortThenBy
    on QueryBuilder<ContactEntry, ContactEntry, QSortThenBy> {
  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> thenByCustomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customId', Sort.asc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> thenByCustomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customId', Sort.desc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> thenByEmojiChar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emojiChar', Sort.asc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> thenByEmojiCharDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emojiChar', Sort.desc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy>
      thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension ContactEntryQueryWhereDistinct
    on QueryBuilder<ContactEntry, ContactEntry, QDistinct> {
  QueryBuilder<ContactEntry, ContactEntry, QDistinct> distinctByCustomId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QDistinct> distinctByEmojiChar(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emojiChar', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<ContactEntry, ContactEntry, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension ContactEntryQueryProperty
    on QueryBuilder<ContactEntry, ContactEntry, QQueryProperty> {
  QueryBuilder<ContactEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ContactEntry, List<ContactAddressEntry>, QQueryOperations>
      addressesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addresses');
    });
  }

  QueryBuilder<ContactEntry, String, QQueryOperations> customIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customId');
    });
  }

  QueryBuilder<ContactEntry, String?, QQueryOperations> emojiCharProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emojiChar');
    });
  }

  QueryBuilder<ContactEntry, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<ContactEntry, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

const ContactAddressEntrySchema = Schema(
  name: r'ContactAddressEntry',
  id: 2556413586404997281,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'coinName': PropertySchema(
      id: 1,
      name: r'coinName',
      type: IsarType.string,
    ),
    r'label': PropertySchema(
      id: 2,
      name: r'label',
      type: IsarType.string,
    ),
    r'other': PropertySchema(
      id: 3,
      name: r'other',
      type: IsarType.string,
    )
  },
  estimateSize: _contactAddressEntryEstimateSize,
  serialize: _contactAddressEntrySerialize,
  deserialize: _contactAddressEntryDeserialize,
  deserializeProp: _contactAddressEntryDeserializeProp,
);

int _contactAddressEntryEstimateSize(
  ContactAddressEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.address.length * 3;
  bytesCount += 3 + object.coinName.length * 3;
  bytesCount += 3 + object.label.length * 3;
  {
    final value = object.other;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _contactAddressEntrySerialize(
  ContactAddressEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeString(offsets[1], object.coinName);
  writer.writeString(offsets[2], object.label);
  writer.writeString(offsets[3], object.other);
}

ContactAddressEntry _contactAddressEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ContactAddressEntry();
  object.address = reader.readString(offsets[0]);
  object.coinName = reader.readString(offsets[1]);
  object.label = reader.readString(offsets[2]);
  object.other = reader.readStringOrNull(offsets[3]);
  return object;
}

P _contactAddressEntryDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ContactAddressEntryQueryFilter on QueryBuilder<ContactAddressEntry,
    ContactAddressEntry, QFilterCondition> {
  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'address',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coinName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'coinName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'coinName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coinName',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      coinNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'coinName',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelEqualTo(
    String value, {
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

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelGreaterThan(
    String value, {
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

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelLessThan(
    String value, {
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

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelBetween(
    String lower,
    String upper, {
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

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelStartsWith(
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

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelEndsWith(
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

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'label',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'other',
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'other',
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'other',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'other',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'other',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'other',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'other',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'other',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'other',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'other',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'other',
        value: '',
      ));
    });
  }

  QueryBuilder<ContactAddressEntry, ContactAddressEntry, QAfterFilterCondition>
      otherIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'other',
        value: '',
      ));
    });
  }
}

extension ContactAddressEntryQueryObject on QueryBuilder<ContactAddressEntry,
    ContactAddressEntry, QFilterCondition> {}

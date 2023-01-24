// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetLogCollection on Isar {
  IsarCollection<Log> get logs => this.collection();
}

const LogSchema = CollectionSchema(
  name: r'Log',
  id: 7425915233166922082,
  properties: {
    r'logLevel': PropertySchema(
      id: 0,
      name: r'logLevel',
      type: IsarType.string,
      enumMap: _LoglogLevelEnumValueMap,
    ),
    r'message': PropertySchema(
      id: 1,
      name: r'message',
      type: IsarType.string,
    ),
    r'timestampInMillisUTC': PropertySchema(
      id: 2,
      name: r'timestampInMillisUTC',
      type: IsarType.long,
    )
  },
  estimateSize: _logEstimateSize,
  serialize: _logSerialize,
  deserialize: _logDeserialize,
  deserializeProp: _logDeserializeProp,
  idName: r'id',
  indexes: {
    r'timestampInMillisUTC': IndexSchema(
      id: 4718041126655087375,
      name: r'timestampInMillisUTC',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestampInMillisUTC',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _logGetId,
  getLinks: _logGetLinks,
  attach: _logAttach,
  version: '3.0.5',
);

int _logEstimateSize(
  Log object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.logLevel.name.length * 3;
  bytesCount += 3 + object.message.length * 3;
  return bytesCount;
}

void _logSerialize(
  Log object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.logLevel.name);
  writer.writeString(offsets[1], object.message);
  writer.writeLong(offsets[2], object.timestampInMillisUTC);
}

Log _logDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Log();
  object.id = id;
  object.logLevel =
      _LoglogLevelValueEnumMap[reader.readStringOrNull(offsets[0])] ??
          LogLevel.Info;
  object.message = reader.readString(offsets[1]);
  object.timestampInMillisUTC = reader.readLong(offsets[2]);
  return object;
}

P _logDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_LoglogLevelValueEnumMap[reader.readStringOrNull(offset)] ??
          LogLevel.Info) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _LoglogLevelEnumValueMap = {
  r'Info': r'Info',
  r'Warning': r'Warning',
  r'Error': r'Error',
  r'Fatal': r'Fatal',
};
const _LoglogLevelValueEnumMap = {
  r'Info': LogLevel.Info,
  r'Warning': LogLevel.Warning,
  r'Error': LogLevel.Error,
  r'Fatal': LogLevel.Fatal,
};

Id _logGetId(Log object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _logGetLinks(Log object) {
  return [];
}

void _logAttach(IsarCollection<dynamic> col, Id id, Log object) {
  object.id = id;
}

extension LogQueryWhereSort on QueryBuilder<Log, Log, QWhere> {
  QueryBuilder<Log, Log, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Log, Log, QAfterWhere> anyTimestampInMillisUTC() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestampInMillisUTC'),
      );
    });
  }
}

extension LogQueryWhere on QueryBuilder<Log, Log, QWhereClause> {
  QueryBuilder<Log, Log, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Log, Log, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> idBetween(
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

  QueryBuilder<Log, Log, QAfterWhereClause> timestampInMillisUTCEqualTo(
      int timestampInMillisUTC) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestampInMillisUTC',
        value: [timestampInMillisUTC],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> timestampInMillisUTCNotEqualTo(
      int timestampInMillisUTC) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestampInMillisUTC',
              lower: [],
              upper: [timestampInMillisUTC],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestampInMillisUTC',
              lower: [timestampInMillisUTC],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestampInMillisUTC',
              lower: [timestampInMillisUTC],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestampInMillisUTC',
              lower: [],
              upper: [timestampInMillisUTC],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> timestampInMillisUTCGreaterThan(
    int timestampInMillisUTC, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestampInMillisUTC',
        lower: [timestampInMillisUTC],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> timestampInMillisUTCLessThan(
    int timestampInMillisUTC, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestampInMillisUTC',
        lower: [],
        upper: [timestampInMillisUTC],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterWhereClause> timestampInMillisUTCBetween(
    int lowerTimestampInMillisUTC,
    int upperTimestampInMillisUTC, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestampInMillisUTC',
        lower: [lowerTimestampInMillisUTC],
        includeLower: includeLower,
        upper: [upperTimestampInMillisUTC],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LogQueryFilter on QueryBuilder<Log, Log, QFilterCondition> {
  QueryBuilder<Log, Log, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Log, Log, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Log, Log, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelEqualTo(
    LogLevel value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelGreaterThan(
    LogLevel value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'logLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelLessThan(
    LogLevel value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'logLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelBetween(
    LogLevel lower,
    LogLevel upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'logLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'logLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'logLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'logLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'logLevel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> logLevelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'logLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> timestampInMillisUTCEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestampInMillisUTC',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> timestampInMillisUTCGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestampInMillisUTC',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> timestampInMillisUTCLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestampInMillisUTC',
        value: value,
      ));
    });
  }

  QueryBuilder<Log, Log, QAfterFilterCondition> timestampInMillisUTCBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestampInMillisUTC',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LogQueryObject on QueryBuilder<Log, Log, QFilterCondition> {}

extension LogQueryLinks on QueryBuilder<Log, Log, QFilterCondition> {}

extension LogQuerySortBy on QueryBuilder<Log, Log, QSortBy> {
  QueryBuilder<Log, Log, QAfterSortBy> sortByLogLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logLevel', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByLogLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logLevel', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByTimestampInMillisUTC() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestampInMillisUTC', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> sortByTimestampInMillisUTCDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestampInMillisUTC', Sort.desc);
    });
  }
}

extension LogQuerySortThenBy on QueryBuilder<Log, Log, QSortThenBy> {
  QueryBuilder<Log, Log, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByLogLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logLevel', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByLogLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logLevel', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByTimestampInMillisUTC() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestampInMillisUTC', Sort.asc);
    });
  }

  QueryBuilder<Log, Log, QAfterSortBy> thenByTimestampInMillisUTCDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestampInMillisUTC', Sort.desc);
    });
  }
}

extension LogQueryWhereDistinct on QueryBuilder<Log, Log, QDistinct> {
  QueryBuilder<Log, Log, QDistinct> distinctByLogLevel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'logLevel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Log, Log, QDistinct> distinctByMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Log, Log, QDistinct> distinctByTimestampInMillisUTC() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestampInMillisUTC');
    });
  }
}

extension LogQueryProperty on QueryBuilder<Log, Log, QQueryProperty> {
  QueryBuilder<Log, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Log, LogLevel, QQueryOperations> logLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logLevel');
    });
  }

  QueryBuilder<Log, String, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<Log, int, QQueryOperations> timestampInMillisUTCProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestampInMillisUTC');
    });
  }
}

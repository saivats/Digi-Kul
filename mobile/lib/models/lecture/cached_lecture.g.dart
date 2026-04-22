// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_lecture.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedLectureCollection on Isar {
  IsarCollection<CachedLecture> get cachedLectures => this.collection();
}

const CachedLectureSchema = CollectionSchema(
  name: r'CachedLecture',
  id: 5892021272320718927,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'cohortId': PropertySchema(
      id: 1,
      name: r'cohortId',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'durationMinutes': PropertySchema(
      id: 3,
      name: r'durationMinutes',
      type: IsarType.long,
    ),
    r'recordingId': PropertySchema(
      id: 4,
      name: r'recordingId',
      type: IsarType.string,
    ),
    r'scheduledTime': PropertySchema(
      id: 5,
      name: r'scheduledTime',
      type: IsarType.dateTime,
    ),
    r'serverId': PropertySchema(
      id: 6,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 7,
      name: r'status',
      type: IsarType.string,
    ),
    r'teacherName': PropertySchema(
      id: 8,
      name: r'teacherName',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 9,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedLectureEstimateSize,
  serialize: _cachedLectureSerialize,
  deserialize: _cachedLectureDeserialize,
  deserializeProp: _cachedLectureDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedLectureGetId,
  getLinks: _cachedLectureGetLinks,
  attach: _cachedLectureAttach,
  version: '3.1.0+1',
);

int _cachedLectureEstimateSize(
  CachedLecture object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cohortId.length * 3;
  bytesCount += 3 + object.description.length * 3;
  {
    final value = object.recordingId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.teacherName.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _cachedLectureSerialize(
  CachedLecture object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.cohortId);
  writer.writeString(offsets[2], object.description);
  writer.writeLong(offsets[3], object.durationMinutes);
  writer.writeString(offsets[4], object.recordingId);
  writer.writeDateTime(offsets[5], object.scheduledTime);
  writer.writeString(offsets[6], object.serverId);
  writer.writeString(offsets[7], object.status);
  writer.writeString(offsets[8], object.teacherName);
  writer.writeString(offsets[9], object.title);
}

CachedLecture _cachedLectureDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedLecture();
  object.cachedAt = reader.readDateTimeOrNull(offsets[0]);
  object.cohortId = reader.readString(offsets[1]);
  object.description = reader.readString(offsets[2]);
  object.durationMinutes = reader.readLong(offsets[3]);
  object.id = id;
  object.recordingId = reader.readStringOrNull(offsets[4]);
  object.scheduledTime = reader.readDateTime(offsets[5]);
  object.serverId = reader.readString(offsets[6]);
  object.status = reader.readString(offsets[7]);
  object.teacherName = reader.readString(offsets[8]);
  object.title = reader.readString(offsets[9]);
  return object;
}

P _cachedLectureDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedLectureGetId(CachedLecture object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedLectureGetLinks(CachedLecture object) {
  return [];
}

void _cachedLectureAttach(
    IsarCollection<dynamic> col, Id id, CachedLecture object) {
  object.id = id;
}

extension CachedLectureByIndex on IsarCollection<CachedLecture> {
  Future<CachedLecture?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  CachedLecture? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<CachedLecture?>> getAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<CachedLecture?> getAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'serverId', values);
  }

  Future<int> deleteAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'serverId', values);
  }

  int deleteAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'serverId', values);
  }

  Future<Id> putByServerId(CachedLecture object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(CachedLecture object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<CachedLecture> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<CachedLecture> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension CachedLectureQueryWhereSort
    on QueryBuilder<CachedLecture, CachedLecture, QWhere> {
  QueryBuilder<CachedLecture, CachedLecture, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedLectureQueryWhere
    on QueryBuilder<CachedLecture, CachedLecture, QWhereClause> {
  QueryBuilder<CachedLecture, CachedLecture, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<CachedLecture, CachedLecture, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedLecture, CachedLecture, QAfterWhereClause> serverIdEqualTo(
      String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterWhereClause>
      serverIdNotEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedLectureQueryFilter
    on QueryBuilder<CachedLecture, CachedLecture, QFilterCondition> {
  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cachedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cachedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cachedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cachedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cachedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cachedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cohortId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cohortId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cohortId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cohortId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cohortId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cohortId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cohortId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cohortId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cohortId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      cohortIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cohortId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      durationMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      durationMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      durationMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      durationMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
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

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recordingId',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recordingId',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordingId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recordingId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recordingId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recordingId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recordingId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recordingId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recordingId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recordingId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordingId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      recordingIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recordingId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      scheduledTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledTime',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      scheduledTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledTime',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      scheduledTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledTime',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      scheduledTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'teacherName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'teacherName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'teacherName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'teacherName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'teacherName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'teacherName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'teacherName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'teacherName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'teacherName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      teacherNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'teacherName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension CachedLectureQueryObject
    on QueryBuilder<CachedLecture, CachedLecture, QFilterCondition> {}

extension CachedLectureQueryLinks
    on QueryBuilder<CachedLecture, CachedLecture, QFilterCondition> {}

extension CachedLectureQuerySortBy
    on QueryBuilder<CachedLecture, CachedLecture, QSortBy> {
  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByCohortId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cohortId', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByCohortIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cohortId', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByRecordingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordingId', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByRecordingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordingId', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByScheduledTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTime', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByScheduledTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTime', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByTeacherName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherName', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      sortByTeacherNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherName', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension CachedLectureQuerySortThenBy
    on QueryBuilder<CachedLecture, CachedLecture, QSortThenBy> {
  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByCohortId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cohortId', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByCohortIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cohortId', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByRecordingId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordingId', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByRecordingIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordingId', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByScheduledTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTime', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByScheduledTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledTime', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByTeacherName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherName', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy>
      thenByTeacherNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherName', Sort.desc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension CachedLectureQueryWhereDistinct
    on QueryBuilder<CachedLecture, CachedLecture, QDistinct> {
  QueryBuilder<CachedLecture, CachedLecture, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QDistinct> distinctByCohortId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cohortId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QDistinct>
      distinctByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMinutes');
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QDistinct> distinctByRecordingId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordingId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QDistinct>
      distinctByScheduledTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledTime');
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QDistinct> distinctByTeacherName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'teacherName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedLecture, CachedLecture, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension CachedLectureQueryProperty
    on QueryBuilder<CachedLecture, CachedLecture, QQueryProperty> {
  QueryBuilder<CachedLecture, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedLecture, DateTime?, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedLecture, String, QQueryOperations> cohortIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cohortId');
    });
  }

  QueryBuilder<CachedLecture, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<CachedLecture, int, QQueryOperations> durationMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMinutes');
    });
  }

  QueryBuilder<CachedLecture, String?, QQueryOperations> recordingIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordingId');
    });
  }

  QueryBuilder<CachedLecture, DateTime, QQueryOperations>
      scheduledTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledTime');
    });
  }

  QueryBuilder<CachedLecture, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<CachedLecture, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CachedLecture, String, QQueryOperations> teacherNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'teacherName');
    });
  }

  QueryBuilder<CachedLecture, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}

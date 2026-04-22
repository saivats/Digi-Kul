// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_attendance.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedAttendanceCollection on Isar {
  IsarCollection<CachedAttendance> get cachedAttendances => this.collection();
}

const CachedAttendanceSchema = CollectionSchema(
  name: r'CachedAttendance',
  id: 5927794780584432287,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'lectureDate': PropertySchema(
      id: 1,
      name: r'lectureDate',
      type: IsarType.dateTime,
    ),
    r'lectureId': PropertySchema(
      id: 2,
      name: r'lectureId',
      type: IsarType.string,
    ),
    r'lectureTitle': PropertySchema(
      id: 3,
      name: r'lectureTitle',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 4,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 5,
      name: r'status',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedAttendanceEstimateSize,
  serialize: _cachedAttendanceSerialize,
  deserialize: _cachedAttendanceDeserialize,
  deserializeProp: _cachedAttendanceDeserializeProp,
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
  getId: _cachedAttendanceGetId,
  getLinks: _cachedAttendanceGetLinks,
  attach: _cachedAttendanceAttach,
  version: '3.1.0+1',
);

int _cachedAttendanceEstimateSize(
  CachedAttendance object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.lectureId.length * 3;
  bytesCount += 3 + object.lectureTitle.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _cachedAttendanceSerialize(
  CachedAttendance object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeDateTime(offsets[1], object.lectureDate);
  writer.writeString(offsets[2], object.lectureId);
  writer.writeString(offsets[3], object.lectureTitle);
  writer.writeString(offsets[4], object.serverId);
  writer.writeString(offsets[5], object.status);
}

CachedAttendance _cachedAttendanceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedAttendance();
  object.cachedAt = reader.readDateTimeOrNull(offsets[0]);
  object.id = id;
  object.lectureDate = reader.readDateTime(offsets[1]);
  object.lectureId = reader.readString(offsets[2]);
  object.lectureTitle = reader.readString(offsets[3]);
  object.serverId = reader.readString(offsets[4]);
  object.status = reader.readString(offsets[5]);
  return object;
}

P _cachedAttendanceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedAttendanceGetId(CachedAttendance object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedAttendanceGetLinks(CachedAttendance object) {
  return [];
}

void _cachedAttendanceAttach(
    IsarCollection<dynamic> col, Id id, CachedAttendance object) {
  object.id = id;
}

extension CachedAttendanceByIndex on IsarCollection<CachedAttendance> {
  Future<CachedAttendance?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  CachedAttendance? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<CachedAttendance?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<CachedAttendance?> getAllByServerIdSync(List<String> serverIdValues) {
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

  Future<Id> putByServerId(CachedAttendance object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(CachedAttendance object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<CachedAttendance> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<CachedAttendance> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension CachedAttendanceQueryWhereSort
    on QueryBuilder<CachedAttendance, CachedAttendance, QWhere> {
  QueryBuilder<CachedAttendance, CachedAttendance, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedAttendanceQueryWhere
    on QueryBuilder<CachedAttendance, CachedAttendance, QWhereClause> {
  QueryBuilder<CachedAttendance, CachedAttendance, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterWhereClause>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterWhereClause>
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

extension CachedAttendanceQueryFilter
    on QueryBuilder<CachedAttendance, CachedAttendance, QFilterCondition> {
  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      cachedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      cachedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      cachedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lectureDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lectureDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lectureDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lectureDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lectureId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lectureId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lectureId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lectureId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lectureId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lectureId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lectureId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lectureId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lectureId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lectureId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lectureTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lectureTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lectureTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lectureTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lectureTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lectureTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lectureTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lectureTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lectureTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      lectureTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lectureTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
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

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }
}

extension CachedAttendanceQueryObject
    on QueryBuilder<CachedAttendance, CachedAttendance, QFilterCondition> {}

extension CachedAttendanceQueryLinks
    on QueryBuilder<CachedAttendance, CachedAttendance, QFilterCondition> {}

extension CachedAttendanceQuerySortBy
    on QueryBuilder<CachedAttendance, CachedAttendance, QSortBy> {
  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByLectureDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureDate', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByLectureDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureDate', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByLectureId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureId', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByLectureIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureId', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByLectureTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureTitle', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByLectureTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureTitle', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension CachedAttendanceQuerySortThenBy
    on QueryBuilder<CachedAttendance, CachedAttendance, QSortThenBy> {
  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByLectureDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureDate', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByLectureDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureDate', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByLectureId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureId', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByLectureIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureId', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByLectureTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureTitle', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByLectureTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lectureTitle', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension CachedAttendanceQueryWhereDistinct
    on QueryBuilder<CachedAttendance, CachedAttendance, QDistinct> {
  QueryBuilder<CachedAttendance, CachedAttendance, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QDistinct>
      distinctByLectureDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lectureDate');
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QDistinct>
      distinctByLectureId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lectureId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QDistinct>
      distinctByLectureTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lectureTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedAttendance, CachedAttendance, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension CachedAttendanceQueryProperty
    on QueryBuilder<CachedAttendance, CachedAttendance, QQueryProperty> {
  QueryBuilder<CachedAttendance, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedAttendance, DateTime?, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedAttendance, DateTime, QQueryOperations>
      lectureDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lectureDate');
    });
  }

  QueryBuilder<CachedAttendance, String, QQueryOperations> lectureIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lectureId');
    });
  }

  QueryBuilder<CachedAttendance, String, QQueryOperations>
      lectureTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lectureTitle');
    });
  }

  QueryBuilder<CachedAttendance, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<CachedAttendance, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}

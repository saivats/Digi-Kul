// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_quiz_submission.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPendingQuizSubmissionCollection on Isar {
  IsarCollection<PendingQuizSubmission> get pendingQuizSubmissions =>
      this.collection();
}

const PendingQuizSubmissionSchema = CollectionSchema(
  name: r'PendingQuizSubmission',
  id: 1759498802559227986,
  properties: {
    r'answersJson': PropertySchema(
      id: 0,
      name: r'answersJson',
      type: IsarType.string,
    ),
    r'attemptId': PropertySchema(
      id: 1,
      name: r'attemptId',
      type: IsarType.string,
    ),
    r'attemptedAt': PropertySchema(
      id: 2,
      name: r'attemptedAt',
      type: IsarType.dateTime,
    ),
    r'isSynced': PropertySchema(
      id: 3,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'quizSetId': PropertySchema(
      id: 4,
      name: r'quizSetId',
      type: IsarType.string,
    ),
    r'startedAt': PropertySchema(
      id: 5,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'studentId': PropertySchema(
      id: 6,
      name: r'studentId',
      type: IsarType.string,
    ),
    r'syncAttempts': PropertySchema(
      id: 7,
      name: r'syncAttempts',
      type: IsarType.long,
    ),
    r'syncError': PropertySchema(
      id: 8,
      name: r'syncError',
      type: IsarType.string,
    )
  },
  estimateSize: _pendingQuizSubmissionEstimateSize,
  serialize: _pendingQuizSubmissionSerialize,
  deserialize: _pendingQuizSubmissionDeserialize,
  deserializeProp: _pendingQuizSubmissionDeserializeProp,
  idName: r'id',
  indexes: {
    r'attemptId': IndexSchema(
      id: 3768995775447394589,
      name: r'attemptId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'attemptId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _pendingQuizSubmissionGetId,
  getLinks: _pendingQuizSubmissionGetLinks,
  attach: _pendingQuizSubmissionAttach,
  version: '3.1.0+1',
);

int _pendingQuizSubmissionEstimateSize(
  PendingQuizSubmission object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.answersJson.length * 3;
  bytesCount += 3 + object.attemptId.length * 3;
  bytesCount += 3 + object.quizSetId.length * 3;
  bytesCount += 3 + object.studentId.length * 3;
  {
    final value = object.syncError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _pendingQuizSubmissionSerialize(
  PendingQuizSubmission object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.answersJson);
  writer.writeString(offsets[1], object.attemptId);
  writer.writeDateTime(offsets[2], object.attemptedAt);
  writer.writeBool(offsets[3], object.isSynced);
  writer.writeString(offsets[4], object.quizSetId);
  writer.writeDateTime(offsets[5], object.startedAt);
  writer.writeString(offsets[6], object.studentId);
  writer.writeLong(offsets[7], object.syncAttempts);
  writer.writeString(offsets[8], object.syncError);
}

PendingQuizSubmission _pendingQuizSubmissionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PendingQuizSubmission();
  object.answersJson = reader.readString(offsets[0]);
  object.attemptId = reader.readString(offsets[1]);
  object.attemptedAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[3]);
  object.quizSetId = reader.readString(offsets[4]);
  object.startedAt = reader.readDateTime(offsets[5]);
  object.studentId = reader.readString(offsets[6]);
  object.syncAttempts = reader.readLong(offsets[7]);
  object.syncError = reader.readStringOrNull(offsets[8]);
  return object;
}

P _pendingQuizSubmissionDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pendingQuizSubmissionGetId(PendingQuizSubmission object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pendingQuizSubmissionGetLinks(
    PendingQuizSubmission object) {
  return [];
}

void _pendingQuizSubmissionAttach(
    IsarCollection<dynamic> col, Id id, PendingQuizSubmission object) {
  object.id = id;
}

extension PendingQuizSubmissionByIndex
    on IsarCollection<PendingQuizSubmission> {
  Future<PendingQuizSubmission?> getByAttemptId(String attemptId) {
    return getByIndex(r'attemptId', [attemptId]);
  }

  PendingQuizSubmission? getByAttemptIdSync(String attemptId) {
    return getByIndexSync(r'attemptId', [attemptId]);
  }

  Future<bool> deleteByAttemptId(String attemptId) {
    return deleteByIndex(r'attemptId', [attemptId]);
  }

  bool deleteByAttemptIdSync(String attemptId) {
    return deleteByIndexSync(r'attemptId', [attemptId]);
  }

  Future<List<PendingQuizSubmission?>> getAllByAttemptId(
      List<String> attemptIdValues) {
    final values = attemptIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'attemptId', values);
  }

  List<PendingQuizSubmission?> getAllByAttemptIdSync(
      List<String> attemptIdValues) {
    final values = attemptIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'attemptId', values);
  }

  Future<int> deleteAllByAttemptId(List<String> attemptIdValues) {
    final values = attemptIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'attemptId', values);
  }

  int deleteAllByAttemptIdSync(List<String> attemptIdValues) {
    final values = attemptIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'attemptId', values);
  }

  Future<Id> putByAttemptId(PendingQuizSubmission object) {
    return putByIndex(r'attemptId', object);
  }

  Id putByAttemptIdSync(PendingQuizSubmission object, {bool saveLinks = true}) {
    return putByIndexSync(r'attemptId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByAttemptId(List<PendingQuizSubmission> objects) {
    return putAllByIndex(r'attemptId', objects);
  }

  List<Id> putAllByAttemptIdSync(List<PendingQuizSubmission> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'attemptId', objects, saveLinks: saveLinks);
  }
}

extension PendingQuizSubmissionQueryWhereSort
    on QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QWhere> {
  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PendingQuizSubmissionQueryWhere on QueryBuilder<PendingQuizSubmission,
    PendingQuizSubmission, QWhereClause> {
  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterWhereClause>
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

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterWhereClause>
      attemptIdEqualTo(String attemptId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'attemptId',
        value: [attemptId],
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterWhereClause>
      attemptIdNotEqualTo(String attemptId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'attemptId',
              lower: [],
              upper: [attemptId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'attemptId',
              lower: [attemptId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'attemptId',
              lower: [attemptId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'attemptId',
              lower: [],
              upper: [attemptId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PendingQuizSubmissionQueryFilter on QueryBuilder<
    PendingQuizSubmission, PendingQuizSubmission, QFilterCondition> {
  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> answersJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'answersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> answersJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'answersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> answersJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'answersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> answersJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'answersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> answersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'answersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> answersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'answersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      answersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'answersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      answersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'answersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> answersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'answersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> answersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'answersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attemptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attemptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attemptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attemptId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'attemptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'attemptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      attemptIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'attemptId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      attemptIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'attemptId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attemptId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'attemptId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attemptedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attemptedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attemptedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> attemptedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attemptedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> quizSetIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quizSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> quizSetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quizSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> quizSetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quizSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> quizSetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quizSetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> quizSetIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'quizSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> quizSetIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'quizSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      quizSetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'quizSetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      quizSetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'quizSetId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> quizSetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quizSetId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> quizSetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'quizSetId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> startedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> startedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> startedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> studentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> studentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> studentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> studentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'studentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> studentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> studentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      studentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'studentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      studentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'studentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> studentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> studentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'studentId',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncAttemptsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncAttemptsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncAttemptsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncAttempts',
        value: value,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncAttemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncAttempts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'syncError',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'syncError',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      syncErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
          QAfterFilterCondition>
      syncErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncError',
        value: '',
      ));
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission,
      QAfterFilterCondition> syncErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncError',
        value: '',
      ));
    });
  }
}

extension PendingQuizSubmissionQueryObject on QueryBuilder<
    PendingQuizSubmission, PendingQuizSubmission, QFilterCondition> {}

extension PendingQuizSubmissionQueryLinks on QueryBuilder<PendingQuizSubmission,
    PendingQuizSubmission, QFilterCondition> {}

extension PendingQuizSubmissionQuerySortBy
    on QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QSortBy> {
  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByAnswersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answersJson', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByAnswersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answersJson', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByAttemptId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptId', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByAttemptIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptId', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByAttemptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByAttemptedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptedAt', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByQuizSetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quizSetId', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByQuizSetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quizSetId', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByStudentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortByStudentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortBySyncAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAttempts', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortBySyncAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAttempts', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortBySyncError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncError', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      sortBySyncErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncError', Sort.desc);
    });
  }
}

extension PendingQuizSubmissionQuerySortThenBy
    on QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QSortThenBy> {
  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByAnswersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answersJson', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByAnswersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answersJson', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByAttemptId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptId', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByAttemptIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptId', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByAttemptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByAttemptedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptedAt', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByQuizSetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quizSetId', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByQuizSetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quizSetId', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByStudentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenByStudentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenBySyncAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAttempts', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenBySyncAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncAttempts', Sort.desc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenBySyncError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncError', Sort.asc);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QAfterSortBy>
      thenBySyncErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncError', Sort.desc);
    });
  }
}

extension PendingQuizSubmissionQueryWhereDistinct
    on QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct> {
  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct>
      distinctByAnswersJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'answersJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct>
      distinctByAttemptId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attemptId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct>
      distinctByAttemptedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attemptedAt');
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct>
      distinctByQuizSetId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quizSetId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct>
      distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct>
      distinctByStudentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'studentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct>
      distinctBySyncAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncAttempts');
    });
  }

  QueryBuilder<PendingQuizSubmission, PendingQuizSubmission, QDistinct>
      distinctBySyncError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncError', caseSensitive: caseSensitive);
    });
  }
}

extension PendingQuizSubmissionQueryProperty on QueryBuilder<
    PendingQuizSubmission, PendingQuizSubmission, QQueryProperty> {
  QueryBuilder<PendingQuizSubmission, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PendingQuizSubmission, String, QQueryOperations>
      answersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'answersJson');
    });
  }

  QueryBuilder<PendingQuizSubmission, String, QQueryOperations>
      attemptIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attemptId');
    });
  }

  QueryBuilder<PendingQuizSubmission, DateTime, QQueryOperations>
      attemptedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attemptedAt');
    });
  }

  QueryBuilder<PendingQuizSubmission, bool, QQueryOperations>
      isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<PendingQuizSubmission, String, QQueryOperations>
      quizSetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quizSetId');
    });
  }

  QueryBuilder<PendingQuizSubmission, DateTime, QQueryOperations>
      startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<PendingQuizSubmission, String, QQueryOperations>
      studentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studentId');
    });
  }

  QueryBuilder<PendingQuizSubmission, int, QQueryOperations>
      syncAttemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncAttempts');
    });
  }

  QueryBuilder<PendingQuizSubmission, String?, QQueryOperations>
      syncErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncError');
    });
  }
}

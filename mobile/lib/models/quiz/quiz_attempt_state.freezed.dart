// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_attempt_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$QuizAttemptState {
  QuizAttemptPhase get phase => throw _privateConstructorUsedError;
  QuizSetDto? get quizSet => throw _privateConstructorUsedError;
  List<QuizQuestionDto> get questions => throw _privateConstructorUsedError;
  Map<String, String> get answers => throw _privateConstructorUsedError;
  String? get attemptId => throw _privateConstructorUsedError;
  int get currentQuestionIndex => throw _privateConstructorUsedError;
  int? get remainingSeconds => throw _privateConstructorUsedError;
  QuizResultDto? get result => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  bool get isOffline => throw _privateConstructorUsedError;

  /// Create a copy of QuizAttemptState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizAttemptStateCopyWith<QuizAttemptState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizAttemptStateCopyWith<$Res> {
  factory $QuizAttemptStateCopyWith(
          QuizAttemptState value, $Res Function(QuizAttemptState) then) =
      _$QuizAttemptStateCopyWithImpl<$Res, QuizAttemptState>;
  @useResult
  $Res call(
      {QuizAttemptPhase phase,
      QuizSetDto? quizSet,
      List<QuizQuestionDto> questions,
      Map<String, String> answers,
      String? attemptId,
      int currentQuestionIndex,
      int? remainingSeconds,
      QuizResultDto? result,
      String? errorMessage,
      bool isOffline});

  $QuizSetDtoCopyWith<$Res>? get quizSet;
  $QuizResultDtoCopyWith<$Res>? get result;
}

/// @nodoc
class _$QuizAttemptStateCopyWithImpl<$Res, $Val extends QuizAttemptState>
    implements $QuizAttemptStateCopyWith<$Res> {
  _$QuizAttemptStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizAttemptState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phase = null,
    Object? quizSet = freezed,
    Object? questions = null,
    Object? answers = null,
    Object? attemptId = freezed,
    Object? currentQuestionIndex = null,
    Object? remainingSeconds = freezed,
    Object? result = freezed,
    Object? errorMessage = freezed,
    Object? isOffline = null,
  }) {
    return _then(_value.copyWith(
      phase: null == phase
          ? _value.phase
          : phase // ignore: cast_nullable_to_non_nullable
              as QuizAttemptPhase,
      quizSet: freezed == quizSet
          ? _value.quizSet
          : quizSet // ignore: cast_nullable_to_non_nullable
              as QuizSetDto?,
      questions: null == questions
          ? _value.questions
          : questions // ignore: cast_nullable_to_non_nullable
              as List<QuizQuestionDto>,
      answers: null == answers
          ? _value.answers
          : answers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      attemptId: freezed == attemptId
          ? _value.attemptId
          : attemptId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentQuestionIndex: null == currentQuestionIndex
          ? _value.currentQuestionIndex
          : currentQuestionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      remainingSeconds: freezed == remainingSeconds
          ? _value.remainingSeconds
          : remainingSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as QuizResultDto?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isOffline: null == isOffline
          ? _value.isOffline
          : isOffline // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of QuizAttemptState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QuizSetDtoCopyWith<$Res>? get quizSet {
    if (_value.quizSet == null) {
      return null;
    }

    return $QuizSetDtoCopyWith<$Res>(_value.quizSet!, (value) {
      return _then(_value.copyWith(quizSet: value) as $Val);
    });
  }

  /// Create a copy of QuizAttemptState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QuizResultDtoCopyWith<$Res>? get result {
    if (_value.result == null) {
      return null;
    }

    return $QuizResultDtoCopyWith<$Res>(_value.result!, (value) {
      return _then(_value.copyWith(result: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$QuizAttemptStateImplCopyWith<$Res>
    implements $QuizAttemptStateCopyWith<$Res> {
  factory _$$QuizAttemptStateImplCopyWith(_$QuizAttemptStateImpl value,
          $Res Function(_$QuizAttemptStateImpl) then) =
      __$$QuizAttemptStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {QuizAttemptPhase phase,
      QuizSetDto? quizSet,
      List<QuizQuestionDto> questions,
      Map<String, String> answers,
      String? attemptId,
      int currentQuestionIndex,
      int? remainingSeconds,
      QuizResultDto? result,
      String? errorMessage,
      bool isOffline});

  @override
  $QuizSetDtoCopyWith<$Res>? get quizSet;
  @override
  $QuizResultDtoCopyWith<$Res>? get result;
}

/// @nodoc
class __$$QuizAttemptStateImplCopyWithImpl<$Res>
    extends _$QuizAttemptStateCopyWithImpl<$Res, _$QuizAttemptStateImpl>
    implements _$$QuizAttemptStateImplCopyWith<$Res> {
  __$$QuizAttemptStateImplCopyWithImpl(_$QuizAttemptStateImpl _value,
      $Res Function(_$QuizAttemptStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of QuizAttemptState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phase = null,
    Object? quizSet = freezed,
    Object? questions = null,
    Object? answers = null,
    Object? attemptId = freezed,
    Object? currentQuestionIndex = null,
    Object? remainingSeconds = freezed,
    Object? result = freezed,
    Object? errorMessage = freezed,
    Object? isOffline = null,
  }) {
    return _then(_$QuizAttemptStateImpl(
      phase: null == phase
          ? _value.phase
          : phase // ignore: cast_nullable_to_non_nullable
              as QuizAttemptPhase,
      quizSet: freezed == quizSet
          ? _value.quizSet
          : quizSet // ignore: cast_nullable_to_non_nullable
              as QuizSetDto?,
      questions: null == questions
          ? _value._questions
          : questions // ignore: cast_nullable_to_non_nullable
              as List<QuizQuestionDto>,
      answers: null == answers
          ? _value._answers
          : answers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      attemptId: freezed == attemptId
          ? _value.attemptId
          : attemptId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentQuestionIndex: null == currentQuestionIndex
          ? _value.currentQuestionIndex
          : currentQuestionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      remainingSeconds: freezed == remainingSeconds
          ? _value.remainingSeconds
          : remainingSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as QuizResultDto?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isOffline: null == isOffline
          ? _value.isOffline
          : isOffline // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$QuizAttemptStateImpl implements _QuizAttemptState {
  const _$QuizAttemptStateImpl(
      {this.phase = QuizAttemptPhase.loading,
      this.quizSet,
      final List<QuizQuestionDto> questions = const <QuizQuestionDto>[],
      final Map<String, String> answers = const <String, String>{},
      this.attemptId,
      this.currentQuestionIndex = 0,
      this.remainingSeconds,
      this.result,
      this.errorMessage,
      this.isOffline = false})
      : _questions = questions,
        _answers = answers;

  @override
  @JsonKey()
  final QuizAttemptPhase phase;
  @override
  final QuizSetDto? quizSet;
  final List<QuizQuestionDto> _questions;
  @override
  @JsonKey()
  List<QuizQuestionDto> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  final Map<String, String> _answers;
  @override
  @JsonKey()
  Map<String, String> get answers {
    if (_answers is EqualUnmodifiableMapView) return _answers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_answers);
  }

  @override
  final String? attemptId;
  @override
  @JsonKey()
  final int currentQuestionIndex;
  @override
  final int? remainingSeconds;
  @override
  final QuizResultDto? result;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final bool isOffline;

  @override
  String toString() {
    return 'QuizAttemptState(phase: $phase, quizSet: $quizSet, questions: $questions, answers: $answers, attemptId: $attemptId, currentQuestionIndex: $currentQuestionIndex, remainingSeconds: $remainingSeconds, result: $result, errorMessage: $errorMessage, isOffline: $isOffline)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizAttemptStateImpl &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.quizSet, quizSet) || other.quizSet == quizSet) &&
            const DeepCollectionEquality()
                .equals(other._questions, _questions) &&
            const DeepCollectionEquality().equals(other._answers, _answers) &&
            (identical(other.attemptId, attemptId) ||
                other.attemptId == attemptId) &&
            (identical(other.currentQuestionIndex, currentQuestionIndex) ||
                other.currentQuestionIndex == currentQuestionIndex) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isOffline, isOffline) ||
                other.isOffline == isOffline));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      phase,
      quizSet,
      const DeepCollectionEquality().hash(_questions),
      const DeepCollectionEquality().hash(_answers),
      attemptId,
      currentQuestionIndex,
      remainingSeconds,
      result,
      errorMessage,
      isOffline);

  /// Create a copy of QuizAttemptState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizAttemptStateImplCopyWith<_$QuizAttemptStateImpl> get copyWith =>
      __$$QuizAttemptStateImplCopyWithImpl<_$QuizAttemptStateImpl>(
          this, _$identity);
}

abstract class _QuizAttemptState implements QuizAttemptState {
  const factory _QuizAttemptState(
      {final QuizAttemptPhase phase,
      final QuizSetDto? quizSet,
      final List<QuizQuestionDto> questions,
      final Map<String, String> answers,
      final String? attemptId,
      final int currentQuestionIndex,
      final int? remainingSeconds,
      final QuizResultDto? result,
      final String? errorMessage,
      final bool isOffline}) = _$QuizAttemptStateImpl;

  @override
  QuizAttemptPhase get phase;
  @override
  QuizSetDto? get quizSet;
  @override
  List<QuizQuestionDto> get questions;
  @override
  Map<String, String> get answers;
  @override
  String? get attemptId;
  @override
  int get currentQuestionIndex;
  @override
  int? get remainingSeconds;
  @override
  QuizResultDto? get result;
  @override
  String? get errorMessage;
  @override
  bool get isOffline;

  /// Create a copy of QuizAttemptState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizAttemptStateImplCopyWith<_$QuizAttemptStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

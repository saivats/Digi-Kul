// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_attempt_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$quizAttemptHash() => r'382271d7a1987430c0af6f4768d2e542b419b3eb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$QuizAttempt
    extends BuildlessAutoDisposeNotifier<QuizAttemptState> {
  late final String quizSetId;

  QuizAttemptState build(
    String quizSetId,
  );
}

/// See also [QuizAttempt].
@ProviderFor(QuizAttempt)
const quizAttemptProvider = QuizAttemptFamily();

/// See also [QuizAttempt].
class QuizAttemptFamily extends Family<QuizAttemptState> {
  /// See also [QuizAttempt].
  const QuizAttemptFamily();

  /// See also [QuizAttempt].
  QuizAttemptProvider call(
    String quizSetId,
  ) {
    return QuizAttemptProvider(
      quizSetId,
    );
  }

  @override
  QuizAttemptProvider getProviderOverride(
    covariant QuizAttemptProvider provider,
  ) {
    return call(
      provider.quizSetId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'quizAttemptProvider';
}

/// See also [QuizAttempt].
class QuizAttemptProvider
    extends AutoDisposeNotifierProviderImpl<QuizAttempt, QuizAttemptState> {
  /// See also [QuizAttempt].
  QuizAttemptProvider(
    String quizSetId,
  ) : this._internal(
          () => QuizAttempt()..quizSetId = quizSetId,
          from: quizAttemptProvider,
          name: r'quizAttemptProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$quizAttemptHash,
          dependencies: QuizAttemptFamily._dependencies,
          allTransitiveDependencies:
              QuizAttemptFamily._allTransitiveDependencies,
          quizSetId: quizSetId,
        );

  QuizAttemptProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.quizSetId,
  }) : super.internal();

  final String quizSetId;

  @override
  QuizAttemptState runNotifierBuild(
    covariant QuizAttempt notifier,
  ) {
    return notifier.build(
      quizSetId,
    );
  }

  @override
  Override overrideWith(QuizAttempt Function() create) {
    return ProviderOverride(
      origin: this,
      override: QuizAttemptProvider._internal(
        () => create()..quizSetId = quizSetId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        quizSetId: quizSetId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<QuizAttempt, QuizAttemptState>
      createElement() {
    return _QuizAttemptProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is QuizAttemptProvider && other.quizSetId == quizSetId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, quizSetId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin QuizAttemptRef on AutoDisposeNotifierProviderRef<QuizAttemptState> {
  /// The parameter `quizSetId` of this provider.
  String get quizSetId;
}

class _QuizAttemptProviderElement
    extends AutoDisposeNotifierProviderElement<QuizAttempt, QuizAttemptState>
    with QuizAttemptRef {
  _QuizAttemptProviderElement(super.provider);

  @override
  String get quizSetId => (origin as QuizAttemptProvider).quizSetId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

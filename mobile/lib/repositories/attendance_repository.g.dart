// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$attendanceRepositoryHash() =>
    r'732b6f30ec5d1b3d5bd95bfda8bf5c3d011c9af7';

/// See also [attendanceRepository].
@ProviderFor(attendanceRepository)
final attendanceRepositoryProvider =
    AutoDisposeProvider<AttendanceRepository>.internal(
  attendanceRepository,
  name: r'attendanceRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$attendanceRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AttendanceRepositoryRef = AutoDisposeProviderRef<AttendanceRepository>;
String _$attendanceHash() => r'4f0639c63ec923ac4509cd0f823d76f04160dcb3';

/// See also [attendance].
@ProviderFor(attendance)
final attendanceProvider =
    AutoDisposeFutureProvider<List<AttendanceDto>>.internal(
  attendance,
  name: r'attendanceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$attendanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AttendanceRef = AutoDisposeFutureProviderRef<List<AttendanceDto>>;
String _$attendanceSummaryHash() => r'3093c40f41ce81d5c917cad3ca16195672873fd4';

/// See also [attendanceSummary].
@ProviderFor(attendanceSummary)
final attendanceSummaryProvider =
    AutoDisposeFutureProvider<AttendanceSummary>.internal(
  attendanceSummary,
  name: r'attendanceSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$attendanceSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AttendanceSummaryRef = AutoDisposeFutureProviderRef<AttendanceSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

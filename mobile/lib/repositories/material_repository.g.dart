// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$materialRepositoryHash() =>
    r'0f0903e520eae9f105819fd7c88b16de50677c54';

/// See also [materialRepository].
@ProviderFor(materialRepository)
final materialRepositoryProvider =
    AutoDisposeProvider<MaterialRepository>.internal(
  materialRepository,
  name: r'materialRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$materialRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MaterialRepositoryRef = AutoDisposeProviderRef<MaterialRepository>;
String _$materialsHash() => r'86cbd4a2704afd8b00d132078e9ee80028159521';

/// See also [materials].
@ProviderFor(materials)
final materialsProvider = AutoDisposeFutureProvider<List<MaterialDto>>.internal(
  materials,
  name: r'materialsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$materialsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MaterialsRef = AutoDisposeFutureProviderRef<List<MaterialDto>>;
String _$downloadProgressHash() => r'8f47ef30e60da5392bfd892408b569f7c36b1c69';

/// See also [DownloadProgress].
@ProviderFor(DownloadProgress)
final downloadProgressProvider =
    AutoDisposeNotifierProvider<DownloadProgress, Map<String, double>>.internal(
  DownloadProgress.new,
  name: r'downloadProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$downloadProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DownloadProgress = AutoDisposeNotifier<Map<String, double>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

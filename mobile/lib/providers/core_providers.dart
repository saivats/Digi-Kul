import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/network/api_client.dart';
import '../core/network/dio_client.dart';
import '../core/storage/isar_service.dart';
import '../repositories/auth_repository.dart';

part 'core_providers.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isar(Ref ref) async {
  return IsarService.instance;
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  return ApiClient(DioClient.instance);
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(apiClientProvider));
}

@riverpod
Stream<DateTime> clockTick(Ref ref) {
  return Stream.periodic(
    const Duration(seconds: 30),
    (_) => DateTime.now(),
  );
}

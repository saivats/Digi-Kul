import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:workmanager/workmanager.dart';

import '../background/background_tasks.dart';

enum ConnectionType { wifi, mobile, none }

class ConnectivityState {
  const ConnectivityState({
    required this.isOnline,
    required this.connectionType,
  });

  final bool isOnline;
  final ConnectionType connectionType;

  static const offline = ConnectivityState(
    isOnline: false,
    connectionType: ConnectionType.none,
  );
}

class ConnectivityService {
  ConnectivityService._();

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  static final _connectivity = Connectivity();
  static ConnectivityState _lastState = ConnectivityState.offline;

  static Stream<ConnectivityState> get stream {
    return _connectivity.onConnectivityChanged.asyncMap((results) async {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      final state = _mapResult(result);
      if (!_lastState.isOnline && state.isOnline) {
        await Workmanager().registerOneOffTask(
          '$syncPendingTaskName-${DateTime.now().millisecondsSinceEpoch}',
          syncPendingTaskName,
          constraints: Constraints(networkType: NetworkType.connected),
        );
      }
      _lastState = state;
      return state;
    });
  }

  static Future<ConnectivityState> check() async {
    final results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final state = _mapResult(result);
    _logger.d('Connectivity check: ${state.connectionType}');
    return state;
  }

  static ConnectivityState _mapResult(ConnectivityResult result) {
    return switch (result) {
      ConnectivityResult.wifi => const ConnectivityState(
          isOnline: true,
          connectionType: ConnectionType.wifi,
        ),
      ConnectivityResult.mobile => const ConnectivityState(
          isOnline: true,
          connectionType: ConnectionType.mobile,
        ),
      ConnectivityResult.ethernet => const ConnectivityState(
          isOnline: true,
          connectionType: ConnectionType.wifi,
        ),
      _ => ConnectivityState.offline,
    };
  }
}

final connectivityStreamProvider = StreamProvider<ConnectivityState>((ref) {
  return ConnectivityService.stream;
});

final connectivityProvider = Provider<ConnectivityState>((ref) {
  final asyncState = ref.watch(connectivityStreamProvider);
  return asyncState.valueOrNull ?? ConnectivityState.offline;
});

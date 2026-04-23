import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../models/session/session_state.dart';

class BandwidthMonitor {
  BandwidthMonitor({
    required this.onModeRecommendation,
    String? authToken,
  }) : _authToken = authToken;

  final void Function(SessionMode mode) onModeRecommendation;
  final String? _authToken;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Timer? _timer;
  int _lastEstimateKbps = 0;

  int get lastEstimateKbps => _lastEstimateKbps;

  Future<int> runProbe() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers:
            _authToken != null ? {'Authorization': 'Bearer $_authToken'} : null,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      final stopwatch = Stopwatch()..start();
      final response = await dio.get('/health');
      stopwatch.stop();

      final responseBytes = response.data.toString().length;
      final elapsedMs = stopwatch.elapsedMilliseconds.clamp(1, 30000);
      final kbps = ((responseBytes * 8) / elapsedMs * 1000 / 1024).round();

      _lastEstimateKbps = kbps.clamp(0, 100000);
      _logger.i('Bandwidth probe: $_lastEstimateKbps kbps ($elapsedMs ms)');

      onModeRecommendation(determineModeFromBandwidth(_lastEstimateKbps));
      return _lastEstimateKbps;
    } catch (e) {
      _logger.w('Bandwidth probe failed: $e');
      _lastEstimateKbps = 0;
      onModeRecommendation(SessionMode.text);
      return 0;
    }
  }

  void startPeriodicMonitoring(
      {Duration interval = const Duration(seconds: 10)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => runProbe());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static SessionMode determineModeFromBandwidth(int kbps) {
    if (kbps >= 500) return SessionMode.video;
    if (kbps >= 64) return SessionMode.audio;
    return SessionMode.text;
  }

  void dispose() {
    stop();
  }
}

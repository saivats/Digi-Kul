import '../constants/app_constants.dart';

enum BandwidthMode { full, audioOnly, chatOnly }

class BandwidthUtils {
  BandwidthUtils._();

  static BandwidthMode determineMode({
    required int speedKbps,
    required int rttMs,
  }) {
    if (speedKbps > AppConstants.bandwidthFullThresholdKbps &&
        rttMs < AppConstants.rttFullThresholdMs) {
      return BandwidthMode.full;
    }

    if (speedKbps >= AppConstants.bandwidthAudioThresholdKbps &&
        rttMs < AppConstants.rttAudioThresholdMs) {
      return BandwidthMode.audioOnly;
    }

    return BandwidthMode.chatOnly;
  }

  static String modeLabel(BandwidthMode mode) {
    return switch (mode) {
      BandwidthMode.full => 'Full Mode',
      BandwidthMode.audioOnly => 'Audio Only Mode',
      BandwidthMode.chatOnly => 'Text Only Mode',
    };
  }

  static String modeDescription(BandwidthMode mode) {
    return switch (mode) {
      BandwidthMode.full =>
        'Audio and video streaming available.',
      BandwidthMode.audioOnly =>
        'Low bandwidth detected. Audio only.',
      BandwidthMode.chatOnly =>
        'Very low bandwidth. Chat is available.',
    };
  }

  static String formatSpeed(int kbps) {
    if (kbps < 1024) return '$kbps Kbps';
    return '${(kbps / 1024).toStringAsFixed(1)} Mbps';
  }
}

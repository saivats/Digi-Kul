import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/app_colors.dart';

// Network status provider
final networkStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

class NetworkStatusIndicator extends ConsumerWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (status) => _buildIndicator(status),
      loading: () => _buildIndicator(ConnectivityResult.none),
      error: (_, __) => _buildIndicator(ConnectivityResult.none),
    );
  }

  Widget _buildIndicator(ConnectivityResult status) {
    Color color;
    IconData icon;
    String tooltip;

    switch (status) {
      case ConnectivityResult.wifi:
        color = AppColors.networkGood;
        icon = Icons.wifi;
        tooltip = 'Connected via WiFi';
        break;
      case ConnectivityResult.mobile:
        color = AppColors.networkPoor;
        icon = Icons.signal_cellular_4_bar;
        tooltip = 'Connected via Mobile Data';
        break;
      case ConnectivityResult.ethernet:
        color = AppColors.networkGood;
        icon = Icons.cable;
        tooltip = 'Connected via Ethernet';
        break;
      case ConnectivityResult.bluetooth:
        color = AppColors.networkPoor;
        icon = Icons.bluetooth;
        tooltip = 'Connected via Bluetooth';
        break;
      case ConnectivityResult.vpn:
        color = AppColors.networkGood;
        icon = Icons.vpn_key;
        tooltip = 'Connected via VPN';
        break;
      case ConnectivityResult.other:
        color = AppColors.networkPoor;
        icon = Icons.device_unknown;
        tooltip = 'Connected via Other';
        break;
      case ConnectivityResult.none:
      default:
        color = AppColors.networkOffline;
        icon = Icons.wifi_off;
        tooltip = 'No Internet Connection';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

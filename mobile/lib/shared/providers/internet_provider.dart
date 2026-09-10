import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../../core/config/app_config.dart';
import '../widgets/no_connection_overlay.dart';

Future<bool> checkInternet() async {
  try {
    final hasInternet = await InternetConnection().hasInternetAccess.timeout(
          const Duration(seconds: 2),
          onTimeout: () => false,
        );
    if (hasInternet) return true;

    final baseUrlStr = AppConfig.baseUrl;
    if (baseUrlStr.isNotEmpty) {
      final uri = Uri.parse(baseUrlStr);
      if (uri.hasAuthority && uri.host.isNotEmpty) {
        final port =
            uri.port != 0 ? uri.port : (uri.scheme == 'https' ? 443 : 80);
        final socket = await Socket.connect(
          uri.host,
          port,
          timeout: const Duration(seconds: 2),
        );
        socket.destroy();
        return true;
      }
    }
  } catch (_) {}
  return false;
}

Future<bool> checkInternetWithLoader(BuildContext context, WidgetRef ref) async {
  final isConnected = await checkInternet();

  if (!isConnected) {
    ref.read(showNoInternetOverlayProvider.notifier).state = true;
  }

  return isConnected;
}

class InternetNotifier extends Notifier<bool> {
  Timer? _timer;
  bool _hasShownOfflineToast = false;
  bool _lastState = true;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());

    checkInternet().then((connected) {
      _lastState = connected;
      state = connected;
      if (connected) {
        _hasShownOfflineToast = false;
      } else {
        _showOfflineToast();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final isConnected = await checkInternet();
      if (isConnected == _lastState) return;
      _lastState = isConnected;
      state = isConnected;
      if (isConnected) {
        _hasShownOfflineToast = false;
      } else {
        _showOfflineToast();
      }
    });

    return true;
  }

  void _showOfflineToast() {
    if (_hasShownOfflineToast) return;
    _hasShownOfflineToast = true;

    Fluttertoast.showToast(
      msg: 'Pas de connexion Internet\nMode hors ligne activé.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF333333),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 14,
    );
  }
}

final internetProvider =
    NotifierProvider<InternetNotifier, bool>(InternetNotifier.new);

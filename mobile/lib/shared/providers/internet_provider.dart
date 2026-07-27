import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../widgets/no_connection_overlay.dart';

Future<bool> checkInternet() async {
  try {
    return await InternetConnection().hasInternetAccess.timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        );
  } catch (_) {
    return false;
  }
}

Future<bool> checkInternetWithLoader(BuildContext context, WidgetRef ref) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    ),
  );

  final isConnected = await checkInternet();

  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }

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
      if (!connected) _showOfflineToast();
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
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

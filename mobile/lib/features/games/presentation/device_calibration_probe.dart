import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import '../domain/entities/device_calibration.dart';

/// Sonde de calibrage APPAREIL (méthode « technique » pure).
///
/// Collecte le profil matériel (taux de rafraîchissement, cœurs, catégorie) et
/// mesure la latence machine « entrée → frame » sur toute la session. Si aucune
/// mesure directe n'est disponible, bascule en `hardware_profile_fallback`
/// (fiabilité réduite). Les essais d'échauffement ne l'alimentent jamais : la
/// mesure est purement technique.
class DeviceCalibrationProbe {
  final List<double> _inputLatencySamplesMs = [];

  /// Mesure la latence machine entre une entrée et la frame suivante, en ms.
  /// À appeler au moment où une entrée utilisateur est traitée (hors échauffement).
  void sampleInputLatency() {
    final watch = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      watch.stop();
      _inputLatencySamplesMs.add(watch.elapsedMicroseconds / 1000.0);
    });
  }

  void reset() => _inputLatencySamplesMs.clear();

  /// Construit le calibrage à soumettre. [inputMode] est fourni par le jeu.
  DeviceCalibration build({required InputMode inputMode}) {
    final refreshRateHz = _detectRefreshRateHz();
    final concurrency = _detectHardwareConcurrency();
    final category = _detectCategory();

    final samples = List<double>.from(_inputLatencySamplesMs)..sort();
    if (samples.isEmpty) {
      // Fallback (guide, section 5) : profil matériel seul, fiabilité réduite.
      return DeviceCalibration(
        calibrationMethod: CalibrationMethod.hardwareProfileFallback,
        inputMode: inputMode,
        deviceCategory: category,
        refreshRateHz: refreshRateHz,
        hardwareConcurrency: concurrency,
        inputProcessingLatencyMs: null,
      );
    }
    return DeviceCalibration(
      calibrationMethod: CalibrationMethod.technique,
      inputMode: inputMode,
      deviceCategory: category,
      refreshRateHz: refreshRateHz,
      hardwareConcurrency: concurrency,
      inputProcessingLatencyMs: _median(samples),
    );
  }

  double _detectRefreshRateHz() {
    try {
      final display =
          WidgetsBinding.instance.platformDispatcher.views.first.display;
      final hz = display.refreshRate;
      if (hz.isFinite && hz > 0) return hz;
    } catch (_) {
      // ignore — défaut ci-dessous
    }
    return 60.0;
  }

  int? _detectHardwareConcurrency() {
    try {
      return Platform.numberOfProcessors;
    } catch (_) {
      return null;
    }
  }

  DeviceCategory _detectCategory() {
    try {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return DeviceCategory.desktop;
      }
    } catch (_) {
      // ignore — plateforme non io
    }
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final logical = view.physicalSize / view.devicePixelRatio;
      return logical.shortestSide >= 600
          ? DeviceCategory.tablet
          : DeviceCategory.mobile;
    } catch (_) {
      return DeviceCategory.mobile;
    }
  }

  static double _median(List<double> sorted) {
    final n = sorted.length;
    if (n == 0) return 0;
    if (n.isOdd) return sorted[n ~/ 2];
    return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;
  }
}

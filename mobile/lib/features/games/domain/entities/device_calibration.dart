/// Méthode de calibrage appareil. Aligné sur CalibrationMethod du contrat.
enum CalibrationMethod {
  technique('technique'),
  hardwareProfileFallback('hardware_profile_fallback');

  final String wire;
  const CalibrationMethod(this.wire);
}

/// Mode d'entrée. Aligné sur InputMode du contrat.
enum InputMode {
  keyboard('keyboard'),
  touch('touch'),
  mouse('mouse'),
  swipe('swipe');

  final String wire;
  const InputMode(this.wire);
}

/// Catégorie d'appareil. Aligné sur DeviceCategory du contrat.
enum DeviceCategory {
  mobile('mobile'),
  tablet('tablet'),
  desktop('desktop');

  final String wire;
  const DeviceCategory(this.wire);
}

/// Socle de calibrage APPAREIL (méthode « technique » pure).
///
/// Sépare la latence machine du temps de réaction cognitif. Envoyé (optionnel)
/// avec chaque soumission de résultat. `displayLatencyMs` et `calibrationOffsetMs`
/// sont calculés côté serveur — le client n'envoie que des mesures brutes.
class DeviceCalibration {
  const DeviceCalibration({
    required this.calibrationMethod,
    required this.inputMode,
    required this.deviceCategory,
    required this.refreshRateHz,
    this.hardwareConcurrency,
    this.deviceMemoryGb,
    this.inputProcessingLatencyMs,
  });

  final CalibrationMethod calibrationMethod;
  final InputMode inputMode;
  final DeviceCategory deviceCategory;
  final double refreshRateHz;
  final int? hardwareConcurrency;
  final double? deviceMemoryGb;
  final double? inputProcessingLatencyMs;

  /// Latence d'affichage théorique — miroir de DeviceCalibration.displayLatencyMs.
  double get displayLatencyMs => (1000.0 / refreshRateHz) / 2.0;

  /// Offset technique = latence affichage + traitement d'entrée — miroir backend.
  /// (Le serveur reste la source autoritaire ; ce getter sert au mock hors-ligne.)
  double get calibrationOffsetMs =>
      displayLatencyMs + (inputProcessingLatencyMs ?? 0.0);

  Map<String, dynamic> toJson() => {
    'calibrationMethod': calibrationMethod.wire,
    'inputMode': inputMode.wire,
    'deviceCategory': deviceCategory.wire,
    'refreshRateHz': refreshRateHz,
    'hardwareConcurrency': hardwareConcurrency,
    'deviceMemoryGb': deviceMemoryGb,
    'inputProcessingLatencyMs': inputProcessingLatencyMs,
  };
}

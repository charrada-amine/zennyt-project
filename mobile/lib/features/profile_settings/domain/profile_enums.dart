/// Mapping helpers between the human-readable labels used in the profile UI and
/// the wire enum values defined by the identity contract (`ProfileInput`).
///
/// Keeping both directions in one place avoids drift between the load (wire ->
/// label) and save (label -> wire) paths.
class ProfileEnums {
  ProfileEnums._();

  // ── Workplace type (ONSITE | REMOTE | HYBRID | FLEXIBLE) ──
  static const Map<String, String> _workplaceToWire = {
    'On-site': 'ONSITE',
    'Remote': 'REMOTE',
    'Hybrid': 'HYBRID',
    'Flexible': 'FLEXIBLE',
  };
  static const Map<String, String> _workplaceFromWire = {
    'ONSITE': 'On-site',
    'REMOTE': 'Remote',
    'HYBRID': 'Hybrid',
    'FLEXIBLE': 'Flexible',
  };

  static String? workplaceToWire(String? label) =>
      label == null ? null : _workplaceToWire[label];

  static String workplaceFromWire(String? wire) =>
      _workplaceFromWire[wire] ?? 'Flexible';

  // ── Job type (FULL_TIME | PART_TIME | INTERNSHIP | FREELANCE | CONTRACT) ──
  static const Map<String, String> _jobTypeToWire = {
    'Full time': 'FULL_TIME',
    'Part time': 'PART_TIME',
    'Contract': 'CONTRACT',
    'Freelance': 'FREELANCE',
    'Internship': 'INTERNSHIP',
  };
  static const Map<String, String> _jobTypeFromWire = {
    'FULL_TIME': 'Full time',
    'PART_TIME': 'Part time',
    'CONTRACT': 'Contract',
    'FREELANCE': 'Freelance',
    'INTERNSHIP': 'Internship',
  };

  static String? jobTypeToWire(String? label) =>
      label == null ? null : _jobTypeToWire[label];

  static String jobTypeFromWire(String? wire) =>
      _jobTypeFromWire[wire] ?? 'Full time';

  /// Availability type wire values.
  static const String availabilityImmediately = 'IMMEDIATELY';
  static const String availabilitySelectDate = 'SELECT_DATE';
}

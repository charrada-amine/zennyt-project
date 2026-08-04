import 'package:equatable/equatable.dart';

/// Entité métier Job — pure, sans dépendance framework ni sérialisation.
///
/// C'est l'objet que manipule le domaine et la présentation. La couche data
/// possède un JobModel séparé (avec fromJson) qui se mappe vers cette entité.
class Job extends Equatable {
  final String id;
  final String title;
  final String companyName;
  final String location;
  final bool remoteAllowed;
  final String contractType;
  final String experienceLevel;
  final String? salaryRange;
  final List<String> requiredSkills;
  final bool hasApplied;

  const Job({
    required this.id,
    required this.title,
    required this.companyName,
    required this.location,
    required this.remoteAllowed,
    required this.contractType,
    required this.experienceLevel,
    this.salaryRange,
    this.requiredSkills = const [],
    this.hasApplied = false,
  });

  @override
  List<Object?> get props =>
      [id, title, companyName, location, remoteAllowed, contractType,
       experienceLevel, salaryRange, requiredSkills, hasApplied];
}

import 'package:equatable/equatable.dart';

/// Critères de recherche d'offres (Value Object de domaine).
class JobFilter extends Equatable {
  final String? query;
  final String? location;
  final String? contractType;
  final bool? remoteAllowed;

  const JobFilter({this.query, this.location, this.contractType, this.remoteAllowed});

  @override
  List<Object?> get props => [query, location, contractType, remoteAllowed];
}

import 'package:equatable/equatable.dart';

class JobOpportunity extends Equatable {
  final String position;
  final String salary;
  final String description;
  final DateTime timestamp;

  const JobOpportunity({
    required this.position,
    required this.salary,
    required this.description,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [position, salary, description, timestamp];
}

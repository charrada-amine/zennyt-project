import '../../domain/entities/job_opportunity.dart';

class JobOpportunityModel {
  final String position;
  final String salary;
  final String description;
  final DateTime timestamp;

  const JobOpportunityModel({
    required this.position,
    required this.salary,
    required this.description,
    required this.timestamp,
  });

  factory JobOpportunityModel.fromJson(Map<String, dynamic> json) {
    return JobOpportunityModel(
      position: json['position'] as String,
      salary: json['salary'] as String,
      description: json['description'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] * 1000).toInt(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'position': position,
        'salary': salary,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
      };

  JobOpportunity toEntity() => JobOpportunity(
        position: position,
        salary: salary,
        description: description,
        timestamp: timestamp,
      );
}

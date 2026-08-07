import 'package:equatable/equatable.dart';

/// Offre publiée par le recruteur (liste "Your Job Offers" + détail).
class RecruiterJobOffer extends Equatable {
  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final List<String> tags;
  final String postedAgo;
  final int candidates;
  final int successRate;

  const RecruiterJobOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    this.tags = const [],
    this.postedAgo = '',
    this.candidates = 0,
    this.successRate = 0,
  });

  @override
  List<Object?> get props =>
      [id, title, company, location, salary, tags, postedAgo, candidates, successRate];
}

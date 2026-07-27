import 'package:equatable/equatable.dart';

class HelpChat extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String time;

  const HelpChat({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  List<Object?> get props => [id, title, subtitle, time];
}

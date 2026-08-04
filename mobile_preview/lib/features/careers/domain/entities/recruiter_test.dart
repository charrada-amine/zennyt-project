import 'package:equatable/equatable.dart';

/// Un test créé par le recruteur (banque de tests "Your Tests").
class RecruiterTest extends Equatable {
  final String id;
  final String name;
  const RecruiterTest({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

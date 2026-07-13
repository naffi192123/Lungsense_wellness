import 'package:equatable/equatable.dart';

/// Pure entity representing a medical condition loaded from the database.
class MedicalConditionEntity extends Equatable {
  final String id;
  final String name;
  final String? description;

  const MedicalConditionEntity({
    required this.id,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, description];
}

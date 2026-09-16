import 'package:equatable/equatable.dart';

/// Entity representing a self-reported patient diagnosis.
class DiagnosisEntity extends Equatable {
  final String? id;
  final String? userId;
  final String diagnosis;
  final String? notes;
  final DateTime? createdAt;

  const DiagnosisEntity({
    this.id,
    this.userId,
    required this.diagnosis,
    this.notes,
    this.createdAt,
  });

  factory DiagnosisEntity.fromJson(Map<String, dynamic> json) {
    return DiagnosisEntity(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      diagnosis: json['diagnosis'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'diagnosis': diagnosis,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, diagnosis, notes, createdAt];
}

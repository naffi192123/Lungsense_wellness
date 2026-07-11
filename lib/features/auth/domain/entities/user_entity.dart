import 'package:equatable/equatable.dart';

/// Pure Dart entity representing a authenticated user in the Domain layer.
class UserEntity extends Equatable {
  /// Unique identifier of the user.
  final String id;

  /// Primary email address of the user.
  final String email;

  /// Optional display name.
  final String? name;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
  });

  @override
  List<Object?> get props => [id, email, name];
}

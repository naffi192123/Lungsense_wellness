import 'package:equatable/equatable.dart';

/// Pure Dart entity representing a authenticated user in the Domain layer.
class UserEntity extends Equatable {
  /// Unique identifier of the user.
  final String id;

  /// Primary email address of the user.
  final String email;

  /// Optional display name.
  final String? name;

  /// Verification status of the user's email address.
  final bool isEmailVerified;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.isEmailVerified = false,
  });

  @override
  List<Object?> get props => [id, email, name, isEmailVerified];
}

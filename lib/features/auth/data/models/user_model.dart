import '../../domain/entities/user_entity.dart';

/// Data layer model representing a user.
/// Inherits from [UserEntity] and provides mapping capabilities.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.isEmailVerified = false,
  });

  /// Factory method to map a JSON map to our [UserModel].
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['full_name'] as String?,
      isEmailVerified: true,
    );
  }
}

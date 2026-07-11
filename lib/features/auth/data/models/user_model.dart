import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/user_entity.dart';

/// Data layer model representing a user.
/// Inherits from [UserEntity] and provides mapping capabilities from Supabase models.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
  });

  /// Factory method to map a Supabase SDK [supabase.User] to our [UserModel].
  factory UserModel.fromSupabase(supabase.User user) {
    final metadata = user.userMetadata;
    final displayName = metadata?['name'] as String? ?? metadata?['full_name'] as String?;
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: displayName,
    );
  }
}

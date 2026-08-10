import 'dart:convert';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

/// Model representing backend user profile.
class ProfileModel {
  final String id;
  final String userId;
  final String email;
  final String? fullName;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.email,
    this.fullName,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json, {String? email, String? fullName}) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      email: email ?? json['email'] as String? ?? '',
      fullName: fullName ?? json['full_name'] as String?,
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
    };
  }
}

/// Contract for backend profile management operations.
abstract class ProfileRemoteDataSource {
  /// Fetch profile from GET /profile and GET /auth/me.
  Future<ProfileModel> getProfile();

  /// Update profile via PUT /profile and local cache.
  Future<ProfileModel> updateProfile({
    String? fullName,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
  });

  /// Request password reset OTP code.
  Future<void> requestPasswordReset(String email);

  /// Change/Reset password with OTP code.
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });
}

/// Implementation of ProfileRemoteDataSource.
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSourceImpl(this.apiClient);

  @override
  Future<ProfileModel> getProfile() async {
    try {
      // First get identity from /auth/me
      String email = apiClient.userEmail ?? '';
      String? fullName = apiClient.userName;

      final meRes = await apiClient.get('/auth/me');
      if (meRes.statusCode == 200) {
        final meData = jsonDecode(meRes.body);
        email = meData['email'] as String? ?? email;
        fullName = meData['full_name'] as String? ?? fullName;
      }

      final res = await apiClient.get('/profile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final profile = ProfileModel.fromJson(data, email: email, fullName: fullName);

        if (profile.fullName != null && profile.fullName!.isNotEmpty) {
          await apiClient.updateUserName(profile.fullName!);
        }

        return profile;
      } else {
        return ProfileModel(
          id: apiClient.userId ?? '',
          userId: apiClient.userId ?? '',
          email: email,
          fullName: fullName,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    String? fullName,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
  }) async {
    try {
      final body = <String, dynamic>{
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (heightCm != null) 'height_cm': heightCm,
        if (weightKg != null) 'weight_kg': weightKg,
      };

      final response = await apiClient.put('/profile', body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (fullName != null && fullName.isNotEmpty) {
          await apiClient.updateUserName(fullName);
        }

        return ProfileModel.fromJson(
          data,
          email: apiClient.userEmail,
          fullName: fullName ?? apiClient.userName,
        );
      } else {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        final message = detail is String ? detail : detail.toString();
        throw ServerException(message, code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await apiClient.post('/auth/forgot-password', body: {
        'email': email,
      });
      if (response.statusCode != 202 && response.statusCode != 200) {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        final message = detail is String ? detail : detail.toString();
        throw ServerException(message, code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.post('/auth/reset-password', body: {
        'email': email,
        'otp_code': otpCode,
        'new_password': newPassword,
      });

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        final message = detail is String ? detail : detail.toString();
        throw ServerException(message, code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}

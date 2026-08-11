import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Remote DataSource contract to perform network authentication calls.
abstract class AuthRemoteDataSource {
  /// Calls FastAPI login endpoint.
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Calls FastAPI registration endpoint.
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  });

  /// Requests a 6-digit password reset code sent to email.
  Future<void> forgotPassword({
    required String email,
  });

  /// Resets password with 6-digit OTP code.
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otpCode,
    required String newPassword,
  });

  /// Signs out the user and clears stored tokens.
  Future<void> logout();

  /// Gets current active session user details.
  Future<UserModel?> getCurrentUser();

  /// Stream of user session state.
  Stream<UserModel?> get userStream;

  /// Performs Google Sign-In redirect.
  Future<void> signInWithGoogle();
}

/// Remote DataSource implementation executing client API transactions against FastAPI.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final StreamController<UserModel?> _userStreamController = StreamController<UserModel?>.broadcast();

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String? ?? '';
        
        // Decode JWT payload for user metadata
        final jwtPayload = _decodeJwtPayload(accessToken);
        
        final userId = data['user_id'] as String? ?? 
                       data['id'] as String? ?? 
                       jwtPayload?['sub'] as String? ?? 
                       '';
                       
        final userEmail = data['email'] as String? ?? 
                          jwtPayload?['email'] as String? ?? 
                          email;

        // Extract name from JWT or fetch profile
        String? name = jwtPayload?['user_metadata']?['full_name'] as String? ??
                       jwtPayload?['user_metadata']?['name'] as String? ??
                       jwtPayload?['name'] as String?;

        // Save session immediately so subsequent requests are authenticated
        await apiClient.saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: userId,
          email: userEmail,
          name: name,
        );

        // Attempt to fetch profile name if missing from JWT
        if (name == null || name.isEmpty) {
          name = await _fetchProfileName(accessToken);
        }

        final userModel = UserModel(
          id: userId,
          email: userEmail,
          name: name ?? apiClient.userName,
          isEmailVerified: true,
        );

        if (userModel.name != null && userModel.name!.isNotEmpty) {
          await apiClient.updateUserName(userModel.name!);
        }

        _userStreamController.add(userModel);
        return userModel;
      } else {
        final message = _extractErrorMessage(response.body, fallback: 'Invalid email or password.');
        throw AuthException(message, code: response.statusCode.toString());
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await apiClient.post('/auth/register', body: {
        'email': email,
        'password': password,
        'full_name': name,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final emailConfirmationRequired = data['email_confirmation_required'] as bool? ?? false;
        
        final userModel = UserModel(
          id: '',
          email: email,
          name: name,
          isEmailVerified: !emailConfirmationRequired,
        );
        return userModel;
      } else {
        final message = _extractErrorMessage(response.body, fallback: 'Registration failed.');
        throw AuthException(message, code: response.statusCode.toString());
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await apiClient.post('/auth/forgot-password', body: {
        'email': email,
      });
      if (response.statusCode != 202 && response.statusCode != 200) {
        final message = _extractErrorMessage(response.body, fallback: 'Password reset request failed.');
        throw AuthException(message, code: response.statusCode.toString());
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetPasswordWithOtp({
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
        final message = _extractErrorMessage(response.body, fallback: 'Failed to reset password.');
        throw AuthException(message, code: response.statusCode.toString());
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.clearSession();
      _userStreamController.add(null);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final token = apiClient.accessToken;
      if (token == null) {
        return null;
      }

      final id = apiClient.userId ?? '';
      final email = apiClient.userEmail ?? '';
      String? name = apiClient.userName;

      if (name == null || name.isEmpty) {
        name = await _fetchProfileName(token);
      }

      if (id.isNotEmpty && email.isNotEmpty) {
        final userModel = UserModel(
          id: id,
          email: email,
          name: name,
          isEmailVerified: true,
        );
        _userStreamController.add(userModel);
        return userModel;
      }

      final response = await apiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetchedName = data['full_name'] as String? ?? data['name'] as String?;
        final fetchedId = data['id'] as String? ?? data['user_id'] as String? ?? id;
        final fetchedEmail = data['email'] as String? ?? email;

        final userModel = UserModel(
          id: fetchedId,
          email: fetchedEmail,
          name: fetchedName ?? name,
          isEmailVerified: true,
        );

        if (userModel.name != null) {
          await apiClient.updateUserName(userModel.name!);
        }

        _userStreamController.add(userModel);
        return userModel;
      } else {
        await apiClient.clearSession();
        _userStreamController.add(null);
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchProfileName(String token) async {
    try {
      final res = await http.get(
        Uri.parse('https://lungsense-wellness.onrender.com/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fullName = data['full_name'] as String?;
        if (fullName != null && fullName.isNotEmpty) {
          await apiClient.updateUserName(fullName);
          return fullName;
        }
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(String responseBody, {String fallback = 'An error occurred.'}) {
    try {
      final data = jsonDecode(responseBody);
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
        return detail.toString();
      }
      if (data['message'] != null) return data['message'].toString();
    } catch (_) {}
    return fallback;
  }

  @override
  Stream<UserModel?> get userStream => _userStreamController.stream;

  @override
  Future<void> signInWithGoogle() async {
    throw const AuthException('Google Sign-In is not supported natively in this configuration.');
  }
}

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

  /// Requests password reset link.
  Future<void> resetPassword({
    required String email,
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
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;

        // Fetch user info via /auth/me
        final meResponse = await http.get(
          Uri.parse('https://lungsense-wellness.onrender.com/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (meResponse.statusCode == 200) {
          final meData = jsonDecode(meResponse.body);
          String? name = meData['full_name'] as String?;

          // Fetch profile details from /profile if full_name is null
          if (name == null || name.isEmpty) {
            name = await _fetchProfileName(accessToken);
          }

          final userModel = UserModel(
            id: meData['id'] as String,
            email: meData['email'] as String,
            name: name ?? apiClient.userName,
            isEmailVerified: true,
          );

          await apiClient.saveSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: userModel.id,
            email: userModel.email,
            name: userModel.name,
          );

          _userStreamController.add(userModel);
          return userModel;
        } else {
          throw const AuthException('Failed to retrieve user details.');
        }
      } else {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        final message = detail is String ? detail : detail.toString();
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
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        final message = detail is String ? detail : detail.toString();
        throw AuthException(message, code: response.statusCode.toString());
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
  }) async {
    try {
      final response = await apiClient.post('/auth/forgot-password', body: {
        'email': email,
      });
      if (response.statusCode != 202) {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        final message = detail is String ? detail : detail.toString();
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
      final response = await apiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? name = data['full_name'] as String?;

        if (name == null || name.isEmpty) {
          name = await _fetchProfileName(token);
        }

        final userModel = UserModel(
          id: data['id'] as String,
          email: data['email'] as String,
          name: name ?? apiClient.userName,
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

  @override
  Stream<UserModel?> get userStream => _userStreamController.stream;

  @override
  Future<void> signInWithGoogle() async {
    throw const AuthException('Google Sign-In is not supported natively in this configuration.');
  }
}

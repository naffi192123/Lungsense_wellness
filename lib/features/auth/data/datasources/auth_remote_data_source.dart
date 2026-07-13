import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Remote DataSource contract to perform network authentication calls.
abstract class AuthRemoteDataSource {
  /// Calls Supabase sign in.
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Calls Supabase sign up.
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  });

  /// Requests password reset link.
  Future<void> resetPassword({
    required String email,
  });

  /// Signs out the user.
  Future<void> logout();

  /// Gets current active session user.
  Future<UserModel?> getCurrentUser();

  /// Stream of user session state.
  Stream<UserModel?> get userStream;

  /// Performs Google Sign-In redirect.
  Future<void> signInWithGoogle();
}

/// Remote DataSource implementation executing client API transactions.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supabase.SupabaseClient client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const AuthException('Sign in completed, but user details are unavailable.');
      }
      return UserModel.fromSupabase(response.user!);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
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
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      if (response.user == null) {
        throw const AuthException('Registration completed, but user details are unavailable.');
      }
      return UserModel.fromSupabase(response.user!);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
  }) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final sessionResponse = await client.auth.refreshSession();
      final user = sessionResponse.user;
      if (user == null) {
        return null;
      }
      return UserModel.fromSupabase(user);
    } catch (e) {
      final user = client.auth.currentUser;
      if (user == null) {
        return null;
      }
      return UserModel.fromSupabase(user);
    }
  }

  @override
  Stream<UserModel?> get userStream {
    return client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) {
        return null;
      }
      return UserModel.fromSupabase(user);
    });
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await client.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: 'io.supabase.lungsense://login-callback/',
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

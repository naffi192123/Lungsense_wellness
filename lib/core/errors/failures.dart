import 'package:equatable/equatable.dart';

/// Base Failure class representable in the Domain layer.
abstract class Failure extends Equatable {
  /// User-friendly error message.
  final String message;

  /// Optional debug info or code.
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Failure representing server side or API errors.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Failure representing local caching or database errors.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Failure representing internet connectivity or timeout errors.
class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message, {super.code});
}

/// Failure representing validation failures (e.g. invalid email).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Failure representing authentication errors.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

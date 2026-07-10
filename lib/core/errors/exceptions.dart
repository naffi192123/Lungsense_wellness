/// Exception representing failures occurring at the API or Server level.
class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException(this.message, {this.code});

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

/// Exception representing failures in caching or local database operations.
class CacheException implements Exception {
  final String message;
  final String? code;

  const CacheException(this.message, {this.code});

  @override
  String toString() => 'CacheException: $message (code: $code)';
}

/// Exception representing network timeout or lack of internet connectivity.
class ConnectionException implements Exception {
  final String message;

  const ConnectionException(this.message);

  @override
  String toString() => 'ConnectionException: $message';
}

/// Exception representing authentication or authorization failures.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

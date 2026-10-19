import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'network_info.dart';

/// Centralized API client to manage requests to the FastAPI backend.
/// Automatically injects Authorization headers, verifies network connectivity, and handles token refreshes.
class ApiClient {
  final http.Client _client;
  final Box _box;
  final NetworkInfo? _networkInfo;

  /// Centralized API base URL.
  static const String baseUrl = AppConstants.apiBaseUrl;
  static const String _baseUrl = baseUrl;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  ApiClient(this._client, this._box, [this._networkInfo]);

  Future<void> _ensureNetworkAvailable() async {
    if (_networkInfo != null) {
      final hasConnection = await _networkInfo.isConnected;
      if (!hasConnection) {
        throw const ConnectionException('No internet connection. Please verify your Wi-Fi or mobile data.');
      }
    }
  }

  /// Get stored access token.
  String? get accessToken => _box.get(_accessTokenKey) as String?;

  /// Get stored refresh token.
  String? get refreshToken => _box.get(_refreshTokenKey) as String?;

  /// Get stored user ID.
  String? get userId => _box.get(_userIdKey) as String?;

  /// Get stored user email.
  String? get userEmail => _box.get(_userEmailKey) as String?;

  /// Get stored user display name.
  String? get userName => _box.get(_userNameKey) as String?;

  /// Save authentication tokens and session data.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    String? name,
  }) async {
    await _box.put(_accessTokenKey, accessToken);
    await _box.put(_refreshTokenKey, refreshToken);
    await _box.put(_userIdKey, userId);
    await _box.put(_userEmailKey, email);
    if (name != null) {
      await _box.put(_userNameKey, name);
    }
  }

  /// Update the stored user name.
  Future<void> updateUserName(String name) async {
    await _box.put(_userNameKey, name);
  }

  /// Remove all tokens and end session.
  Future<void> clearSession() async {
    await _box.delete(_accessTokenKey);
    await _box.delete(_refreshTokenKey);
    await _box.delete(_userIdKey);
    await _box.delete(_userEmailKey);
    await _box.delete(_userNameKey);
  }

  Map<String, String> _headers({bool isMultipart = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    final token = accessToken;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  MediaType _resolveAudioMediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'm4a':
        return MediaType('audio', 'm4a');
      case 'wav':
        return MediaType('audio', 'wav');
      case 'mp3':
        return MediaType('audio', 'mpeg');
      case 'aac':
        return MediaType('audio', 'aac');
      case 'mp4':
        return MediaType('audio', 'mp4');
      case 'ogg':
        return MediaType('audio', 'ogg');
      case 'webm':
        return MediaType('audio', 'webm');
      default:
        return MediaType('audio', 'm4a');
    }
  }

  /// Perform a HTTP GET request.
  Future<http.Response> get(String path) async {
    await _ensureNetworkAvailable();
    try {
      final uri = Uri.parse('$_baseUrl$path');
      var response = await _client.get(uri, headers: _headers());
      if (response.statusCode == 401) {
        final refreshed = await _attemptRefresh();
        if (refreshed) {
          response = await _client.get(uri, headers: _headers());
        }
      }
      return response;
    } on SocketException catch (_) {
      throw const ConnectionException('Unable to reach backend server. Please check your internet connection.');
    } on http.ClientException catch (_) {
      throw const ConnectionException('Network request failed. Please check your internet connection.');
    }
  }

  /// Perform a HTTP POST request.
  Future<http.Response> post(String path, {dynamic body}) async {
    await _ensureNetworkAvailable();
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final encodedBody = body != null ? jsonEncode(body) : null;
      var response = await _client.post(uri, headers: _headers(), body: encodedBody);
      if (response.statusCode == 401 && path != '/auth/login' && path != '/auth/refresh') {
        final refreshed = await _attemptRefresh();
        if (refreshed) {
          response = await _client.post(uri, headers: _headers(), body: encodedBody);
        }
      }
      return response;
    } on SocketException catch (_) {
      throw const ConnectionException('Unable to reach backend server. Please check your internet connection.');
    } on http.ClientException catch (_) {
      throw const ConnectionException('Network request failed. Please check your internet connection.');
    }
  }

  /// Perform a HTTP PUT request.
  Future<http.Response> put(String path, {dynamic body}) async {
    await _ensureNetworkAvailable();
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final encodedBody = body != null ? jsonEncode(body) : null;
      var response = await _client.put(uri, headers: _headers(), body: encodedBody);
      if (response.statusCode == 401) {
        final refreshed = await _attemptRefresh();
        if (refreshed) {
          response = await _client.put(uri, headers: _headers(), body: encodedBody);
        }
      }
      return response;
    } on SocketException catch (_) {
      throw const ConnectionException('Unable to reach backend server. Please check your internet connection.');
    } on http.ClientException catch (_) {
      throw const ConnectionException('Network request failed. Please check your internet connection.');
    }
  }

  /// Perform a HTTP Multipart POST request for audio uploads.
  Future<http.Response> multipartPost(String path, {required List<int> fileBytes, required String filename}) async {
    await _ensureNetworkAvailable();
    try {
      final uri = Uri.parse('$_baseUrl$path');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
        contentType: _resolveAudioMediaType(filename),
      ));
      request.headers.addAll(_headers(isMultipart: true));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        final refreshed = await _attemptRefresh();
        if (refreshed) {
          request = http.MultipartRequest('POST', uri);
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: filename,
            contentType: _resolveAudioMediaType(filename),
          ));
          request.headers.addAll(_headers(isMultipart: true));
          streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        }
      }
      return response;
    } on SocketException catch (_) {
      throw const ConnectionException('Unable to reach backend server. Please check your internet connection.');
    } on http.ClientException catch (_) {
      throw const ConnectionException('Network request failed. Please check your internet connection.');
    }
  }

  Future<bool> _attemptRefresh() async {
    final token = refreshToken;
    if (token == null) {
      await clearSession();
      return false;
    }
    try {
      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': token}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String?;
        
        // Retain existing user fields
        final uId = userId ?? '';
        final uEmail = userEmail ?? '';
        final uName = userName;

        await saveSession(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? token,
          userId: uId,
          email: uEmail,
          name: uName,
        );
        return true;
      }
    } catch (_) {}
    await clearSession();
    return false;
  }
}

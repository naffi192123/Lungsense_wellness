import 'dart:convert';
import '../../../../core/network/api_client.dart';

/// Remote data source for the History API endpoint.
abstract class HistoryRemoteDataSource {
  /// Fetches history entries from GET /history?limit=...&offset=...
  /// Returns the raw JSON map with 'count' and 'entries' keys.
  Future<Map<String, dynamic>> getHistory({int limit = 50, int offset = 0});
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final ApiClient apiClient;

  HistoryRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> getHistory({int limit = 50, int offset = 0}) async {
    final response = await apiClient.get('/history?limit=$limit&offset=$offset');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      // Handle list response (some backends return a list directly)
      if (data is List) {
        return {
          'count': data.length,
          'entries': data,
        };
      }
      return {'count': 0, 'entries': []};
    }
    // Non-200 — return empty rather than crash
    return {'count': 0, 'entries': []};
  }
}

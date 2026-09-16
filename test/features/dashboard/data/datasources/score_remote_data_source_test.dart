import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/core/network/api_client.dart';
import 'package:lungsense_wellness/features/dashboard/data/datasources/score_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('ScoreRemoteDataSourceImpl - getBaselineStatus', () {
    late ScoreRemoteDataSourceImpl dataSource;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      dataSource = ScoreRemoteDataSourceImpl(mockApiClient);
    });

    test('returns baseline data map when API returns 200 with valid JSON', () async {
      const jsonResponse =
          '{"session_count":7,"status":"active","baseline_mean":78.1,"message":"Your personal baseline is active and updating."}';

      when(() => mockApiClient.get('/score/baseline')).thenAnswer(
        (_) async => http.Response(jsonResponse, 200),
      );

      final result = await dataSource.getBaselineStatus();

      expect(result['status'], equals('active'));
      expect(result['baseline_mean'], equals(78.1));
      expect(result['session_count'], equals(7));
      expect(result['message'], equals('Your personal baseline is active and updating.'));
      verify(() => mockApiClient.get('/score/baseline')).called(1);
    });

    test('returns user-friendly fallback message when baseline is initializing', () async {
      const jsonResponse =
          '{"session_count":1,"status":"initializing","message":"Baseline will be available after a few sessions."}';

      when(() => mockApiClient.get('/score/baseline')).thenAnswer(
        (_) async => http.Response(jsonResponse, 200),
      );

      final result = await dataSource.getBaselineStatus();

      expect(result['status'], equals('initializing'));
      expect(result['baseline_mean'], isNull);
      expect(result['message'], equals('Baseline will be available after a few sessions.'));
    });

    test('returns graceful fallback when API returns empty body', () async {
      when(() => mockApiClient.get('/score/baseline')).thenAnswer(
        (_) async => http.Response('', 200),
      );

      final result = await dataSource.getBaselineStatus();

      expect(result['status'], equals('initializing'));
      expect(result['message'], equals('Baseline will be available after a few sessions.'));
    });

    test('returns graceful fallback when API returns null body', () async {
      when(() => mockApiClient.get('/score/baseline')).thenAnswer(
        (_) async => http.Response('null', 200),
      );

      final result = await dataSource.getBaselineStatus();

      expect(result['status'], equals('initializing'));
      expect(result['message'], equals('Baseline will be available after a few sessions.'));
    });

    test('returns graceful fallback on server error or network exception', () async {
      when(() => mockApiClient.get('/score/baseline')).thenThrow(
        Exception('Network unavailable'),
      );

      final result = await dataSource.getBaselineStatus();

      expect(result['status'], equals('initializing'));
      expect(result['message'], equals('Baseline will be available after a few sessions.'));
    });
  });
}

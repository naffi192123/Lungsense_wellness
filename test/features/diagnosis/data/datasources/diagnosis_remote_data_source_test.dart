import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/core/errors/exceptions.dart';
import 'package:lungsense_wellness/core/network/api_client.dart';
import 'package:lungsense_wellness/features/diagnosis/data/datasources/diagnosis_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('DiagnosisRemoteDataSourceImpl Tests', () {
    late DiagnosisRemoteDataSourceImpl dataSource;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      dataSource = DiagnosisRemoteDataSourceImpl(mockApiClient);
    });

    group('getDiagnosisOptions', () {
      test('returns list of diagnosis strings on HTTP 200', () async {
        when(() => mockApiClient.get('/diagnosis/options')).thenAnswer(
          (_) async => http.Response('["Asthma", "COPD", "Bronchitis"]', 200),
        );

        final result = await dataSource.getDiagnosisOptions();

        expect(result, equals(['Asthma', 'COPD', 'Bronchitis']));
        verify(() => mockApiClient.get('/diagnosis/options')).called(1);
      });

      test('throws ServerException on HTTP non-200', () async {
        when(() => mockApiClient.get('/diagnosis/options')).thenAnswer(
          (_) async => http.Response('Internal Server Error', 500),
        );

        expect(
          () => dataSource.getDiagnosisOptions(),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws ServerException on HTML or empty response', () async {
        when(() => mockApiClient.get('/diagnosis/options')).thenAnswer(
          (_) async => http.Response('<!DOCTYPE html><html>Error</html>', 200),
        );

        expect(
          () => dataSource.getDiagnosisOptions(),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getLatestDiagnosis', () {
      test('returns DiagnosisEntity on HTTP 200 with valid JSON', () async {
        const jsonStr =
            '{"id":"diag_1","diagnosis":"Asthma","notes":"Mild","created_at":"2026-09-16T12:00:00.000Z"}';
        when(() => mockApiClient.get('/diagnosis/latest')).thenAnswer(
          (_) async => http.Response(jsonStr, 200),
        );

        final result = await dataSource.getLatestDiagnosis();

        expect(result, isNotNull);
        expect(result!.diagnosis, equals('Asthma'));
        expect(result.notes, equals('Mild'));
        expect(result.id, equals('diag_1'));
      });

      test('returns null on HTTP 200 with null string or empty', () async {
        when(() => mockApiClient.get('/diagnosis/latest')).thenAnswer(
          (_) async => http.Response('null', 200),
        );

        final result = await dataSource.getLatestDiagnosis();
        expect(result, isNull);
      });

      test('returns null gracefully on HTTP 404', () async {
        when(() => mockApiClient.get('/diagnosis/latest')).thenAnswer(
          (_) async => http.Response('{"detail":"Not found"}', 404),
        );

        final result = await dataSource.getLatestDiagnosis();
        expect(result, isNull);
      });

      test('returns null gracefully on exception', () async {
        when(() => mockApiClient.get('/diagnosis/latest')).thenThrow(
          Exception('Network failed'),
        );

        final result = await dataSource.getLatestDiagnosis();
        expect(result, isNull);
      });
    });

    group('createDiagnosis', () {
      test('sends POST /diagnosis and returns DiagnosisEntity on HTTP 200/201', () async {
        const responseJson =
            '{"id":"diag_2","diagnosis":"COPD","notes":"Moderate","created_at":"2026-09-16T12:05:00.000Z"}';
        when(() => mockApiClient.post(
              '/diagnosis',
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(responseJson, 201));

        final result = await dataSource.createDiagnosis(
          diagnosis: 'COPD',
          notes: 'Moderate',
        );

        expect(result.diagnosis, equals('COPD'));
        expect(result.notes, equals('Moderate'));
        verify(() => mockApiClient.post(
              '/diagnosis',
              body: {'diagnosis': 'COPD', 'notes': 'Moderate'},
            )).called(1);
      });

      test('throws ServerException with detail message on error', () async {
        when(() => mockApiClient.post(
              '/diagnosis',
              body: any(named: 'body'),
            )).thenAnswer(
          (_) async => http.Response('{"detail":"Invalid diagnosis option"}', 422),
        );

        expect(
          () => dataSource.createDiagnosis(diagnosis: 'Unknown'),
          throwsA(predicate<ServerException>(
            (e) => e.message.contains('Invalid diagnosis option'),
          )),
        );
      });
    });
  });
}

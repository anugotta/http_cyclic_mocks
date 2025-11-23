import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_cyclic_mocks/http_cyclic_mocks.dart';

void main() {
  group('MockHttpClient Tests', () {
    late Dio dio;
    late CyclicMockClient mockHttpClient;

    setUp(() {
      dio = Dio();
      mockHttpClient = CyclicMockClient(dio);
    });

    test('Single route, single response', () async {
      mockHttpClient.addMockResponses('/test-route', [
        MockResponse(data: {'message': 'Test Response'}, statusCode: 200),
      ]);

      final response = await dio.get('/test-route');
      expect(response.statusCode, 200);
      expect(response.data, {'message': 'Test Response'});
    });

    test('Single route, multiple responses', () async {
      mockHttpClient.addMockResponses('/test-route', [
        MockResponse(data: {'message': 'Response 1'}, statusCode: 200),
        MockResponse(data: {'message': 'Response 2'}, statusCode: 200),
      ]);

      final response1 = await dio.get('/test-route');
      expect(response1.statusCode, 200);
      expect(response1.data, {'message': 'Response 1'});

      final response2 = await dio.get('/test-route');
      expect(response2.statusCode, 200);
      expect(response2.data, {'message': 'Response 2'});

      final response3 = await dio.get('/test-route');
      expect(response3.statusCode, 200);
      expect(response3.data, {'message': 'Response 1'});
    });

    test('Multiple routes, single response each', () async {
      mockHttpClient.addMockResponses('/route1', [
        MockResponse(data: {'message': 'Route 1 Response'}, statusCode: 200),
      ]);

      mockHttpClient.addMockResponses('/route2', [
        MockResponse(data: {'message': 'Route 2 Response'}, statusCode: 200),
      ]);

      final response1 = await dio.get('/route1');
      expect(response1.statusCode, 200);
      expect(response1.data, {'message': 'Route 1 Response'});

      final response2 = await dio.get('/route2');
      expect(response2.statusCode, 200);
      expect(response2.data, {'message': 'Route 2 Response'});
    });

    test('Route not found', () async {
      try {
        await dio.get('/unknown-route');
        fail('Expected DioError not thrown');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 404);
        expect(e.response?.data, 'Not Found');
      }
    });

    test('HTTP method-specific mocking - GET vs POST', () async {
      mockHttpClient.addMockResponses('/api/users', [
        MockResponse(data: {'users': ['user1', 'user2']}, statusCode: 200),
      ], method: 'GET');

      mockHttpClient.addMockResponses('/api/users', [
        MockResponse(data: {'message': 'User created'}, statusCode: 201),
      ], method: 'POST');

      // GET request
      final getResponse = await dio.get('/api/users');
      expect(getResponse.statusCode, 200);
      expect(getResponse.data, {'users': ['user1', 'user2']});

      // POST request
      final postResponse = await dio.post('/api/users', data: {'name': 'New User'});
      expect(postResponse.statusCode, 201);
      expect(postResponse.data, {'message': 'User created'});
    });

    test('Error status codes throw DioException', () async {
      mockHttpClient.addMockResponses('/error-route', [
        MockResponse(data: {'error': 'Bad Request'}, statusCode: 400),
        MockResponse(data: {'error': 'Not Found'}, statusCode: 404),
        MockResponse(data: {'error': 'Server Error'}, statusCode: 500),
      ]);

      // 400 Bad Request
      try {
        await dio.get('/error-route');
        fail('Expected DioException for 400');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 400);
        expect(e.response?.data, {'error': 'Bad Request'});
      }

      // 404 Not Found
      try {
        await dio.get('/error-route');
        fail('Expected DioException for 404');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 404);
        expect(e.response?.data, {'error': 'Not Found'});
      }

      // 500 Server Error
      try {
        await dio.get('/error-route');
        fail('Expected DioException for 500');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 500);
        expect(e.response?.data, {'error': 'Server Error'});
      }
    });

    test('Custom headers in mock response', () async {
      mockHttpClient.addMockResponses('/headers-route', [
        MockResponse(
          data: {'message': 'Success'},
          statusCode: 200,
          headers: {
            'X-Custom-Header': ['custom-value'],
            'X-Request-ID': ['12345'],
          },
        ),
      ]);

      final response = await dio.get('/headers-route');
      expect(response.statusCode, 200);
      expect(response.headers.value('X-Custom-Header'), 'custom-value');
      expect(response.headers.value('X-Request-ID'), '12345');
    });

    test('String data (non-JSON)', () async {
      mockHttpClient.addMockResponses('/text-route', [
        MockResponse(data: 'Plain text response', statusCode: 200),
      ]);

      final response = await dio.get('/text-route');
      expect(response.statusCode, 200);
      expect(response.data, 'Plain text response');
    });

    test('Empty responses list throws ArgumentError', () {
      expect(
        () => mockHttpClient.addMockResponses('/route', []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Clear all mocks', () async {
      mockHttpClient.addMockResponses('/route1', [
        MockResponse(data: {'message': 'Route 1'}, statusCode: 200),
      ]);

      mockHttpClient.addMockResponses('/route2', [
        MockResponse(data: {'message': 'Route 2'}, statusCode: 200),
      ]);

      // Verify mocks work
      final response1 = await dio.get('/route1');
      expect(response1.statusCode, 200);

      // Clear all
      mockHttpClient.clear();

      // Now route1 should return 404
      try {
        await dio.get('/route1');
        fail('Expected 404 after clear');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 404);
      }
    });

    test('Remove specific route mock', () async {
      mockHttpClient.addMockResponses('/route1', [
        MockResponse(data: {'message': 'Route 1'}, statusCode: 200),
      ]);

      mockHttpClient.addMockResponses('/route2', [
        MockResponse(data: {'message': 'Route 2'}, statusCode: 200),
      ]);

      // Remove route1
      mockHttpClient.removeMockResponses('/route1');

      // route1 should return 404
      try {
        await dio.get('/route1');
        fail('Expected 404 after removal');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 404);
      }

      // route2 should still work
      final response2 = await dio.get('/route2');
      expect(response2.statusCode, 200);
      expect(response2.data, {'message': 'Route 2'});
    });

    test('Remove method-specific mock', () async {
      mockHttpClient.addMockResponses('/api/users', [
        MockResponse(data: {'users': []}, statusCode: 200),
      ], method: 'GET');

      mockHttpClient.addMockResponses('/api/users', [
        MockResponse(data: {'message': 'Created'}, statusCode: 201),
      ], method: 'POST');

      // Remove only GET
      mockHttpClient.removeMockResponses('/api/users', method: 'GET');

      // GET should return 404
      try {
        await dio.get('/api/users');
        fail('Expected 404 for GET after removal');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 404);
      }

      // POST should still work
      final postResponse = await dio.post('/api/users');
      expect(postResponse.statusCode, 201);
    });

    test('Reset counter for route', () async {
      mockHttpClient.addMockResponses('/test-route', [
        MockResponse(data: {'message': 'Response 1'}, statusCode: 200),
        MockResponse(data: {'message': 'Response 2'}, statusCode: 200),
      ]);

      // Get first response
      final response1 = await dio.get('/test-route');
      expect(response1.data, {'message': 'Response 1'});

      // Get second response
      final response2 = await dio.get('/test-route');
      expect(response2.data, {'message': 'Response 2'});

      // Reset counter
      mockHttpClient.resetCounter('/test-route');

      // Should start from first again
      final response3 = await dio.get('/test-route');
      expect(response3.data, {'message': 'Response 1'});
    });

    test('Backward compatibility - path-only matching works', () async {
      // Add mock without method (should match all methods)
      mockHttpClient.addMockResponses('/api/data', [
        MockResponse(data: {'data': 'value'}, statusCode: 200),
      ]);

      // All methods should work
      final getResponse = await dio.get('/api/data');
      expect(getResponse.statusCode, 200);

      final postResponse = await dio.post('/api/data');
      expect(postResponse.statusCode, 200);

      final putResponse = await dio.put('/api/data');
      expect(putResponse.statusCode, 200);
    });
  });
}

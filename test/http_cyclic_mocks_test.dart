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
  });
}

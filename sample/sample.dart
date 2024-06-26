import 'package:dio/dio.dart';
import 'package:http_cyclic_mocks/http_cyclic_mocks.dart';

void main() async {
  final dio = Dio();
  final mockHttpClient = CyclicMockClient(dio);

  mockHttpClient.addMockResponses('/route1', [
    MockResponse(data: {'message': 'Not Found'}, statusCode: 200),
    MockResponse(data: {'message': 'Route 1 - SUCCESS'}, statusCode: 200),
  ]);

  mockHttpClient.addMockResponses('/route2', [
    MockResponse(data: {'message': 'Error Response'}, statusCode: 400),
    MockResponse(data: {'message': 'Route 2 - SUCCESS'}, statusCode: 200),
    MockResponse(data: {'message': 'ERROR - Route 2'}, statusCode: 404),
  ]);

  for (int i = 0; i < 6; i++) {
    final response1 = await dio.get('/route1');
    print(response1.data);

    try{
     final response2 = await dio.get('/route2');
    print(response2.data);
    }catch(e){
    print(e);
    }
  }
}
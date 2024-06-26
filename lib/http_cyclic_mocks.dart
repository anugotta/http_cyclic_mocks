library http_cyclic_mocks;

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class CyclicMockClientAdapter implements HttpClientAdapter {
  final Map<String, List<MockResponse>> routeResponses = {};
  final Map<String, int> routeCounters = {};

  CyclicMockClientAdapter();

  void addMockResponses(String route, List<MockResponse> responses) {
    routeResponses[route] = responses;
    routeCounters[route] = 0;
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (routeResponses.containsKey(options.path)) {
      final responses = routeResponses[options.path]!;
      final counter = routeCounters[options.path] ?? 0;
      final response = responses[counter];
      routeCounters[options.path] = (counter + 1) % responses.length;

      return ResponseBody.fromString(
        jsonEncode(response.data),
        response.statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('Not Found', 404);
  }
}

class MockResponse {
  final dynamic data;
  final int statusCode;

  MockResponse({required this.data, required this.statusCode});
}

class CyclicMockClient {
  final Dio dio;
  final CyclicMockClientAdapter adapter = CyclicMockClientAdapter();

  CyclicMockClient(this.dio) {
    dio.httpClientAdapter = adapter;
  }

  void addMockResponses(String route, List<MockResponse> responses) {
    adapter.addMockResponses(route, responses);
  }
}
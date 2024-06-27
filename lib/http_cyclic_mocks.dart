library http_cyclic_mocks;

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// A custom HttpClientAdapter that cycles through a list of mock responses
/// for specific routes.
class CyclicMockClientAdapter implements HttpClientAdapter {
  final Map<String, List<MockResponse>> routeResponses = {};
  final Map<String, int> routeCounters = {};

  CyclicMockClientAdapter();

  /// Adds a list of mock responses for a specific route.
  ///
  /// The responses will be cycled through sequentially each time the route is hit.
  ///
  /// Example:
  /// ```dart
  /// adapter.addMockResponses('/route1', [
  ///   MockResponse(data: {'message': 'Response 1'}, statusCode: 200),
  ///   MockResponse(data: {'message': 'Response 2'}, statusCode: 200),
  /// ]);
  /// ```
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

/// Represents a mock HTTP response with data and status code.
class MockResponse {
  final dynamic data;
  final int statusCode;

  MockResponse({required this.data, required this.statusCode});
}

/// A class to manage and configure the custom CyclicMockClientAdapter for Dio.
///
/// This class provides an interface to add mock responses for specific routes
/// and attaches the adapter to the provided Dio instance.
class CyclicMockClient {
  final Dio dio;
  final CyclicMockClientAdapter adapter = CyclicMockClientAdapter();

  /// Creates an instance of CyclicMockClient and attaches the custom adapter to the provided Dio instance.
  ///
  /// Example:
  /// ```dart
  /// final dio = Dio();
  /// final mockClient = CyclicMockClient(dio);
  /// ```
  CyclicMockClient(this.dio) {
    dio.httpClientAdapter = adapter;
  }

  /// Adds a list of mock responses for a specific route.
  ///
  /// The responses will be cycled through sequentially each time the route is hit.
  ///
  /// Example:
  /// ```dart
  /// mockClient.addMockResponses('/route1', [
  ///   MockResponse(data: {'message': 'Response 1'}, statusCode: 200),
  ///   MockResponse(data: {'message': 'Response 2'}, statusCode: 200),
  /// ]);
  /// ```
  void addMockResponses(String route, List<MockResponse> responses) {
    adapter.addMockResponses(route, responses);
  }
}

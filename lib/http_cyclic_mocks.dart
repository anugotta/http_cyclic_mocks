library http_cyclic_mocks;

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// A custom HttpClientAdapter that cycles through a list of mock responses
/// for specific routes.
class CyclicMockClientAdapter implements HttpClientAdapter {
  // Key format: "METHOD:path" (e.g., "GET:/api/users") or just "path" for backward compatibility
  final Map<String, List<MockResponse>> routeResponses = {};
  final Map<String, int> routeCounters = {};

  CyclicMockClientAdapter();

  /// Generates a route key from method and path
  String _getRouteKey(String method, String path) {
    return '$method:$path';
  }

  /// Adds a list of mock responses for a specific route.
  ///
  /// [method] is optional. If provided, the route will only match that HTTP method.
  /// If not provided, it matches all methods (backward compatible).
  ///
  /// The responses will be cycled through sequentially each time the route is hit.
  ///
  /// Throws [ArgumentError] if responses list is empty.
  ///
  /// Example:
  /// ```dart
  /// adapter.addMockResponses('/route1', [
  ///   MockResponse(data: {'message': 'Response 1'}, statusCode: 200),
  ///   MockResponse(data: {'message': 'Response 2'}, statusCode: 200),
  /// ]);
  /// 
  /// // With HTTP method
  /// adapter.addMockResponses('/api/users', [
  ///   MockResponse(data: {'users': []}, statusCode: 200),
  /// ], method: 'GET');
  /// ```
  void addMockResponses(String route, List<MockResponse> responses, {String? method}) {
    if (responses.isEmpty) {
      throw ArgumentError('Responses list cannot be empty', 'responses');
    }
    
    final key = method != null ? _getRouteKey(method.toUpperCase(), route) : route;
    routeResponses[key] = responses;
    routeCounters[key] = 0;
  }

  /// Removes all mock responses for a specific route.
  ///
  /// [method] is optional. If provided, only removes mocks for that method.
  void removeMockResponses(String route, {String? method}) {
    if (method != null) {
      final key = _getRouteKey(method.toUpperCase(), route);
      routeResponses.remove(key);
      routeCounters.remove(key);
    } else {
      // Remove all methods for this route
      final keysToRemove = routeResponses.keys
          .where((key) => key == route || key.endsWith(':$route'))
          .toList();
      for (final key in keysToRemove) {
        routeResponses.remove(key);
        routeCounters.remove(key);
      }
    }
  }

  /// Clears all mock responses and resets counters.
  void clear() {
    routeResponses.clear();
    routeCounters.clear();
  }

  /// Resets the counter for a specific route (starts cycling from the first response again).
  void resetCounter(String route, {String? method}) {
    final key = method != null ? _getRouteKey(method.toUpperCase(), route) : route;
    if (routeCounters.containsKey(key)) {
      routeCounters[key] = 0;
    }
  }

  @override
  void close({bool force = false}) {
    clear();
  }

  /// Finds a matching route key for the given request options
  String? _findMatchingRoute(RequestOptions options) {
    // First try method-specific match
    final methodKey = _getRouteKey(options.method, options.path);
    if (routeResponses.containsKey(methodKey)) {
      return methodKey;
    }
    
    // Fall back to path-only match (backward compatibility)
    if (routeResponses.containsKey(options.path)) {
      return options.path;
    }
    
    return null;
  }

  /// Serializes response data to string
  String _serializeData(dynamic data) {
    if (data is String) {
      return data;
    }
    try {
      return jsonEncode(data);
    } catch (e) {
      // If JSON encoding fails, convert to string
      return data.toString();
    }
  }

  /// Determines content type based on data
  String _getContentType(dynamic data) {
    if (data is String) {
      // Try to detect if it's JSON
      try {
        jsonDecode(data);
        return Headers.jsonContentType;
      } catch (e) {
        return 'text/plain';
      }
    }
    return Headers.jsonContentType;
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final routeKey = _findMatchingRoute(options);
    
    if (routeKey != null) {
      final responses = routeResponses[routeKey]!;
      final counter = routeCounters[routeKey] ?? 0;
      final response = responses[counter];
      routeCounters[routeKey] = (counter + 1) % responses.length;

      final serializedData = _serializeData(response.data);
      final contentType = response.headers?[Headers.contentTypeHeader]?.firstOrNull ?? 
                         _getContentType(response.data);

      final headers = <String, List<String>>{
        Headers.contentTypeHeader: [contentType],
        ...?response.headers,
      };

      final responseBody = ResponseBody.fromString(
        serializedData,
        response.statusCode,
        headers: headers,
      );

      // For error status codes, Dio expects a DioException to be thrown
      // However, we return the ResponseBody and let Dio handle the exception
      // The ResponseBody will be wrapped in a DioException by Dio if statusCode >= 400
      return responseBody;
    }
    
    // Route not found
    return ResponseBody.fromString('Not Found', 404, headers: {
      Headers.contentTypeHeader: ['text/plain'],
    });
  }
}

/// Represents a mock HTTP response with data and status code.
class MockResponse {
  final dynamic data;
  final int statusCode;
  final Map<String, List<String>>? headers;

  /// Creates a mock response.
  ///
  /// [data] can be any serializable object (Map, List, String, etc.)
  /// [statusCode] is the HTTP status code
  /// [headers] are optional custom headers to include in the response
  MockResponse({
    required this.data,
    required this.statusCode,
    this.headers,
  });
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
  /// [method] is optional. If provided, the route will only match that HTTP method.
  /// If not provided, it matches all methods (backward compatible).
  ///
  /// The responses will be cycled through sequentially each time the route is hit.
  ///
  /// Throws [ArgumentError] if responses list is empty.
  ///
  /// Example:
  /// ```dart
  /// mockClient.addMockResponses('/route1', [
  ///   MockResponse(data: {'message': 'Response 1'}, statusCode: 200),
  ///   MockResponse(data: {'message': 'Response 2'}, statusCode: 200),
  /// ]);
  /// 
  /// // With HTTP method
  /// mockClient.addMockResponses('/api/users', [
  ///   MockResponse(data: {'users': []}, statusCode: 200),
  /// ], method: 'GET');
  /// ```
  void addMockResponses(String route, List<MockResponse> responses, {String? method}) {
    adapter.addMockResponses(route, responses, method: method);
  }

  /// Removes all mock responses for a specific route.
  ///
  /// [method] is optional. If provided, only removes mocks for that method.
  void removeMockResponses(String route, {String? method}) {
    adapter.removeMockResponses(route, method: method);
  }

  /// Clears all mock responses and resets counters.
  void clear() {
    adapter.clear();
  }

  /// Resets the counter for a specific route (starts cycling from the first response again).
  void resetCounter(String route, {String? method}) {
    adapter.resetCounter(route, method: method);
  }
}

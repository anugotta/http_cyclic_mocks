# Mock Multiple Responses for single route / endpoint

A Simple and lightweight Dart library for mocking/overriding HTTP responses with Dio. In this library you can add multiple responses for a single route/api endpoint.

## Introduction

`http_cyclic_mocks` is a lightweight library designed to facilitate the mocking of HTTP responses when using the Dio HTTP client. It allows developers to define mock responses for specific routes, cycling through multiple responses if needed. This helps avoid running the application mutliple times to mock different responses/scenarios for the same route. Find in [pub.dev](https://pub.dev/packages/http_cyclic_mocks) 

## Features

- Mock HTTP responses for specific routes
- Support for multiple responses per route (cycles through responses)
- HTTP method-specific mocking (GET, POST, PUT, DELETE, etc.)
- Custom headers support in mock responses
- Automatic content-type detection (JSON, plain text)
- Resource management (clear, remove, reset mocks)
- Input validation
- Easy integration with Dio
- 100% backward compatible

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  http_cyclic_mocks: ^0.1.0
  ```

Then, run flutter pub get to install the package.

## Usage

### Basic Usage

Here's a basic example of how to use `http_cyclic_mocks` in your project:

```dart
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

    try {
      final response2 = await dio.get('/route2');
      print(response2.data);
    } catch (e) {
      print(e);
    }
  }
}
```

### HTTP Method-Specific Mocking

You can mock different responses for different HTTP methods on the same route:

```dart
// Mock GET requests
mockHttpClient.addMockResponses('/api/users', [
  MockResponse(data: {'users': ['user1', 'user2']}, statusCode: 200),
], method: 'GET');

// Mock POST requests
mockHttpClient.addMockResponses('/api/users', [
  MockResponse(data: {'message': 'User created'}, statusCode: 201),
], method: 'POST');

// GET request returns users list
final getResponse = await dio.get('/api/users');

// POST request returns creation message
final postResponse = await dio.post('/api/users', data: {'name': 'New User'});
```

### Custom Headers

Add custom headers to your mock responses:

```dart
mockHttpClient.addMockResponses('/api/data', [
  MockResponse(
    data: {'message': 'Success'},
    statusCode: 200,
    headers: {
      'X-Custom-Header': ['custom-value'],
      'X-Request-ID': ['12345'],
      'Authorization': ['Bearer token123'],
    },
  ),
]);
```

### String/Non-JSON Responses

The library automatically detects content type:

```dart
mockHttpClient.addMockResponses('/text-endpoint', [
  MockResponse(data: 'Plain text response', statusCode: 200),
]);
```

### Resource Management

Clear, remove, or reset mocks as needed:

```dart
// Clear all mocks
mockHttpClient.clear();

// Remove a specific route
mockHttpClient.removeMockResponses('/route1');

// Remove method-specific mock
mockHttpClient.removeMockResponses('/api/users', method: 'GET');

// Reset counter to start from first response again
mockHttpClient.resetCounter('/route1');
```

## API Reference

### CyclicMockClient

Main class for managing mock HTTP responses.

#### Methods

- `addMockResponses(String route, List<MockResponse> responses, {String? method})`
  - Adds mock responses for a route. If `method` is provided, only matches that HTTP method. Otherwise, matches all methods.
  - Throws `ArgumentError` if responses list is empty.

- `removeMockResponses(String route, {String? method})`
  - Removes mock responses for a route. If `method` is provided, only removes that method's mocks.

- `clear()`
  - Clears all mock responses and resets all counters.

- `resetCounter(String route, {String? method})`
  - Resets the counter for a route, causing it to cycle from the first response again.

### MockResponse

Represents a mock HTTP response.

#### Constructor

```dart
MockResponse({
  required dynamic data,
  required int statusCode,
  Map<String, List<String>>? headers,
})
```

- `data`: The response data (can be Map, List, String, etc.)
- `statusCode`: HTTP status code (e.g., 200, 404, 500)
- `headers`: Optional custom headers for the response

## Example

A complete example is available in the example directory. You can run it to see the mock HTTP client in action.

## Contributing

Contributions are welcome! This library is at a beginner stage with lot of scope for improvements, so feel free to contribute.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](https://github.com/anugotta/http_cyclic_mocks/blob/main/LICENSE) file for details.

## Issues

If you encounter any issues, please open an issue on GitHub: https://github.com/anugotta/http_cyclic_mocks/issues

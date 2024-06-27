# Mock Multiple Responses for single route / endpoint

A Simple and lightweight Dart library for mocking/overriding HTTP responses with Dio. In this library you can add multiple responses for a single route/api endpoint.

## Introduction

`http_cyclic_mocks` is a lightweight library designed to facilitate the mocking of HTTP responses when using the Dio HTTP client. It allows developers to define mock responses for specific routes, cycling through multiple responses if needed. This helps avoid running the application mutliple times to mock different responses/scenarios for the same route. Find in [pub.dev](https://pub.dev/packages/http_cyclic_mocks) 

## Features

- Mock HTTP responses for specific routes.
- Support for multiple responses per route.
- Easy integration with Dio.

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  http_cyclic_mocks: ^0.0.4
  ```

Then, run flutter pub get to install the package.

## Usage

Here’s an example of how to use `http_cyclic_mocks` in your project:

```
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
```

## Example

A complete example is available in the example directory. You can run it to see the mock HTTP client in action.

## Contributing

Contributions are welcome! This library is at a beginner stage with lot of scope for improvements, so feel free to contribute.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](https://github.com/anugotta/http_cyclic_mocks/blob/main/LICENSE) file for details.

## Issues

If you encounter any issues, please open an issue on GitHub: https://github.com/anugotta/http_cyclic_mocks/issues

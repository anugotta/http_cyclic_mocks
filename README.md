# Cyclic Mock Client

A Simple Dart library for easily mocking multiple HTTP responses for same route with Dio.

## Introduction

`http_cyclic_mocks` is a lightweight library designed to facilitate the mocking of HTTP responses when using the Dio HTTP client. It allows developers to define mock responses for specific routes, cycling through multiple responses if needed. This is particularly useful for unit testing and development environments where actual network requests need to be avoided.

## Description

This library provides an easy-to-use interface for mocking HTTP responses in your Dart and Flutter projects. By using `CyclicMockClient`, you can simulate different server responses without having to rely on an actual backend. The library supports multiple routes and allows you to cycle through predefined responses for each route.

## Features

- Mock HTTP responses for specific routes.
- Support for multiple responses per route.
- Easy integration with Dio.
- Useful for unit testing and development environments.

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  http_cyclic_mocks: ^0.0.1
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

Contributions are welcome! Please follow these steps to contribute:

	1.	Fork the repository.
	2.	Create a new branch for your feature or bugfix.
	3.	Make your changes and commit them.
	4.	Push your changes to your fork.
	5.	Create a pull request with a description of your changes.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/anugotta/FlipTimerView/blob/master/LICENSE) file for details.

## Issues

If you encounter any issues, please open an issue on GitHub: https://github.com/anugotta/http_cyclic_mocks/issues

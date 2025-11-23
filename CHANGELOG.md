## 0.1.0
* Added HTTP method-specific mocking support (GET, POST, PUT, DELETE, etc.)
* Added custom headers support in MockResponse
* Added automatic content-type detection (JSON, plain text)
* Added resource management methods: clear(), removeMockResponses(), resetCounter()
* Added input validation (throws ArgumentError for empty response lists)
* Improved error handling for error status codes (4xx, 5xx)
* Enhanced content-type handling for non-JSON responses
* 100% backward compatible with previous versions
* Updated README with new features and API documentation

## 0.0.4
* Edited readme

## 0.0.3
* Code formatting and general housekeeping

## 0.0.2
* Code formatting and cleanups

## 0.0.1

* Initial Release.
* Ability to mock an array of responses for unique routes

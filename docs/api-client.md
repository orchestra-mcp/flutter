# API Client

Platform-aware API layer: MCP TCP client on desktop, REST/Dio on mobile.

## Architecture

```
ApiClient (abstract)
├── RestClient        — Dio HTTP, used on Android/iOS/Web
└── McpTcpClient      — JSON-RPC 2.0 over subprocess stdout/stdin, used on macOS/Windows/Linux
```

## Usage

```dart
// Riverpod — auto-selects correct implementation
final client = ref.read(apiClientProvider);

// List projects
final projects = await client.listProjects();

// Call any MCP tool directly
final result = await client.callTool('list_features', {'project_id': 'my-project'});
```

## Interceptors (REST only)

| Interceptor | Behaviour |
|-------------|-----------|
| `AuthInterceptor` | Injects `Authorization: Bearer <token>`, refreshes on 401 |
| `ErrorInterceptor` | Maps `DioException` → typed `AppException` subclass |
| `PerformanceService.dioInterceptor` | Records Firebase `HttpMetric` per request |

## Exception types

```dart
sealed class AppException
├── NetworkException   — connection/timeout errors
├── AuthException      — 401/403
├── NotFoundException  — 404
├── ServerException    — 5xx
└── UnknownApiException
```

## MCP framing

4-byte big-endian length prefix + UTF-8 JSON-RPC 2.0 body. Orchestra subprocess auto-restarts on exit with a 2-second delay.

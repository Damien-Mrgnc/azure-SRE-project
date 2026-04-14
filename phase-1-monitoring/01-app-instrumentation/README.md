# Step 1: App Side — Prometheus Instrumentation

## Concept
To make a system observable, the application must first **emit signals**. Without metrics exposed by the code, no external tool can measure the application's real health. Prometheus instrumentation turns the application into a structured data source for SRE monitoring.

## Implementation Details
The Node.js (Express) application was instrumented with the `prom-client` library to expose Prometheus-formatted metrics on a dedicated endpoint.

### Custom Metrics Implemented
1. **`http_request_duration_ms` (Histogram)**: Measures the duration of each HTTP request in milliseconds. Uses predefined buckets (`10, 50, 100, 200, 500, 1000, 2000, 5000`) to categorize response times and compute percentiles (p50, p95, p99).
2. **`http_requests_total` (Counter)**: Cumulative counter of total HTTP requests. Labeled by `method`, `route`, and `code` for fine-grained filtering (e.g., 5xx error rate per route).
3. **Default Node.js Metrics**: `collectDefaultMetrics()` automatically exposes runtime metrics (heap, event loop, GC, etc.).

### `response-time` Middleware
The `response-time` middleware intercepts all requests and feeds Prometheus metrics with the actual response time. The `/metrics` route is excluded from tracking to avoid data pollution.

### `/metrics` Endpoint
- **Route**: `GET /metrics`
- **Format**: `text/plain` in Prometheus format (scraping-compatible).
- **Access**: Public (not auth-protected) to allow scraping by collectors.

## Key Files (Phase 1 Snapshot)

| File | Description |
|---|---|
| [`server.js`](./server.js) | Snapshot of the instrumented source code |
| [`metrics-output-example.txt`](./metrics-output-example.txt) | Simulated `/metrics` endpoint output in production |

> Live source files are located at [`app/src/server.js`](../../../app/src/server.js).

## Sample `/metrics` Output

Excerpt of custom metrics (see [`metrics-output-example.txt`](./metrics-output-example.txt) for the full output):

```
# HELP http_request_duration_ms Duration of HTTP requests in ms
# TYPE http_request_duration_ms histogram
http_request_duration_ms_bucket{le="10",method="GET",route="/",code="200"} 45
http_request_duration_ms_bucket{le="50",method="GET",route="/",code="200"} 88
http_request_duration_ms_count{method="GET",route="/",code="200"} 100

# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/",code="200"} 100
http_requests_total{method="GET",route="/api/config",code="401"} 5
```

## Result
The application exposes a complete `/metrics` endpoint in Prometheus format, ready to be consumed by Azure Monitor or any compatible collector. All 4 Golden Signals are covered on the application side.

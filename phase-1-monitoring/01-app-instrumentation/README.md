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

## Key Files
- `app/src/server.js` — Prometheus instrumentation, metrics declaration, middleware, and `/metrics` endpoint.

## Result
The application now exposes a complete `/metrics` endpoint, ready to be consumed by Azure Monitor, Prometheus, or any compatible collector. All 4 Golden Signals are covered on the application side.

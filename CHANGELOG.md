## 1.3.0

### Correct attribution of API and crash events

API and crash events previously reported the request path (or the literal
string `global_error_handler`) in the `screen` field. Every distinct endpoint
therefore appeared as its own "screen" in the dashboard, each with zeroed-out
render metrics that diluted the app's averages and inflated its screen count.

- Added `target` to `sendMetric` and `MetricRecord`: `screen` now always names
  a real, user-visible screen, and `target` carries the endpoint path or crash
  handler name.
- Added `ScreenContext`, a shared record of the currently visible screen.
  `ScreenTracker` keeps it current; `ApiMetricsInterceptor` and `CrashTracker`
  read from it, so their events are attributed to the screen the user was
  actually on. Both accept an injected context for testing.

**Requires a backend with the `target` column** (migration `006`).

### Delivery reliability

- A flush that fails for a *transient* reason (network error, timeout, 5xx,
  429) now returns its events to the buffer and retries on the next flush
  instead of dropping them. Definitive `4xx` rejections are still dropped,
  since retrying them would never succeed.
- `flush()` is now re-entrant-safe: the periodic timer and a `maxBatchSize`
  trip can no longer both send the same events.
- Added `maxBufferSize` (default 1000) to bound memory while the device is
  offline; the oldest events are discarded once it is reached.

### Other fixes

- `CrashTracker.initialize` now chains to any previously installed
  `FlutterError.onError` / `PlatformDispatcher.onError` handler instead of
  silently replacing it.
- `ApiMetricsInterceptor` keys in-flight requests by a token on the request
  itself rather than by `RequestOptions` identity, so retries and redirects no
  longer lose or misattribute a latency measurement.
- `ScreenTracker` now updates attribution on `didReplace` and `didRemove`, and
  sets the current screen on push immediately rather than a frame later.

## 1.2.0

- **Batched delivery**: events are now buffered and sent to `/metrics/batch`
  on a periodic timer (default 5s) or once `maxBatchSize` events are queued
  (default 20), instead of one HTTP request per event.
- Added `sampleRate` to probabilistically drop high-frequency
  `app_render` frame events while always keeping crash, API and screen
  events.
- Added `MetricsClient.flush()` and `MetricsClient.dispose()` for manual
  flushing and graceful shutdown; the client now flushes automatically when
  the app is paused or detached.
- Re-enabled connect/receive timeouts (15s) so a slow backend can no longer
  hang a flush.
- `FrameTracker` now takes a configurable `frameBudgetMs` (default 16) for
  non-60Hz displays, and exposes `FrameTracker.isDropped`.
- Fixed unbounded growth of `ApiMetricsInterceptor`'s in-flight request map.
- Added unit tests covering batching, sampling, frame-drop detection, the
  API interceptor and crash reporting.
- Added an `example/` app and dartdoc comments across the public API.

## 1.1.0

- Added automatic screen and route tracking via `NavigatorObserver`
- Added API performance tracking
- Enhanced frame drop and render time tracking
- Added `app_render` and `api_call` metrics

## 1.0.1

- Initial stable release of Flutter Metrics SDK
- Supports screen render time tracking
- Supports frame drop (UI jank) detection
- Supports crash signal reporting
- Secure API key-based metrics ingestion
- Compatible with Flutter Mobile and Web

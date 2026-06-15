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

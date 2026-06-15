# Flutter Metrics SDK

A lightweight Flutter performance analytics SDK that captures real-user
performance metrics — render time, frame drops, network latency and crash
signals — and ships them to a backend in efficient, batched requests.

---

## 🚀 Features

- Screen render time and frame drop (UI jank) tracking, with a configurable
  frame budget for 90Hz/120Hz displays
- Network latency tracking via a Dio interceptor
- Crash and uncaught-error reporting
- Automatic screen/route tracking via `NavigatorObserver`
- **Batched, low-overhead delivery**: events are buffered in memory and
  flushed periodically (or once a batch size threshold is hit) instead of
  one HTTP request per event
- Optional sampling (`sampleRate`) for high-frequency frame events
- Secure API key-based ingestion
- Non-blocking, fail-silent by design — telemetry never crashes or blocks
  the host app
- Supports Android, iOS and Web

---

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_metrics_sdk: ^1.2.0
```

Then run:

```bash
flutter pub get
```

A runnable example app is available in [`example/`](example).

---

## 🌐 Dashboard Setup (Required)

This SDK integrates with a web-based performance dashboard.

### Dashboard URL
https://ai-performance-intelligence-dashboa.vercel.app

### Setup Steps
1. Create an account on the dashboard
2. Create an application
3. Copy the generated API key
4. Use the API key while initializing the SDK

### Backend API URL
```
https://ai-performance-intelligence-backend.onrender.com
```

---

## ⚙️ Initialization

```dart
final metrics = MetricsClient(
  apiKey: 'app_live_xxxxxxxxx',
  baseUrl: 'https://ai-performance-intelligence-backend.onrender.com',

  // Buffering & batching (controls overhead)
  flushInterval: const Duration(seconds: 5), // default
  maxBatchSize: 20,                          // default
  sampleRate: 1.0,                           // 0.0-1.0, applies to frame-render events only
);

// Report uncaught errors as crash metrics
CrashTracker.initialize(metrics);

// Track render time and frame drops for the active screen
final frameTracker = FrameTracker(metrics)..startTrackingMetrics();

// Automatically track screen opens/load time via the Navigator
final screenTracker = ScreenTracker(metrics, frameTracker: frameTracker);

MaterialApp(
  navigatorObservers: [screenTracker],
  // ...
);
```

Call `metrics.flush()` to send buffered events immediately, and
`metrics.dispose()` on shutdown to flush any remaining events and cancel the
flush timer.

---

## 🧪 Usage

### Track a custom event
```dart
metrics.sendMetric(
  event: MetricsEvent.buttonClick,
  screen: 'home',
);
```

### Track network latency
```dart
final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
dio.interceptors.add(ApiMetricsInterceptor(metrics));
```

### Render time & frame drops
Handled automatically once `FrameTracker` and `ScreenTracker` are wired up
as shown above — `frameDropped` is `true` whenever a frame's build + raster
time exceeds the configured `frameBudgetMs` (default `16`, i.e. 60fps).

### Crash reporting
Handled automatically by `CrashTracker.initialize(metrics)`.

---

## 📨 How delivery works

`sendMetric` never makes a network call directly — it appends the event to
an in-memory buffer. The buffer is flushed to `POST /metrics/batch` as a
single request when **either**:

- `flushInterval` has elapsed since the last flush, or
- the buffer reaches `maxBatchSize` events,

whichever happens first. The buffer is also flushed automatically when the
app is paused, inactive or detached.

---

## 🔐 Security

- Uses app-level API keys for metrics ingestion
- API keys are generated from the dashboard
- API keys should not be committed to source control
- Supports API key rotation

---

## 🌍 Platform Support

- Flutter Android
- Flutter iOS
- Flutter Web

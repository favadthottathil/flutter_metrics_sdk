# Flutter Metrics SDK

A Flutter performance analytics SDK that captures real-user performance
metrics and sends them securely to a web-based dashboard for analysis
and optimization.

---

## 🚀 Features

- Screen render time tracking
- Frame drop (UI jank) detection
- User interaction tracking
- Crash signal reporting
- Secure API key-based ingestion
- Non-blocking and production-safe design
- Supports Android, iOS, and Web

---

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_metrics_sdk: ^1.0.0
```

Then run:

```bash
flutter pub get
```

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
);
```

---

## 🧪 Usage

### Track screen render time
```dart
metrics.sendMetric(
  event: 'screen_render',
  screen: 'home',
  renderTimeMs: 420,
);
```

### Track frame drops (UI jank)
```dart
metrics.sendMetric(
  event: 'frame_drop',
  screen: 'profile',
  frameTimeMs: 34,
  frameDropped: true,
);
```

### Track crash signals
```dart
FlutterError.onError = (details) {
  metrics.sendMetric(
    event: 'app_crash',
    screen: 'unknown',
  );
};
```

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

# Flutter Metrics SDK

A Flutter performance analytics SDK that captures real-user performance
metrics and sends them securely to a web-based dashboard for analysis
and optimization.

## 🚀 Features

- Screen render time tracking
- Frame drop (UI jank) detection
- User interaction tracking
- Crash signal reporting
- Secure API key-based ingestion
- Non-blocking and production-safe design

## Installation
dependencies:
  flutter_metrics_sdk: ^1.0.0

Then run:
flutter pub get

## 🔹 4️⃣ Dashboard Setup Section (VERY IMPORTANT)

👉 **https://ai-performance-intelligence-dashboa.vercel.app**

```md
## 🌐 Dashboard Setup (Required)

This SDK integrates with a web-based performance dashboard.

### Dashboard URL
https://ai-performance-intelligence-dashboa.vercel.app

### Setup Steps
1. Create an account on the dashboard
2. Create an application
3. Copy the generated API key
4. Initialize the SDK using the API key and backend URL

Backend API URL:
https://ai-performance-intelligence-backend.onrender.com


## ⚙️ Initialization

```dart
final metrics = MetricsClient(
  apiKey: 'app_live_xxxxxxxxx',
  baseUrl: 'https://ai-performance-intelligence-backend.onrender.com',
);

## 🔹 6️⃣ Usage Section

```md
## 🧪 Usage

### Track screen render time
metrics.sendMetric(
  event: 'screen_render',
  screen: 'home',
  renderTimeMs: 420,
); 

Track frame drops
metrics.sendMetric(
  event: 'frame_drop',
  screen: 'profile',
  frameTimeMs: 34,
  frameDropped: true,
);

Track crash signals
FlutterError.onError = (details) {
  metrics.sendMetric(
    event: 'app_crash',
    screen: 'unknown',
  );
};

---

### 📄 `LICENSE` (MANDATORY)

Use **MIT License** (best choice).

Content:
MIT License

Copyright (c) 2026 Favad T


---

### 📄 `CHANGELOG.md`

## 1.0.0
- Initial stable release
- Performance metrics SDK
- Supports render time, frame drops, crashes
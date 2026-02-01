# Flutter Metrics SDK

A Flutter performance analytics SDK to capture real-user metrics such as
screen render time, frame drops (UI jank), user interactions, and crash signals.

## Features
- Screen render performance tracking
- Frame drop detection
- Crash reporting
- Secure API key-based ingestion
- Works on Flutter Mobile & Web

## Installation
dependencies:
  flutter_metrics_sdk: ^1.0.0


Usage
final metrics = MetricsClient(
  apiKey: 'app_live_xxx',
  baseUrl: 'https://your-backend.com',
);

metrics.sendMetric(
  event: 'screen_open',
  screen: 'home',
);  

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
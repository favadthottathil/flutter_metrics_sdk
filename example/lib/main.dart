import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_metrics_sdk/flutter_metrics_sdk.dart';

/// Minimal example showing how to wire up every part of
/// `flutter_metrics_sdk`:
///
/// - [MetricsClient] buffers and batches telemetry.
/// - [CrashTracker] reports uncaught errors.
/// - [FrameTracker] + [ScreenTracker] report render time, frame drops and
///   screen-load time.
/// - [ApiMetricsInterceptor] reports network latency for API calls made
///   through a [Dio] client.
void main() {
  final metrics = MetricsClient(
    apiKey: 'app_live_xxxxxxxxx',
    baseUrl: 'https://ai-performance-intelligence-backend.onrender.com',
    // Send at most every 10s or once 20 events are buffered, whichever
    // comes first, and only keep 50% of raw frame-render events.
    flushInterval: const Duration(seconds: 10),
    maxBatchSize: 20,
    sampleRate: 0.5,
  );

  CrashTracker.initialize(metrics);

  final frameTracker = FrameTracker(metrics)..startTrackingMetrics();
  final screenTracker = ScreenTracker(metrics, frameTracker: frameTracker);

  runApp(MetricsExampleApp(
    metrics: metrics,
    screenTracker: screenTracker,
  ));
}

class MetricsExampleApp extends StatelessWidget {
  const MetricsExampleApp({
    super.key,
    required this.metrics,
    required this.screenTracker,
  });

  final MetricsClient metrics;
  final ScreenTracker screenTracker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Metrics SDK Example',
      navigatorObservers: [screenTracker],
      home: HomePage(metrics: metrics),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.metrics});

  final MetricsClient metrics;

  Future<void> _makeApiCall() async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.interceptors.add(ApiMetricsInterceptor(metrics));
    try {
      await dio.get('/ping');
    } catch (_) {
      // Network errors are recorded as api_error metrics regardless.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_metrics_sdk example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                metrics.sendMetric(
                  event: MetricsEvent.buttonClick,
                  screen: 'home',
                );
              },
              child: const Text('Send button_click metric'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _makeApiCall,
              child: const Text('Make tracked API call'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => metrics.flush(),
              child: const Text('Flush buffered metrics now'),
            ),
          ],
        ),
      ),
    );
  }
}

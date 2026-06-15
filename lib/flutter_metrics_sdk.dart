/// A lightweight, batched performance telemetry SDK for Flutter apps.
///
/// Capture render time, frame drops, network latency and crash metrics
/// with minimal overhead — events are buffered in memory and delivered to
/// the backend in periodic batches rather than one request per event.
///
/// See [MetricsClient] for the main entry point.
library;

export 'src/metrics_client.dart';
export 'src/metric_record.dart';
export 'src/metrics_event.dart';
export 'src/screen_tracker.dart';
export 'src/crash_tracker.dart';
export 'src/api_tracker.dart';
export 'src/frame_tracker.dart';

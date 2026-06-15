/// A single telemetry event queued for delivery to the backend.
///
/// Instances are created internally by [MetricsClient.sendMetric] and
/// serialized via [toJson] when a batch is flushed.
class MetricRecord {
  final String event;
  final String screen;
  final int? frameTimeMs;
  final bool? frameDropped;
  final int? renderTimeMs;
  final int? apiLatencyMs;
  final bool? isError;
  final String? errorMessage;
  final String? stackTrace;
  final int? screenLoadTimeMs;
  final DateTime timestamp;

  MetricRecord({
    required this.event,
    required this.screen,
    this.frameTimeMs,
    this.frameDropped,
    this.renderTimeMs,
    this.apiLatencyMs,
    this.isError,
    this.errorMessage,
    this.stackTrace,
    this.screenLoadTimeMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Converts this record into the JSON shape expected by the backend's
  /// `/metrics` and `/metrics/batch` endpoints.
  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'screen': screen,
      if (frameTimeMs != null) 'frame_time': frameTimeMs,
      if (frameDropped != null) 'frame_dropped': frameDropped,
      if (renderTimeMs != null) 'render_time': renderTimeMs,
      if (apiLatencyMs != null) 'api_latency': apiLatencyMs,
      if (isError != null) 'is_error': isError,
      if (errorMessage != null) 'error_message': errorMessage,
      if (stackTrace != null) 'stack_trace': stackTrace,
      if (screenLoadTimeMs != null) 'screen_load_time': screenLoadTimeMs,
      'client_timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}

/// A single telemetry event queued for delivery to the backend.
///
/// Instances are created internally by [MetricsClient.sendMetric] and
/// serialized via [toJson] when a batch is flushed.
class MetricRecord {
  /// The user-visible screen this event occurred on.
  ///
  /// This is always a real screen, never an endpoint path or an error
  /// handler name — see [target] for those.
  final String screen;

  /// What the event acted on, when that differs from the screen: the
  /// request path for API events, or the handler name for crashes.
  ///
  /// `null` for events whose subject *is* the screen, such as
  /// screen-open and frame-render events.
  final String? target;

  final String event;
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
    this.target,
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
      if (target != null) 'target': target,
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

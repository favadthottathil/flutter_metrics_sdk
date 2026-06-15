import 'package:flutter/scheduler.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';

/// Observes Flutter's frame timing pipeline and reports render time and
/// frame-drop metrics for the currently active screen.
///
/// Each frame produces one [MetricsEvent.appRender] event containing the
/// build time, total render time (build + raster), and whether the frame
/// missed its budget. Sampling of these high-frequency events is
/// controlled by [MetricsClient]'s `sampleRate`.
class FrameTracker {
  final MetricsClient _client;

  /// The maximum time, in milliseconds, a frame may take to build and
  /// raster before it is considered dropped. Defaults to `16` (the
  /// budget for a 60Hz display); pass `8` for 120Hz displays, etc.
  final int frameBudgetMs;

  String? _currentScreen;

  FrameTracker(this._client, {this.frameBudgetMs = 16});

  /// Starts listening for frame timing callbacks.
  void startTrackingMetrics() {
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
  }

  /// Stops listening for frame timing callbacks.
  void stopTracking() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
  }

  /// Sets the screen name attributed to subsequent frame timing events.
  void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
  }

  /// Returns whether a frame that took [totalRenderTimeMs] to build and
  /// raster exceeds [frameBudgetMs] and should be considered dropped.
  static bool isDropped(int totalRenderTimeMs, {int frameBudgetMs = 16}) {
    return totalRenderTimeMs > frameBudgetMs;
  }

  void _onFrameTiming(List<FrameTiming> timings) {
    if (_currentScreen == null) return;

    for (final timing in timings) {
      final buildTime = timing.buildDuration.inMilliseconds;
      final rasterTime = timing.rasterDuration.inMilliseconds;
      final totalRenderTime = buildTime + rasterTime;

      _client.sendMetric(
        event: MetricsEvent.appRender,
        screen: _currentScreen!,
        frameTimeMs: buildTime,
        renderTimeMs: totalRenderTime,
        frameDropped: isDropped(totalRenderTime, frameBudgetMs: frameBudgetMs),
      );
    }
  }
}

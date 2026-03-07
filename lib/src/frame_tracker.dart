import 'package:flutter/scheduler.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';

class FrameTracker {
  final MetricsClient _client;
  String? _currentScreen;

  FrameTracker(this._client);

  void startTrackingMetrics() {
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
  }

  void stopTracking() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
  }

  void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
  }

  void _onFrameTiming(List<FrameTiming> timings) {
    if (_currentScreen == null) return;

    for (final timing in timings) {
      final buildTime = timing.buildDuration.inMilliseconds;
      final rasterTime = timing.rasterDuration.inMilliseconds;
      final totalRenderTime = buildTime + rasterTime;

      // Typical target is ~16ms for 60fps
      final isDroppedFrame = totalRenderTime > 16;

      _client.sendMetric(
        event: MetricsEvent.appRender,
        screen: _currentScreen!,
        frameTimeMs: buildTime,
        renderTimeMs: totalRenderTime,
        frameDropped: isDroppedFrame,
      );
    }
  }
}

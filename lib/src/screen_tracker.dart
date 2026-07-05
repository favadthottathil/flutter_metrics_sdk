import 'package:flutter/widgets.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';
import 'frame_tracker.dart';

/// A [NavigatorObserver] that automatically reports screen-open and
/// screen-load-time metrics as routes are pushed and popped.
///
/// Register an instance on your app's `Navigator`/`MaterialApp`:
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [ScreenTracker(metrics, frameTracker: frameTracker)],
///   ...
/// )
/// ```
///
/// If a [FrameTracker] is supplied, it is kept informed of the currently
/// visible screen so frame-render metrics are attributed correctly.
class ScreenTracker extends NavigatorObserver {
  final MetricsClient _client;
  final FrameTracker? _frameTracker;
  final Map<String, DateTime> _routeStartTimes = {};

  ScreenTracker(this._client, {FrameTracker? frameTracker})
      : _frameTracker = frameTracker;

  /// Manually reports a [MetricsEvent.screenOpen] event for [screenName]
  /// and updates the attached [FrameTracker], if any.
  ///
  /// Useful for screens not reachable via the [Navigator], such as the
  /// initial screen shown before the first route is pushed.
  void trackScreen(String screenName) {
    _client.sendMetric(event: MetricsEvent.screenOpen, screen: screenName);
    _frameTracker?.setCurrentScreen(screenName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name ?? 'Unknown_Route';

    // Track transition or load time
    _routeStartTimes[routeName] = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final startTime = _routeStartTimes.remove(routeName);
      final loadTime = startTime != null
          ? DateTime.now().difference(startTime).inMilliseconds
          : null;

      _client.sendMetric(
        event: MetricsEvent.screenOpen,
        screen: routeName,
        screenLoadTimeMs: loadTime,
      );

      _frameTracker?.setCurrentScreen(routeName);
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      final routeName = previousRoute.settings.name ?? 'Unknown_Route';
      _frameTracker?.setCurrentScreen(routeName);
    }
  }
}

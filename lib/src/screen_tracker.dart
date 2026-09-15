import 'package:flutter/widgets.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';
import 'frame_tracker.dart';
import 'screen_context.dart';

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
/// The observer also keeps a [ScreenContext] up to date, so API and crash
/// events are attributed to the screen that was visible when they fired.
/// If a [FrameTracker] is supplied, it too is kept informed of the
/// currently visible screen.
class ScreenTracker extends NavigatorObserver {
  final MetricsClient _client;
  final FrameTracker? _frameTracker;
  final ScreenContext _screenContext;
  final Map<String, DateTime> _routeStartTimes = {};

  ScreenTracker(
    this._client, {
    FrameTracker? frameTracker,
    ScreenContext? screenContext,
  }) : _frameTracker = frameTracker,
       _screenContext = screenContext ?? ScreenContext.instance;

  /// Manually reports a [MetricsEvent.screenOpen] event for [screenName]
  /// and updates the attached trackers.
  ///
  /// Useful for screens not reachable via the [Navigator], such as the
  /// initial screen shown before the first route is pushed.
  void trackScreen(String screenName) {
    _setCurrentScreen(screenName);
    _client.sendMetric(event: MetricsEvent.screenOpen, screen: screenName);
  }

  void _setCurrentScreen(String screenName) {
    _screenContext.setCurrentScreen(screenName);
    _frameTracker?.setCurrentScreen(screenName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name ?? 'Unknown_Route';

    // Attribute immediately, so API calls and crashes fired during the
    // route's first frame are not still credited to the previous screen.
    _setCurrentScreen(routeName);

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
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    // The popped route may never have reached its post-frame callback.
    _routeStartTimes.remove(route.settings.name ?? 'Unknown_Route');

    if (previousRoute != null) {
      _setCurrentScreen(previousRoute.settings.name ?? 'Unknown_Route');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    // Without this, a `pushReplacement` would leave attribution pointing at
    // the route that was just replaced.
    if (newRoute != null) {
      _setCurrentScreen(newRoute.settings.name ?? 'Unknown_Route');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routeStartTimes.remove(route.settings.name ?? 'Unknown_Route');
  }
}

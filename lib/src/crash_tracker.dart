import 'package:flutter/foundation.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';
import 'screen_context.dart';

/// Installs global error handlers that report uncaught Flutter framework
/// errors and uncaught asynchronous/platform errors as
/// [MetricsEvent.crash] events.
///
/// Crashes are attributed to the screen that was visible when they fired,
/// with the originating handler recorded as the event's `target`.
///
/// Call [initialize] once, typically right after creating a
/// [MetricsClient]:
///
/// ```dart
/// final metrics = MetricsClient(apiKey: '...', baseUrl: '...');
/// CrashTracker.initialize(metrics);
/// ```
class CrashTracker {
  /// Registers [FlutterError.onError] and
  /// [PlatformDispatcher.instance.onError] handlers that forward errors to
  /// [client] before re-presenting them via [FlutterError.presentError].
  ///
  /// Existing handlers are preserved and still invoked, so installing the
  /// crash tracker never silently disables another error reporter.
  static void initialize(MetricsClient client, {ScreenContext? screenContext}) {
    final context = screenContext ?? ScreenContext.instance;

    final previousFlutterOnError = FlutterError.onError;
    final previousPlatformOnError = PlatformDispatcher.instance.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      _sendCrash(
        client,
        context,
        details.exceptionAsString(),
        details.stack,
        'FlutterError.onError',
      );

      if (previousFlutterOnError != null) {
        previousFlutterOnError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _sendCrash(
        client,
        context,
        error.toString(),
        stack,
        'PlatformDispatcher.onError',
      );

      // Preserve whatever the host app already decided about handling.
      return previousPlatformOnError?.call(error, stack) ?? true;
    };
  }

  static void _sendCrash(
    MetricsClient client,
    ScreenContext context,
    String error,
    StackTrace? stack,
    String handler,
  ) {
    client.sendMetric(
      event: MetricsEvent.crash,
      screen: context.currentScreen,
      target: handler,
      isError: true,
      errorMessage: error,
      stackTrace: stack?.toString(),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';

/// Installs global error handlers that report uncaught Flutter framework
/// errors and uncaught asynchronous/platform errors as
/// [MetricsEvent.crash] events.
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
  static void initialize(MetricsClient client) {
    FlutterError.onError = (FlutterErrorDetails details) {
      _sendCrash(client, details.exceptionAsString(), details.stack);
      // Pass to original handler if needed, or dump to console
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _sendCrash(client, error.toString(), stack);
      return true;
    };
  }

  static void _sendCrash(
    MetricsClient client,
    String error,
    StackTrace? stack,
  ) {
    client.sendMetric(
      event: MetricsEvent.crash,
      screen: 'global_error_handler',
      isError: true,
      errorMessage: error,
      stackTrace: stack?.toString(),
    );
  }
}

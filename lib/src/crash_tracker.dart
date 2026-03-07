import 'package:flutter/foundation.dart';
import 'metrics_client.dart';
import 'metrics_event.dart';

class CrashTracker {
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

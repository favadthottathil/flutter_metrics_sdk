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
      // We might want to pass more details like stack trace in a real app,
      // but for now keeping it compatible with existing sendMetric signature
      // or deciding if sendMetric needs to support extra data.
      // Based on MetricsClient, it only takes event and screen.
      // So we'll just log the crash event for now.
    );
    // Ideally we would send the error message and stack trace too.
  }
}

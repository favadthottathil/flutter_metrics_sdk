import 'metrics_client.dart';
import 'metrics_event.dart';

class ScreenTracker {
  final MetricsClient _client;

  ScreenTracker(this._client);

  void track(String screenName) {
    _client.sendMetric(event: MetricsEvent.screenOpen, screen: screenName);
  }
}

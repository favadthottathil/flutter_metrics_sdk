/// Event type constants used as the `event` field of a metric payload.
class MetricsEvent {
  /// Reported once when the app starts.
  static const appStart = 'app_start';

  /// Reported when a screen/route becomes visible.
  static const screenOpen = 'screen_open';

  /// Reported for a user-initiated interaction such as a button press.
  static const buttonClick = 'button_click';

  /// Reported when a tracked API call fails or returns an error status.
  static const apiError = 'api_error';

  /// Reported for a successful tracked API call.
  static const apiCall = 'api_call';

  /// Reported when an uncaught exception or platform error occurs.
  static const crash = 'app_crash';

  /// Reported per-frame with render time and frame-drop information.
  static const appRender = 'app_render';
}

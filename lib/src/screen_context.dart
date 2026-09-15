/// Tracks which screen is currently visible, so events whose subject is
/// not a screen — API calls, crashes — can still be attributed to the
/// screen the user was on when they occurred.
///
/// [ScreenTracker] updates this as routes are pushed and popped;
/// [ApiMetricsInterceptor] and [CrashTracker] read from it. Using a shared
/// context rather than passing the screen name through every call site
/// keeps attribution correct even for code with no access to a
/// [BuildContext], such as a Dio interceptor or a global error handler.
class ScreenContext {
  /// The ambient context used by default across the SDK.
  static final ScreenContext instance = ScreenContext();

  /// Screen name reported before any route has been observed.
  static const String unknownScreen = 'unknown';

  String _currentScreen = unknownScreen;

  /// The screen currently visible, or [unknownScreen] if no route has been
  /// observed yet.
  String get currentScreen => _currentScreen;

  /// Records [screenName] as the visible screen. Empty names are ignored
  /// so a malformed route cannot blank out attribution for later events.
  void setCurrentScreen(String screenName) {
    if (screenName.isEmpty) return;
    _currentScreen = screenName;
  }

  /// Resets the context back to [unknownScreen]. Intended for tests.
  void reset() => _currentScreen = unknownScreen;
}

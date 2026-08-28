/// LUCKY BOSS — API ENDPOINT CONFIGURATION
///
/// Every network call in the app resolves its host through this class.
///
/// Before this existed, `ApiService` and `GeminiCopilotService` each hardcoded
/// `http://127.0.0.1:8000`. That address means "this device" — so a release APK
/// on a real phone asked the *phone* for the Laravel server, got nothing, and
/// fell through to the offline dataset. The app looked fine in Chrome on the
/// dev machine and was silently dead on any handset.
///
/// The host is supplied at build time so the same source produces a local build
/// and a production build with no code edit:
///
///   flutter run   -d chrome
///   flutter build apk --release --dart-define=API_BASE_URL=https://api.luckyboss.com
///
/// `--dart-define` is compile-time constant, so the production host is baked in
/// and cannot be swapped by anyone inspecting the APK.
class ApiConfig {
  ApiConfig._();

  /// Root of the Laravel deployment, no trailing slash.
  ///
  /// Defaults to the local `php artisan serve` host so a fresh clone runs with
  /// no flags. Android emulators cannot reach `127.0.0.1` — that resolves to the
  /// emulator itself — so use `--dart-define=API_BASE_URL=http://10.0.2.2:8000`
  /// there, and the machine's LAN IP for a physical device on the same network.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// Versioned mobile API. Auth, jobs, applications, profile.
  static String get v1 => '$baseUrl/api/v1';

  /// The AI chat route is registered at the API root rather than under /v1 —
  /// see routes/api.php: Route::post('/ai-chat', AiChatController::class).
  static String get aiChat => '$baseUrl/api/ai-chat';

  /// True when pointed at a loopback/dev host. Used to decide whether it is
  /// safe to surface verbose connection errors in the UI.
  static bool get isLocal =>
      baseUrl.contains('127.0.0.1') ||
      baseUrl.contains('localhost') ||
      baseUrl.contains('10.0.2.2');

  /// Absolute URL for a storage path returned by Laravel (e.g. a profile photo
  /// stored as `profile-photos/abc.jpg`). Passes through absolute URLs so an
  /// S3/CDN migration needs no client change.
  static String storageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return clean.startsWith('storage/')
        ? '$baseUrl/$clean'
        : '$baseUrl/storage/$clean';
  }
}

/// Relay base URL for the live server (no trailing slash).
const defaultApiBase = 'http://85.113.129.93:3000';

/// Production relay: [defaultApiBase] (`/health` → `{"ok":true}`).
///
/// By default the app uses that URL. Override:
/// - LAN: `--dart-define=API_BASE=http://192.168.0.99:3000`
/// - Offline mock: `--dart-define=USE_MOCK=1`
class ApiConfig {
  const ApiConfig({required this.baseUrl});

  final String baseUrl;

  bool get useRealServer => baseUrl.isNotEmpty;

  static ApiConfig fromEnvironment() {
    const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
    if (useMock) return const ApiConfig(baseUrl: '');

    const raw = String.fromEnvironment('API_BASE', defaultValue: defaultApiBase);
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const ApiConfig(baseUrl: '');
    return ApiConfig(baseUrl: trimmed.replaceAll(RegExp(r'/+$'), ''));
  }
}

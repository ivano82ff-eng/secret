/// Server base URL for the real relay, e.g. `http://192.168.0.99:3000`.
///
/// Empty → mock transport (offline demo). Set via:
/// `flutter run --dart-define=API_BASE=http://192.168.0.99:3000`
class ApiConfig {
  const ApiConfig({required this.baseUrl});

  final String baseUrl;

  bool get useRealServer => baseUrl.isNotEmpty;

  static ApiConfig fromEnvironment() {
    const raw = String.fromEnvironment('API_BASE', defaultValue: '');
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const ApiConfig(baseUrl: '');
    return ApiConfig(baseUrl: trimmed.replaceAll(RegExp(r'/+$'), ''));
  }
}

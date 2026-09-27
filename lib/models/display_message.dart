import 'envelope.dart';

/// In-memory row for the thread.
///
/// [mockDisplayText] is UI-only. It is recovered through [SessionCipher] for
/// the mock pipeline and must never be written to Drift or sent to the API.
class DisplayMessage {
  const DisplayMessage({required this.envelope, required this.mockDisplayText});

  final Envelope envelope;

  /// Mock-only display text. Not part of the persisted envelope.
  final String mockDisplayText;
}

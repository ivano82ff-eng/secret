import 'dart:typed_data';

import 'envelope.dart';

/// How the thread should draw a decrypted envelope.
///
/// Everything except [envelope] is UI-only and must not be serialized.
enum MockKind { text, wallSmiley, file, voice }

class DisplayMessage {
  const DisplayMessage({
    required this.envelope,
    required this.mockDisplayText,
    this.kind = MockKind.text,
    this.mockFileName,
    this.mockSizeBytes,
    this.mockDuration,
    this.mockBytes,
    this.mockMimeType,
  });

  final Envelope envelope;

  /// Mock-only display text. Not part of the persisted envelope.
  final String mockDisplayText;
  final MockKind kind;

  /// Mock-only file name. Never a field on the wire envelope.
  final String? mockFileName;
  final int? mockSizeBytes;
  final Duration? mockDuration;

  /// Local bytes for playback or a file that was not uploaded.
  final Uint8List? mockBytes;
  final String? mockMimeType;
}

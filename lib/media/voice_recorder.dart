import 'dart:typed_data';

class VoiceClip {
  const VoiceClip({
    required this.bytes,
    required this.duration,
    required this.mimeType,
  });

  final Uint8List bytes;
  final Duration duration;
  final String mimeType;
}

class MicrophoneDenied implements Exception {
  const MicrophoneDenied();
}

abstract interface class VoiceRecorder {
  Future<void> start();

  Future<VoiceClip?> stop();

  Future<void> dispose();
}

abstract interface class VoicePlayer {
  Future<void> play(Uint8List bytes, {required String mimeType});

  Future<void> stop();

  Future<void> dispose();
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'read_audio.dart';
import 'voice_recorder.dart';

class DeviceVoiceRecorder implements VoiceRecorder {
  DeviceVoiceRecorder() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  final Stopwatch _watch = Stopwatch();

  @override
  Future<void> start() async {
    final allowed = await _recorder.hasPermission();
    if (!allowed) throw const MicrophoneDenied();
    _watch
      ..reset()
      ..start();
    await _recorder.start(
      RecordConfig(encoder: kIsWeb ? AudioEncoder.wav : AudioEncoder.aacLc),
      path: kIsWeb ? '' : 'voice.m4a',
    );
  }

  @override
  Future<VoiceClip?> stop() async {
    _watch.stop();
    final path = await _recorder.stop();
    final duration = _watch.elapsed;
    if (path == null || path.isEmpty) return null;
    final bytes = await readLocalAudio(path);
    if (bytes.isEmpty) return null;
    return VoiceClip(
      bytes: bytes,
      duration: duration,
      mimeType: kIsWeb ? 'audio/wav' : 'audio/mp4',
    );
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}

class DeviceVoicePlayer implements VoicePlayer {
  DeviceVoicePlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> play(Uint8List bytes, {required String mimeType}) {
    return _player.play(BytesSource(bytes, mimeType: mimeType));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

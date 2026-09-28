import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/display_message.dart';

/// Display metadata and bytes that stay on this device.
///
/// This map is not the envelope table and is not sent to the server.
class LocalAttachment {
  const LocalAttachment({
    required this.kind,
    this.name,
    this.bytes,
    this.duration = Duration.zero,
    this.mimeType,
  });

  final MockKind kind;
  final String? name;
  final Uint8List? bytes;
  final Duration duration;
  final String? mimeType;
}

class LocalMediaCatalog extends Notifier<Map<String, LocalAttachment>> {
  @override
  Map<String, LocalAttachment> build() => {};

  void put(String envelopeId, LocalAttachment attachment) {
    state = {...state, envelopeId: attachment};
  }
}

final localMediaProvider =
    NotifierProvider<LocalMediaCatalog, Map<String, LocalAttachment>>(
      LocalMediaCatalog.new,
    );

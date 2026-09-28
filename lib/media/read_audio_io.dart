import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readLocalAudio(String path) {
  return File(path).readAsBytes();
}

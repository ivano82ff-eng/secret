import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedLocalFile {
  const PickedLocalFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract interface class AttachmentPicker {
  Future<PickedLocalFile?> pick();
}

class DeviceAttachmentPicker implements AttachmentPicker {
  @override
  Future<PickedLocalFile?> pick() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    return PickedLocalFile(name: file.name, bytes: bytes);
  }
}

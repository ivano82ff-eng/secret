import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'session_cipher.dart';

/// Second layer on top of [SessionCipher]. The cipher output is unchanged;
/// these helpers only hide those bytes in a lossless lock-pattern PNG.
class LockStego {
  const LockStego._();

  static const pngSignature = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];

  static bool looksLikePng(Uint8List bytes) {
    if (bytes.length < pngSignature.length) return false;
    for (var i = 0; i < pngSignature.length; i++) {
      if (bytes[i] != pngSignature[i]) return false;
    }
    return true;
  }

  /// Hide [ciphertext] in the RGB least-significant bits of a lock picture.
  static Uint8List embed(Uint8List ciphertext) {
    final payload = Uint8List(4 + ciphertext.length);
    final length = ciphertext.length;
    payload[0] = (length >> 24) & 0xff;
    payload[1] = (length >> 16) & 0xff;
    payload[2] = (length >> 8) & 0xff;
    payload[3] = length & 0xff;
    payload.setRange(4, payload.length, ciphertext);

    final side = _sideFor(payload.length);
    final image = img.Image(width: side, height: side, numChannels: 3);
    _paintLock(image);
    _writeLsb(image, payload);
    return Uint8List.fromList(img.encodePng(image));
  }

  /// Ciphertext hidden in [payload], or null when [payload] is not our PNG.
  static Uint8List? extract(Uint8List payload) {
    if (!looksLikePng(payload)) return null;
    final image = img.decodePng(payload);
    if (image == null) {
      throw const FormatException('Lock picture could not be read');
    }
    final header = _readBytes(image, 4);
    final length =
        (header[0] << 24) | (header[1] << 16) | (header[2] << 8) | header[3];
    final capacity = (image.width * image.height * 3) ~/ 8;
    if (length < 1 || 4 + length > capacity) {
      throw const FormatException('Lock picture has no ciphertext');
    }
    final packed = _readBytes(image, 4 + length);
    return Uint8List.sublistView(packed, 4);
  }

  static int _sideFor(int payloadBytes) {
    final bits = payloadBytes * 8;
    var side = 64;
    while (side * side * 3 < bits) {
      side += 32;
      if (side > 1024) {
        throw StateError('Message is too large for the lock picture');
      }
    }
    return side;
  }

  static void _paintLock(img.Image image) {
    final background = img.ColorRgb8(0xD7, 0xDE, 0xE8);
    final ink = img.ColorRgb8(0x3D, 0x4E, 0x63);
    img.fill(image, color: background);
    final step = image.width >= 128 ? 48 : 32;
    for (var y = step ~/ 2; y < image.height; y += step) {
      for (var x = step ~/ 2; x < image.width; x += step) {
        _stampLock(image, x, y, ink);
      }
    }
  }

  static void _stampLock(img.Image image, int cx, int cy, img.Color color) {
    img.fillRect(
      image,
      x1: cx - 8,
      y1: cy - 1,
      x2: cx + 8,
      y2: cy + 10,
      color: color,
    );
    for (var deg = 200; deg <= 340; deg += 6) {
      final rad = deg * math.pi / 180;
      final px = cx + (6 * math.cos(rad)).round();
      final py = (cy - 1) + (7 * math.sin(rad)).round();
      if (px >= 0 && py >= 0 && px < image.width && py < image.height) {
        image.setPixelRgb(px, py, 0x3D, 0x4E, 0x63);
      }
    }
  }

  static void _writeLsb(img.Image image, Uint8List data) {
    final total = data.length * 8;
    var bit = 0;
    for (var y = 0; y < image.height && bit < total; y++) {
      for (var x = 0; x < image.width && bit < total; x++) {
        final pixel = image.getPixel(x, y);
        var r = pixel.r.toInt() & 0xff;
        var g = pixel.g.toInt() & 0xff;
        var b = pixel.b.toInt() & 0xff;
        r = _setBit(r, _bitAt(data, bit));
        bit++;
        if (bit < total) {
          g = _setBit(g, _bitAt(data, bit));
          bit++;
        }
        if (bit < total) {
          b = _setBit(b, _bitAt(data, bit));
          bit++;
        }
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    if (bit < total) {
      throw StateError('Lock picture ran out of pixels');
    }
  }

  static Uint8List _readBytes(img.Image image, int count) {
    final out = Uint8List(count);
    final total = count * 8;
    var bit = 0;
    var value = 0;
    var filled = 0;
    var written = 0;
    for (var y = 0; y < image.height && bit < total; y++) {
      for (var x = 0; x < image.width && bit < total; x++) {
        final pixel = image.getPixel(x, y);
        final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        for (final channel in channels) {
          if (bit >= total) break;
          value = (value << 1) | (channel & 1);
          filled++;
          bit++;
          if (filled == 8) {
            out[written++] = value & 0xff;
            value = 0;
            filled = 0;
          }
        }
      }
    }
    if (written != count) {
      throw const FormatException('Lock picture is truncated');
    }
    return out;
  }

  static int _bitAt(Uint8List data, int index) {
    final byte = data[index >> 3];
    final shift = 7 - (index & 7);
    return (byte >> shift) & 1;
  }

  static int _setBit(int channel, int bit) => (channel & 0xfe) | (bit & 1);
}

class OpenedMessage {
  const OpenedMessage({required this.text, required this.extraLayer});

  final String text;
  final bool extraLayer;
}

/// Session-cipher bytes, optionally wrapped in a lock PNG.
Future<Uint8List> sealMessage(
  SessionCipher cipher,
  String text, {
  required bool extra,
}) async {
  final encrypted = await cipher.encrypt(Uint8List.fromList(utf8.encode(text)));
  if (!extra) return encrypted;
  return LockStego.embed(encrypted);
}

/// Detect a lock PNG, extract the hidden bytes, then decrypt with [cipher].
Future<OpenedMessage> openMessage(
  SessionCipher cipher,
  String ciphertextBase64,
) async {
  final stored = base64Decode(ciphertextBase64);
  final hidden = LockStego.extract(stored);
  final plain = await cipher.decrypt(hidden ?? stored);
  return OpenedMessage(text: utf8.decode(plain), extraLayer: hidden != null);
}

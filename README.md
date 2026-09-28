# Секрет

Offline client for a one-to-one end-to-end messenger. The interface is Russian, Material 3, and Riverpod. It runs without a server: a mock transport stores ciphertext envelopes locally and answers with a mock reply.

Signal is not implemented. `MockSessionCipher` only prefixes a version byte and base64-wraps the payload so the send path is real. Production must replace it with official libsignal via FFI (`flutter_rust_bridge`) or a reviewed Dart port. Do not add a from-scratch ratchet.

The X25519 identity key is generated with `package:cryptography` (and `cryptography_flutter` where the platform plugin is present). The private key is stored only through `flutter_secure_storage`.

## Run

Requires the Flutter stable SDK.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 43123
```

Open http://127.0.0.1:43123

## Build

Project folders exist for web, Android, iOS, Linux, macOS, and Windows. These are Flutter targets, not a separate native app.

```bash
flutter build web
flutter build apk
flutter build appbundle
flutter build linux
flutter build windows
flutter build macos
flutter build ios --no-codesign
```

`flutter build apk` needs an Android SDK. `flutter build windows` needs a Windows host. `flutter build macos` and `flutter build ios` need a Mac with Xcode. On this machine `flutter build web` completed and wrote `build/web`. Linux was not compiled here: Ninja and the GTK 3 development libraries are not installed. The Android SDK is not installed, so the APK was not built. The Android, iOS, Linux, macOS, and Windows project folders are still in the tree.

The first launch creates an X25519 identity, calls the mock `POST /v1/devices`, and shows the issued `userId`. That id is what you send to the other person. A later launch with a stored key opens the chat list. There is no password.

The chat list starts with three local conversations. Sending in a thread appends your envelope and a mock inbound reply. The list preview stays the neutral placeholder «Сообщение».

«Дополнительное шифрование» in a chat’s menu applies only to that chat and is kept on this device. While it is on, the list row and the thread header show a lock, and the thread wallpaper is two or three translucent bubbles of different sizes, clipped to the conversation pane. A message is still encrypted with the session cipher first. Those ciphertext bytes are then hidden in the least significant bits of a lossless lock-pattern PNG, and that PNG is what the envelope stores as `ciphertext` (base64). Chats with the toggle off keep the normal ciphertext and the normal wallpaper. Turning it off restores the row and the wallpaper. No filename, mime type, or key is added to the wire JSON.

The composer has an emoji picker and one original animated smiley (a face against a brick wall). Files and short voice messages stay on this device: the bubble shows a name or a duration, and the wire envelope stays ciphertext only. If the microphone is blocked, the chat still sends text.

When a mock inbound message arrives for a thread that is not open, an in-app banner shows the sender name and «Новое сообщение», without the message body. On the web, the same neutral text is used for a local notification when the browser allows it.

Preview states (web):

- `/?preview=empty` — no chats
- `/?preview=loading` — list stays on the loading state
- `/?preview=error` — list error with retry
- `/?preview=thread-error` — opening a thread fails
- `/?preview=notify` — after the chat list opens, one inbound banner from Марина

## Server contract

[docs/server-contract.md](docs/server-contract.md)

`HttpMessengerTransport` implements the same `MessengerTransport` interface as the mock and throws `UnimplementedError` until that contract is filled in.

## What is stored

Drift table `envelopes`: id, chat id, sender, time, base64 ciphertext, status. No plaintext column. Database encryption is the next step and is not turned on.

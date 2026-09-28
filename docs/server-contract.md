# Server contract

The server stores and forwards ciphertext. It never receives a message body, a decryption key, or a filename.

Tokens are short-lived JWTs for `accessToken`. `refreshToken` is an opaque secret. One account, one device is enough for the first server, but every response still carries `deviceId`.

Prekey bytes are opaque. Until the two people compare safety numbers, a server can substitute a prekey bundle and sit in the middle (MITM). The client will show a safety-number screen when libsignal lands. That screen is a stub today and does not block chat.

Errors used below:

| Status | When |
| --- | --- |
| 401 | Missing, expired, or already-rotated token. |
| 409 | One-time prekeys for that user are exhausted. |

Other failures use 400 with `{ "error": "..." }`. No stack traces.

Base URL in examples: `https://api.example`.

## userId

`userId` is the address. `deviceId` is not.

The id is six digits and one Latin letter, written as three digits, a space, the letter, a space, three digits:

```
456 N 634
```

Canonical form matches `^[0-9]{3} [A-Z] [0-9]{3}$`. The letter is uppercase `A`–`Z`. `POST /v1/devices` assigns a new id in this form and returns it as `userId`. Reinstalling with the same identity public key still creates a new `userId`. The server stores and returns only the canonical form. On input, trim the string, collapse spaces, and uppercase the letter before lookup. A recipient id that is not this shape is `400`.

In `GET /v1/keys/bundle/{userId}` the spaces are percent-encoded (`456%20N%20634`). JWT `sub` is this same `userId`.

## POST /v1/devices

Register this device. The identity public key is the X25519 public key the client generated. `signedPreKey` and `oneTimePreKeys` are stored as opaque records. The current client sends placeholders until libsignal fills them; the server must not interpret the bytes.

Request:

```json
{
  "registrationId": 4821,
  "identityPublicKey": "m2s8Q0h1n0c8p2a5d7f9h1j3k5m7n9p1q3r5s7t9u1w=",
  "signedPreKey": {
    "keyId": 1,
    "publicKey": "cHVibGljLXByZWtleS1ieXRlcy0zMi4uLi4=",
    "signature": "c2lnbmF0dXJlLWJ5dGVzLTY0Li4uLi4uLi4="
  },
  "oneTimePreKeys": [
    { "keyId": 1, "publicKey": "b25ldGltZS1wdWJsaWMta2V5LTE=" },
    { "keyId": 2, "publicKey": "b25ldGltZS1wdWJsaWMta2V5LTI=" }
  ]
}
```

Response `201`:

```json
{
  "userId": "456 N 634",
  "deviceId": "device_1",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0NTYgTiA2MzQifQ.sig",
  "refreshToken": "rfr_7b1c9e"
}
```

## POST /v1/sessions/refresh

Rotate both tokens. The presented refresh token becomes invalid.

Request:

```json
{ "refreshToken": "rfr_7b1c9e" }
```

Response `200`:

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0NTYgTiA2MzQiLCJ2IjoxfQ.sig",
  "refreshToken": "rfr_a02d44"
}
```

`401` when the refresh token is unknown or already used:

```json
{ "error": "invalid refresh token" }
```

## PUT /v1/keys/one-time

Replenish the one-time prekey pool. Requires `Authorization: Bearer <accessToken>`.

Request:

```json
{
  "oneTimePreKeys": [
    { "keyId": 3, "publicKey": "b25ldGltZS1wdWJsaWMta2V5LTM=" }
  ]
}
```

Response `200`:

```json
{ "stored": 1 }
```

## GET /v1/keys/bundle/{userId}

Fetch a prekey bundle to start a session. Requires `Authorization: Bearer <accessToken>`.

Consumes one one-time prekey when one is available. `oneTimePreKey` is omitted only when you intentionally document a signed-prekey-only fallback; this API returns **409** instead of a bundle with an empty pool.

Response `200`:

```json
{
  "userId": "781 K 209",
  "deviceId": "device_1",
  "registrationId": 1904,
  "identityPublicKey": "Ym9iLWlkZW50aXR5LXB1YmxpYy1rZXk=",
  "signedPreKey": {
    "keyId": 1,
    "publicKey": "Ym9iLXNpZ25lZC1wcmVrZXk=",
    "signature": "Ym9iLXNpZ25lZC1wcmVrZXktc2ln"
  },
  "oneTimePreKey": {
    "keyId": 3,
    "publicKey": "Ym9iLW9uZS10aW1lLXByZWtleQ=="
  }
}
```

`409` when the pool is empty:

```json
{ "error": "one-time prekeys exhausted" }
```

The client must later show a safety number derived from the identity keys. Do not treat a successful bundle fetch as proof the peer is who they claim.

## WebSocket /v1/ws

Upgrade `GET /v1/ws`. Do not accept the access token as a query parameter.

Auth, either:

- `Authorization: Bearer <accessToken>` on the upgrade request, or
- the first text frame, and no other frame before it:

```json
{ "type": "auth", "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0NTYgTiA2MzQifQ.sig" }
```

If auth fails, close the socket. A `401` on the upgrade is correct when the header is present and bad. For a bad first frame, send one error and close:

```json
{ "type": "error", "status": 401, "error": "invalid access token" }
```

### Client to server

```json
{
  "type": "envelope",
  "id": "env_01j8",
  "recipientUserId": "781 K 209",
  "ciphertext": "AQJDZmFrZS1jaXBoZXJ0ZXh0",
  "sentAt": "2026-09-27T18:04:11.000Z"
}
```

`ciphertext` is base64 opaque bytes. There is no `body`, `text`, `plaintext`, or `filename`.

The server appends the authenticated sender and forwards this delivery frame to the recipient's socket:

```json
{
  "type": "envelope",
  "id": "env_01j8",
  "senderUserId": "456 N 634",
  "recipientUserId": "781 K 209",
  "ciphertext": "AQJDZmFrZS1jaXBoZXJ0ZXh0",
  "sentAt": "2026-09-27T18:04:11.000Z"
}
```

Then it tells the sender the message was accepted:

```json
{ "type": "ack", "id": "env_01j8" }
```

The server does not decrypt, does not store keys, and does not expect attachments. Persist the envelope fields only: id, sender, recipient, ciphertext, sentAt, and enough device routing to deliver them.

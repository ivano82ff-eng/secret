# Контракт сервера

Сервер хранит и пересылает шифротекст. Тела сообщения, ключа расшифровки и имени файла он не получает и не хранит.

Основа — `docs/server-contract.md` на `main`, коммит `bbbf3d26fabc`. Этот файл его не заменяет.

Стек этой версии: Node.js, HTTP, WebSocket, PostgreSQL. Redis нет. MinIO нет. Файлы и голосовые байты в это хранилище не кладутся.

В примерах базовый URL — `https://api.example`. Тела HTTP — JSON. Стек трейсов в ответах нет.

Пароля нет. Учётную запись создаёт только `POST /v1/devices`.

## Ошибки

| Код | Когда |
| --- | --- |
| 401 | Токена нет, он просрочен или уже ротирован. |
| 409 | Одноразовые prekey этого пользователя кончились. |

Любой другой сбой — `400` и тело `{ "error": "..." }`.

Тексты ошибок, которые уже зафиксированы:

```json
{ "error": "invalid refresh token" }
```

```json
{ "error": "one-time prekeys exhausted" }
```

```json
{ "type": "error", "status": 401, "error": "invalid access token" }
```

## userId

Адрес человека — `userId`. `deviceId` адресом не является.

Шесть цифр и одна латинская буква: три цифры, пробел, буква, пробел, три цифры.

```
456 N 634
```

Канонический вид: `^[0-9]{3} [A-Z] [0-9]{3}$`. Буква — заглавная латиница `A`–`Z`.

Сервер выдаёт новый `userId` в `POST /v1/devices` и дальше отдаёт только канонический вид. Повторная установка с тем же публичным ключом личности создаёт новый `userId`. Старый адрес при этом не оживает.

Перед поиском: обрезать края, схлопнуть подряд идущие пробелы в один, букву перевести в верхний регистр. `456  n   634` становится `456 N 634`. Строка без пробелов (`456N634`) и строка с нелатинской буквой каноном не являются: это `400`.

В пути `GET /v1/keys/bundle/{userId}` пробелы закодированы: `456%20N%20634`. В JWT поле `sub` — тот же `userId`.

## POST /v1/devices

Регистрация устройства и создание учётки. Авторизация не нужна. Тот же `identityPublicKey` не ищется: каждый вызов — новый пользователь и новый `userId`.

`identityPublicKey` — публичный ключ X25519, который собрал клиент. `signedPreKey` и `oneTimePreKeys` сервер хранит как непрозрачные записи и байты не разбирает. Пока клиент шлёт заглушки, сервер всё равно принимает их как есть.

Запрос:

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

Ответ `201`:

```json
{
  "userId": "456 N 634",
  "deviceId": "device_1",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0NTYgTiA2MzQifQ.sig",
  "refreshToken": "rfr_7b1c9e"
}
```

На первую версию хватает одной учётки и одного устройства. `deviceId` сервер назначает сам и всё равно возвращает его здесь и в бандле.

Вместе с учёткой сохраняются `registrationId`, `identityPublicKey`, подписанный prekey и начальный пул одноразовых ключей. Повторная загрузка одноразового ключа с тем же `keyId` не очищает `used_at`.

## Токены

`accessToken` — JWT (в примерах алгоритм HS256). Живёт 15 минут. Обязательные поля: `sub` = `userId`, `exp`. Сервер проверяет подпись и срок. Сам access-токен в базе не хранится.

`refreshToken` — случайный непрозрачный секрет. Живёт 30 дней. В базе лежит только SHA-256 от строки токена, не сам токен.

Защищённые вызовы ждут заголовок `Authorization: Bearer <accessToken>`. Это `PUT /v1/keys/one-time`, `GET /v1/keys/bundle/{userId}` и WebSocket.

### POST /v1/sessions/refresh

Выдаёт новую пару и гасит предъявленный refresh. Авторизация Bearer не нужна: секрет передаётся в теле.

Запрос:

```json
{ "refreshToken": "rfr_7b1c9e" }
```

Ответ `200`:

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0NTYgTiA2MzQiLCJ2IjoxfQ.sig",
  "refreshToken": "rfr_a02d44"
}
```

Неизвестный, просроченный или уже использованный refresh — `401`:

```json
{ "error": "invalid refresh token" }
```

Порядок: найти запись по хешу, убедиться, что срок не вышел, удалить эту запись, записать хеш нового refresh, и только потом отдать пару. Повтор старого секрета новую пару не выдаёт.

## PUT /v1/keys/one-time

Пополнить пул одноразовых prekey текущего пользователя. Нужен Bearer.

Запрос:

```json
{
  "oneTimePreKeys": [
    { "keyId": 3, "publicKey": "b25ldGltZS1wdWJsaWMta2V5LTM=" }
  ]
}
```

Ответ `200`:

```json
{ "stored": 1 }
```

`stored` — сколько ключей принято в этом запросе. Запись идёт upsert по паре (пользователь, `keyId`): `publicKey` можно заменить, `used_at` этот upsert не сбрасывает. Уже потраченный ключ потраченным и остаётся.

## GET /v1/keys/bundle/{userId}

Выдать бандл, чтобы начать сессию. Нужен Bearer. `{userId}` — адрес собеседника в каноническом виде, пробелы как `%20`.

Сервер забирает один свободный одноразовый ключ и больше его не выдаёт. Захват — один запрос с блокировкой строки, чтобы два параллельных чтения не получили один ключ:

```sql
UPDATE one_time_prekeys
SET used_at = now()
WHERE id = (
  SELECT id
  FROM one_time_prekeys
  WHERE user_id = $1 AND used_at IS NULL
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
RETURNING key_id, public_key;
```

Пустой пул — не бандл без `oneTimePreKey`, а `409`. Ключ, который не удалось занять, в ответ не попадает.

Ответ `200`:

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

Пул пуст:

```json
{ "error": "one-time prekeys exhausted" }
```

Неизвестный адрес и адрес не в каноническом виде — `400`. Успешный бандл не доказывает, что собеседник тот, за кого себя выдаёт: пока люди сами не сверят контрольное число, сервер может подменить бандл. Экран сверки будет на клиенте, когда появится libsignal. Этот вызов чат не блокирует.

## WebSocket /v1/ws

Переход с `GET /v1/ws`. Токен в query string не принимается.

Вход одним из двух способов:

- заголовок `Authorization: Bearer <accessToken>` на запросе перехода;
- или первый текстовый кадр, и до него других кадров нет:

```json
{ "type": "auth", "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0NTYgTiA2MzQifQ.sig" }
```

Чужой токен закрывает сокет. Если заголовок был и он плохой — `401` на переходе. Если плохой первый кадр — один кадр ошибки и закрытие:

```json
{ "type": "error", "status": 401, "error": "invalid access token" }
```

### Клиент → сервер

```json
{
  "type": "envelope",
  "id": "env_01j8",
  "recipientUserId": "781 K 209",
  "ciphertext": "AQJDZmFrZS1jaXBoZXJ0ZXh0",
  "sentAt": "2026-09-27T18:04:11.000Z"
}
```

`ciphertext` — непрозрачные байты в base64. Полей `body`, `text`, `plaintext`, `filename` нет. Поля `kind` (`text`, `file`, `voice`) нет и добавлять его нельзя: тип сообщения сервер не различает.

`senderUserId` из кадра клиента не читается. Отправитель берётся из сессии по access-токену.

`recipientUserId` приводится к каноническому виду. Чужой формат — кадр ошибки со статусом `400`, без `ack`. Неизвестный получатель — то же самое.

Сервер пишет конверт и только после commit шлёт отправителю:

```json
{ "type": "ack", "id": "env_01j8" }
```

До commit `ack` нет. Если запись не сохранилась, `ack` нет.

Повтор того же `id` от того же отправителя вторую строку не создаёт. `ack` уходит, когда эта строка уже зафиксирована.

Хранятся только поля доставки: `id`, отправитель, получатель, `ciphertext`, `sentAt` клиента, серверный `received_at` и маршрутизация на устройство получателя. `received_at` ставит сервер в момент записи.

Очередь для того, кто не в сети, сортируется по `received_at`, не по `sentAt`. Открытому сокету получателя кадр уходит после commit. Закрытому — ждёт и уходит при следующем успешном входе, по возрастанию `received_at`. Из очереди конверт убирается после записи кадра в сокет получателя.

Кадр получателю:

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

Сервер конверт не расшифровывает и ключей сообщения не хранит.

Вложения этой версией не ожидаются. Позже байты файла и голоса останутся внутри того же шифротекста, ключ файла — тоже внутри него. Смайлы и смайл на стене собирает клиент. Графическое дополнительное шифрование — PNG вокруг уже существующего шифротекста сессии; на сервер приходит тот же непрозрачный `ciphertext`.

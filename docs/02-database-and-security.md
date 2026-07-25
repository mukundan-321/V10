# 02 — Database and Security

Sections covered: Database, Security.

---

## 5. Database

### Everything about drift, in this project

`drift` is used in "Dart-defined schema" style: each table is a Dart
class extending `Table`, with each column declared as a getter
returning a typed column builder (`text()`, `integer()`, `boolean()`,
`dateTime()`, `real()`). `drift_dev`'s `build_runner` codegen reads
these classes and generates (into `app_database.g.dart`, not checked
into the repo):
- A typed **row class** per table (e.g. `Messages` → `Message`,
  `Reactions` → `Reaction` — drift drops a trailing `s` from the table
  class name by default to name the row class; two tables in this
  schema don't end in `s` and use `@DataClassName(...)` explicitly to
  avoid a table/row name collision — see "gotchas" below).
- A typed **Companion class** per table (e.g. `MessagesCompanion`) used
  for type-safe inserts/updates, where each field is a `Value<T>`
  wrapper distinguishing "not set" from "set to null."
- The `_$AppDatabase` base class that `AppDatabase` extends, exposing
  `db.messages`, `db.reactions`, etc. as query-building entry points.

### Every table, every column

**`Messages`** — the core chat table.
| Column | Type | Nullable | Purpose |
|---|---|---|---|
| `id` | text (PK) | no | UUIDv4, generated client-side on send or on receipt (peer's own ID, reused as-is). |
| `senderDeviceId` | text | no | Either the literal string `'local'` or `'peer'` — see "known simplification" below. |
| `content` | text | yes | Message body. Null for media-only messages (media isn't implemented yet — see doc 06). |
| `replyToMessageId` | text | yes | ID of the message this replies to. **Not** a SQL foreign key — see the in-code comment; this is deliberate, not an oversight (explained below). |
| `threadRootId` | text | yes | For threaded replies; not currently populated by any code path — the column exists ahead of a feature that reads/writes it. |
| `isEdited` | boolean | no (default false) | Set true by `editMessage`. |
| `editedAt` | datetime | yes | Timestamp of the last edit. |
| `isDeletedForMe` | boolean | no (default false) | Local-only soft delete — `watchMessages()` filters these out. |
| `isDeletedForBoth` | boolean | no (default false) | Set on both devices when `deleteForBoth` succeeds. |
| `isPinned` | boolean | no (default false) | |
| `forwardedFromMessageId` | text | yes | Not currently populated by any code path — schema ahead of feature. |
| `sentAt` | datetime | no | When the message was created (indexed — see below). |
| `deliveredAt` | datetime | yes | Set when the send actually reached the peer over the wire. |
| `readAt` | datetime | yes | Not currently populated — no "mark as read" feature exists yet. |
| `mediaMetadataId` | text | yes | Would link to `MediaMetadataTable`; unused today since no message ever sets it (no media feature). |

Messages are stored **already decrypted at rest**. This is deliberate:
the entire database *file* is encrypted (SQLCipher), so a second layer
of per-row/per-field encryption on top would add real complexity (you
can no longer do a plain `WHERE content LIKE ...` search, every read
needs a decrypt step) for no additional security benefit — the
plaintext is already only ever readable by someone who has the
database passphrase, at which point they can read everything anyway.

**`MediaMetadataTable`** (row class `MediaMetadataRow` — explicitly
named via `@DataClassName` because the table class doesn't end in
`s`, so drift's default row-class-naming would otherwise collide with
the table class itself). Fully defined in the schema, **but no code
path currently creates a row here** — this is groundwork for a media
transfer feature that doesn't exist yet (see doc 06). Columns: `id`,
`localPath` (never transmitted — only a local file path), `mimeType`,
`sizeBytes`, `checksumSha256` (for post-transfer integrity
verification, once transfer exists), `transferState`,
`transferProgress`, `isOriginalQuality`, `widthPx`/`heightPx`/`durationMs`.

**`Reactions`** — one shared table for reactions on any target,
disambiguated by `targetType` (only `'message'` is ever used today;
the column exists so extending to other reactable content later
doesn't need a schema migration). Columns: `id`, `targetId`,
`targetType`, `reactorDeviceId`, `emoji`, `reactedAt`.

**`KeyRecords`** — stores the **peer's public key material only**.
Never the local device's private keys (those live in
`flutter_secure_storage` — see Security section). Columns: `id` (as of
the latest fix, this is the peer's *actual* device ID for the identity
row — see doc 03's "bugs found and fixed" note), `keyType` (one of
`'peer_identity_pub'`, `'peer_signing_pub'` — a `'session_meta'`
literal is documented in a comment but never actually written by any
code path today), `publicKeyBase64`, `fingerprint` (the computed
safety number for the pair), `fingerprintVerifiedByUser` (whether the
human has confirmed the safety number matches — the actual security
boundary of pairing), `createdAt`, `rotatedAt`/`expiresAt` (columns
exist, no code path currently sets them — session key rotation
happens in memory per-connection, not tracked in this table).

**`Settings`** — a plain key/value table (`key` text primary key,
`value` text). Defined, never read or written by any current code
path — there's no settings screen. Groundwork only.

### Why SQLCipher

Plain SQLite stores data in cleartext on disk — anyone with filesystem
access to the app's data directory (a rooted/jailbroken device, a
device backup, a forensic tool) can read every message directly.
SQLCipher is a SQLite extension that transparently encrypts the entire
database *file* with AES-256 (in CBC mode with an HMAC for integrity,
specifically), keyed by a passphrase supplied via `PRAGMA key`. Every
page of the file is encrypted; nothing is readable without the
passphrase, including the schema itself, not just message content.

**Wiring in this codebase:** `AppDatabase.open(passphrase)` builds a
`LazyDatabase` (drift defers actually opening the file until first
query) whose `setup` callback runs `PRAGMA key = '<passphrase>'`
(with embedded quotes escaped) immediately after opening the raw
connection, before drift does anything else with it. It then verifies
SQLCipher actually took effect by running `PRAGMA cipher_version;` and
checking the result set is non-empty (if SQLCipher isn't actually
linked into the SQLite build, that pragma returns no rows rather than
erroring, so checking the result — not just running the pragma — is
what makes this check real).

**The current, critical gap:** `main.dart` calls
`configureDependencies(dbPassphrase: 'REPLACE_WITH_DERIVED_KEY')` — a
fixed placeholder string, not a derived secret. This means, as shipped
right now, the "encrypted" database is encrypted with a passphrase
that's identical on every install and visible in source. **This must
be replaced with a passphrase derived from a real secret** (e.g. a
random key generated on first launch and stored in
`flutter_secure_storage`, or derived from a biometric/PIN-gated key)
before this touches real data. This is flagged with a `TODO` in the
code and repeated here deliberately — it's the single most important
unresolved item in the entire codebase.

### Migrations

`schemaVersion => 1` — this project has never shipped a schema change,
so no `MigrationStrategy` has been written. Drift's mechanism for
this, when needed: override `migration` to return a
`MigrationStrategy(onUpgrade: (m, from, to) async { ... })` that runs
`m.addColumn(...)`/`m.createTable(...)` etc. based on the `from`/`to`
version numbers, and bump `schemaVersion`. Nothing here yet — this is
a real gap to fill in before ever shipping a schema change, since
without it, a version bump would need users to lose their data (or a
manual, undocumented migration).

### Indexes

One explicit index: `@TableIndex(name: 'messages_sent_at_idx', columns: {#sentAt})`
on `Messages`, added because every message list query does
`ORDER BY sentAt` and a full table scan for that ordering doesn't
scale. No other explicit indexes exist. `searchMessages()`
deliberately does **not** use a SQL `LIKE` query with an index — it
fetches all non-deleted messages and filters in Dart with
`.toLowerCase().contains()` (see doc 06 for why: a raw SQL `LIKE`
treats literal `%`/`_` in the user's search text as wildcards,
silently producing wrong results — filtering in Dart avoids that
correctness bug at this app's message-volume scale, where a full scan
is cheap enough not to matter).

### Relationships

Deliberately **not** modeled as SQL foreign keys, anywhere in this
schema (`replyToMessageId`, `mediaMetadataId` are both plain nullable
text columns, not `.references(...)`). This is not an oversight — it
was an actual bug that got found and fixed: SQLite foreign keys are
disabled by default unless `PRAGMA foreign_keys = ON` is explicitly
set (which this codebase never does), so declaring FKs would have
looked correct while doing nothing, and would have started silently
rejecting legitimate data — specifically, a reply arriving over the
wire *before* the message it replies to has synced, which is a normal
occurrence in a P2P system with no guaranteed delivery order — the
moment anyone "correctly" turned that pragma on later. Referential
integrity for these relationships is an intentional application-level
concern, not a database-level one.

### Database lifecycle

1. `main()` calls `configureDependencies(dbPassphrase: ...)`.
2. `injector.dart` registers `AppDatabase` as a **lazy singleton**:
   `sl.registerLazySingleton<AppDatabase>(() => AppDatabase.open(dbPassphrase))`
   — the `AppDatabase` object is constructed (which just sets up the
   `LazyDatabase` executor) the first time anything calls `sl<AppDatabase>()`,
   not at registration time.
3. The **actual file** isn't opened until the first real query runs
   against it (that's what "Lazy" in `LazyDatabase` means) — at that
   point, the `setup` callback (PRAGMA key, cipher verification) runs.
4. The database lives for the entire app process lifetime — there is
   no explicit `db.close()` call anywhere in the app's normal
   operation (see doc 06, "known gaps," for why this is a deliberate,
   documented, low-priority gap rather than an oversight).
5. For tests: `AppDatabase.forTesting()` uses `NativeDatabase.memory()`
   — an in-memory, unencrypted database, so tests run fast and don't
   need SQLCipher at all.

### How data is read and written

**Writes** go through typed Companion inserts/updates, e.g.:
```dart
await db.into(db.messages).insert(MessagesCompanion.insert(
  id: id,
  senderDeviceId: _localDeviceIdPlaceholder,
  content: Value(content),
  sentAt: now,
));
```
**Reads** are either one-shot (`.get()`) or reactive (`.watch()` —
returns a `Stream` that re-emits automatically whenever a query result
*could* have changed, by tracking which tables the query touched).
`ChatRepositoryImpl.watchMessages()` uses `.watch()` — this is the
entire mechanism behind the chat screen updating live without any
manual "refresh" logic: drift notices a write to the `messages` table
and re-runs the active watch query automatically, which flows through
`chatProvider` (a Riverpod `StreamProvider`) into the widget tree.

### Possible bottlenecks

- SQLCipher's per-page AES overhead — real but not significant at this
  app's scale (a two-person chat, likely thousands, not millions, of
  rows over the app's lifetime).
- `searchMessages()`'s full-table-scan-then-filter-in-Dart approach —
  fine today, would need to become a proper indexed SQL search (with
  correct wildcard escaping) if message volume ever grew large.
- No index on `content`, `threadRootId`, or `replyToMessageId` — not a
  bottleneck today since no query filters on them at scale, but worth
  revisiting if reply-threading or content-based queries grow more complex.

---

## 6. Security

This section is the one place in this document set where precision
matters most — read it alongside `lib/features/pairing/data/crypto/`
directly, not as a substitute for it.

### The trust model, stated plainly

This app uses **Trust On First Use (TOFU)**, the same model Signal,
SSH, and most other end-to-end-encrypted systems use for initial key
exchange. The cryptography *guarantees* that whoever holds the private
key matching a given public key controls that side of the
conversation, and that no one without that private key can read
messages or forge them. What cryptography **cannot** guarantee is that
the public key you received during pairing actually came from the
person you meant to pair with, rather than an attacker positioned
between you during that exchange (a "machine in the middle").
**That's what fingerprint verification is for** — it's not a
formality, it's the actual security boundary. Skipping it means
trusting the pairing channel (however the QR/text was transmitted)
implicitly, with no cryptographic backstop.

### Key generation

On first launch, `IdentityKeyService.getOrCreateIdentity()` generates
two separate keypairs:
- **X25519** (`identityKeyPair`) — an elliptic-curve Diffie-Hellman
  key exchange algorithm. Used to derive shared secrets, never to
  sign anything.
- **Ed25519** (`signingKeyPair`) — an elliptic-curve signature
  algorithm. Used to sign the pairing payload, never for key exchange.

**Why two separate keypairs instead of one doing both jobs:** this is
a deliberate, standard cryptographic practice called algorithm/key
separation. Using the same key for both signing and key-exchange can,
depending on the specific algorithms and how they're combined, create
subtle cross-protocol attacks (a signature in one context being
replayable/interpretable as valid key-exchange material in another).
X25519 and Ed25519 are also different curve representations
internally (Montgomery vs. Edwards form of Curve25519) — they're not
even directly interchangeable at the bit level.

**Why Curve25519-family algorithms specifically:** X25519/Ed25519 are
widely audited, fast, constant-time-by-design (resistant to
timing-attack key leakage), and have no known practical weaknesses.
They're the same primitives underlying Signal's own protocol, WireGuard,
and most modern secure messaging systems — this is a "boring,
well-trodden choice" by design, not an experimental one.

A **device ID** is also generated at this point — 16 random bytes
(`Random.secure()`) base64url-encoded. Not cryptographic material,
just a unique local identifier.

### Key storage

Private key material (the 32-byte seeds for both keypairs) is written
to `flutter_secure_storage` — Android Keystore or iOS/macOS Keychain —
**never** to the SQLite database, encrypted or not. This is a
deliberate, meaningful separation: even if the SQLCipher passphrase
were somehow compromised, the attacker would gain access to message
content, not to the private keys that would let them impersonate this
device or decrypt *future* sessions with a fresh MITM.

`getOrCreateIdentity()` is memoized in-memory (a `Future<LocalIdentity>?`
field) — this was a real race-condition fix: without it, two
concurrent calls before the first completes could each see no stored
key, each generate a *different* keypair, and race to persist,
leaving one caller silently out of sync with what's actually stored.

### Secure storage

`SecureKeyValueStore` is an abstraction over `flutter_secure_storage`,
with a real implementation (`DeviceSecureKeyValueStore`) and an
in-memory fake (`InMemorySecureKeyValueStore`) used only in tests —
because `flutter_secure_storage` needs real platform channels
unavailable under plain `flutter_test`. The real implementation
configures `AndroidOptions(encryptedSharedPreferences: true)` (uses
Android's `EncryptedSharedPreferences`, which itself is backed by
Android Keystore-managed keys) and
`IOSOptions(accessibility: .first_unlock_this_device)` (the key is
only accessible after the device has been unlocked at least once
since boot, and — critically — `this_device` means it does **not**
sync via iCloud Keychain to other devices, which matters since this
key must never leave this specific device).

### Encryption — two layers, for different data

**Layer 1 — the pairing payload signature (Ed25519).** Every QR/
invite-link payload is signed with the sender's Ed25519 key before
transmission (`PairingPayload.createSigned`). This proves the payload
wasn't tampered with in transit (e.g. by whatever app it got pasted
through) — it does **not** prove who signed it, since an attacker
generating their own fresh keypair could sign their own payload just
as validly. That's the TOFU gap fingerprint verification closes.

**Layer 2 — session encryption (X25519 ECDH + HKDF + ChaCha20-Poly1305).**
This is the encryption that actually protects message content. Full
flow:
1. Both sides generate a **fresh, ephemeral** X25519 keypair for this
   specific session (`SessionKeyExchange.generateEphemeral()`) —
   separate from the long-term identity keypair generated at first
   launch. This is what provides **forward secrecy**: even if a
   long-term private key were later compromised, past session keys
   (derived from ephemeral keys that were discarded after use) can't
   be reconstructed.
2. Both sides compute a shared secret via ECDH
   (`X25519().sharedSecretKey(keyPair: local, remotePublicKey: remote)`)
   — this produces the same 32-byte secret on both sides without ever
   transmitting it.
3. **HKDF** (`SessionKeyExchange._hkdfDerive`) derives two *separate*
   directional keys from that one shared secret, using distinct
   context strings (`'two-person-app/i2r/v1'` and
   `'.../r2i/v1'`) — domain separation, so the
   initiator's send key is never the same bytes as the responder's
   send key. This matters for nonce-reuse safety (see below).
4. **ChaCha20-Poly1305** (an AEAD cipher — Authenticated Encryption
   with Associated Data) encrypts every message. AEAD means each
   ciphertext carries a MAC (message authentication code) verified on
   decrypt — tampering with even one bit of ciphertext causes
   decryption to fail loudly, rather than silently returning garbage
   plaintext.

**Why ChaCha20-Poly1305 instead of AES-GCM** (the other extremely
common modern AEAD choice): both are secure, well-audited choices;
ChaCha20-Poly1305 was picked because it doesn't depend on hardware AES
acceleration for good performance (AES-GCM without AES-NI hardware
support, common on some Android devices' Dart/software crypto paths,
is meaningfully slower and historically more prone to timing-attack
implementation bugs than a well-implemented ChaCha20) — a defensible,
conservative choice for a cross-platform Dart implementation rather
than a native one.

### Nonce construction and replay protection

Each direction's `SessionCipher` tracks a strictly monotonic counter
(`_sendCounter`, `_highestSeenReceiveCounter`). The 12-byte
ChaCha20-Poly1305 nonce is 4 zero bytes + the 8-byte big-endian
counter. This is safe from nonce reuse because: (a) the key is unique
per session per direction (fresh ephemeral ECDH + HKDF domain
separation, above), and (b) the counter never repeats within one
key's lifetime — a **new session means a new ephemeral key**, which
resets the counter against a completely different key, so there's no
cross-session counter collision risk.

Replay protection: `decrypt()` throws `ReplayDetectedException` if an
incoming counter is `<=` the highest one already seen. This is
deliberately **strict, not a sliding window** — a message can't arrive
out of counter order at all. This is only correct because the
underlying WebRTC data channel is configured `ordered: true`
(`RTCDataChannelInit()..ordered = true` in
`WebRtcConnectionManager.createOffer`), which guarantees SCTP-level
in-order, reliable delivery — the strict counter check is a second,
application-layer confirmation of a guarantee the transport layer is
already supposed to provide, not a replacement for it.

### Identity verification — the fingerprint / safety number

`FingerprintService.compute()` takes both devices' long-term X25519
identity public keys, sorts them into a canonical order (so it doesn't
matter which device computes it — both arrive at the identical
result), concatenates them, hashes with SHA-256, and formats the
result as 15 groups of 5 digits (75 digits total) — a "safety number"
the two humans compare out loud or side by side. This is the
**actual** authentication step: it converts "I received a public key
during pairing" into "I have independently confirmed this public key
belongs to the specific person I intended to pair with," using a
channel (voice, in-person) an attacker positioned during the QR/text
exchange doesn't control.

75 decimal digits ≈ 249 bits of entropy from a 256-bit hash — vastly
more than needed for human comparison; the point isn't
brute-force resistance (an attacker doesn't need to *guess* a
fingerprint, they'd need to find a *different* keypair producing the
*same* fingerprint against a specific target, i.e. a preimage/collision
attack against SHA-256, which is computationally infeasible at any
realistic scale).

### Authentication in the wire protocol

Beyond the pairing handshake, ongoing message authenticity comes
entirely from AEAD: only someone holding the correct session key
(derivable only from one of the two ECDH private keys) can produce a
ciphertext that decrypts successfully. There's no separate
per-message signature — the AEAD tag *is* the authentication for
session traffic.

**A real bug that was found and fixed here:** the incoming-message
handler originally applied `'edit'`/`'delete_for_both'` wire-protocol
frames to *any* message ID the peer referenced, without checking that
the peer actually authored that message. AEAD proves the frame came
from the paired peer — it does **not** prove the peer is only editing
messages the *sender-device-id* field says they should be allowed to
touch. That's an application-level authorization check, and it was
missing. Fixed by requiring `senderDeviceId == peer` in the update's
`WHERE` clause before applying an edit or delete-for-both.

### Cryptographic algorithms — summary table

| Algorithm | Used for | Why chosen |
|---|---|---|
| X25519 | ECDH key exchange (identity + ephemeral) | Fast, constant-time, no known practical weaknesses, industry standard for modern key exchange. |
| Ed25519 | Signing the pairing payload | Fast, constant-time, deterministic signatures (no per-signature randomness requirement to get right, unlike ECDSA). |
| ChaCha20-Poly1305 | AEAD encryption of session traffic | Doesn't require hardware AES acceleration for safe performance; well-audited, modern AEAD. |
| HKDF (with SHA-256) | Deriving directional session keys from one ECDH shared secret | Standard, provably-secure key derivation; domain separation via distinct info strings. |
| SHA-256 | Safety-number/fingerprint hashing | Standard, no known practical weaknesses for this use (not being used for password hashing, where a slow KDF would matter more). |

### Possible attacks and current weaknesses

- **Skipped fingerprint verification.** If the two humans never
  actually compare the safety number (the UI allows navigating past
  it once connected — nothing *forces* verification before chat
  becomes usable in every code path), the app degrades to "encrypted,
  but not authenticated against a MITM during initial pairing." This
  is a genuine, currently-possible user behavior, not just a
  theoretical weakness.
- **The hardcoded DB passphrase** (see Database section above) means
  data-at-rest encryption is currently theater, not real protection,
  until fixed.
- **No key rotation for long-term identity keys.** The X25519/Ed25519
  identity keypair generated on first launch is used forever (barring
  an explicit `destroyIdentity()` call, which no UI currently
  triggers). If that private key were ever extracted from secure
  storage (e.g. a compromised/jailbroken device), an attacker could
  impersonate that device indefinitely, including for **past**
  captured pairing payloads (though not past **session** traffic,
  which has forward secrecy via ephemeral keys — this only affects
  *future* impersonation, not decrypting old messages).
- **No post-pairing re-verification if a peer's key changes.**
  `_persistPeerKeys` does detect a *different* peer identity key
  arriving (vs. the one already stored) and correctly resets
  `fingerprintVerifiedByUser` to require re-verification — this is
  handled correctly. What's not handled: there's no *proactive* UI
  warning equivalent to Signal's "safety number has changed" banner;
  the user would only notice if they happened to check the fingerprint
  screen again.
- **iOS Keychain default persistence across app deletion.** Not
  audited/configured explicitly in this codebase — worth verifying
  before shipping, since a private key silently surviving an app
  *deletion* could have unexpected implications for a "delete this
  app to walk away" mental model a privacy-focused user might have.

### How these could be improved

- Make fingerprint verification a hard gate — don't allow entering the
  chat screen at all until `fingerprintVerified == true`, removing the
  current path where a connected-but-unverified session can be used.
- Derive the DB passphrase from a real secret immediately — this is
  not a "nice to have," it's the single highest-priority fix in the
  codebase.
- Add a UI-visible warning when a peer's identity key changes
  unexpectedly (the data layer already detects this — it just isn't
  surfaced to the user proactively).
- Consider periodic re-verification prompts, or at minimum, a
  persistent visual indicator of verification status inside the chat
  screen itself (currently, verification status is only visible during
  the pairing flow, not afterward).

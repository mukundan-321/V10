# 01 — Architecture Overview

Sections covered: High-Level Overview, Overall Architecture, Folder
Structure, Every Package.

---

## 1. High-Level Overview

### What is this application?

A mobile chat app for exactly two people, with no server anywhere in
the picture. Two phones find each other, establish a direct encrypted
connection over WebRTC, and exchange messages over that connection
directly. When the app is closed, the connection is gone — there is no
"account" living on a server, no message queue holding messages for
later delivery, nothing.

### What problem does it solve?

Ordinary messaging apps are built around a server: your messages pass
through (and are usually stored, at least transiently, by) a company's
infrastructure. Even end-to-end-encrypted apps like Signal still route
*ciphertext* through a central server, which means that company knows
*when* you talked, *how much* you talked, and *who* you talked to,
even if not *what* you said. This app removes that server entirely.
The two devices talk directly to each other. There is nothing for a
third party to see, store, or subpoena, because there is no third
party in the data path at all.

The trade-off, and it's a real one: **both people have to be online at
the same time for anything to work.** There's no store-and-forward.
Close the app, and you're not reachable until you open it again and
re-establish the connection. This is a deliberate design constraint,
not an oversight.

### What are the design goals?

In priority order:

1. **No server, ever.** Not "no server for messages" — no server for
   *anything*, including discovery/signaling. This is the hardest
   constraint and it shapes everything else.
2. **End-to-end encryption that's actually end-to-end**, meaning there
   is no point in the data path — not even a relay — that sees
   plaintext, and ideally no point that sees *ciphertext* either,
   since with no server there's nothing to intercept in the middle at
   all in the direct-connection case.
3. **Exactly two participants, permanently.** Not "two people in this
   conversation, but the architecture could support more" — the whole
   trust model (see doc 03) assumes exactly one other party ever
   exists.
4. **Real, working code over broad, stubbed code.** Given limited
   scope, chat is fully implemented end-to-end; other features
   (stories, feed, calls, media transfer) were deliberately cut rather
   than left as half-working placeholders. See doc 06 for what's
   *not* here and why.

### Why this architecture instead of alternatives?

- **Client-server with E2E encryption (Signal-style).** Rejected
  because it doesn't meet goal #1 — even encrypted, a server in the
  path is a server in the path. It sees connection metadata.
- **Federated (Matrix-style).** Same problem, distributed across more
  servers instead of one.
- **Peer-to-peer with a signaling server for discovery, direct
  transport for content.** Closest alternative — many "serverless" P2P
  apps work this way (a lightweight signaling server just exchanges
  WebRTC offer/answer, then content flows directly). Rejected because
  goal #1 says *no server for anything* — a signaling server, even a
  dumb one that never sees plaintext, is still infrastructure that
  could log connection metadata.
- **This app's actual approach: manual/out-of-band signaling.** The
  WebRTC offer/answer/ICE-candidate exchange — normally handled by a
  signaling server — is packed into a payload the user transmits
  themselves, via QR code or copy-pasted text, through any channel
  they like. This satisfies goal #1 completely. The cost is UX
  friction — pairing/reconnecting requires an explicit manual exchange
  step every time — the honest trade-off for "no server, ever."

---

## 2. Overall Architecture

### Layers

Clean architecture, applied per feature rather than globally:

```
+-------------------------------------------------------+
|  Presentation layer                                    |
|  (Flutter widgets, Riverpod providers)                 |
|  lib/features/<feature>/presentation/                  |
+---------------------------+----------------------------+
                             | depends on (via abstract interfaces only)
+---------------------------v----------------------------+
|  Domain layer                                           |
|  (entities, repository interfaces -- no implementation) |
|  lib/features/<feature>/domain/                          |
+---------------------------^----------------------------+
                             | implements
+---------------------------+----------------------------+
|  Data layer                                              |
|  (repository implementations: drift queries, crypto,      |
|   WebRTC signaling)                                        |
|  lib/features/<feature>/data/                                |
+---------------------------+------------------------------+
                             | depends on
+---------------------------v------------------------------+
|  Infrastructure / core layer                                |
|  (drift database, get_it DI container, Result/Failure         |
|   types, theme)                                                 |
|  lib/core/                                                       |
+-------------------------------------------------------------------+
```

There is no separate "business logic layer" folder — business logic
lives in the **data layer** (repository implementations). For an app
this size, adding a fourth "use case" layer between domain and
presentation would add indirection without value — repository methods
here already represent complete units of business logic (`sendMessage`,
`acceptInvite`, `deleteForBoth`), not raw CRUD needing a use-case
wrapper.

### Data flow, concretely: sending a chat message

```
ChatScreen (presentation)
  | user taps send
  v
ref.read(chatRepositoryProvider).sendMessage(content: ...)
  | (Riverpod provider resolves to the singleton from get_it)
  v
ChatRepositoryImpl.sendMessage()  (data layer)
  |
  +-> db.into(db.messages).insert(...)          [drift -> SQLCipher DB]
  |     (message is now persisted locally, unconditionally --
  |      this happens whether or not the peer is reachable)
  |
  +-> pairingRepository.transport?.send(bytes)   [domain interface]
        |
        v
      EncryptedTransport.send()  (pairing feature's data layer)
        | encrypts with SessionCipher (ChaCha20-Poly1305)
        v
      WebRtcConnectionManager.sendRaw()
        | RTCDataChannel.send()
        v
      (bytes travel over the live peer-to-peer connection)
        v
      [other device's WebRtcConnectionManager receives on its data channel]
        |
        v
      EncryptedTransport (other device) decrypts, verifies AEAD tag
        |
        v
      ChatRepositoryImpl (other device) inserts into ITS OWN local DB
        |
        v
      ChatScreen (other device) -- watching the DB via a Stream --
      rebuilds automatically with the new message
```

Chat never imports anything WebRTC- or crypto-specific directly. It
depends only on `PairingRepository` (an abstract interface) and,
through that, on `EncryptedChannel` (another abstract interface
exposing just `send()` and a `decryptedIncoming` stream). The entire
WebRTC/crypto machinery is invisible to the chat feature — this is the
concrete payoff of the domain-layer abstraction.

---

## 3. Folder Structure

```
lib/
  core/                          Shared infrastructure -- nothing here
                                  knows about "chat" or "pairing" as
                                  concepts.
    database/
      app_database.dart          The drift @DriftDatabase class --
                                  opens the SQLCipher-encrypted file,
                                  wires all tables together.
      tables/
        messages_table.dart      Messages + MediaMetadataTable schema.
        reactions_table.dart     Reactions schema (message reactions).
        keys_settings_tables.dart  KeyRecords (peer public keys +
                                  fingerprint verification state) +
                                  Settings (key/value, currently unused
                                  by any screen).
    di/
      injector.dart               get_it service locator setup.
                                  configureDependencies() is called
                                  once from main().
    error/
      failures.dart                Failure hierarchy -- PeerOfflineFailure,
                                  SignalingPayloadInvalidFailure,
                                  LocalStorageFailure, UnknownFailure.
    theme/
      app_theme.dart               Material 3 dark/light ThemeData.
    utils/
      result.dart                   Result<T> / Ok<T> / Err<T> -- the
                                  return type every repository method
                                  uses instead of throwing.

  features/
    pairing/                     Identity, key exchange, WebRTC
                                  signaling, the live encrypted channel.
                                  This is the foundational feature --
                                  chat depends on it, nothing depends
                                  the other way.
      domain/
        entities/
          device_identity.dart      Public-key-only identity record
                                  (local device or peer).
          encrypted_channel.dart    Abstract interface: send(bytes),
                                  decryptedIncoming stream. Chat's
                                  ONLY dependency on the pairing feature.
        repositories/
          pairing_repository.dart   Abstract interface: isPaired,
                                  localIdentity, peerIdentity,
                                  createInviteLink, acceptInvite,
                                  completePairing,
                                  confirmFingerprintVerified,
                                  connectionStatus, transport.
      data/
        crypto/
          identity_key_service.dart   X25519 + Ed25519 keypair
                                  generation/persistence.
          fingerprint.dart             Safety-number computation.
          pairing_payload.dart          Signed QR/invite-link payload
                                  format.
          session_crypto_service.dart   Ephemeral ECDH + HKDF + AEAD
                                  session encryption.
          secure_key_store.dart          Keychain/Keystore wrapper
                                  (+ in-memory fake for tests).
        signaling/
          webrtc_connection_manager.dart  RTCPeerConnection + data
                                  channel + ICE gathering.
          ice_config.dart                  STUN server list (TURN
                                  gated off by default).
          encrypted_transport.dart          Binds SessionCipher to the
                                  raw data channel -- implements
                                  EncryptedChannel.
        pairing_repository_impl.dart  Orchestrates all of the above --
                                  implements PairingRepository.
      presentation/
        providers/
          pairing_providers.dart      Riverpod providers exposing the
                                  repository and its live state.
        screens/
          pairing_flow_screen.dart     The entire pairing/reconnect UI
                                  state machine.
        widgets/
          qr_scanner_screen.dart        Reusable full-screen QR scanner.

    chat/                        Messaging. Depends on pairing only via
                                  EncryptedChannel + PairingRepository
                                  (never on WebRTC/crypto types directly).
      domain/
        entities/
          message.dart                ChatMessage entity.
        repositories/
          chat_repository.dart          Abstract interface.
      data/
        chat_repository_impl.dart       drift-backed CRUD + wire
                                  protocol (JSON frames) over
                                  EncryptedChannel.
      presentation/
        providers/
          chat_providers.dart            Riverpod providers.
        screens/
          chat_screen.dart                 The chat UI.

  main.dart                       Entry point -- DI setup, root
                                  navigation gate.
```

### Dependency rules (what depends on what)

- **`core/` depends on nothing feature-specific.** It's imported BY
  features, never the other way.
- **`domain/` depends only on `core/` and Dart/Flutter SDK types.**
  Never on `data/` or `presentation/`, not even within its own feature.
- **`data/` depends on its own feature's `domain/` (implements the
  interfaces) and on `core/`.** The chat feature's `data/` layer also
  depends on the **pairing feature's `domain/`** (specifically
  `EncryptedChannel` and `PairingRepository`) — this is the one
  cross-feature dependency in the codebase, and it's deliberately
  scoped to domain-layer interfaces only.
- **`presentation/` depends on its own feature's `domain/` (entities,
  repository interface) via Riverpod providers — never on `data/`
  directly.** A screen never does
  `import '.../data/chat_repository_impl.dart'`; it does
  `ref.read(chatRepositoryProvider)`, which resolves to a
  `ChatRepository` (the interface), with `get_it` supplying the
  concrete implementation behind the scenes.

### What should never directly communicate

- **Chat's presentation layer must never import anything from
  `pairing/data/`.** If a chat screen needs connection status, it goes
  through `pairingRepositoryProvider` (the `PairingRepository`
  interface), not through `WebRtcConnectionManager` or
  `EncryptedTransport` directly.
- **`core/database/` tables must never import anything from
  `features/`.** The schema is feature-agnostic — it doesn't know
  "Messages" belongs to a "chat feature," it's just a table.
- **Two repository *implementations* should never import each other.**
  `ChatRepositoryImpl` depends on `PairingRepository` (interface), not
  on `PairingRepositoryImpl` (implementation) — enforced by the DI
  graph in `injector.dart`, which registers `ChatRepositoryImpl` with
  a `PairingRepository`-typed constructor parameter.

---

## 4. Every Package

### `flutter_riverpod: ^2.5.1`
- **Why used:** State management — turning Stream-producing
  repository methods (`watchMessages()`, `connectionStatus`) into
  something Flutter widgets can reactively rebuild from
  (`StreamProvider`), plus a place to hold references to repositories
  (`Provider`) without manually threading them through constructors.
- **Why chosen over alternatives:** `provider` (the older, simpler
  package) lacks `StreamProvider`'s automatic subscription lifecycle
  management and Riverpod's compile-time safety improvements.
  `bloc`/`flutter_bloc` is a heavier pattern (explicit event/state
  classes for every interaction) that adds ceremony this app's
  relatively simple screens don't need. `GetX` was avoided because its
  state management is tightly coupled to its own DI/navigation system,
  which conflicts with using `get_it` for DI specifically so state
  management and DI stay independently swappable.
- **Advantages:** compile-time provider dependency checking,
  automatic dispose of stream subscriptions when no widget is
  listening, testable (providers can be overridden in tests).
- **Disadvantages:** another concept to learn beyond plain `setState`;
  some boilerplate (`ConsumerWidget`/`ConsumerStatefulWidget` instead
  of `StatelessWidget`/`StatefulWidget`).
- **Essential:** yes, for the reactive chat message list and
  connection-status indicator specifically — could be replaced with
  manual `StreamBuilder`s + `InheritedWidget` for repository access,
  but that's strictly more code for the same result.
- **Performance:** negligible overhead at this app's scale (a handful
  of providers, no complex derived-state graphs).
- **Security implications:** none directly — it's a state layer, not a
  data layer.

### `get_it: ^7.7.0`
- **Why used:** Dependency injection — a single place
  (`injector.dart`) wires concrete implementations
  (`ChatRepositoryImpl`, `PairingRepositoryImpl`) to their abstract
  interfaces (`ChatRepository`, `PairingRepository`), and anything
  needing a repository asks the locator for it by type.
- **Why chosen over alternatives:** `injectable` (codegen on top of
  `get_it`) was considered and rejected — for ~6 registrations, hand
  writing them is more readable than maintaining codegen annotations.
  Riverpod itself can also do DI (via `Provider`s holding repository
  instances) — `get_it` is used *underneath* Riverpod here specifically
  so "which concrete class implements this interface" wiring stays
  independent of the state-management choice.
- **Advantages:** trivial to read top-to-bottom, no codegen step, no
  magic.
- **Disadvantages:** no compile-time verification that all
  dependencies are registered — a missing registration only fails at
  runtime, when `sl<T>()` is first called.
- **Essential:** no — could be replaced entirely by Riverpod
  `Provider`s doing the same wiring. Kept separate deliberately.
- **Performance:** negligible — `registerLazySingleton` means nothing
  is constructed until first use.
- **Security implications:** none directly.

### `drift: ^2.17.0` + `sqlite3_flutter_libs: ^0.5.24` + `sqlcipher_flutter_libs: ^0.6.4`
- **Why used:** `drift` is a type-safe SQL ORM/query-builder — table
  schemas are Dart classes, queries are Dart method chains that
  compile to SQL, and `drift_dev`'s codegen produces typed row classes
  (`Message`, `Reaction`) and reactive `.watch()` streams.
  `sqlite3_flutter_libs` bundles the native SQLite binary per
  platform. `sqlcipher_flutter_libs` swaps that binary for a
  SQLCipher-compiled build, adding transparent full-database AES
  encryption.
- **Why chosen over alternatives:** `sqflite` requires hand-writing
  raw SQL strings and manually mapping `Map<String, dynamic>` rows to
  Dart objects — for a 5-table schema with non-trivial reactive
  queries, drift's type safety saves real bugs (a typo'd column name
  is a compile error, not a runtime one). `hive`/`isar` (NoSQL-style)
  were rejected because this data genuinely is relational (messages
  reference other messages via replies, reactions reference messages
  by ID) and benefits from real `WHERE`/`ORDER BY`/indexed queries.
- **Advantages:** compile-time query safety, reactive streams built
  in (what makes `ChatScreen`'s message list auto-update), migrations
  support (not yet exercised here — schema is still v1).
- **Disadvantages:** requires `build_runner` codegen
  (`app_database.g.dart` isn't checked in — see `BUILD.md`), an extra
  build step and a common "why won't this compile" trap for newcomers
  who forget to run it after changing a table.
- **Essential:** yes — the entire local persistence layer depends on
  it.
- **Performance:** SQLCipher encryption adds measurable CPU overhead
  per query vs. plain SQLite (AES on every page read/write) — at this
  app's message volume (a two-person chat, not a high-throughput
  system) this is not practically noticeable.
- **Security implications:** THE security-critical dependency for
  data at rest. See docs 02 and 03 for the encryption setup and its
  current gap: the passphrase is currently a hardcoded placeholder in
  `main.dart`, not derived from a real secret — must-fix before
  shipping.

### `path_provider: ^2.1.3` + `path: ^1.9.0`
- **Why used:** `path_provider` gets the platform-correct app-data
  directory (`getApplicationSupportDirectory()`) for the SQLite file;
  `path` joins path segments safely across platforms instead of hand-
  concatenating strings with the wrong separator on the wrong OS.
- **Alternatives:** hand-rolled platform-specific path logic — exactly
  what these packages exist to avoid.
- **Essential:** yes, for `AppDatabase.open()`.
- **Performance/security:** negligible/none — thin platform-channel
  wrappers.

### `flutter_webrtc: ^0.10.4`
- **Why used:** The entire peer-to-peer transport layer — wraps
  native WebRTC (libwebrtc) for `RTCPeerConnection` and
  `RTCDataChannel`. See doc 04 for the full WebRTC explanation.
- **Why chosen:** essentially the only maintained, full-featured
  WebRTC binding for Flutter across Android/iOS/desktop. The real
  architectural choice was WebRTC itself vs. hand-rolling a UDP
  hole-punching transport — WebRTC won because it already solves NAT
  traversal (ICE/STUN) and has a mature encrypted data channel
  (SCTP-over-DTLS) built in.
- **Advantages:** handles NAT traversal, connection state, and
  channel-level reliability (ordered, guaranteed delivery via SCTP).
- **Disadvantages:** large native dependency (pulls in the full
  libwebrtc binary per platform, meaningfully increasing app binary
  size); the API is a fairly direct mapping of native WebRTC — verbose
  with a real learning curve (see doc 04).
- **Essential:** yes — no P2P connection without it.
- **Performance:** the data channel itself is efficient (what video
  calling apps use for real-time media at far higher bandwidth than
  text chat needs); ICE gathering has a real latency cost (bounded to
  8 seconds by `_iceGatheringTimeout` here) during connection setup.
- **Security implications:** the data channel is protected by **DTLS**
  at the transport level, *independent of* this app's own
  ChaCha20-Poly1305 application-layer encryption — chat messages are
  encrypted twice, once by DTLS (transport) and once by this app's own
  session cipher (application). This is intentional defense in depth:
  DTLS protects against a network-level eavesdropper even if the
  application-layer scheme somehow had a flaw, and the application
  layer protects against a compromised/malicious TURN relay (if ever
  enabled) that DTLS terminates at.

### `cryptography: ^2.7.0`
- **Why used:** the actual cryptographic primitives — X25519 (key
  exchange), Ed25519 (signatures), ChaCha20-Poly1305 (AEAD
  encryption), HKDF (key derivation), SHA-256 (hashing). See doc 03
  for why each algorithm was chosen.
- **Why chosen over alternatives:** `pointycastle` is the other major
  pure-Dart crypto library — `cryptography` was chosen for its cleaner
  async API (native crypto backends used where available, pure-Dart
  fallback otherwise, transparently) and because it's purpose-built
  around exactly this app's primitive set rather than a
  general-purpose "every algorithm ever" toolkit, where it's easier to
  accidentally reach for a weaker/legacy algorithm.
- **Advantages:** modern, focused API; uses platform-native crypto
  implementations when available.
- **Disadvantages:** smaller ecosystem than `pointycastle`; fewer
  legacy-algorithm options (a non-issue here).
- **Essential:** yes — the cryptographic foundation of the entire
  trust model.
- **Security implications:** the single most security-critical
  dependency in the project. See doc 03 in full.

### `flutter_secure_storage: ^9.2.2`
- **Why used:** stores this device's long-term private key material
  (X25519 + Ed25519 private key seeds) in the platform's actual secure
  enclave — Android Keystore (via `EncryptedSharedPreferences`) or
  iOS/macOS Keychain — rather than the SQLite database or plain
  `SharedPreferences`.
- **Why chosen over alternatives:** close to the only well-maintained
  cross-platform wrapper for "give me the OS's actual secure
  credential storage" in Flutter; the alternative is hand-written
  platform channels to Keystore/Keychain, significant native code for
  no benefit over an existing, widely-used wrapper.
- **Advantages:** private keys never touch application-readable
  storage — hardware-backed on devices that support it.
- **Disadvantages:** platform secure storage can have unexpected
  behavior around app reinstalls/backups (e.g. iOS Keychain items can
  survive an app *deletion* by default unless explicitly configured
  otherwise) — worth auditing before shipping.
- **Essential:** yes — this is what makes "private keys never leave
  the device" true rather than aspirational.
- **Security implications:** central to the whole trust model — doc 03.

### `qr_flutter: ^4.1.0` + `mobile_scanner: ^5.1.1`
- **Why used:** `qr_flutter` renders a QR code (`QrImageView`) from
  the invite/response payload string; `mobile_scanner` reads one back
  via the device camera (CameraX on Android, AVFoundation on
  iOS/macOS).
- **Why chosen:** the current, actively maintained standard choice for
  each job; `mobile_scanner` specifically over the older
  `qr_code_scanner` package, which has had maintenance gaps.
- **Advantages:** a well-understood, camera-only way to move a chunk
  of text between two physical devices in the same room.
- **Disadvantages:** QR codes have a practical data-capacity ceiling —
  this directly caused a real problem in this app's design (see doc
  04, "why the QR became large / how it's kept bounded") — and require
  camera permission, which not every environment grants (hence the
  paste-text fallback built into the pairing UI).
- **Essential:** no — the paste-text fallback means the app is
  functionally complete without camera access at all; QR is a
  convenience layer over the same underlying text payload.
- **Security implications:** none of its own — an encoding/decoding
  convenience for a payload that's already cryptographically signed
  before becoming a QR code (see `pairing_payload.dart`).

### `equatable: ^2.0.5`
- **Why used:** value-equality for entity classes (`DeviceIdentity`,
  `ChatMessage`) — without it, two Dart objects with identical fields
  are NOT `==` to each other by default (Dart's default equality is
  identity-based), which would break Riverpod's rebuild-avoidance
  logic and make test comparisons awkward.
- **Alternatives:** Dart 3 `records`, or hand-overriding `==`/`hashCode`
  — `equatable` is simply less boilerplate for the same result.
  `freezed` (codegen-based immutable classes with equality built in)
  was considered and explicitly **removed** from this project at one
  point — it added a codegen dependency for something `equatable`
  already covered without codegen, so it was cut to keep the
  dependency surface minimal.
- **Essential:** not strictly — could be hand-rolled per class.
- **Performance/security:** negligible/none.

### `uuid: ^4.4.2`
- **Why used:** generates UUIDv4 identifiers for messages, reactions,
  and key records.
- **Alternatives:** Dart has no built-in UUID generator; hand-rolling
  one is exactly what this package already does correctly.
- **Essential:** yes as currently used, though technically replaceable
  with any collision-resistant ID scheme — UUIDs need no coordination
  between the two devices to avoid collisions.
- **Security implications:** message/reaction IDs aren't
  security-sensitive (not secrets, not cryptographic material) —
  collision resistance is the only property that matters.

### Dev dependencies: `flutter_test`, `flutter_lints: ^4.0.0`, `build_runner: ^2.4.11`, `drift_dev: ^2.17.0`
- `flutter_test` — the standard Flutter testing framework.
- `flutter_lints` — standard recommended lint rules, with
  `unawaited_futures: true` explicitly added on top in
  `analysis_options.yaml` — this specific rule caught real bugs during
  development (see the audit history / doc 06).
- `build_runner` + `drift_dev` — codegen tooling; `drift_dev` generates
  `app_database.g.dart` from the table definitions. This is why
  `dart run build_runner build` is required before the project
  compiles.

### Packages considered and explicitly removed
- **`freezed` / `json_annotation` / `json_serializable`** — added
  early, removed once nothing in the codebase used codegen'd immutable
  classes or JSON serialization codegen (JSON here is hand-written
  `jsonEncode`/`jsonDecode` on plain `Map<String, dynamic>` — simple
  enough not to need codegen for small, stable wire-format payloads).
- **`mocktail`** — added early for test mocking, removed once every
  test settled on hand-written fake implementations of the repository
  interfaces instead (e.g. `_UnpairedFakePairingRepository` in
  `chat_repository_test.dart`) — for interfaces this small, a
  hand-written fake is often more readable than a generated mock, and
  avoids the extra dependency.

# two_person_app

Pairing + chat between exactly two people, direct peer-to-peer,
end-to-end encrypted. Pairing is now bootstrapped through a
lightweight signaling relay server instead of a fully manual QR/text
exchange — see `docs/PAIRING_MIGRATION.md` for exactly what changed,
why, and the privacy trade-off that decision carries (a relay server,
even one that never sees message content, sees connection metadata a
purely serverless design wouldn't have exposed — that's a real,
deliberate change, not a side effect).

## What's here

```
lib/                    Flutter app — 35 files
signaling_server/        Standalone Dart signaling relay — 3 files,
                          zero runtime dependencies (dart:io only)
docs/                    Architecture handover docs (see docs/ below)
```

```
lib/
  core/
    database/    — drift schema (SQLCipher-encrypted): messages, media
                    metadata, reactions, keys, settings. 5 tables.
    di/           — get_it service locator
    error/         — Failure types
    theme/
    utils/         — Result<T>
  features/
    pairing/
      domain/      — PairingRepository interface, DeviceIdentity,
                      EncryptedChannel, Invite, PairingStage,
                      SignalingMessage (the relay protocol)
      data/
        crypto/     — key generation, per-message signing, fingerprint,
                       session keys (X25519 + Ed25519 + HKDF + ChaCha20-Poly1305)
        signaling/   — WebRTC offer/answer/trickle-ICE, the signaling
                       relay client, invite creation, encrypted transport
      presentation/ — pairing flow screen, QR scanner, deep link
                       handler, Riverpod providers
    chat/
      domain/       — ChatRepository interface, ChatMessage
      data/          — drift-backed CRUD + live delivery over the wire
      presentation/  — chat screen, Riverpod providers
  main.dart
```

Chat required **zero changes** for the pairing migration — it only
ever depended on `PairingRepository`'s `transport`/`connectionStatus`
interface, never on how pairing works underneath. That's the concrete
payoff of the domain-layer abstraction described in `docs/01`.

## What the app actually does

1. First launch on two devices → pairing screen.
2. One side creates an invite — this hits the signaling server, gets
   back a short ID, and shows it as a small QR code / `twoperson://pair/AB7K9P`
   link. The other side scans it, pastes it, or just opens the link
   directly (deep link).
3. From there the exchange is live: identity keys, ephemeral session
   keys, the WebRTC offer/answer, and ICE candidates all flow over the
   relay automatically — no more manual "now send this back" step.
4. Both sides see the same safety-number fingerprint and confirm it
   matches — that's the actual trust check, not the invite exchange
   itself.
5. Chat: send, edit, delete for me, delete for both (fails if the peer
   isn't reachable — by design), pin, react (❤️ only).
6. Closing and reopening the app shows a lighter "Reconnect" screen —
   the signaling relay is only used during pairing, not as an
   always-on presence service, so reconnecting is a fresh (but
   lightweight) relay handshake, not a full re-pairing.

## What's explicitly not here


Media/voice notes, stories, feed, gallery, calls UI, settings screens,
any visual design beyond default Material 3 dark theme, TURN toggle,
screen-recording/lock-screen privacy. None of it is half-built —
it was removed rather than left as broken stubs.

## Before real use

`main.dart` hardcodes the database passphrase
(`'REPLACE_WITH_DERIVED_KEY'`) — this needs to come from a real
biometric/PIN-gated key before this holds actual private conversations.
That's the one remaining TODO in the codebase (`grep -rn TODO lib`
finds exactly one hit).

## Building it

I can't produce an installable `.apk`/`.ipa` — this was written
without a Flutter toolchain or network access, so it's never been
compiled. What I can tell you: every internal import resolves to a
file that exists (checked), every Companion/table field name matches
its drift table definition (checked by hand), and the trickier
third-party APIs (`qr_flutter`'s `QrImageView`, `mobile_scanner`'s
`onDetect`, `cryptography`'s `Hkdf`/`Chacha20`/`Ed25519`/`X25519`) were
checked against current package documentation, not just recalled. Two
real bugs were caught and fixed this way in earlier passes (a missing
WebRTC enum prefix, a drift table/row class name collision), and one
more this pass (a missing `mounted` check before `setState` after an
async call). That's a real, careful review — not a substitute for
`flutter analyze`.

```
# 1. Start the signaling relay (needed for pairing to work at all)
cd signaling_server && dart run bin/server.dart 8080 &
cd ..

# 2. Build/run the Flutter app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

`build_runner` is required because drift's generated
`app_database.g.dart` isn't checked in. The app is hardcoded to talk
to `localhost:8080` (see `lib/core/di/injector.dart`) — fine for
running the server and app on the same machine/emulator during
development, but needs updating to a real deployed address (and
`ws://`/`http://` switched to `wss://`/`https://`) before this is used
by two people on two separate networks. See `signaling_server/README.md`.

## Platform support (Android / iOS)

Full build instructions: **`BUILD.md`**. Full list of what's
machine-generated and exactly how to generate it: **`CHECKLIST.md`**.
Short version below.

**Android — fully generated.** `android/` has the complete Gradle
Kotlin DSL setup, `AndroidManifest.xml` with camera + network
permissions, `MainActivity.kt`, ProGuard rules for
flutter_webrtc/SQLCipher/flutter_secure_storage, and real launcher
icons at every density. `applicationId` is `com.twoperson.us`,
`minSdk` 23, `compileSdk`/`targetSdk` 35. One gap: `gradle-wrapper.jar`
is a compiled binary I can't hand-write — see `CHECKLIST.md` for the
one-line fix.

**iOS — the plain-text parts are generated, the Xcode project graph
is not.** `ios/Info.plist` (camera/microphone/local-network
permissions), `AppDelegate.swift`, `Podfile` (with the
flutter_webrtc-required `post_install` workaround), the `.xcconfig`
files, `Assets.xcassets` with a real 1024×1024 icon, and
`LaunchScreen.storyboard` are all in this zip. `Runner.xcodeproj`
(`project.pbxproj`, the workspace, the scheme) is not — that file
format is generated by Xcode's own model layer, cross-references
internal UUIDs, and — concretely, not just abstractly — Flutter's
default iOS app lifecycle is *mid-migration right now* (UIScene-based
became the `flutter create` default as of Flutter 3.41, replacing the
AppDelegate pattern that had been stable for years), which makes this
a worse-than-usual moment to hand-fabricate that structure from
memory. One command generates it correctly for whatever Flutter
version you have: `flutter create --platforms=ios .` — it fills in
only what's missing, won't touch the files already here.

**Web** isn't included, and it's not a missing-folder problem — the
database layer uses `dart:io` file paths that don't exist in a
browser; supporting web means a second WASM-based drift backend, a
real chunk of work, not a generated folder.

**macOS / Linux / Windows desktop** — not attempted this pass. Ask if
you want them; macOS has the same Xcode-project caveat as iOS, Linux/
Windows are CMake + C++ (more like Android's Gradle in risk profile)
and could be built out the same way Android was.

If `flutter analyze` still finds something — possible, since a
third-party package API can differ from what documentation showed, or
a Flutter-version-specific detail could be off — the failure is most
likely narrow (one method signature) rather than structural, given how
this pass went through the codebase file by file.

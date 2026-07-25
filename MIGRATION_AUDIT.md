# MIGRATION_AUDIT — pairing architecture change

Audit of the migration from QR-embedded-payload pairing to
invite-link + signaling-relay pairing, described in
`docs/PAIRING_MIGRATION.md`. This document tracks what actually
changed against what was planned, plus bugs caught during
implementation.

## Files added

| File | Status |
|---|---|
| `signaling_server/` (whole standalone project: `pubspec.yaml`, `bin/server.dart`, `lib/invite_store.dart`, `test/invite_store_test.dart`, `README.md`) | Done |
| `lib/features/pairing/domain/entities/invite.dart` | Done |
| `lib/features/pairing/domain/entities/signaling_message.dart` | Done — 9 message types (`PeerJoinedMessage`, `PeerLeftMessage`, `InviteExpiredMessage`, `IdentityMessage`, `EphemeralKeyMessage`, `SdpOfferMessage`, `SdpAnswerMessage`, `IceCandidateMessage`, `DataChannelOpenMessage`), sealed class with exhaustive `tryParse` |
| `lib/features/pairing/domain/entities/pairing_stage.dart` | Done — added beyond the original plan; needed once it became clear the UI needs finer-grained state (waiting/negotiating/peer-left/expired) than a single `connectionStatus` bool can express |
| `lib/features/pairing/data/signaling/signaling_client.dart` | Done |
| `lib/features/pairing/data/signaling/invite_api_client.dart` | Done |
| `lib/features/pairing/presentation/deep_link_handler.dart` | Done |
| `test/features/pairing/message_signing_test.dart` | Done (replaces the planned rewrite of `pairing_payload_test.dart` — the old file was deleted rather than edited, since nothing in it applied anymore) |
| `test/features/pairing/invite_test.dart` | Done |

## Files rewritten

| File | Status | Notes |
|---|---|---|
| `lib/features/pairing/data/crypto/pairing_payload.dart` | Deleted, replaced by `message_signing.dart` | Plan said "keep signing logic, shrink content" — in practice this meant a full replacement: the old file's entire public surface (`PairingPayload` class, `createSigned`, `verifySignature`, `toJson`/`tryParse`) doesn't apply to per-message signing, so keeping the file and editing it in place wasn't meaningfully different from deleting and replacing it. Functionally equivalent to the plan; different in mechanics. |
| `lib/features/pairing/data/signaling/webrtc_connection_manager.dart` | Done | `createOffer`/`createAnswerForOffer` now return `Future<String>` (bare SDP) instead of `Future<SignalingOffer>`/`Future<SignalingAnswer>`. ICE gathering is trickle (`localIceCandidates` stream) instead of batch-collected. `SignalingOffer`/`SignalingAnswer` classes removed entirely — nothing constructs or references them anymore (verified by grep). |
| `lib/features/pairing/data/pairing_repository_impl.dart` | Done | Full rewrite as planned. `createInviteLink`/`acceptInvite`/`completePairing` replaced by `createInvite`/`joinInvite`/`cancelPairing`. Message dispatch (`_handleSignalingMessage`) uses a sealed-class exhaustive switch over `SignalingMessage`. |
| `lib/features/pairing/domain/repositories/pairing_repository.dart` | Done | Interface updated as planned, plus `pairingStage` added (not in the original plan — see `pairing_stage.dart` note above). |
| `lib/features/pairing/presentation/providers/pairing_providers.dart` | Done | Added `pairingStageProvider`. |
| `lib/features/pairing/presentation/screens/pairing_flow_screen.dart` | Done | Old file deleted and replaced rather than edited in place — the state machine shape changed enough (3-stage round-trip → 2-entry-point + live-stage-stream) that editing in place would have been harder to get right than a clean rewrite. |
| `lib/main.dart` | Done | Deep link handler wired up via a `GlobalKey<NavigatorState>` so a link can be handled regardless of what screen is currently showing. |
| `pubspec.yaml` | Done | Added `web_socket_channel`, `http`, `app_links`. |
| `android/app/src/main/AndroidManifest.xml` | Done | Added two intent filters: `twoperson://pair` custom scheme (works standalone) and `https://pair.twoperson.app` (works as a browser-chooser option now, becomes a true auto-opening App Link only once `assetlinks.json` is deployed — documented inline). |
| `ios/Runner/Info.plist` | Done | Added `CFBundleURLTypes` for the `twoperson` scheme. |
| `test/features/chat/chat_delivery_test.dart`, `test/core/database/chat_repository_test.dart` | Done | Not in the original file-change table — these weren't anticipated to need changes, but both contain hand-written fakes of `PairingRepository`, and the interface change meant those fakes no longer compiled. **This is exactly the kind of cross-file consistency break a partial/patch-style migration would have missed** — caught here by grepping for every implementer of the interface, not by having anticipated it in the plan. |

## Files explicitly NOT touched (as planned)

Verified by grep — none of these reference anything that changed:
`session_crypto_service.dart`, `identity_key_service.dart`,
`fingerprint.dart`, `secure_key_store.dart`, `encrypted_transport.dart`,
`encrypted_channel.dart`, `device_identity.dart`, the entire `chat/`
feature (domain, data, presentation), `core/database/`, `app_theme.dart`,
`result.dart`, `failures.dart`. `qr_scanner_screen.dart` also needed no
changes — it just returns whatever string it scans; it never knew or
cared whether that string was a huge JSON blob or a tiny link.

## Real bugs caught during this migration (not in the original plan)

1. **Fragile generic type inference in `createInvite()`.** First draft
   used `result.when(ok: ..., err: Err.new)` to unwrap a `Result<Invite>`
   — the exact class of bug flagged and fixed in the pre-migration
   codebase audit (mixing generic callback return types). Caught on
   review before it shipped; replaced with a plain sealed-class
   `switch` (`case Ok<Invite>(value: final v): ...`), which has no
   inference ambiguity.
2. **Invalid XML: literal `--` inside comments.** My own comment-writing
   habit (using `--` as an em-dash substitute) produced `<!-- ... -- ... -->`
   in `AndroidManifest.xml`, which is illegal per the XML spec (comments
   may not contain `--` anywhere in their content, not just at the
   boundaries) — this would have failed to parse at build time, not
   just been a style nit. Found by actually parsing the file with an
   XML parser rather than eyeballing it, then **every** XML/plist file
   in `android/` and `ios/` was swept for the same pattern (found only
   in the one file). Fixed by rewording rather than by allowing the
   pattern to slip through elsewhere.
3. **Two test fakes silently stopped compiling.** Covered above —
   `_ConnectedFakePairingRepository` and `_UnpairedFakePairingRepository`
   both implemented the old `PairingRepository` interface directly
   (required by Dart's `implements` — there's no way to "partially"
   implement an interface and have it compile), so the interface
   rewrite broke them even though neither file was in the original
   change list. Found by grepping for every file implementing
   `PairingRepository`, not just the ones the plan anticipated.

## What this audit did not verify

Same limitation as every previous pass: no compiler, no `flutter
analyze`, no `dart analyze` on `signaling_server/`, no `flutter test`.
Every claim above is from tracing imports, grepping for dangling
references, checking brace balance, and — critically, given what it
caught — actually parsing every XML/plist file with a real parser
instead of trusting visual inspection. That combination catches a
specific, real class of bug (as items 1-3 above show) but is not
equivalent to compiling the project.

## Known gaps carried forward, or introduced by this migration

- **The relay server address is hardcoded to `localhost:8080`** in
  `injector.dart` — fine for local development, must be changed before
  two people on different networks could actually use this.
- **No TLS on the reference signaling server** — see
  `signaling_server/README.md`'s "deploying this for real" section.
  Running the app against an unencrypted relay over a real network
  would expose the same metadata this migration already accepts
  exposing to the server operator (see `PAIRING_MIGRATION.md` section
  3) to anyone on the network path as well.
- **The `https://pair.twoperson.app` Universal Link/App Link form is
  configured but not functional** without deploying the
  domain-verification files (`apple-app-site-association`,
  `assetlinks.json`) — the `twoperson://` custom scheme works without
  any of that and is the default/recommended path until those are deployed.
- **No rate limiting on invite creation** in the reference server —
  noted in its README as a pre-production requirement, not implemented.
- **The debug-signed Android release build situation is unchanged**
  from before this migration — still documented in `CHECKLIST.md`,
  still not something to distribute as-is.

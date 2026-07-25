# PAIRING_MIGRATION — invite-link + signaling relay architecture

This replaces the QR/text-embedded-payload pairing system with a
lightweight invite-link system backed by a signaling relay server.
Read this in full before the code — it explains what's changing, what
it costs, and exactly which files move for which reason.

## 1. What's changing, in one sentence

The QR/invite-link now encodes **only an invite ID**
(`twoperson://pair/AB7K9P`, ~28 bytes). Everything that used to be
crammed into that one payload — identity keys, signing keys, SDP
offer/answer, ICE candidates, ephemeral keys, signature — now travels
over a **live relay connection** to a signaling server, opened after
the invite link is followed, as a sequence of small messages instead
of one large one.

## 2. Why this fixes the actual problem

The old failure mode (documented in `docs/03-pairing-webrtc-networking.md`,
"why the QR can get large"): SDP text (1-3 KB) + a variable number of
ICE candidates (60-150 bytes each, sometimes 10+) + base64 public keys
+ a signature, all bundled into one payload that has to survive being
turned into a single QR code or pasted as one block of text. QR codes
have a hard capacity ceiling; payloads near or past it either fail to
encode or become unreliable to scan.

Moving SDP/ICE to a live relay removes the size ceiling entirely,
because nothing about a live connection needs to fit in a QR code —
and it enables **trickle ICE** (candidates sent one at a time, as
they're discovered, instead of gathered up front and batched), which
is both the standard, faster way WebRTC apps normally work and a
direct structural fix for the root cause, not a workaround for it.

## 3. What this costs — read this before deciding to proceed

The original architecture's central property was **zero
infrastructure**: nothing this app's developer runs or controls was
ever in the data path, not even briefly, not even for metadata. That
property is now gone. Specifically, the signaling server — even
built as a "blind relay" that never inspects message content and
never sees encryption keys used for actual chat traffic — necessarily
sees:

- **That two specific devices paired, and when.** The server matches
  Device A and Device B on the same invite ID; it knows both
  connected around the same time.
- **Both devices' IP addresses**, since they're connecting to it
  directly as a relay.
- **The raw SDP and ICE candidate data**, since the server is the one
  relaying it (it doesn't need to *act* on this data maliciously to
  have "seen" it — a subpoena, a breach, or a logging misconfiguration
  on the relay server is now a real exposure category that didn't
  exist before).

**What does NOT change:** message content is still fully end-to-end
encrypted with keys the server never sees (ChaCha20-Poly1305 session
keys are derived from ECDH on both ends independently — the server
relays public ephemeral keys, which are not secret by definition).
Identity verification (the fingerprint/safety-number step) is
unchanged and still the real authentication boundary — a malicious or
compromised relay server could attempt to inject its own keys during
the exchange (a MITM), and fingerprint verification is exactly what
catches that, same as before.

This is a reasonable, common trade-off — most "serverless" P2P chat
apps in practice work exactly this way (a minimal signaling relay,
direct P2P for content) rather than the original zero-infrastructure
design. It is not, however, the same privacy posture as before, and
that difference should be a decision made with full information, not
a side effect of a refactor.

## 4. New architecture, end to end

```
Device A                    Signaling Server                    Device B
--------                    ----------------                    --------
createInvite()
  -> POST /invites
                          generate inviteId (e.g. "AB7K9P")
                          store: {inviteId, deviceA_connId,
                                  createdAt, expiresAt: +10min,
                                  status: 'waiting'}
                          <- {inviteId, expiresAt}
  connect WS
  /ws/invites/AB7K9P
  (role: initiator)
                                                          openInvite("AB7K9P")
                                                          (from QR scan, paste,
                                                           or deep link)
                                                            connect WS
                                                            /ws/invites/AB7K9P
                                                            (role: responder)
                          match A+B on inviteId
                          -> A: {type: 'peer_joined'}
                          -> B: {type: 'peer_joined'}

  send signed envelope:                                   send signed envelope:
  {type: 'identity',                                      {type: 'identity',
   identityPublicKey,                                      identityPublicKey,
   signingPublicKey,                                       signingPublicKey,
   signature}                                               signature}
       -----------------> relay (opaque) -------------------->
       <----------------- relay (opaque) <--------------------

  [both sides now have both              [both sides now have both
   public keys -- compute fingerprint     public keys -- compute fingerprint
   independently, same result]            independently, same result]

  send signed envelope:                                   send signed envelope:
  {type: 'ephemeral_key',                                 {type: 'ephemeral_key',
   ephemeralPublicKey, signature}                          ephemeralPublicKey, signature}
       -----------------> relay (opaque) -------------------->
       <----------------- relay (opaque) <--------------------

  [derive session keys via ECDH+HKDF,                     [derive session keys, same]
   same as before -- unchanged]

  createOffer() (trickle ICE)
  send {type: 'sdp_offer', sdp}
       -----------------> relay -------------------->
                                                            setRemoteDescription(offer)
                                                            createAnswer()
                                                            send {type: 'sdp_answer', sdp}
       <----------------- relay <--------------------
  setRemoteDescription(answer)

  as each ICE candidate is found:                          as each ICE candidate is found:
  send {type: 'ice_candidate', candidate}                  send {type: 'ice_candidate', candidate}
       <----------------> relay (both directions, ongoing) <---------------->

  [WebRTC connects directly -- DTLS handshake, data channel opens]

  server marks invite 'completed',
  deletes invite record,
  closes both WS connections

  [fingerprint verification screen -- human confirms safety number,
   exactly as before]

       ------------------ chat over the direct P2P data channel ------------------
```

## 5. Server responsibilities, precisely

- `POST /invites` — generate a short, unique, unguessable invite ID
  (crypto-random, not sequential), store `{inviteId, createdAt,
  expiresAt: now+10min, status: 'waiting', initiatorConnId: null,
  responderConnId: null}`. Return `{inviteId, expiresAt}`.
- `WS /ws/invites/:inviteId?role=initiator|responder` — on connect,
  validate the invite exists, isn't expired, and (for `responder`)
  that no responder has already joined (one invite = exactly one
  pairing attempt, ever — not reusable). Register the connection.
  When both roles are connected, notify both with `peer_joined`.
- **Relay only** — every other message type (`identity`,
  `ephemeral_key`, `sdp_offer`, `sdp_answer`, `ice_candidate`) is
  forwarded byte-for-byte to the other party on the same invite,
  without the server parsing or validating its contents beyond "is
  this valid JSON with a `type` field so I know it's a relay message
  and not a protocol command." All actual validation (signature
  verification, structure) happens client-side, same trust boundary
  as before.
- **10-minute TTL**, enforced server-side — an invite not completed
  within 10 minutes is deleted and both WebSocket connections (if any)
  are closed with a clear reason code.
- **Deleted immediately on successful pairing** — once the server sees
  a `data_channel_open` acknowledgment from each side (a new,
  lightweight message type the client sends once its own
  `RTCPeerConnection` reaches `connected`), the invite record is
  deleted and both connections closed. This is what makes an invite
  ID **single-use** — replaying an old invite ID doesn't work even
  within the TTL window if it already completed.
- **Never stores chat data or private keys** — true by construction:
  the server has no code path that ever touches the `messages` table,
  private key material, or SQLCipher passphrase; it only ever
  processes the relay envelope types listed above, all of which
  contain public keys, SDP, and ICE candidates — never a private key,
  never message content.

## 6. Complete file-change inventory

### New files

| File | Purpose |
|---|---|
| `signaling_server/` (new top-level directory, separate Dart project) | Reference signaling relay server implementation. |
| `lib/features/pairing/domain/entities/invite.dart` | `Invite` entity: `id`, `expiresAt`, `deepLink`. |
| `lib/features/pairing/domain/entities/signaling_message.dart` | The relay envelope types (`identity`, `ephemeral_key`, `sdp_offer`, `sdp_answer`, `ice_candidate`, `peer_joined`, `data_channel_open`) as a sealed class hierarchy. |
| `lib/features/pairing/data/signaling/signaling_client.dart` | WebSocket client — connects to the relay, sends/receives `SignalingMessage`s, exposes them as a `Stream`. Replaces the QR-payload-parsing role `pairing_payload.dart` used to play for SDP/ICE. |
| `lib/features/pairing/data/signaling/invite_api_client.dart` | Thin HTTP client for `POST /invites`. |
| `lib/features/pairing/presentation/deep_link_handler.dart` | Listens for `twoperson://pair/<id>` launches and routes to the join flow. |
| `test/features/pairing/signaling_client_test.dart` | Tests for the new relay client against a fake WebSocket. |
| `test/features/pairing/invite_test.dart` | Tests for invite creation/expiry logic. |

### Rewritten files

| File | Why it changes |
|---|---|
| `lib/features/pairing/data/crypto/pairing_payload.dart` | The "bundle everything into one signed JSON blob for QR" responsibility is gone. Keeps the **signing/verification logic** (still needed — every relay envelope is still signed, same reasons as before: the relay server, or a MITM of it, must not be able to inject unsigned/forged key material) but the *content* shrinks to one message type at a time (`SignalingMessage`), not one giant bundle. |
| `lib/features/pairing/data/signaling/webrtc_connection_manager.dart` | Switches from non-trickle (gather-then-return) to **trickle ICE**: `onIceCandidate` now sends each candidate immediately via the `SignalingClient` instead of accumulating into a list returned at the end. `createOffer`/`createAnswerForOffer` no longer wait for gathering to complete before returning. |
| `lib/features/pairing/data/pairing_repository_impl.dart` | Complete rewrite of the orchestration logic — `createInviteLink()` becomes `createInvite()` (calls the invite API, returns a tiny `Invite`), `acceptInvite()` becomes `joinInvite(inviteId)` (opens the WS relay connection), and the entire offer/answer/candidate exchange becomes event-driven (reacting to `SignalingMessage`s arriving on the relay stream) instead of the old two-shot request/response shape. |
| `lib/features/pairing/domain/repositories/pairing_repository.dart` | Interface changes to match: `createInvite()`/`joinInvite(id)` replace `createInviteLink()`/`acceptInvite()`/`completePairing()` (the three-step QR round-trip collapses into a two-step "create" / "join" since the relay makes the exchange live instead of manual-round-trip). |
| `lib/features/pairing/presentation/providers/pairing_providers.dart` | New providers for invite state and relay connection status. |
| `lib/features/pairing/presentation/screens/pairing_flow_screen.dart` | UI simplifies significantly — no more "scan/paste the response and submit" step, since the exchange is now live. Becomes: create → show tiny QR/link → "waiting for your person" → (peer joins automatically) → fingerprint verify → chat. Join side: scan/paste/deep-link → "connecting" → fingerprint verify → chat. |
| `lib/main.dart` | Wires up the deep link listener at startup. |
| `pubspec.yaml` | New dependencies: `web_socket_channel` (relay client), `app_links` (deep link handling), `http` (invite creation POST). |
| `android/app/src/main/AndroidManifest.xml` | New `<intent-filter>` for the `twoperson://pair` custom scheme. |
| `ios/Runner/Info.plist` | New `CFBundleURLTypes` entry for the custom scheme. |
| `test/features/pairing/pairing_payload_test.dart` | Rewritten for the new minimal per-message signing, not the old bundled payload. |

### Deleted / obsolete

| What | Why |
|---|---|
| `PairingPayload.createSigned`'s old bundled `signalingData` field (offer+candidates+ephemeral key all in one) | Replaced by individual `SignalingMessage`s sent live. |
| `WebRtcConnectionManager._listenForIceCandidates` (batch-wait-then-return logic) | Replaced by trickle: candidates stream out as found. |
| The "paste the response payload back" UI step in `pairing_flow_screen.dart` | No longer exists — the relay makes exchange bidirectional/live, there's no "response to paste back." |
| Any reference to `SignalingOffer`/`SignalingAnswer` as return values from `createOffer`/`createAnswerForOffer` | These become fire-into-the-relay side effects, not return values round-tripped through a QR payload. |

### Unaffected (explicitly, so it's clear what's NOT touched)

`session_crypto_service.dart`, `identity_key_service.dart`,
`fingerprint.dart`, `secure_key_store.dart`, `encrypted_transport.dart`,
`encrypted_channel.dart`, the entire `chat/` feature, the entire
`core/database/` schema, `app_theme.dart`, `result.dart`,
`failures.dart`, `injector.dart` (aside from adding the new
`SignalingClient`/`InviteApiClient` registrations). The chat feature
in particular depends only on `EncryptedChannel` and
`PairingRepository.transport`/`connectionStatus` — none of which
change shape — so **chat requires zero changes**, which is exactly
what the domain-layer abstraction from the original architecture was
for.

## 7. Implementation order

Given the scope, built in this order (each stage keeps the project in
a working state before moving to the next):

1. Signaling protocol contract (`signaling_message.dart`) + reference
   server.
2. `SignalingClient` + `InviteApiClient` (client-side relay plumbing).
3. `WebRtcConnectionManager` trickle-ICE rewrite.
4. `PairingRepository`/`PairingRepositoryImpl` rewrite.
5. `pairing_payload.dart` slimmed down.
6. UI (`pairing_flow_screen.dart`, providers).
7. Deep link handling + platform config.
8. Tests.

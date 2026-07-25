# 03 — Pairing, WebRTC, and Networking

> **This document describes the pre-migration architecture** (manual
> QR/text payload exchange, no server). It's kept for historical
> context and because most of the WebRTC/ICE/STUN conceptual content
> (sections 8-9) is still accurate. **The actual pairing mechanism it
> describes in section 7 has been replaced** — see
> `../PAIRING_MIGRATION.md` for the current invite-link +
> signaling-relay design, and `../MIGRATION_AUDIT.md` for exactly what
> changed. Specifically outdated below: the QR payload no longer
> contains SDP/ICE/keys (just a tiny invite ID), ICE is now trickle
> rather than batch-gathered, and there is now a signaling server in
> the picture (`signaling_server/`) — contradicting this doc's
> "no server, ever" framing, which was true of the *original* design
> and is a deliberate trade-off the migration document explains.

Sections covered: Pairing, WebRTC, Networking.

---

## 7. Pairing

### The complete flow, both roles

There are two roles: **initiator** (taps "Start pairing" / "Start
session") and **responder** (taps "Join with an invite" / "Join their
session"). The UI state machine for both lives entirely in one file:
`pairing_flow_screen.dart`.

```
INITIATOR                                    RESPONDER
----------                                   ----------
createInviteLink()
  - generate ephemeral X25519 keypair
  - WebRtcConnectionManager.createOffer()
      - create RTCPeerConnection
      - create RTCDataChannel "app-data"
      - createOffer() -> local SDP offer
      - gather ICE candidates (up to 8s)
  - build PairingPayload:
      { deviceId, identityPublicKey,
        signingPublicKey, sessionId,
        createdAt,
        signalingData: { offer: {sdp, candidates},
                          ephemeralPublicKey },
        signature }
  - sign payload with Ed25519 signing key
  - render as QR code + copyable text
        │
        │  (user manually transmits this text/QR
        │   through ANY channel they choose —
        │   in person, an existing messaging app,
        │   email, whatever — the app has no part
        │   in this transmission)
        ▼
                                              acceptInvite(payload)
                                                - verify Ed25519 signature
                                                - reject if older than 10 min
                                                - compute fingerprint from
                                                  both identity public keys
                                                - persist peer's public keys
                                                  (fingerprintVerified=false
                                                  unless this exact peer key
                                                  was already known)
                                                - WebRtcConnectionManager
                                                  .createAnswerForOffer()
                                                    - new RTCPeerConnection
                                                    - setRemoteDescription(offer)
                                                    - add remote ICE candidates
                                                    - createAnswer()
                                                    - gather own ICE candidates
                                                - generate own ephemeral
                                                  X25519 keypair
                                                - derive session keys
                                                  (responder side,
                                                  isInitiator: false)
                                                - build + sign response
                                                  PairingPayload with
                                                  { answer: {sdp, candidates},
                                                    ephemeralPublicKey }
                                                - render as QR/text
        ▲
        │  (transmitted back, same manual channel)
        │
completePairing(response)
  - verify sessionId matches the
    pending outgoing one
  - verify Ed25519 signature
  - verify not a replay (age check
    was already done on invite side;
    the response correlates via
    sessionId instead)
  - persist peer's public keys
  - WebRtcConnectionManager.applyAnswer()
      - setRemoteDescription(answer)
      - add remote ICE candidates
  - derive session keys
    (initiator side, isInitiator: true)
  - build SessionCipher, attach to
    EncryptedTransport
        │
        ▼
   [WebRTC ICE negotiation happens
    automatically at the native layer
    on both sides now — ICE checks
    candidate pairs, DTLS handshake
    completes, SCTP data channel opens]
        │
        ▼
   connectionStatus stream emits `true`
   on BOTH sides once their own
   RTCPeerConnection reaches the
   `connected` state
        │
        ▼
   IF first-time pairing: both sides
   show the fingerprint/safety-number
   screen, independently computed but
   identical, and require the human to
   tap "confirm" before proceeding
   IF reconnect: skip straight to chat
   once connectionStatus is true
        │
        ▼
       ChatScreen
```

### QR contents, precisely

The invite QR encodes the *entire* `PairingPayload` as JSON:
```json
{
  "deviceId": "...",
  "identityPublicKey": "<base64 X25519 pub>",
  "signingPublicKey": "<base64 Ed25519 pub>",
  "sessionId": "<uuid>",
  "createdAt": "<ISO8601>",
  "signalingData": {
    "offer": { "sdp": "<full SDP text>", "candidates": [ {candidate, sdpMid, sdpMLineIndex}, ... ] },
    "ephemeralPublicKey": "<base64 X25519 pub>"
  },
  "signature": "<base64 Ed25519 signature over everything above>"
}
```
The response payload has the identical shape, with `signalingData`
containing `{ answer: {...}, ephemeralPublicKey }` instead of `offer`.

### SDP, offer, answer, ICE candidates — what's actually in there

**SDP (Session Description Protocol)** is a text format describing a
media/data session: which codecs/protocols are offered, network
transport parameters, and DTLS fingerprints for encryption setup. It's
not itself encrypted — it doesn't need to be, since knowing someone's
SDP alone doesn't let you connect to them (you'd also need to win the
ICE candidate exchange and possess the corresponding DTLS key
material, and in this app's case, everything is wrapped in a
separately-signed payload anyway).

**Offer/Answer** is WebRTC's negotiation pattern (borrowed from SIP):
one side proposes a session description (offer), the other responds
with a compatible one (answer). This app's initiator always produces
the offer; the responder always produces the answer — roles are fixed
by who tapped which button, never renegotiated.

**ICE candidates** are individual "here's an address you might be able
to reach me at" entries — host candidates (your actual local network
IP), server-reflexive candidates (your public IP:port as seen by a
STUN server, revealing what's on the other side of your NAT), and
(only if TURN were enabled, which it isn't by default in this app)
relay candidates. Each side gathers *all* the addresses it might be
reachable at, and ICE tries every combination of local-candidate ×
remote-candidate to find one pair that actually works.

### Why this exchange is bundled non-trickle (all at once, not streamed)

"Trickle ICE" — the normal, faster approach used by apps with a live
signaling server — sends candidates one at a time as they're
discovered, over the signaling channel, while negotiation is already
underway. This app has no live signaling channel during initial
pairing (that's the whole point), so candidates are gathered
**up front**, all of them, before the payload is ever generated —
`WebRtcConnectionManager._listenForIceCandidates()` waits for ICE
gathering to complete (or an 8-second timeout, whichever comes first)
and only then returns the offer/answer with the full candidate list
attached.

### Why the QR payload can get large, and why that matters

Every additional ICE candidate is roughly 60-150 bytes of text
(protocol, IP, port, priority, foundation, type — see any raw SDP/ICE
candidate line for the shape). A device with multiple network
interfaces (Wi-Fi + cellular data both active, or multiple IPv6
addresses) can easily gather 5-15 candidates. Multiply by the base
payload overhead (SDP text itself is typically 1-3 KB even with zero
candidates, plus the JSON wrapper, base64-encoded public keys, and the
signature) and the total payload can reach several KB.

QR codes have a hard capacity ceiling depending on error-correction
level and QR version (the largest standard QR code, version 40 with
low error correction, holds ~2,953 bytes of raw binary or ~4,296
alphanumeric characters — and `qr_flutter`'s default rendering doesn't
automatically reach for the largest, hardest-to-scan version). A
payload that grows past what a reasonably-sized, reliably-scannable QR
code can hold will either fail to encode, or encode into a QR code so
dense it's unreliable to scan with a phone camera at arm's length.
**This is exactly why the paste-text fallback exists as a first-class
path in the pairing UI, not an afterthought** — for any network
environment with an unusually large candidate set, pasting the raw
text sidesteps the QR size ceiling entirely.

Two concrete ways to keep the payload smaller, not currently
implemented: (1) filter candidates to the most likely-to-succeed types
before including them (e.g. drop redundant same-network-interface
duplicates), (2) compress the JSON payload (e.g. gzip + base64) before
QR-encoding, trading a small CPU cost for meaningfully smaller QR
data. Neither is implemented today — the paste-text fallback was
judged sufficient given the added complexity these would introduce.

### Fingerprint verification, again, briefly

Already covered in depth in doc 02's Security section — the short
version for this doc's context: it's the step that turns "I received
a payload claiming to be from my person" into "I have independently
confirmed it actually was." It happens *after* the WebRTC connection
is already technically live (encryption is already active by that
point) — it's an authentication gate on top of already-working
encryption, not a prerequisite for the encryption to function at all.

### Alternative pairing methods considered

- **NFC tap-to-pair** — would avoid the QR size ceiling entirely (NFC
  can transfer much more data, and doesn't need visual/camera
  reliability), but requires NFC hardware on both devices and doesn't
  work for remote pairing (same-room only, arguably even more
  restrictive than QR). Not implemented.
- **Bluetooth-based exchange** — could carry the same payload without
  a size ceiling, and could plausibly extend to *reconnection*
  discovery (auto-detect a previously-paired device is nearby) rather
  than requiring a manual exchange every session. Not implemented —
  meaningful additional native platform complexity (Bluetooth
  permissions, pairing/bonding, platform-specific quirks) for a
  feature that doesn't change the "no server" property, just the UX
  around it.
- **Deep links** — the codebase's `PairingPayload.toJson()`/`tryParse()`
  design already supports this in principle (any text transport
  works, including a `myapp://pair?data=...` deep link opened from
  another app), it's just not wired into a URL scheme handler
  currently — the manual-paste path already covers the same use case.

---

## 8. WebRTC — from beginner to expert, and exactly what this app does

### The concepts, in order

**NAT (Network Address Translation).** Almost every device on the
internet today sits behind a NAT — a router that lets many devices
share one public IP address. This means your phone's actual IP
address (e.g. `192.168.1.42`) is meaningless to anyone outside your
home network; they'd need your router's public IP *and* the NAT would
need to know to forward incoming traffic to your specific phone, which
it normally only does in response to *outgoing* traffic it saw first.
This is the fundamental problem P2P connections have to solve: two
devices, each behind their own NAT, with no server relaying traffic —
how do they ever exchange the first packet?

**STUN (Session Traversal Utilities for NAT).** A STUN server's entire
job is answering one question: "what does my traffic look like from
outside my NAT?" Your device sends a STUN server a UDP packet; the
STUN server replies with the public IP:port it saw the packet arrive
from. This is how a device discovers its own "server-reflexive"
address to share with a peer. Critically: **STUN servers never see
your application data** — they only ever see a tiny discovery
handshake, and (in this app specifically) that handshake happens
during connection *setup*, not during the encrypted chat traffic
itself. This app uses Google's public STUN servers
(`stun:stun.l.google.com:19302` and a backup) by default —
see `ice_config.dart`.

**ICE (Interactive Connectivity Establishment).** The overall
algorithm that takes both sides' gathered candidates (host,
server-reflexive, and — if enabled — relay) and tries every pairing to
find one that actually works, ranked by priority (direct host-to-host
connections preferred over anything requiring a relay). This app
implements **non-trickle** ICE — see the Pairing section above.

**TURN (Traversal Using Relays around NAT).** When ICE can't find a
directly-reachable candidate pair for either side (common with
"symmetric" NATs, common on some corporate/mobile networks), a TURN
server relays traffic between the two peers — the TURN server *does*
see the encrypted packets flow through it (not the plaintext — DTLS
encryption is already active — but it does see connection metadata:
when, how much, how often). **This app has TURN disabled by default**
(`_turnEnabled = false` in `PairingRepositoryImpl`, and
`IceConfig.stunOnlyServers` is used unless a settings toggle — which
doesn't exist yet — enables it) — this is a direct consequence of
design goal #1 (no third-party infrastructure in the path, ever). The
honest trade-off: on a small number of restrictive networks (notably
symmetric NAT, common on some cellular carriers and corporate
firewalls), **this app will simply fail to connect**, with no relay
fallback. The UI shows a clear failure rather than silently trying to
relay through infrastructure the user didn't opt into.

**PeerConnection (`RTCPeerConnection`).** The core WebRTC object
representing one connection to one peer. It owns ICE candidate
gathering, the DTLS handshake, and every data channel/media track
attached to it. This app creates exactly one, wrapped by
`WebRtcConnectionManager`.

**DataChannel (`RTCDataChannel`).** A generic, ordered (in this app's
configuration — `ordered: true`), reliable, encrypted (via DTLS/SCTP)
bidirectional byte stream over an established `RTCPeerConnection`.
This is what carries every chat message, edit, delete, and reaction —
this app uses exactly one data channel, labeled `"app-data"`, per
connection.

**DTLS (Datagram Transport Layer Security).** TLS's UDP-compatible
sibling — provides the encryption and authentication for the data
channel at the transport level, using certificates exchanged as part
of ICE/connection setup (WebRTC generates a self-signed certificate
per `RTCPeerConnection` automatically; its fingerprint is embedded in
the SDP, so both sides can verify the DTLS handshake connects to the
peer they actually negotiated with, not an imposter who somehow
intercepted the SDP exchange).

### What this app's WebRTC code actually does, method by method

`WebRtcConnectionManager` (in `signaling/webrtc_connection_manager.dart`):
- `createOffer({turnEnabled})` — initiator path. Resets any previous
  attempt's state (a real bug fix — see doc 06), creates the
  `RTCPeerConnection`, creates the data channel locally (the responder
  receives it via the `onDataChannel` callback, not by creating its
  own), calls `pc.createOffer()`, sets it as the local description,
  waits for ICE gathering, returns `SignalingOffer(sdp, candidates)`.
- `createAnswerForOffer(remoteOffer, {turnEnabled})` — responder path.
  Same reset, new `RTCPeerConnection`, binds `pc.onDataChannel` (this
  is how the responder gets a reference to the data channel the
  initiator created), applies the remote offer + candidates, creates
  and sets the local answer, waits for its own ICE gathering, returns
  `SignalingAnswer`.
- `applyAnswer(answer)` — initiator path, after receiving the
  response. Sets the remote description and adds the responder's ICE
  candidates.
- `sendRaw(bytes)` / `incomingMessages` stream — the raw (pre-decryption)
  data channel send/receive surface, wrapped by `EncryptedTransport`
  (see doc 02) so nothing above this layer ever sees unencrypted bytes.
- `connectionState` stream — maps directly from `pc.onConnectionState`.
- `close()` / `_resetForNewAttempt()` — resource cleanup. The latter
  exists specifically to fix a real bug: retrying a failed pairing
  attempt used to leak the previous `RTCPeerConnection` and accumulate
  stale ICE candidates from the abandoned attempt into the new one.

### Every callback wired up

- `pc.onIceCandidate` — appends each gathered candidate to an internal
  list (used by `_listenForIceCandidates`'s completer logic).
- `pc.onIceGatheringState` — resolves the gathering-complete future
  when state reaches `RTCIceGatheringStateComplete` (or the 8-second
  timeout fires first).
- `pc.onConnectionState` — forwarded directly to
  `PairingRepository.connectionStatus` (mapped to a simple `bool`:
  `true` only for `RTCPeerConnectionStateConnected`, `false` for
  every other state including the transient `disconnected` state —
  see "limitations" below).
- `pc.onDataChannel` — responder-only; captures the data channel the
  initiator created.
- `channel.onMessage` — forwards binary frames into the
  `incomingMessages` stream, which `EncryptedTransport` subscribes to
  for decryption.

### Connection lifecycle, and what happens at each stage

`new → connecting → connected → disconnected/failed/closed`. This app
only ever surfaces a binary `bool` (`connected` or not) to the rest of
the app via `connectionStatus` — the finer-grained states aren't
exposed to the UI. Notably, `disconnected` (a state ICE can recover
from without full renegotiation, e.g. after a brief network blip) is
currently treated identically to `failed` (unrecoverable) — both show
as "Offline" in the chat screen's connection indicator. This is a
known simplification, not a considered trade-off — see doc 06.

### Reconnection

There is no automatic reconnection. Once a connection reaches
`disconnected`/`failed`/`closed`, or the app process ends, re-establishing
a session requires going back through the pairing flow screen's
"Reconnect" path — a full new offer/answer/ICE exchange (skipping only
the fingerprint re-verification, since the long-term identity keys are
already trusted). This is the direct, unavoidable consequence of
having no server to help re-establish contact automatically — there's
no rendezvous point for one side to say "I'm back online, let's
reconnect" without the other side already being present to receive
that signal, which is exactly the chicken-and-egg problem a signaling
server normally solves.

### Connection failures

- **ICE fails to find any working candidate pair** (symmetric NAT on
  one or both sides, no TURN available) — connection never reaches
  `connected`; the pairing flow screen shows a generic error via the
  `Result.err` path (`UnknownFailure`), since `WebRtcConnectionManager`
  doesn't currently distinguish "ICE failed" from other WebRTC-layer
  errors with a dedicated failure type — see doc 06.
- **Malformed/tampered signaling payload** — caught at the
  `PairingPayload.tryParse`/`verifySignature` stage, well before any
  WebRTC object is even created; surfaces as `SignalingPayloadInvalidFailure`.
- **Stale/expired invite** — rejected by the 10-minute freshness check
  before any WebRTC work begins.

### Limitations

- No TURN fallback (by design — see above).
- No automatic reconnection (by design, but a real UX cost).
- No renegotiation support (no code path ever calls `createOffer` a
  second time on an *already-connected* peer connection to add new
  capabilities — every new session is a from-scratch `RTCPeerConnection`).
- The 8-second ICE gathering timeout is a fixed constant, not adaptive
  to network conditions — could cut off legitimate slow-to-discover
  candidates on some networks, or could be shortened safely on others.

---

## 9. Networking

### How devices discover each other

They don't, automatically — **there is no discovery mechanism**. This
is the most direct consequence of design goal #1. The user *is* the
discovery mechanism: they know who they're pairing with because
they're physically transmitting the QR code/text to that specific
person through a channel they already trust for that purpose (in
person, a call, an existing contact in another app).

### Signaling — why it exists, and where it lives here

Signaling, in WebRTC generally, is the mechanism for exchanging offer/
answer/ICE-candidate data *before* a direct connection exists — by
definition, this can't happen over the connection being negotiated
itself, so *something* else has to carry it. In the typical
architecture, that's a lightweight WebSocket server. **In this app,
the human is the signaling channel** — the entire signaling exchange
is bundled into `PairingPayload`, encoded as QR/text, and transmitted
by the user through whatever means they choose. The app has zero
signaling infrastructure of its own.

### What "peer-to-peer" means here, precisely

Once ICE finds a working candidate pair and the data channel opens,
packets travel **directly** between the two devices' network
addresses — no intermediary relays, forwards, or inspects them. This
is only true when a direct (host-to-host or server-reflexive/STUN-assisted)
candidate pair succeeds.

### When it's direct vs. when it would be relayed

- **Direct, same network:** both devices on the same Wi-Fi — host
  candidates connect directly, no external server involved at all,
  not even for discovery (though STUN is still queried during
  gathering regardless, the resulting server-reflexive candidate
  simply won't be the one ICE picks).
- **Direct, different networks:** STUN-assisted — each device learns
  its public IP:port via STUN, ICE connects those directly (this is
  the common case, and works for the large majority of consumer NAT
  setups, which are "full cone" or "restricted cone," not symmetric).
- **Would-be-relayed:** symmetric NAT on one or both sides, where the
  public port a NAT exposes changes per destination, defeating
  STUN-discovered addresses. Normal WebRTC apps fall back to TURN
  here. **This app has no TURN by default, so this case is simply a
  connection failure**, not a relayed connection — see doc 08.

### Every network path in this app, enumerated

1. **STUN queries during ICE gathering** — UDP, to Google's public
   STUN servers, carrying no application data, only NAT-discovery
   handshake packets.
2. **The manual signaling transmission** — not a network path this app
   controls at all; QR (visual, no network) or pasted text (through
   whatever app the user chooses — SMS, another messenger, email,
   verbally read aloud — entirely outside this app's control or
   visibility).
3. **The DTLS/SCTP data channel** — UDP, directly between the two
   devices (or, if TURN were ever enabled, via the TURN relay) once
   ICE negotiation completes. This carries every encrypted chat
   message, edit, delete, and reaction frame.

There is no path 4 — no analytics endpoint, no crash reporting
service, no update-check server, nothing. If you run this app under a
network monitor, everything you see should be explainable by paths 1-3.

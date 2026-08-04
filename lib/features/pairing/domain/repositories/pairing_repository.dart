import 'package:two_person_app/features/pairing/data/signaling/webrtc_connection_manager.dart';
import 'package:two_person_app/core/utils/result.dart';
import 'package:two_person_app/features/pairing/domain/entities/device_identity.dart';
import 'package:two_person_app/features/pairing/domain/entities/encrypted_channel.dart';
import 'package:two_person_app/features/pairing/domain/entities/invite.dart';
import 'package:two_person_app/features/pairing/domain/entities/pairing_stage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../data/crypto/session_crypto_service.dart';

RTCDataChannel? get rtcDataChannel;

SessionCipher? get sessionCipher;
/// Contract for identity, key exchange, and the live connection to the
/// one other person this app talks to. Chat depends only on this
/// interface -- never on the signaling relay, WebRTC, or crypto types
/// directly.
///
/// Rewritten for the invite-link/signaling-relay architecture -- see
/// docs/PAIRING_MIGRATION.md. The old three-step QR round trip
/// (createInviteLink -> acceptInvite -> completePairing) is gone,
/// replaced by two entry points (createInvite / joinInvite) since the
/// relay makes the exchange live/bidirectional instead of manual.
abstract class PairingRepository {
  /// Whether this device already has a paired peer (max: 1, ever).
  Future<bool> get isPaired;

  /// This device's own identity (generated on first launch).
  Future<DeviceIdentity> get localIdentity;

  /// The paired peer's identity, if pairing has completed.
  Future<DeviceIdentity?> get peerIdentity;

  /// Initiator side: creates a new invite via the signaling server
  /// and opens a relay connection to wait for a peer. Returns the
  /// tiny [Invite] (id + expiry) to render as a QR code / share link
  /// -- nothing else needs to be embedded in it anymore.
  Future<Result<Invite>> createInvite();

  /// Responder side: joins an existing invite (from a scanned QR,
  /// pasted text, or opened deep link) and opens a relay connection.
  /// The actual identity/SDP/ICE exchange happens automatically after
  /// this via the relay -- watch [pairingStage] for progress.
  Future<Result<void>> joinInvite(String inviteId);

  /// Cancels an in-progress invite (before it completes) -- closes
  /// the relay connection rather than waiting out the full TTL.
  Future<void> cancelPairing();

  /// User-facing manual verification of the peer's fingerprint
  /// (read-aloud / compare-side-by-side flow). Only meaningful the
  /// first time two devices pair.
  Future<Result<void>> confirmFingerprintVerified();

  /// True once a live encrypted data channel to the peer is open for
  /// *this session*. Resets to false on every app relaunch -- there
  /// is no server keeping a connection alive between launches (the
  /// signaling relay only exists during pairing itself, not as an
  /// always-on presence service).
  Stream<bool> get connectionStatus;

  /// Fine-grained progress through one pairing attempt -- see
  /// [PairingStage] for what each value means. This is what the
  /// pairing flow UI actually watches; [connectionStatus] only tells
  /// it "connected or not," not "waiting for peer" vs "negotiating."
  Stream<PairingStage> get pairingStage;

  /// The live encrypted channel, once session keys are established
  /// and the data channel is open. Null before that point.
  EncryptedChannel? get transport;
}
/// Exposes the active WebRTC connection so the media layer can wrap the
/// existing RTCDataChannel. The media layer never creates another
/// PeerConnection.
WebRtcConnectionManager? get connectionManager;

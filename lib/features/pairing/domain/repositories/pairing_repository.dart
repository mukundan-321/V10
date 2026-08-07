import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:two_person_app/core/utils/result.dart';
import 'package:two_person_app/features/pairing/data/crypto/session_crypto_service.dart';
import 'package:two_person_app/features/pairing/data/signaling/webrtc_connection_manager.dart';
import 'package:two_person_app/features/pairing/domain/entities/device_identity.dart';
import 'package:two_person_app/features/pairing/domain/entities/encrypted_channel.dart';
import 'package:two_person_app/features/pairing/domain/entities/invite.dart';
import 'package:two_person_app/features/pairing/domain/entities/pairing_stage.dart';

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
  /// and opens a relay connection to wait for a peer.
  Future<Result<Invite>> createInvite();

  /// Responder side: joins an existing invite and opens a relay
  /// connection. The identity/SDP/ICE exchange then happens
  /// automatically.
  Future<Result<void>> joinInvite(String inviteId);

  /// Cancels an in-progress pairing attempt.
  Future<void> cancelPairing();

  /// Marks the peer fingerprint as manually verified.
  Future<Result<void>> confirmFingerprintVerified();

  /// True whenever the encrypted data channel is currently connected.
  Stream<bool> get connectionStatus;

  /// Pairing progress.
  Stream<PairingStage> get pairingStage;

  /// Active encrypted transport.
  EncryptedChannel? get transport;

  // ==========================================================
  // Media Layer Accessors
  // ==========================================================

  /// The active WebRTC data channel.
  RTCDataChannel? get rtcDataChannel;

  /// Current session cipher used for media encryption.
  SessionCipher? get sessionCipher;

  /// Active WebRTC connection manager.
  WebRtcConnectionManager get connectionManager;
}
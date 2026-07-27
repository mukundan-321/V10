import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import 'package:two_person_app/core/database/app_database.dart';
import 'package:two_person_app/core/error/failures.dart';
import 'package:two_person_app/core/utils/result.dart';
import 'package:two_person_app/features/pairing/domain/entities/device_identity.dart';
import 'package:two_person_app/features/pairing/domain/entities/encrypted_channel.dart';
import 'package:two_person_app/features/pairing/domain/entities/invite.dart';
import 'package:two_person_app/features/pairing/domain/entities/pairing_stage.dart';
import 'package:two_person_app/features/pairing/domain/entities/signaling_message.dart';
import 'package:two_person_app/features/pairing/domain/repositories/pairing_repository.dart';

import 'crypto/fingerprint.dart';
import 'crypto/identity_key_service.dart';
import 'crypto/message_signing.dart';
import 'crypto/session_crypto_service.dart';
import 'signaling/encrypted_transport.dart';
import 'signaling/invite_api_client.dart';
import 'signaling/signaling_client.dart';
import 'signaling/webrtc_connection_manager.dart';

const _peerIdentityKeyType = 'peer_identity_pub';
const _peerSigningKeyType = 'peer_signing_pub';

/// Orchestrates the invite-link + signaling-relay pairing architecture
/// (see docs/PAIRING_MIGRATION.md). Key generation, fingerprint
/// computation, session-key derivation, and the encrypted transport
/// underneath chat are all unchanged from the previous QR-payload
/// design -- only how the offer/answer/ICE/key exchange gets from one
/// device to the other has changed, from "printed in a QR code" to
/// "relayed live over a signaling server."
///
/// TURN is hardcoded off -- this app has no settings UI to toggle it.
class PairingRepositoryImpl implements PairingRepository {
  final AppDatabase db;
  final IdentityKeyService identityKeyService;
  final InviteApiClient inviteApiClient;
  final String baseWsUrl;
  final _uuid = const Uuid();
  final _sessionKeyExchange = SessionKeyExchange();

  static const _turnEnabled = false;

  final _connectionManager = WebRtcConnectionManager();
  EncryptedTransport? _transport;

  SignalingClient? _signalingClient;
  StreamSubscription<SignalingMessage>? _signalingSub;
  StreamSubscription<void>? _signalingClosedSub;
  StreamSubscription<RTCIceCandidate>? _localCandidateSub;
  StreamSubscription<RTCPeerConnectionState>? _connectionStateSub;

  final _stageController = StreamController<PairingStage>.broadcast();

  bool? _isInitiator;
  String? _currentInviteId;
  String? _peerSigningKeyBase64; // learned from the peer's IdentityMessage
  SimpleKeyPair? _pendingEphemeralKeyPair;
  bool _dataChannelOpenSent = false;

  PairingRepositoryImpl({
    required this.db,
    required this.identityKeyService,
    required this.inviteApiClient,
    required this.baseWsUrl,
  });

    @override
  Future<bool> get isPaired async {
    print("========== STEP 3 ==========");
    print("PairingRepository.isPaired() called");

    try {
      final peerKey = await (db.select(db.keyRecords)
            ..where((t) => t.keyType.equals(_peerIdentityKeyType)))
          .getSingleOrNull();

      print("========== STEP 4 ==========");
      print("Database query completed");
      print("peerKey = $peerKey");

      return peerKey != null;
    } catch (e, stackTrace) {
      print("========== DATABASE ERROR ==========");
      print(e);
      print(stackTrace);
      rethrow;
    }
  }

  @override
  Future<DeviceIdentity> get localIdentity async {
    final identity = await identityKeyService.getOrCreateIdentity();
    return DeviceIdentity(
      deviceId: identity.deviceId,
      identityPublicKeyBase64: await identity.identityPublicKeyBase64,
      signingPublicKeyBase64: await identity.signingPublicKeyBase64,
      fingerprint: '',
      fingerprintVerified: false,
      pairedAt: DateTime.now(),
    );
  }

  @override
  Future<DeviceIdentity?> get peerIdentity async {
    final identityRow = await (db.select(db.keyRecords)
          ..where((t) => t.keyType.equals(_peerIdentityKeyType)))
        .getSingleOrNull();
    final signingRow = await (db.select(db.keyRecords)
          ..where((t) => t.keyType.equals(_peerSigningKeyType)))
        .getSingleOrNull();
    if (identityRow == null || signingRow == null) return null;

    return DeviceIdentity(
      deviceId: identityRow.id,
      identityPublicKeyBase64: identityRow.publicKeyBase64 ?? '',
      signingPublicKeyBase64: signingRow.publicKeyBase64 ?? '',
      fingerprint: identityRow.fingerprint ?? '',
      fingerprintVerified: identityRow.fingerprintVerifiedByUser,
      pairedAt: identityRow.createdAt,
    );
  }

  @override
  Future<Result<Invite>> createInvite() async {
    await _resetPairingState();
    _isInitiator = true;

    final inviteResult = await inviteApiClient.createInvite();
    final Invite invite;
    switch (inviteResult) {
      case Ok<Invite>(value: final v):
        invite = v;
      case Err<Invite>(failure: final f):
        return Err(f);
    }
    _currentInviteId = invite.id;

    try {
      final client = SignalingClient(baseWsUrl: baseWsUrl);
      await client.connect(inviteId: invite.id, isInitiator: true);
      _signalingClient = client;
      _bindSignalingClient(client);
      _bindLocalIceCandidates();
      _bindConnectionState();
      _stageController.add(PairingStage.waitingForPeer);
      return Ok(invite);
    } catch (e) {
      _stageController.add(PairingStage.failed);
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> joinInvite(String inviteId) async {
    await _resetPairingState();
    _isInitiator = false;
    _currentInviteId = inviteId;

    try {
      final client = SignalingClient(baseWsUrl: baseWsUrl);
      await client.connect(inviteId: inviteId, isInitiator: false);
      _signalingClient = client;
      _bindSignalingClient(client);
      _bindLocalIceCandidates();
      _bindConnectionState();
      _stageController.add(PairingStage.negotiating);
      return const Ok(null);
    } catch (e) {
      _stageController.add(PairingStage.failed);
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> cancelPairing() async {
    await _resetPairingState();
    _stageController.add(PairingStage.idle);
  }

  @override
  Future<Result<void>> confirmFingerprintVerified() async {
    final rows = await (db.update(db.keyRecords)
          ..where((t) => t.keyType.equals(_peerIdentityKeyType)))
        .write(const KeyRecordsCompanion(
      fingerprintVerifiedByUser: Value(true),
    ));
    if (rows == 0) return const Err(UnknownFailure('No peer key on record.'));
    return const Ok(null);
  }

  @override
  Stream<bool> get connectionStatus => _connectionManager.connectionState
      .map((s) => s == RTCPeerConnectionState.RTCPeerConnectionStateConnected);

  @override
  Stream<PairingStage> get pairingStage => _stageController.stream;

  @override
  EncryptedChannel? get transport => _transport;

  // --- Signaling message handling ------------------------------------

  void _bindSignalingClient(SignalingClient client) {
    _signalingSub = client.incoming.listen(_handleSignalingMessage);
    _signalingClosedSub = client.connectionClosed.listen((_) {
      // Expected once pairing completes (server closes both sockets
      // after seeing data_channel_open from both sides) -- only treat
      // this as a failure if it happens before we ever reached
      // `connected`.
      if (_connectionManager.isDataChannelOpen) return;
    });
  }

  void _bindLocalIceCandidates() {
    _localCandidateSub = _connectionManager.localIceCandidates.listen((candidate) async {
      final identity = await identityKeyService.getOrCreateIdentity();
      final message = IceCandidateMessage(
        candidate: candidate.candidate ?? '',
        sdpMid: candidate.sdpMid,
        sdpMLineIndex: candidate.sdpMLineIndex,
        signatureBase64: '',
      );
      final signed = IceCandidateMessage(
        candidate: message.candidate,
        sdpMid: message.sdpMid,
        sdpMLineIndex: message.sdpMLineIndex,
        signatureBase64: await MessageSigning.sign(message.signedBytes, identity.signingKeyPair),
      );
      _signalingClient?.send(signed);
    });
  }

  void _bindConnectionState() {
    _connectionStateSub =
    _connectionManager.connectionState.listen((state) async {

  print("WebRTC State: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _stageController.add(PairingStage.connected);
        if (!_dataChannelOpenSent) {
          _dataChannelOpenSent = true;
          _signalingClient?.send(const DataChannelOpenMessage());
        }
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _stageController.add(PairingStage.failed);
      }
    });
  }

  Future<void> _handleSignalingMessage(SignalingMessage message) async {
print("Received: $
{message.runtimeType}");
  try {
    switch (message) {
      case PeerJoinedMessage():
        await _onPeerJoined();

      case PeerLeftMessage():
        _stageController.add(PairingStage.peerLeft);

      case InviteExpiredMessage():
        _stageController.add(PairingStage.expired);

      case IdentityMessage():
        await _onIdentityReceived(message);

      case EphemeralKeyMessage():
        await _onEphemeralKeyReceived(message);

      case SdpOfferMessage():
        await _onSdpOfferReceived(message);

      case SdpAnswerMessage():
        await _onSdpAnswerReceived(message);

      case IceCandidateMessage():
        await _onIceCandidateReceived(message);

      case DataChannelOpenMessage():
        break;
    }
  } catch (e, stack) {
    print("================================");
    print("SIGNALING ERROR");
    print(e);
    print(stack);
    print("================================");

    _stageController.add(PairingStage.failed);
  }
}

  Future<void> _onPeerJoined() async {
   print("Peer Joined"); _stageController.add(PairingStage.negotiating);
    final identity = await identityKeyService.getOrCreateIdentity();

    final identityMsg = IdentityMessage(
      identityPublicKeyBase64: await identity.identityPublicKeyBase64,
      signingPublicKeyBase64: await identity.signingPublicKeyBase64,
      deviceId: identity.deviceId,
      signatureBase64: '',
    );
    final signedIdentityMsg = IdentityMessage(
      identityPublicKeyBase64: identityMsg.identityPublicKeyBase64,
      signingPublicKeyBase64: identityMsg.signingPublicKeyBase64,
      deviceId: identityMsg.deviceId,
      signatureBase64:
          await MessageSigning.sign(identityMsg.signedBytes, identity.signingKeyPair),
    );
    _signalingClient?.send(signedIdentityMsg);

    _pendingEphemeralKeyPair = await _sessionKeyExchange.generateEphemeral();
    final ephemeralPub = await _pendingEphemeralKeyPair!.extractPublicKey();
    final ephemeralMsg = EphemeralKeyMessage(
      ephemeralPublicKeyBase64: base64Encode(ephemeralPub.bytes),
      signatureBase64: '',
    );
    final signedEphemeralMsg = EphemeralKeyMessage(
      ephemeralPublicKeyBase64: ephemeralMsg.ephemeralPublicKeyBase64,
      signatureBase64:
          await MessageSigning.sign(ephemeralMsg.signedBytes, identity.signingKeyPair),
    );
    _signalingClient?.send(signedEphemeralMsg);

    if (_isInitiator == true) {
      final offerSdp = await _connectionManager.createOffer(turnEnabled: _turnEnabled);
      final offerMsg = SdpOfferMessage(sdp: offerSdp, signatureBase64: '');
      final signedOfferMsg = SdpOfferMessage(
        sdp: offerSdp,
        signatureBase64: await MessageSigning.sign(offerMsg.signedBytes, identity.signingKeyPair),
      );
      _signalingClient?.send(signedOfferMsg);
    }
  }

  Future<void> _onIdentityReceived(IdentityMessage message) async {
print("Identity Received");
    final valid = await MessageSigning.verify(
      message.signedBytes,
      signatureBase64: message.signatureBase64,
      signingPublicKeyBase64: message.signingPublicKeyBase64,
    );
    if (!valid) return;

    _peerSigningKeyBase64 = message.signingPublicKeyBase64;

    final identity = await identityKeyService.getOrCreateIdentity();
    final fingerprint = await FingerprintService.compute(
      localIdentityPublicKey: base64Decode(await identity.identityPublicKeyBase64),
      peerIdentityPublicKey: base64Decode(message.identityPublicKeyBase64),
    );

    await _persistPeerKeys(
      peerDeviceId: message.deviceId,
      identityPublicKeyBase64: message.identityPublicKeyBase64,
      signingPublicKeyBase64: message.signingPublicKeyBase64,
      fingerprint: fingerprint,
    );
  }

  Future<void> _onEphemeralKeyReceived(EphemeralKeyMessage message) async {
print("Ephemeral Key Received");
    final peerSigningKey = _peerSigningKeyBase64;
    if (peerSigningKey == null) return; // identity must arrive first
    final valid = await MessageSigning.verify(
      message.signedBytes,
      signatureBase64: message.signatureBase64,
      signingPublicKeyBase64: peerSigningKey,
    );
    if (!valid) return;

    final localEphemeral = _pendingEphemeralKeyPair;
    if (localEphemeral == null) return;

    final peerEphemeralPub = SimplePublicKey(
      base64Decode(message.ephemeralPublicKeyBase64),
      type: KeyPairType.x25519,
    );
    final sessionKeys = await _sessionKeyExchange.deriveSessionKeys(
      localEphemeralKeyPair: localEphemeral,
      remoteEphemeralPublicKey: peerEphemeralPub,
      isInitiator: _isInitiator ?? false,
    );

    await _transport?.dispose();
    _transport = EncryptedTransport(_connectionManager)
      ..attachSessionCipher(SessionCipher(sessionKeys));
  }

  Future<void> _onSdpOfferReceived(SdpOfferMessage message) async {
print("SDP Offer Received");
    final peerSigningKey = _peerSigningKeyBase64;
    if (peerSigningKey == null || _isInitiator != false) return;
    final valid = await MessageSigning.verify(
      message.signedBytes,
      signatureBase64: message.signatureBase64,
      signingPublicKeyBase64: peerSigningKey,
    );
    if (!valid) return;

    final answerSdp = await _connectionManager.createAnswerForOffer(
      message.sdp,
      turnEnabled: _turnEnabled,
    );
    final identity = await identityKeyService.getOrCreateIdentity();
    final answerMsg = SdpAnswerMessage(sdp: answerSdp, signatureBase64: '');
    final signedAnswerMsg = SdpAnswerMessage(
      sdp: answerSdp,
      signatureBase64: await MessageSigning.sign(answerMsg.signedBytes, identity.signingKeyPair),
    );
    _signalingClient?.send(signedAnswerMsg);
  }

  Future<void> _onSdpAnswerReceived(SdpAnswerMessage message) async {
    final peerSigningKey = _peerSigningKeyBase64;
    if (peerSigningKey == null || _isInitiator != true) return;
    final valid = await MessageSigning.verify(
      message.signedBytes,
      signatureBase64: message.signatureBase64,
      signingPublicKeyBase64: peerSigningKey,
    );
    if (!valid) return;

    await _connectionManager.applyAnswer(message.sdp);
  }

  Future<void> _onIceCandidateReceived(IceCandidateMessage message) async {
print("ICE Candidate Received");
    final peerSigningKey = _peerSigningKeyBase64;
    if (peerSigningKey == null) return;
    final valid = await MessageSigning.verify(
      message.signedBytes,
      signatureBase64: message.signatureBase64,
      signingPublicKeyBase64: peerSigningKey,
    );
    if (!valid) return;

    await _connectionManager.addRemoteIceCandidate(
      candidate: message.candidate,
      sdpMid: message.sdpMid,
      sdpMLineIndex: message.sdpMLineIndex,
    );
  }

  // --- Cleanup ---------------------------------------------------------

  Future<void> _resetPairingState() async {
    await _signalingSub?.cancel();
    await _signalingClosedSub?.cancel();
    await _localCandidateSub?.cancel();
    await _connectionStateSub?.cancel();
    await _signalingClient?.close();
    _signalingClient = null;
    _peerSigningKeyBase64 = null;
    _pendingEphemeralKeyPair = null;
    _dataChannelOpenSent = false;
    _currentInviteId = null;
  }

  Future<void> _persistPeerKeys({
    required String peerDeviceId,
    required String identityPublicKeyBase64,
    required String signingPublicKeyBase64,
    required String fingerprint,
  }) async {
    final existing = await (db.select(db.keyRecords)
          ..where((t) => t.keyType.equals(_peerIdentityKeyType)))
        .getSingleOrNull();

    if (existing != null && existing.publicKeyBase64 == identityPublicKeyBase64) {
      return; // same peer as before -- nothing to update, verified flag stays.
    }

    await (db.delete(db.keyRecords)
          ..where((t) =>
              t.keyType.equals(_peerIdentityKeyType) |
              t.keyType.equals(_peerSigningKeyType)))
        .go();

    final now = DateTime.now();
    await db.into(db.keyRecords).insert(KeyRecordsCompanion.insert(
          id: peerDeviceId,
          keyType: _peerIdentityKeyType,
          publicKeyBase64: Value(identityPublicKeyBase64),
          fingerprint: Value(fingerprint),
          createdAt: now,
        ));
    await db.into(db.keyRecords).insert(KeyRecordsCompanion.insert(
          id: _uuid.v4(),
          keyType: _peerSigningKeyType,
          publicKeyBase64: Value(signingPublicKeyBase64),
          fingerprint: Value(fingerprint),
          createdAt: now,
        ));
  }
}

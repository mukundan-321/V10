import 'dart:convert';

/// Every message that travels over the signaling relay during pairing.
/// The server treats all of these as opaque JSON it forwards without
/// interpreting — everything meaningful about validity (signatures,
/// structure) is checked client-side, same trust boundary the old
/// QR-payload design used, just applied to several small messages
/// instead of one large bundle.
///
/// Why every payload-carrying message is still signed even though it
/// now travels over a "live" connection instead of a printed QR code:
/// signing was never about proving the *transport* was safe (QR
/// codes aren't inherently more trustworthy than a WebSocket) — it's
/// about making tampering detectable regardless of transport. A
/// compromised or malicious relay server can see and could try to
/// alter these messages in transit; a signature makes that alteration
/// either fail verification or require the attacker to also forge a
/// consistent identity, which is exactly the scenario fingerprint
/// verification (see fingerprint.dart) exists to catch.
sealed class SignalingMessage {
  const SignalingMessage();

  Map<String, dynamic> toJsonMap();

  String toJson() => jsonEncode(toJsonMap());

  static SignalingMessage? tryParse(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      switch (map['type'] as String?) {
        case 'peer_joined':
          return const PeerJoinedMessage();
        case 'peer_left':
          return const PeerLeftMessage();
        case 'invite_expired':
          return const InviteExpiredMessage();
        case 'identity':
          return IdentityMessage(
            identityPublicKeyBase64: map['identityPublicKey'] as String,
            signingPublicKeyBase64: map['signingPublicKey'] as String,
            deviceId: map['deviceId'] as String,
            signatureBase64: map['signature'] as String,
          );
        case 'ephemeral_key':
          return EphemeralKeyMessage(
            ephemeralPublicKeyBase64: map['ephemeralPublicKey'] as String,
            signatureBase64: map['signature'] as String,
          );
        case 'sdp_offer':
          return SdpOfferMessage(
            sdp: map['sdp'] as String,
            signatureBase64: map['signature'] as String,
          );
        case 'sdp_answer':
          return SdpAnswerMessage(
            sdp: map['sdp'] as String,
            signatureBase64: map['signature'] as String,
          );
        case 'ice_candidate':
          return IceCandidateMessage(
            candidate: map['candidate'] as String,
            sdpMid: map['sdpMid'] as String?,
            sdpMLineIndex: map['sdpMLineIndex'] as int?,
            signatureBase64: map['signature'] as String,
          );
        case 'data_channel_open':
          return const DataChannelOpenMessage();
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}

/// Server -> both clients, once a responder connects to the same
/// invite ID as the waiting initiator.
class PeerJoinedMessage extends SignalingMessage {
  const PeerJoinedMessage();
  @override
  Map<String, dynamic> toJsonMap() => {'type': 'peer_joined'};
}

/// Server -> remaining client, if the other side disconnects before
/// pairing completes.
class PeerLeftMessage extends SignalingMessage {
  const PeerLeftMessage();
  @override
  Map<String, dynamic> toJsonMap() => {'type': 'peer_left'};
}

/// Server -> client, if the invite's 10-minute TTL elapses.
class InviteExpiredMessage extends SignalingMessage {
  const InviteExpiredMessage();
  @override
  Map<String, dynamic> toJsonMap() => {'type': 'invite_expired'};
}

class IdentityMessage extends SignalingMessage {
  final String identityPublicKeyBase64;
  final String signingPublicKeyBase64;
  final String deviceId;
  final String signatureBase64;

  const IdentityMessage({
    required this.identityPublicKeyBase64,
    required this.signingPublicKeyBase64,
    required this.deviceId,
    required this.signatureBase64,
  });

  /// Canonical bytes covered by the signature — fixed field order so
  /// both the signer and verifier hash the same thing.
  List<int> get signedBytes => utf8.encode(jsonEncode({
        'type': 'identity',
        'identityPublicKey': identityPublicKeyBase64,
        'signingPublicKey': signingPublicKeyBase64,
        'deviceId': deviceId,
      }));

  @override
  Map<String, dynamic> toJsonMap() => {
        'type': 'identity',
        'identityPublicKey': identityPublicKeyBase64,
        'signingPublicKey': signingPublicKeyBase64,
        'deviceId': deviceId,
        'signature': signatureBase64,
      };
}

class EphemeralKeyMessage extends SignalingMessage {
  final String ephemeralPublicKeyBase64;
  final String signatureBase64;

  const EphemeralKeyMessage({
    required this.ephemeralPublicKeyBase64,
    required this.signatureBase64,
  });

  List<int> get signedBytes => utf8.encode(jsonEncode({
        'type': 'ephemeral_key',
        'ephemeralPublicKey': ephemeralPublicKeyBase64,
      }));

  @override
  Map<String, dynamic> toJsonMap() => {
        'type': 'ephemeral_key',
        'ephemeralPublicKey': ephemeralPublicKeyBase64,
        'signature': signatureBase64,
      };
}

class SdpOfferMessage extends SignalingMessage {
  final String sdp;
  final String signatureBase64;

  const SdpOfferMessage({required this.sdp, required this.signatureBase64});

  List<int> get signedBytes =>
      utf8.encode(jsonEncode({'type': 'sdp_offer', 'sdp': sdp}));

  @override
  Map<String, dynamic> toJsonMap() =>
      {'type': 'sdp_offer', 'sdp': sdp, 'signature': signatureBase64};
}

class SdpAnswerMessage extends SignalingMessage {
  final String sdp;
  final String signatureBase64;

  const SdpAnswerMessage({required this.sdp, required this.signatureBase64});

  List<int> get signedBytes =>
      utf8.encode(jsonEncode({'type': 'sdp_answer', 'sdp': sdp}));

  @override
  Map<String, dynamic> toJsonMap() =>
      {'type': 'sdp_answer', 'sdp': sdp, 'signature': signatureBase64};
}

class IceCandidateMessage extends SignalingMessage {
  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;
  final String signatureBase64;

  const IceCandidateMessage({
    required this.candidate,
    required this.sdpMid,
    required this.sdpMLineIndex,
    required this.signatureBase64,
  });

  List<int> get signedBytes => utf8.encode(jsonEncode({
        'type': 'ice_candidate',
        'candidate': candidate,
        'sdpMid': sdpMid,
        'sdpMLineIndex': sdpMLineIndex,
      }));

  @override
  Map<String, dynamic> toJsonMap() => {
        'type': 'ice_candidate',
        'candidate': candidate,
        'sdpMid': sdpMid,
        'sdpMLineIndex': sdpMLineIndex,
        'signature': signatureBase64,
      };
}

/// Client -> server -> other client, sent once this side's own
/// RTCPeerConnection reaches the `connected` state. Once the server
/// has seen this from both sides, the invite is deleted — this is
/// what makes an invite single-use even within its 10-minute window.
class DataChannelOpenMessage extends SignalingMessage {
  const DataChannelOpenMessage();
  @override
  Map<String, dynamic> toJsonMap() => {'type': 'data_channel_open'};
}

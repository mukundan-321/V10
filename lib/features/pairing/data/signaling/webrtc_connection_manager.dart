import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'ice_config.dart';

/// Wraps a single [RTCPeerConnection] and its one data channel.
///
/// Rewritten for the invite-link/signaling-relay pairing architecture
/// (see docs/PAIRING_MIGRATION.md): ICE is now **trickle** — each
/// candidate is emitted the moment it's discovered, via
/// [localIceCandidates], instead of being gathered into a batch and
/// returned only once gathering completes. This is possible now
/// because there's a live relay connection to send candidates over as
/// they're found; the old non-trickle approach existed only because
/// the QR/text-based signaling had no "live channel" to trickle
/// candidates over and had to ship them all at once instead — that
/// batching was the direct cause of oversized QR payloads, so
/// removing it is the actual structural fix, not a workaround.
class WebRtcConnectionManager {
  static const _dataChannelLabel = 'app-data';

  RTCPeerConnection? _pc;
  RTCDataChannel? _dataChannel;

  final _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();
  final _incomingMessagesController = StreamController<Uint8List>.broadcast();
  final _localIceCandidatesController =
      StreamController<RTCIceCandidate>.broadcast();

  Stream<RTCPeerConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<Uint8List> get incomingMessages => _incomingMessagesController.stream;

  /// Emits each local ICE candidate as soon as it's discovered — the
  /// caller (PairingRepositoryImpl) is expected to relay each one to
  /// the peer via the signaling client immediately, not batch them.
  Stream<RTCIceCandidate> get localIceCandidates =>
      _localIceCandidatesController.stream;

  bool get isDataChannelOpen =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;

  /// Offer side (pairing initiator). Creates the peer connection and
  /// opens the data channel locally (the answerer receives it via
  /// `onDataChannel`). Returns immediately after the local
  /// description is set — does NOT wait for ICE gathering, since
  /// candidates now trickle out individually via [localIceCandidates]
  /// instead of being collected into the return value.
  Future<String> createOffer({required bool turnEnabled}) async {
    await _resetForNewAttempt();
    final pc = await createPeerConnection(
      IceConfig.configuration(turnEnabled: turnEnabled),
    );
    _pc = pc;
    _bindConnectionState(pc);
    _bindIceCandidateTrickle(pc);

    final channel = await pc.createDataChannel(
      _dataChannelLabel,
      RTCDataChannelInit()..ordered = true,
    );
    _bindDataChannel(channel);

    final offer = await pc.createOffer();
print("========== CREATE OFFER ==========");
print("Offer Created");
    await pc.setLocalDescription(offer);
print("Local Description Set");
    return offer.sdp!;
  }

  /// Answer side (pairing responder).
  Future<String> createAnswerForOffer(
    String remoteOfferSdp, {
    required bool turnEnabled,
  }) async {
    await _resetForNewAttempt();
    final pc = await createPeerConnection(
      IceConfig.configuration(turnEnabled: turnEnabled),
    );
    _pc = pc;
    _bindConnectionState(pc);
    _bindIceCandidateTrickle(pc);

    pc.onDataChannel = (channel) => _bindDataChannel(channel);

print("========== APPLY OFFER ==========");

    await pc.setRemoteDescription(RTCSessionDescription(remoteOfferSdp, 'offer'));

print("Remote Offer Applied");

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
print("Local Answer Applied");
    return answer.sdp!;
  }

  /// Offer side, after receiving the answer over the relay.
  Future<void> applyAnswer(String answerSdp) async {
  final pc = _pc;
  if (pc == null) {
    throw StateError('applyAnswer called before createOffer.');
  }

  print("========== APPLY ANSWER ==========");

  await pc.setRemoteDescription(
    RTCSessionDescription(answerSdp, 'answer'),
  );

  print("Remote Answer Applied");
}

  /// Adds one remote ICE candidate as it arrives over the relay.
  /// Safe to call even if a candidate arrives slightly before the
  /// local RTCPeerConnection exists in some unusual ordering — it's
  /// simply dropped in that case rather than throwing, since a
  /// legitimate peer will keep sending candidates as it discovers
  /// them and a dropped early one rarely matters given how many are
  /// typically gathered.
  Future<void> addRemoteIceCandidate({
  required String candidate,
  String? sdpMid,
  int? sdpMLineIndex,
}) async {
  final pc = _pc;

  print("========== REMOTE ICE ==========");
  print("Candidate : $candidate");

  if (pc == null) {
    print("PeerConnection is NULL");
    return;
  }

  await pc.addCandidate(
    RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
  );

  print("Remote ICE Added");
}
  Future<void> sendRaw(Uint8List bytes) async {
    final channel = _dataChannel;
    if (channel == null || !isDataChannelOpen) {
      throw StateError('Data channel is not open.');
    }
    await channel.send(RTCDataChannelMessage.fromBinary(bytes));
  }

  Future<void> close() async {
    await _dataChannel?.close();
    await _pc?.close();
    await _connectionStateController.close();
    await _incomingMessagesController.close();
    await _localIceCandidatesController.close();
  }

  /// Called at the start of every new offer/answer attempt, so a
  /// retry doesn't leak the previous RTCPeerConnection's native
  /// resources or leave its data channel callback still bound.
  Future<void> _resetForNewAttempt() async {
    await _dataChannel?.close();
    await _pc?.close();
    _dataChannel = null;
    _pc = null;
  }

  void _bindConnectionState(RTCPeerConnection pc) {
  pc.onConnectionState = (state) {
    print("========== PEER CONNECTION ==========");
    print("Connection State : $state");
    _connectionStateController.add(state);
  };

  pc.onIceConnectionState = (state) {
    print("========== ICE CONNECTION ==========");
    print("ICE State : $state");
  };

  pc.onIceGatheringState = (state) {
    print("========== ICE GATHERING ==========");
    print("ICE Gathering : $state");
  };

  pc.onSignalingState = (state) {
    print("========== SIGNALING ==========");
    print("Signaling State : $state");
  };
}

  void _bindIceCandidateTrickle(RTCPeerConnection pc) {
  pc.onIceCandidate = (candidate) {
    print("========== LOCAL ICE ==========");
    print("Candidate : ${candidate.candidate}");
    print("Mid       : ${candidate.sdpMid}");
    print("Index     : ${candidate.sdpMLineIndex}");

    if (candidate.candidate != null &&
        candidate.candidate!.isNotEmpty) {
      _localIceCandidatesController.add(candidate);
    }
  };
}

  void _bindDataChannel(RTCDataChannel channel) {
  print("========== DATA CHANNEL ==========");
  print("Channel Created");

  _dataChannel = channel;

  channel.onDataChannelState = () {
    print("========== DATA CHANNEL ==========");
    print("State : ${channel.state}");
  };

  channel.onMessage = (message) {
    print("========== DATA CHANNEL MESSAGE ==========");
    print("Binary : ${message.isBinary}");

    if (message.isBinary) {
      print("Length : ${message.binary.length}");
      _incomingMessagesController.add(message.binary);
    } else {
      print("Text : ${message.text}");
    }
  };
}

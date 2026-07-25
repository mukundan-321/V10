import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:two_person_app/features/pairing/data/crypto/message_signing.dart';
import 'package:two_person_app/features/pairing/domain/entities/signaling_message.dart';

void main() {
  group('MessageSigning + SignalingMessage', () {
    late SimpleKeyPair signingKeyPair;
    late String signingPublicKeyBase64;

    setUp(() async {
      signingKeyPair = await Ed25519().newKeyPair();
      final pub = await signingKeyPair.extractPublicKey();
      signingPublicKeyBase64 = base64Encode(pub.bytes);
    });

    test('a correctly signed IdentityMessage verifies', () async {
      final draft = IdentityMessage(
        identityPublicKeyBase64: 'aWRlbnRpdHk=',
        signingPublicKeyBase64: signingPublicKeyBase64,
        deviceId: 'device-a',
        signatureBase64: '',
      );
      final signature = await MessageSigning.sign(draft.signedBytes, signingKeyPair);
      final valid = await MessageSigning.verify(
        draft.signedBytes,
        signatureBase64: signature,
        signingPublicKeyBase64: signingPublicKeyBase64,
      );
      expect(valid, isTrue);
    });

    test('tampering with a signed field breaks verification', () async {
      final draft = IdentityMessage(
        identityPublicKeyBase64: 'aWRlbnRpdHk=',
        signingPublicKeyBase64: signingPublicKeyBase64,
        deviceId: 'device-a',
        signatureBase64: '',
      );
      final signature = await MessageSigning.sign(draft.signedBytes, signingKeyPair);

      final tampered = IdentityMessage(
        identityPublicKeyBase64: 'aWRlbnRpdHk=',
        signingPublicKeyBase64: signingPublicKeyBase64,
        deviceId: 'device-EVIL', // changed after signing
        signatureBase64: signature,
      );
      final valid = await MessageSigning.verify(
        tampered.signedBytes,
        signatureBase64: tampered.signatureBase64,
        signingPublicKeyBase64: signingPublicKeyBase64,
      );
      expect(valid, isFalse);
    });

    test('verifying with the wrong public key fails', () async {
      final otherKeyPair = await Ed25519().newKeyPair();
      final otherPub = await otherKeyPair.extractPublicKey();

      final draft = EphemeralKeyMessage(
        ephemeralPublicKeyBase64: 'ZXBoZW1lcmFs',
        signatureBase64: '',
      );
      final signature = await MessageSigning.sign(draft.signedBytes, signingKeyPair);

      final valid = await MessageSigning.verify(
        draft.signedBytes,
        signatureBase64: signature,
        signingPublicKeyBase64: base64Encode(otherPub.bytes),
      );
      expect(valid, isFalse);
    });

    test('garbage signature/key input fails closed, not with an exception', () async {
      final draft = SdpOfferMessage(sdp: 'v=0...', signatureBase64: '');
      final valid = await MessageSigning.verify(
        draft.signedBytes,
        signatureBase64: 'not valid base64!!!',
        signingPublicKeyBase64: 'also not valid base64!!!',
      );
      expect(valid, isFalse);
    });

    test('SignalingMessage round-trips through JSON', () {
      final original = IceCandidateMessage(
        candidate: 'candidate:1 1 UDP 2130706431 192.168.1.1 5000 typ host',
        sdpMid: '0',
        sdpMLineIndex: 0,
        signatureBase64: 'c2ln',
      );
      final parsed = SignalingMessage.tryParse(original.toJson());
      expect(parsed, isA<IceCandidateMessage>());
      final candidate = parsed as IceCandidateMessage;
      expect(candidate.candidate, original.candidate);
      expect(candidate.sdpMid, original.sdpMid);
      expect(candidate.sdpMLineIndex, original.sdpMLineIndex);
    });

    test('tryParse returns null for garbage input', () {
      expect(SignalingMessage.tryParse('not json'), isNull);
      expect(SignalingMessage.tryParse('{"type":"unknown_type"}'), isNull);
    });

    test('peer_joined/peer_left/invite_expired/data_channel_open round-trip', () {
      for (final msg in [
        const PeerJoinedMessage(),
        const PeerLeftMessage(),
        const InviteExpiredMessage(),
        const DataChannelOpenMessage(),
      ]) {
        final parsed = SignalingMessage.tryParse(msg.toJson());
        expect(parsed.runtimeType, msg.runtimeType);
      }
    });
  });
}

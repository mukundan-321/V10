import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Signs and verifies individual [SignalingMessage]s during pairing.
///
/// Replaces the old `PairingPayload` class, which used to bundle an
/// entire offer+ICE-candidates+keys blob into one signed JSON payload
/// meant for QR encoding. Now each message is signed independently as
/// it's sent over the live relay connection instead — see
/// docs/PAIRING_MIGRATION.md for why, and note the signing rationale
/// is unchanged from before: a signature proves a message wasn't
/// altered in transit (relevant now because the relay server, or a
/// MITM of it, could otherwise tamper with what it forwards) — it
/// does NOT prove who sent it, since an attacker generating their own
/// fresh keypair could sign their own substituted messages just as
/// validly. That gap is closed by fingerprint verification, not by
/// the signature itself, exactly as before.
class MessageSigning {
  static Future<String> sign(List<int> bytes, SimpleKeyPair signingKeyPair) async {
    final signature = await Ed25519().sign(bytes, keyPair: signingKeyPair);
    return base64Encode(signature.bytes);
  }

  static Future<bool> verify(
    List<int> bytes, {
    required String signatureBase64,
    required String signingPublicKeyBase64,
  }) async {
    try {
      final publicKey = SimplePublicKey(
        base64Decode(signingPublicKeyBase64),
        type: KeyPairType.ed25519,
      );
      final signature = Signature(base64Decode(signatureBase64), publicKey: publicKey);
      return await Ed25519().verify(bytes, signature: signature);
    } catch (_) {
      return false;
    }
  }
}

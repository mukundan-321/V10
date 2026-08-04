import 'dart:typed_data';

import 'session_cipher.dart';

import '../../features/pairing/data/crypto/session_crypto_service.dart'
    as crypto;

class AppSessionCipher implements SessionCipher {
  AppSessionCipher(this._cipher);

  final crypto.SessionCipher _cipher;

  @override
  Future<Uint8List> encrypt(Uint8List plaintext) async {
    final envelope = await _cipher.encrypt(plaintext);

    return Uint8List.fromList(envelope.ciphertext);
  }

  @override
  Future<Uint8List> decrypt(Uint8List ciphertext) async {
    throw UnimplementedError(
      'EncryptedTransport handles decryption. '
      'MediaReceiver should receive already decrypted bytes.',
    );
  }
}

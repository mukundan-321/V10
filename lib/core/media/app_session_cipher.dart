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
    final builder = BytesBuilder(copy: false);
    final counterBytes = ByteData(8)..setUint64(0, envelope.counter, Endian.big);
    builder.add(counterBytes.buffer.asUint8List());
    builder.add(Uint8List.fromList(envelope.nonce));
    builder.add(Uint8List.fromList(envelope.mac));
    builder.add(Uint8List.fromList(envelope.ciphertext));
    return builder.toBytes();
  }

  @override
  Future<Uint8List> decrypt(Uint8List data) async {
    if (data.length < 36) {
      throw const FormatException('Ciphertext payload too short for AEAD envelope');
    }
    final counter = ByteData.sublistView(data).getUint64(0, Endian.big);
    final nonce = data.sublist(8, 20);
    final mac = data.sublist(20, 36);
    final ciphertextBytes = data.sublist(36);

    final envelope = crypto.EncryptedEnvelope(
      counter: counter,
      ciphertext: ciphertextBytes,
      nonce: nonce,
      mac: mac,
    );

    final plaintext = await _cipher.decrypt(envelope);
    return Uint8List.fromList(plaintext);
  }
}

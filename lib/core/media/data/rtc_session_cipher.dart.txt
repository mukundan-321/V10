/// Adapts the app's existing paired-session cipher (X25519 key agreement,
/// ChaCha20-Poly1305 AEAD, forward-secret session keys rotated per
/// session) to the media transfer engine's [media.SessionCipher]
/// interface. Performs no cryptography itself — every call forwards
/// straight to the existing cipher's own encrypt/decrypt functions, passed
/// in at construction, so encryption stays single-sourced and this file
/// never needs to know the existing cipher's concrete class.
library rtc_session_cipher;

import 'dart:typed_data';

import '../../../core/media/session_cipher.dart' as media;

class RtcSessionCipher implements media.SessionCipher {
  const RtcSessionCipher({
    required Future<Uint8List> Function(Uint8List plaintext) encryptWith,
    required Future<Uint8List> Function(Uint8List ciphertext) decryptWith,
  })  : _encryptWith = encryptWith,
        _decryptWith = decryptWith;

  final Future<Uint8List> Function(Uint8List plaintext) _encryptWith;
  final Future<Uint8List> Function(Uint8List ciphertext) _decryptWith;

  @override
  Future<Uint8List> encrypt(Uint8List plaintext) => _encryptWith(plaintext);

  @override
  Future<Uint8List> decrypt(Uint8List ciphertext) => _decryptWith(ciphertext);
}

// -----------------------------------------------------------------------
// Wiring example (adjust method names to your existing SessionCipher):
//
//   final cipher = RtcSessionCipher(
//     encryptWith: existingSessionCipher.encrypt,
//     decryptWith: existingSessionCipher.decrypt,
//   );
//
// Passing the existing cipher's own methods as tear-offs means this
// adapter has zero knowledge of — and makes zero assumptions about — the
// existing cipher's class shape beyond "async Uint8List in, Uint8List
// out", so it compiles against whatever the real signatures are without
// edits here.

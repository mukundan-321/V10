/// Interface over the app's existing paired-session encryption. The media
/// transfer sender/receiver never construct or manage keys themselves —
/// they only call through this interface, so the real `SessionCipher`
/// (X25519/ChaCha20-Poly1305, forward-secret session keys rotated per
/// session) stays the single source of truth for crypto. Never bypassed,
/// never reimplemented here.
library session_cipher;

import 'dart:typed_data';

abstract class SessionCipher {
  Future<Uint8List> encrypt(Uint8List plaintext);
  Future<Uint8List> decrypt(Uint8List ciphertext);
}

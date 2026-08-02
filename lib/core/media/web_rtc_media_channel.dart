library web_rtc_media_channel;

import 'dart:async';
import 'dart:typed_data';

import 'package:two_person_app/core/media/media_channel.dart';
import 'package:two_person_app/features/pairing/data/transport/encrypted_transport.dart';

/// Adapter between EncryptedTransport and the media transfer layer.
///
/// Chat messages and media share the same encrypted WebRTC data channel.
/// This class simply exposes that transport through the MediaDataChannel
/// interface so ChunkedFileSender/Receiver remain completely independent
/// of flutter_webrtc.
class WebRtcMediaChannel implements MediaDataChannel {
  WebRtcMediaChannel(this._transport);

  final EncryptedTransport _transport;

  final StreamController<void> _bufferLowController =
      StreamController<void>.broadcast();

  int _lowThreshold = 0;

  @override
  bool get isOpen => true;

  @override
  int get bufferedAmount => 0;

  @override
  set bufferedAmountLowThreshold(int bytes) {
    _lowThreshold = bytes;
  }

  @override
  Stream<void> get onBufferedAmountLow =>
      _bufferLowController.stream;

  @override
  Stream<Uint8List> get incomingMessages =>
      _transport.decryptedIncoming.map(
        (e) => Uint8List.fromList(e),
      );

  @override
  Future<void> send(Uint8List data) async {
    await _transport.send(data);

    // Current transport exposes no bufferedAmount API.
    // Wake anyone waiting immediately.
    if (!_bufferLowController.isClosed) {
      _bufferLowController.add(null);
    }
  }

  Future<void> dispose() async {
    await _bufferLowController.close();
  }
}

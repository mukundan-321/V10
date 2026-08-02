/// Thin abstraction over `flutter_webrtc`'s `RTCDataChannel` so the media
/// transfer sender/receiver have no direct plugin dependency and can be
/// unit tested with a fake. One instance wraps the single paired
/// DataChannel and is shared by both the sender and receiver, since a
/// DataChannel is inherently bidirectional (chunks flow one way, acks and
/// cancel/error frames flow back).
library media_channel;

import 'dart:typed_data';

abstract class MediaDataChannel {
  bool get isOpen;

  int get bufferedAmount;
  set bufferedAmountLowThreshold(int bytes);

  /// Fires once buffered amount drops to/below the configured low
  /// threshold. Used for send-side backpressure so large files don't get
  /// queued into the channel faster than the peer's network can drain it.
  Stream<void> get onBufferedAmountLow;

  /// All binary messages arriving on this channel, in receipt order.
  Stream<Uint8List> get incomingMessages;

  Future<void> send(Uint8List data);
}

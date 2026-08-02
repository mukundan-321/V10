/// Adapts the app's existing, already-connected `RTCDataChannel` to the
/// media transfer engine's [MediaDataChannel] interface. Does not create,
/// negotiate, or configure the channel — it only wraps one that pairing/
/// connection setup has already established, so the existing WebRTC flow
/// is untouched.
library rtc_media_data_channel;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/media/media_channel.dart';

class RtcMediaDataChannel implements MediaDataChannel {
  RtcMediaDataChannel(this._channel) {
    _channel.onMessage = (RTCDataChannelMessage message) {
      if (message.isBinary && !_incomingController.isClosed) {
        _incomingController.add(message.binary);
      }
    };
    _channel.onBufferedAmountLow = (_) {
      if (!_lowController.isClosed) _lowController.add(null);
    };
  }

  final RTCDataChannel _channel;
  final StreamController<void> _lowController =
      StreamController<void>.broadcast();
  final StreamController<Uint8List> _incomingController =
      StreamController<Uint8List>.broadcast();

  @override
  bool get isOpen => _channel.state == RTCDataChannelState.RTCDataChannelOpen;

  @override
  int get bufferedAmount => _channel.bufferedAmount ?? 0;

  @override
  set bufferedAmountLowThreshold(int bytes) {
    _channel.bufferedAmountLowThreshold = bytes;
  }

  @override
  Stream<void> get onBufferedAmountLow => _lowController.stream;

  @override
  Stream<Uint8List> get incomingMessages => _incomingController.stream;

  @override
  Future<void> send(Uint8List data) {
    return _channel.send(RTCDataChannelMessage.fromBinary(data));
  }

  /// Call when the peer connection / chat screen is torn down. Does not
  /// close the underlying `RTCDataChannel` itself — that stays owned by
  /// whatever set up the WebRTC connection.
  Future<void> dispose() async {
    await _lowController.close();
    await _incomingController.close();
  }
}

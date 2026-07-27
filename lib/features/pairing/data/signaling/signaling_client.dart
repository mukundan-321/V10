import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'package:two_person_app/features/pairing/domain/entities/signaling_message.dart';

/// Connects to the signaling relay for exactly one invite, for exactly
/// one pairing attempt. A new [SignalingClient] (or at minimum a fresh
/// [connect] call) is used for every invite — this class does not
/// attempt to reuse a connection across different invites.
class SignalingClient {
  final String baseWsUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _rawSubscription;
  final _incomingController = StreamController<SignalingMessage>.broadcast();
  final _connectionClosedController = StreamController<void>.broadcast();

  SignalingClient({required this.baseWsUrl});

  Stream<SignalingMessage> get incoming => _incomingController.stream;

  /// Fires when the relay connection drops — for any reason (server
  /// closed it after successful pairing, the peer disconnected, a
  /// network error, the invite expired). Callers distinguish *why* by
  /// the SignalingMessage (if any) received just before this fires —
  /// e.g. a PeerLeftMessage or InviteExpiredMessage — vs. a silent
  /// drop with no such message, which is treated as an unexpected
  /// network failure.
  Stream<void> get connectionClosed => _connectionClosedController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect({
    required String inviteId,
    required bool isInitiator,
  }) async {
    final role = isInitiator ? 'initiator' : 'responder';
    final uri = Uri.parse('$baseWsUrl/ws/invites/$inviteId')
        .replace(queryParameters: {'role': role});

    final channel = WebSocketChannel.connect(uri);
    await channel.ready; // throws if the connection/handshake fails
    _channel = channel;

    _rawSubscription = channel.stream.listen(
      (data) {
  print("RAW WS: $data");

  final message = SignalingMessage.tryParse(data as String);

  print("PARSED: $message");

  if (message != null) {
    _incomingController.add(message);
  } else {
    print("FAILED TO PARSE MESSAGE");
  }
},
      onError: (_) {
        _channel = null;
        _connectionClosedController.add(null);
      },
    );
  }

  void send(SignalingMessage message) {
  print("SEND: ${message.toJson()}");
  _channel?.sink.add(message.toJson());
}

  Future<void> close() async {
    await _rawSubscription?.cancel();
    await _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
    await _incomingController.close();
    await _connectionClosedController.close();
  }
}

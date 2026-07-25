import 'dart:convert';
import 'dart:io';

import 'package:signaling_server/invite_store.dart';

/// Reference signaling relay. Run with:
///   dart run bin/server.dart [port]
///
/// Endpoints:
///   POST /invites                          -> {"inviteId": "...", "expiresAt": "..."}
///   GET  /ws/invites/<id>?role=initiator    -> WebSocket upgrade
///   GET  /ws/invites/<id>?role=responder    -> WebSocket upgrade
///
/// Everything sent over the WebSocket after the connection is
/// established is relayed byte-for-byte to the other party on the
/// same invite, without this server parsing or validating the
/// content beyond reading the `type` field to know whether it's a
/// relay message or the `data_channel_open` completion signal. See
/// PAIRING_MIGRATION.md for the full trust model.
Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args[0]) ?? 8080 : 8080;
  final store = InviteStore()..startExpirySweep();

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Signaling server listening on :$port');

  await for (final request in server) {
    _handleRequest(request, store);
  }
}

void _handleRequest(HttpRequest request, InviteStore store) async {
  try {
    final path = request.uri.path;

    if (request.method == 'POST' && path == '/invites') {
      await _handleCreateInvite(request, store);
      return;
    }

    if (path.startsWith('/ws/invites/')) {
      await _handleWebSocketUpgrade(request, store);
      return;
    }

    if (request.method == 'GET' && path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({'status': 'ok', 'activeInvites': store.activeInviteCount}));
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  } catch (e, st) {
    stderr.writeln('Unhandled error: $e\n$st');
    try {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    } catch (_) {
      // Response may already be closed/broken — nothing more to do.
    }
  }
}

Future<void> _handleCreateInvite(HttpRequest request, InviteStore store) async {
  final record = store.create();
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'inviteId': record.id,
      'expiresAt': record.expiresAt.toUtc().toIso8601String(),
    }));
  await request.response.close();
}

Future<void> _handleWebSocketUpgrade(HttpRequest request, InviteStore store) async {
  final segments = request.uri.pathSegments; // ['ws', 'invites', '<id>']
  if (segments.length != 3) {
    request.response.statusCode = HttpStatus.badRequest;
    await request.response.close();
    return;
  }
  final inviteId = segments[2].toUpperCase();
  final role = request.uri.queryParameters['role'];
  if (role != 'initiator' && role != 'responder') {
    request.response.statusCode = HttpStatus.badRequest;
    await request.response.close();
    return;
  }

  final record = store.get(inviteId);
  if (record == null) {
    request.response.statusCode = HttpStatus.gone; // 410: invite expired/unknown
    await request.response.close();
    return;
  }

  // An invite is exactly one pairing attempt: reject a second
  // initiator or a second responder trying to join the same invite.
  if (role == 'initiator' && record.initiatorSocket != null) {
    request.response.statusCode = HttpStatus.conflict;
    await request.response.close();
    return;
  }
  if (role == 'responder' && record.responderSocket != null) {
    request.response.statusCode = HttpStatus.conflict;
    await request.response.close();
    return;
  }

  final socket = await WebSocketTransformer.upgrade(request);

  if (role == 'initiator') {
    record.initiatorSocket = socket;
  } else {
    record.responderSocket = socket;
  }

  if (record.initiatorSocket != null && record.responderSocket != null) {
    record.status = InviteStatus.bothConnected;
    const peerJoined = '{"type":"peer_joined"}';
    record.initiatorSocket!.add(peerJoined);
    record.responderSocket!.add(peerJoined);
  }

  socket.listen(
    (message) => _relay(store, record, fromRole: role, message: message as String),
    onDone: () => _handleDisconnect(store, record, role),
    onError: (_) => _handleDisconnect(store, record, role),
  );
}

void _relay(
  InviteStore store,
  InviteRecord record, {
  required String fromRole,
  required String message,
}) {
  Map<String, dynamic>? map;
  try {
    map = jsonDecode(message) as Map<String, dynamic>;
  } catch (_) {
    return; // malformed — drop, don't relay garbage
  }

  if (map['type'] == 'data_channel_open') {
    if (fromRole == 'initiator') {
      record.initiatorDataChannelOpen = true;
    } else {
      record.responderDataChannelOpen = true;
    }
    if (record.bothSidesOpen) {
      // Pairing succeeded on both ends — this invite is now spent.
      store.completeAndRemove(record.id);
      record.initiatorSocket?.close();
      record.responderSocket?.close();
    }
    return;
  }

  final target = fromRole == 'initiator' ? record.responderSocket : record.initiatorSocket;
  target?.add(message);
}

void _handleDisconnect(InviteStore store, InviteRecord record, String role) {
  if (role == 'initiator') {
    record.initiatorSocket = null;
  } else {
    record.responderSocket = null;
  }
  // If pairing hadn't completed yet, tell the other side (if still
  // connected) that their peer is gone, rather than leaving them
  // waiting silently until the TTL sweep eventually cleans up.
  if (record.status != InviteStatus.completed) {
    const peerLeft = '{"type":"peer_left"}';
    record.initiatorSocket?.add(peerLeft);
    record.responderSocket?.add(peerLeft);
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math';

enum InviteStatus { waitingForPeer, bothConnected, completed, expired }

class InviteRecord {
  final String id;
  final DateTime createdAt;
  final DateTime expiresAt;
  InviteStatus status;
  WebSocket? initiatorSocket;
  WebSocket? responderSocket;

  /// Set true independently by each side once its own
  /// RTCPeerConnection reaches `connected` — once both are true, the
  /// invite is deleted. This is what makes an invite single-use even
  /// within the TTL window.
  bool initiatorDataChannelOpen = false;
  bool responderDataChannelOpen = false;

  InviteRecord({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
  }) : status = InviteStatus.waitingForPeer;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get bothSidesOpen => initiatorDataChannelOpen && responderDataChannelOpen;
}

/// Pure invite lifecycle logic, deliberately separated from the
/// HTTP/WebSocket server plumbing in server.dart so it can be
/// unit-tested (see the Flutter-side test suite's expectations for
/// this contract) without spinning up real sockets.
class InviteStore {
  static const _ttl = Duration(minutes: 10);
  static const _idAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I/L
  static const _idLength = 6;

  final Map<String, InviteRecord> _invites = {};
  final _random = Random.secure();
  Timer? _sweepTimer;

  /// Sweeps expired invites periodically, notifying and disconnecting
  /// any still-connected sockets rather than leaving them hanging.
  void startExpirySweep({Duration interval = const Duration(seconds: 30)}) {
    _sweepTimer?.cancel();
    _sweepTimer = Timer.periodic(interval, (_) => _sweepExpired());
  }

  void stopExpirySweep() => _sweepTimer?.cancel();

  InviteRecord create() {
    String id;
    do {
      id = _generateId();
    } while (_invites.containsKey(id));

    final now = DateTime.now();
    final record = InviteRecord(id: id, createdAt: now, expiresAt: now.add(_ttl));
    _invites[id] = record;
    return record;
  }

  InviteRecord? get(String id) {
    final record = _invites[id];
    if (record == null) return null;
    if (record.isExpired) {
      _expireAndRemove(record);
      return null;
    }
    return record;
  }

  void completeAndRemove(String id) {
    final record = _invites.remove(id);
    record?.status = InviteStatus.completed;
  }

  void remove(String id) => _invites.remove(id);

  int get activeInviteCount => _invites.length;

  String _generateId() => List.generate(
        _idLength,
        (_) => _idAlphabet[_random.nextInt(_idAlphabet.length)],
      ).join();

  void _sweepExpired() {
    final expired = _invites.values.where((r) => r.isExpired).toList();
    for (final record in expired) {
      _expireAndRemove(record);
    }
  }

  void _expireAndRemove(InviteRecord record) {
    record.status = InviteStatus.expired;
    _invites.remove(record.id);
  }
}

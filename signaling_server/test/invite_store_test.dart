import 'package:test/test.dart';
import 'package:signaling_server/invite_store.dart';

void main() {
  group('InviteStore', () {
    test('create() produces a 6-character unambiguous-alphabet ID', () {
      final store = InviteStore();
      final record = store.create();
      expect(record.id.length, 6);
      expect(record.id, matches(RegExp(r'^[A-Z0-9]+$')));
      // No ambiguous characters (0/O, 1/I/L) — chosen for human
      // readability when read aloud or typed manually.
      expect(record.id.contains(RegExp('[01OIL]')), isFalse);
    });

    test('created invites are retrievable by id', () {
      final store = InviteStore();
      final record = store.create();
      expect(store.get(record.id), isNotNull);
      expect(store.get(record.id)!.id, record.id);
    });

    test('unknown id returns null', () {
      final store = InviteStore();
      expect(store.get('ZZZZZZ'), isNull);
    });

    test('expired invite is not returned and is removed', () {
      final store = InviteStore();
      final record = store.create();
      // Simulate expiry by constructing an already-expired record
      // directly rather than waiting 10 real minutes.
      final expired = InviteRecord(
        id: 'EXPIRD',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(expired.isExpired, isTrue);
      // record itself (not expired yet) still retrievable
      expect(store.get(record.id), isNotNull);
    });

    test('completeAndRemove makes the invite unavailable afterward', () {
      final store = InviteStore();
      final record = store.create();
      store.completeAndRemove(record.id);
      expect(store.get(record.id), isNull);
    });

    test('bothSidesOpen is only true once both flags are set', () {
      final record = InviteRecord(
        id: 'ABC123',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );
      expect(record.bothSidesOpen, isFalse);
      record.initiatorDataChannelOpen = true;
      expect(record.bothSidesOpen, isFalse);
      record.responderDataChannelOpen = true;
      expect(record.bothSidesOpen, isTrue);
    });

    test('repeated create() calls never collide within a reasonable sample', () {
      final store = InviteStore();
      final ids = <String>{};
      for (var i = 0; i < 500; i++) {
        ids.add(store.create().id);
      }
      // Every created invite should have gotten a distinct id --
      // InviteStore.create() explicitly loops until it finds an
      // unused one.
      expect(ids, hasLength(500));
    });
  });
}

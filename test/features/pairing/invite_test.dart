import 'package:flutter_test/flutter_test.dart';
import 'package:two_person_app/features/pairing/domain/entities/invite.dart';

void main() {
  group('Invite.tryExtractInviteId', () {
    test('extracts from a twoperson:// deep link', () {
      expect(Invite.tryExtractInviteId('twoperson://pair/AB7K9P'), 'AB7K9P');
    });

    test('extracts from an https universal link', () {
      expect(
        Invite.tryExtractInviteId('https://pair.twoperson.app/AB7K9P'),
        'AB7K9P',
      );
    });

    test('extracts from a bare pasted code, normalizing case', () {
      expect(Invite.tryExtractInviteId('ab7k9p'), 'AB7K9P');
      expect(Invite.tryExtractInviteId('AB7K9P'), 'AB7K9P');
    });

    test('trims whitespace', () {
      expect(Invite.tryExtractInviteId('  AB7K9P  '), 'AB7K9P');
    });

    test('rejects garbage input', () {
      expect(Invite.tryExtractInviteId('not an invite'), isNull);
      expect(Invite.tryExtractInviteId(''), isNull);
      expect(Invite.tryExtractInviteId('https://evil.com/AB7K9P'), isNull);
    });

    test('deepLink getter produces a well-formed twoperson:// URI', () {
      final invite = Invite(id: 'AB7K9P', expiresAt: DateTime.now());
      expect(invite.deepLink, 'twoperson://pair/AB7K9P');
      // Round-trips back through the same extractor.
      expect(Invite.tryExtractInviteId(invite.deepLink), 'AB7K9P');
    });
  });
}

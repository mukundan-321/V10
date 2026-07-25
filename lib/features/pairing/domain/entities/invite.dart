/// What actually gets turned into a QR code / share link now: just
/// this. No keys, no SDP, no signature — those all travel over the
/// signaling relay after the invite is opened, not inside the invite
/// itself. This is the entire fix for the old oversized-QR problem:
/// there is no longer anything variable-sized (ICE candidate count,
/// SDP length) in what has to be printed as a QR code.
class Invite {
  final String id;
  final DateTime expiresAt;

  const Invite({required this.id, required this.expiresAt});

  /// Deep link scheme. A production deployment would also serve
  /// `https://pair.twoperson.app/<id>` as a Universal Link /
  /// App Link (see PAIRING_MIGRATION.md for what that additionally
  /// requires — domain verification files this app can't deploy on
  /// your behalf) but the custom scheme works standalone with no
  /// server-hosted verification file needed, so it's the default.
  String get deepLink => 'twoperson://pair/$id';

  static const _idPattern = r'^[A-Z0-9]{6,10}$';

  /// Parses an invite ID out of a deep link, a bare ID (from manual
  /// paste), or a universal-link-style https URL — whichever form the
  /// user happened to scan or paste.
  static String? tryExtractInviteId(String raw) {
    final trimmed = raw.trim();

    final deepLinkMatch = RegExp(r'^twoperson://pair/([A-Z0-9]{6,10})$')
        .firstMatch(trimmed);
    if (deepLinkMatch != null) return deepLinkMatch.group(1);

    final httpsMatch =
        RegExp(r'^https://pair\.twoperson\.app/([A-Z0-9]{6,10})$')
            .firstMatch(trimmed);
    if (httpsMatch != null) return httpsMatch.group(1);

    if (RegExp(_idPattern).hasMatch(trimmed.toUpperCase())) {
      return trimmed.toUpperCase();
    }

    return null;
  }
}

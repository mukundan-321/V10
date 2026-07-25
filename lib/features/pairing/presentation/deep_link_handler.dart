import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'package:two_person_app/features/pairing/domain/entities/invite.dart';

/// Listens for `twoperson://pair/<id>` (and, if you've deployed the
/// https:// Universal/App Link form -- see
/// signaling_server/README.md -- `https://pair.twoperson.app/<id>`
/// too) being opened, whether the app was already running or launched
/// cold by tapping the link. Extracts just the invite ID and hands it
/// to [onInviteLinkOpened] -- deliberately knows nothing about the
/// pairing flow UI or repository itself, just URI parsing and event
/// plumbing.
class DeepLinkHandler {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  final void Function(String inviteId) onInviteLinkOpened;

  DeepLinkHandler({required this.onInviteLinkOpened});

  Future<void> start() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handle(initialUri);
    } catch (e) {
      debugPrint('DeepLinkHandler: failed to read initial link: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (e) => debugPrint('DeepLinkHandler: link stream error: $e'),
    );
  }

  void _handle(Uri uri) {
    final inviteId = Invite.tryExtractInviteId(uri.toString());
    if (inviteId != null) onInviteLinkOpened(inviteId);
  }

  void dispose() {
    _subscription?.cancel();
  }
}

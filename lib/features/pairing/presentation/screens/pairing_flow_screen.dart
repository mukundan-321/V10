import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:two_person_app/core/utils/result.dart';
import 'package:two_person_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:two_person_app/features/pairing/domain/entities/device_identity.dart';
import 'package:two_person_app/features/pairing/domain/entities/invite.dart';
import 'package:two_person_app/features/pairing/domain/entities/pairing_stage.dart';
import 'package:two_person_app/features/pairing/presentation/providers/pairing_providers.dart';
import 'package:two_person_app/features/pairing/presentation/widgets/qr_scanner_screen.dart';

enum _UiStage { choosing, showingInvite, joiningInput, negotiating, verifyFingerprint }

/// [isReconnect] distinguishes first-time pairing (full flow, ending
/// in mandatory fingerprint verification) from reconnecting to an
/// already-trusted peer (same relay handshake, but skips
/// re-verifying a fingerprint that hasn't changed).
///
/// [initialInviteId] is set when this screen is reached by opening a
/// `twoperson://pair/<id>` deep link directly -- skips the "choosing"
/// and "joining input" stages and goes straight to joining.
class PairingFlowScreen extends ConsumerStatefulWidget {
  final bool isReconnect;
  final String? initialInviteId;

  const PairingFlowScreen({super.key, required this.isReconnect, this.initialInviteId});

  @override
  ConsumerState<PairingFlowScreen> createState() => _PairingFlowScreenState();
}

class _PairingFlowScreenState extends ConsumerState<PairingFlowScreen> {
  _UiStage _stage = _UiStage.choosing;
  Invite? _invite;
  String? _errorMessage;
  bool _busy = false;
  DeviceIdentity? _peerIdentity;
  StreamSubscription<PairingStage>? _stageSub;
  final _pasteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialInviteId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _join(widget.initialInviteId!));
    }
  }

  @override
  void dispose() {
    _stageSub?.cancel();
    _pasteController.dispose();
    super.dispose();
  }

  void _listenToPairingStage() {
    _stageSub?.cancel();
    _stageSub = ref.read(pairingRepositoryProvider).pairingStage.listen((stage) async {
      if (!mounted) return;
      switch (stage) {
        case PairingStage.idle:
        case PairingStage.waitingForPeer:
          break;
        case PairingStage.negotiating:
          setState(() => _stage = _UiStage.negotiating);
        case PairingStage.connected:
          await _onConnected();
        case PairingStage.peerLeft:
          setState(() {
            _stage = _UiStage.choosing;
            _errorMessage = 'Your person disconnected before pairing finished.';
          });
        case PairingStage.expired:
          setState(() {
            _stage = _UiStage.choosing;
            _errorMessage = 'That invite expired. Start a new one.';
          });
        case PairingStage.failed:
          setState(() {
            _stage = _UiStage.choosing;
            _errorMessage = 'Connection failed. Try again.';
          });
      }
    });
  }

  Future<void> _onConnected() async {
    final peer = await ref.read(pairingRepositoryProvider).peerIdentity;
    if (!mounted) return;
    setState(() => _peerIdentity = peer);

    if (widget.isReconnect || peer?.fingerprintVerified == true) {
      _goToChat();
    } else {
      setState(() => _stage = _UiStage.verifyFingerprint);
    }
  }

  void _goToChat() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  Future<void> _startCreateInvite() async {
    setState(() { _busy = true; _errorMessage = null; });
    _listenToPairingStage();
    final result = await ref.read(pairingRepositoryProvider).createInvite();
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok<Invite>(value: final invite):
          _invite = invite;
          _stage = _UiStage.showingInvite;
        case Err<Invite>(failure: final f):
          _errorMessage = f.message;
      }
    });
  }

  Future<void> _join(String inviteId) async {
    setState(() { _busy = true; _errorMessage = null; });
    _listenToPairingStage();
    final result = await ref.read(pairingRepositoryProvider).joinInvite(inviteId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.isErr) {
        _errorMessage = result.when(ok: (_) => '', err: (f) => f.message);
      } else {
        _stage = _UiStage.negotiating;
      }
    });
  }

  Future<void> _cancel() async {
    await ref.read(pairingRepositoryProvider).cancelPairing();
    await _stageSub?.cancel();
    if (!mounted) return;
    setState(() { _stage = _UiStage.choosing; _invite = null; });
  }

  Future<void> _scanAndJoin() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (scanned == null) return;
    final inviteId = Invite.tryExtractInviteId(scanned);
    if (inviteId == null) {
      setState(() => _errorMessage = 'That doesn\'t look like a valid invite.');
      return;
    }
    await _join(inviteId);
  }

  Future<void> _confirmFingerprint() async {
    setState(() => _busy = true);
    await ref.read(pairingRepositoryProvider).confirmFingerprintVerified();
    if (!mounted) return;
    setState(() => _busy = false);
    _goToChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isReconnect ? 'Reconnect' : 'Pairing')),
      body: Padding(padding: const EdgeInsets.all(24), child: _buildStageContent()),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case _UiStage.choosing:
        return _ChoosingView(
          isReconnect: widget.isReconnect,
          busy: _busy,
          error: _errorMessage,
          onCreate: _startCreateInvite,
          onJoin: () => setState(() => _stage = _UiStage.joiningInput),
        );
      case _UiStage.joiningInput:
        return _JoinInputView(
          controller: _pasteController,
          busy: _busy,
          error: _errorMessage,
          onScan: _scanAndJoin,
          onSubmitPasted: () {
            final inviteId = Invite.tryExtractInviteId(_pasteController.text);
            if (inviteId == null) {
              setState(() => _errorMessage = 'That doesn\'t look like a valid invite.');
              return;
            }
            _join(inviteId);
          },
        );
      case _UiStage.showingInvite:
        return _ShowingInviteView(invite: _invite!, onCancel: _cancel);
      case _UiStage.negotiating:
        return const _NegotiatingView();
      case _UiStage.verifyFingerprint:
        return _FingerprintVerifyView(
          fingerprint: _peerIdentity?.fingerprint ?? '',
          busy: _busy,
          onConfirm: _confirmFingerprint,
        );
    }
  }
}

class _ChoosingView extends StatelessWidget {
  final bool isReconnect;
  final bool busy;
  final String? error;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _ChoosingView({
    required this.isReconnect,
    required this.busy,
    required this.error,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isReconnect
              ? 'You\'re already paired. Reconnect to start this session.'
              : 'This app connects exactly two people, directly.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        if (error != null) ...[
          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 16),
        ],
        FilledButton(
          onPressed: busy ? null : onCreate,
          child: Text(isReconnect ? 'Start session' : 'Start pairing'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: busy ? null : onJoin,
          child: Text(isReconnect ? 'Join their session' : 'Join with an invite'),
        ),
        if (busy)
          const Padding(padding: EdgeInsets.only(top: 24), child: CircularProgressIndicator()),
      ],
    );
  }
}

class _JoinInputView extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onScan;
  final VoidCallback onSubmitPasted;

  const _JoinInputView({
    required this.controller,
    required this.busy,
    required this.error,
    required this.onScan,
    required this.onSubmitPasted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Paste or scan the invite', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : onScan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR code'),
        ),
        const SizedBox(height: 16),
        const Text('— or paste the invite link/code —'),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'twoperson://pair/AB7K9P',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: busy ? null : onSubmitPasted, child: const Text('Join')),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        if (busy)
          const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _ShowingInviteView extends StatelessWidget {
  final Invite invite;
  final VoidCallback onCancel;

  const _ShowingInviteView({required this.invite, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: QrImageView(data: invite.deepLink, size: 200),
          ),
        ),
        const SizedBox(height: 16),
        SelectableText(invite.deepLink, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: invite.deepLink));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied — share it any way you like.')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy invite link'),
        ),
        const SizedBox(height: 24),
        const Text('Waiting for your person to open it…'),
        const SizedBox(height: 16),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
      ],
    );
  }
}

class _NegotiatingView extends StatelessWidget {
  const _NegotiatingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting…'),
        ],
      ),
    );
  }
}

class _FingerprintVerifyView extends StatelessWidget {
  final String fingerprint;
  final bool busy;
  final VoidCallback onConfirm;

  const _FingerprintVerifyView({
    required this.fingerprint,
    required this.busy,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Read this number out loud together, or compare it side by side. '
          'This is what actually confirms you\'re connected to the right person.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            fingerprint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 1.2),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : onConfirm,
          child: const Text('It matches — confirm'),
        ),
        if (busy)
          const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

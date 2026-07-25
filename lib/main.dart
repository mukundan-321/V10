import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:two_person_app/core/di/injector.dart';
import 'package:two_person_app/core/theme/app_theme.dart';
import 'package:two_person_app/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:two_person_app/features/pairing/presentation/deep_link_handler.dart';
import 'package:two_person_app/features/pairing/presentation/screens/pairing_flow_screen.dart';
import 'dart:io';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  
WidgetsFlutterBinding.ensureInitialized();

if (Platform.isAndroid) {
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();

  open.overrideFor(
    OperatingSystem.android,
    openCipherOnAndroid,
  );
}

  runApp(ProviderScope(child: TwoPersonApp(startupError: startupError)));
}

class TwoPersonApp extends StatefulWidget {
  final String? startupError;
  const TwoPersonApp({super.key, this.startupError});

  @override
  State<TwoPersonApp> createState() => _TwoPersonAppState();
}

class _TwoPersonAppState extends State<TwoPersonApp> {
  DeepLinkHandler? _deepLinkHandler;

  @override
  void initState() {
    super.initState();
    if (widget.startupError == null) {
      // Deep links only make sense once DI succeeded -- there's
      // nothing to join a pairing session with otherwise.
      _deepLinkHandler = DeepLinkHandler(onInviteLinkOpened: _handleInviteLink);
      _deepLinkHandler!.start();
    }
  }

  @override
  void dispose() {
    _deepLinkHandler?.dispose();
    super.dispose();
  }

  void _handleInviteLink(String inviteId) {
    // Pushes on top of whatever's currently showing -- works whether
    // the app was already open somewhere else or just cold-started
    // directly into this via the link (in which case it lands on top
    // of the initial pairing/chat route almost immediately).
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PairingFlowScreen(isReconnect: false, initialInviteId: inviteId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Us', // deliberately no product-y branding -- this is a
      // private space for two people, not a product with a marketing name.
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: widget.startupError != null
          ? _StartupErrorScreen(message: widget.startupError!)
          : const _RootGate(),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final String message;
  const _StartupErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text('Something went wrong starting up.', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every app launch starts here -- including on a device that's
/// already paired, because reconnecting still means a fresh signaling-
/// relay handshake (the relay only exists during pairing itself, not
/// as an always-on presence service). "Already paired" (long-term
/// trust) and "connected right now" (this session's live link) are
/// different things; [PairingFlowScreen] handles both, just with a
/// lighter-weight path when [isPaired] is already true.
class _RootGate extends StatefulWidget {
  const _RootGate({super.key});

  @override
  State<_RootGate> createState() => _RootGateState();
}
class _RootGateState extends State<_RootGate> {
  late final Future<bool> _isPairedFuture = sl<PairingRepository>()
      .isPaired
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Startup timed out after 10 seconds.',
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isPairedFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return PairingFlowScreen(
          isReconnect: snapshot.data ?? false,
        );
      },
    );
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:two_person_app/core/di/injector.dart';
import 'package:two_person_app/features/pairing/domain/entities/device_identity.dart';
import 'package:two_person_app/features/pairing/domain/entities/pairing_stage.dart';
import 'package:two_person_app/features/pairing/domain/repositories/pairing_repository.dart';

final pairingRepositoryProvider = Provider<PairingRepository>(
  (ref) => sl<PairingRepository>(),
);

/// Whether this device has ever completed pairing -- persists across
/// restarts (backed by the DB), unlike [connectionStatusProvider]
/// which reflects the current session's live connection only.
final isPairedProvider = FutureProvider<bool>(
  (ref) => ref.watch(pairingRepositoryProvider).isPaired,
);

/// True only while the encrypted WebRTC data channel for *this app
/// session* is actually open. Every app relaunch starts this at
/// false again -- the signaling relay only exists during pairing
/// itself, not as an always-on presence service.
final connectionStatusProvider = StreamProvider<bool>(
  (ref) => ref.watch(pairingRepositoryProvider).connectionStatus,
);

/// Fine-grained pairing-attempt progress (waiting for peer,
/// negotiating, connected, peer left, expired, failed) -- what the
/// pairing flow screen actually watches.
final pairingStageProvider = StreamProvider<PairingStage>(
  (ref) => ref.watch(pairingRepositoryProvider).pairingStage,
);

final peerIdentityProvider = FutureProvider<DeviceIdentity?>(
  (ref) => ref.watch(pairingRepositoryProvider).peerIdentity,
);

/// Riverpod wiring for the media transfer stack. The four providers at the
/// top have no meaningful default — they must be overridden with real
/// implementations (see the integration notes in chunked_file_sender.dart
/// and chunked_file_receiver.dart) once pairing/WebRTC/Drift are
/// available, typically in a `ProviderScope(overrides: [...])` created
/// right after a successful pairing/reconnect. Everything below them
/// (`chunkedFileSenderProvider` onward) is complete and requires no
/// further changes.
library media_transfer_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_channel.dart';
import '../../../core/media/session_cipher.dart';
import 'chunked_file_receiver.dart';
import 'chunked_file_sender.dart';
import 'media_file_storage.dart';
import 'media_repository.dart';

/// Concrete app-local media storage (app documents `media/received` and
/// `media/sent` folders). Async because resolving the documents directory
/// is async; await this once at startup/pairing time and reuse the same
/// instance for both `mediaFileStorageProvider`'s override below and the
/// `ChatMediaCoordinator` your `ChatRepositoryImpl` constructs (it needs
/// the concrete `AppMediaFileStorage` for `storeSentFile`, not just the
/// narrower `MediaFileStorage` interface the receiver uses).
final appMediaFileStorageProvider =
    FutureProvider<AppMediaFileStorage>((ref) => AppMediaFileStorage.create());

/// The live paired DataChannel for the current session. Override with the
/// real `RtcMediaDataChannel` wrapping the app's `RTCDataChannel` once the
/// WebRTC connection is established.
final mediaDataChannelProvider = Provider<MediaDataChannel>((ref) {
  throw UnimplementedError(
    'mediaDataChannelProvider must be overridden with the live paired '
    'DataChannel once the WebRTC connection is established.',
  );
});

/// The app's existing paired-session cipher, adapted to [SessionCipher].
/// Override with the real `AppSessionCipher` once key exchange has
/// completed.
final sessionCipherProvider = Provider<SessionCipher>((ref) {
  throw UnimplementedError(
    "sessionCipherProvider must be overridden with the paired session's "
    'SessionCipher.',
  );
});

/// Where incoming media gets written. Override with `AppMediaFileStorage`
/// backed by the app's media directory.
final mediaFileStorageProvider = Provider<MediaFileStorage>((ref) {
  throw UnimplementedError(
    'mediaFileStorageProvider must be overridden with an '
    'AppMediaFileStorage backed by the app media directory.',
  );
});

/// Outgoing-transfer persistence. Override with a `MediaMetadata`-Drift
/// backed implementation.
final mediaTransferProgressStoreProvider =
    Provider<MediaTransferProgressStore>((ref) {
  throw UnimplementedError(
    'mediaTransferProgressStoreProvider must be overridden with a '
    'MediaMetadata-Drift-backed implementation.',
  );
});

/// Incoming-transfer persistence. Override with a `MediaMetadata`-Drift
/// backed implementation.
final mediaReceiveProgressStoreProvider =
    Provider<MediaReceiveProgressStore>((ref) {
  throw UnimplementedError(
    'mediaReceiveProgressStoreProvider must be overridden with a '
    'MediaMetadata-Drift-backed implementation.',
  );
});

final chunkedFileSenderProvider = Provider<ChunkedFileSender>((ref) {
  return ChunkedFileSender(
    channel: ref.watch(mediaDataChannelProvider),
    cipher: ref.watch(sessionCipherProvider),
    progressStore: ref.watch(mediaTransferProgressStoreProvider),
  );
});

final chunkedFileReceiverProvider = Provider<ChunkedFileReceiver>((ref) {
  final receiver = ChunkedFileReceiver(
    channel: ref.watch(mediaDataChannelProvider),
    cipher: ref.watch(sessionCipherProvider),
    storage: ref.watch(mediaFileStorageProvider),
    progressStore: ref.watch(mediaReceiveProgressStoreProvider),
  );
  ref.onDispose(receiver.dispose);
  return receiver;
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final repository = MediaRepository(
    sender: ref.watch(chunkedFileSenderProvider),
    receiver: ref.watch(chunkedFileReceiverProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// All outgoing-transfer progress events, for media bubbles to filter by
/// `transferId`/`messageId`.
final mediaSendingProgressProvider =
    StreamProvider.autoDispose<MediaTransferProgress>((ref) {
  return ref.watch(mediaRepositoryProvider).sendingProgress;
});

/// All incoming-transfer progress events, for media bubbles to filter by
/// `transferId`/`messageId`.
final mediaReceivingProgressProvider =
    StreamProvider.autoDispose<MediaReceiveProgress>((ref) {
  return ref.watch(mediaRepositoryProvider).receivingProgress;
});

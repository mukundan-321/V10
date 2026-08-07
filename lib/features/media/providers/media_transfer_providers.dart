library media_transfer_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:two_person_app/core/di/injector.dart';
import 'package:two_person_app/features/chat/data/media_session_manager.dart';
import 'package:two_person_app/features/media/data/chunked_file_receiver.dart';
import 'package:two_person_app/features/media/data/chunked_file_sender.dart';
import 'package:two_person_app/features/media/data/media_repository.dart';

final mediaSessionManagerProvider = Provider<MediaSessionManager>((ref) {
  return sl<MediaSessionManager>();
});

final mediaRepositoryProvider = Provider<MediaRepository?>((ref) {
  final sessionManager = ref.watch(mediaSessionManagerProvider);
  return sessionManager.repository;
});

final mediaSendingProgressProvider =
    StreamProvider.autoDispose<MediaTransferProgress>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.sendingProgress;
});

final mediaReceivingProgressProvider =
    StreamProvider.autoDispose<MediaReceiveProgress>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.receivingProgress;
});

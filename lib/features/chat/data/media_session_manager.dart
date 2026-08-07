import 'dart:async';

import 'package:two_person_app/core/media/app_session_cipher.dart';
import 'package:two_person_app/features/media/data/chunked_file_receiver.dart';
import 'package:two_person_app/features/media/data/chunked_file_sender.dart';
import 'package:two_person_app/features/media/data/media_file_storage.dart';
import 'package:two_person_app/features/media/data/media_repository.dart';
import 'package:two_person_app/features/media/data/rtc_media_data_channel.dart';
import 'package:two_person_app/features/media/data/media_transfer_progress_store.dart';
import 'package:two_person_app/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:two_person_app/features/chat/data/chat_repository_impl.dart';

class MediaSessionManager {
  final PairingRepository pairingRepository;
  final AppMediaFileStorage storage;
  final DriftMediaTransferProgressStore progressStore;

  MediaRepository? _repository;
  RtcMediaDataChannel? _dataChannelAdapter;
  StreamSubscription<bool>? _connectionSub;
  ChatRepositoryImpl? _chatRepository;

  MediaSessionManager({
    required this.pairingRepository,
    required this.storage,
    required this.progressStore,
  });

  MediaRepository? get repository => _repository;
  bool get isReady => _repository != null;

  void initialize(ChatRepositoryImpl chatRepository) {
    _chatRepository = chatRepository;
    _connectionSub?.cancel();
    _connectionSub = pairingRepository.connectionStatus.listen(_onConnectionStatusChanged);
  }

  void _onConnectionStatusChanged(bool connected) {
    if (connected) {
      _setupMediaSession();
    } else {
      clear();
    }
  }

  void _setupMediaSession() {
    final rawChannel = pairingRepository.rtcDataChannel;
    final connectionMgr = pairingRepository.connectionManager;
    final rawCipher = pairingRepository.sessionCipher;

    if (rawChannel == null || rawCipher == null || connectionMgr == null) {
      return;
    }

    _cleanupCurrentSession();

    _dataChannelAdapter = RtcMediaDataChannel(rawChannel, connectionMgr.incomingMessages);

    final cipher = AppSessionCipher(rawCipher);

    final sender = ChunkedFileSender(
      channel: _dataChannelAdapter!,
      cipher: cipher,
      progressStore: progressStore,
    );

    final receiver = ChunkedFileReceiver(
      channel: _dataChannelAdapter!,
      cipher: cipher,
      storage: storage,
      progressStore: progressStore,
    );

    _repository = MediaRepository(
      sender: sender,
      receiver: receiver,
    );

    _chatRepository?.attachMediaRepository(_repository!);
  }

  void _cleanupCurrentSession() {
    _repository?.dispose();
    _repository = null;
    _dataChannelAdapter?.dispose();
    _dataChannelAdapter = null;
  }

  Future<void> clear() async {
    _cleanupCurrentSession();
    _chatRepository?.detachMediaRepository();
  }

  Future<void> dispose() async {
    await _connectionSub?.cancel();
    await clear();
  }
}

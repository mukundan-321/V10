/// Connects [MediaRepository] to chat message persistence without this
/// module needing to know `ChatRepositoryImpl`'s concrete shape.
///
/// Your existing `ChatRepositoryImpl` composes one `ChatMediaCoordinator`
/// and delegates the five send methods to it:
///
///   class ChatRepositoryImpl implements ChatRepository {
///     ChatRepositoryImpl(..., MediaRepository mediaRepository, AppMediaFileStorage storage)
///         : _media = ChatMediaCoordinator(
///             mediaRepository: mediaRepository,
///             storage: storage,
///             createPendingMessage: _insertPendingMediaMessage,
///             updateMessageMedia: _updateMessageMediaFields,
///           );
///     final ChatMediaCoordinator _media;
///
///     @override
///     Future<String> sendImage(File file, {required int width, required int height}) =>
///         _media.sendImage(file: file, width: width, height: height);
///     // sendVideo/sendDocument/sendAudio/sendVoiceMessage forward the same way.
///   }
///
/// Incoming transfers need **no per-message wiring** — the moment a
/// `ChatMediaCoordinator` is constructed it starts listening to
/// `mediaRepository.receivingProgress`, and creates the chat message row
/// itself the first time it sees a given `messageId` (using the filename/
/// mimeType/kind the sender attached to the transfer's init frame), then
/// keeps that row's `MediaAttachment` updated as bytes arrive.
///
/// [createPendingMessage] and [updateMessageMedia] are the only two hooks
/// into your existing chat message persistence/stream; everything else —
/// talking to the transfer engine, building/updating `MediaAttachment` —
/// is handled here.
library chat_media_coordinator;

import 'dart:async';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../data/chunked_file_receiver.dart'
    show MediaReceiveProgress, MediaReceiveState;
import '../data/chunked_file_sender.dart'
    show MediaTransferProgress, MediaTransferState;
import '../data/media_file_storage.dart';
import '../data/media_repository.dart';
import '../domain/chat_message_media.dart';

/// Creates the local chat message row for a media attachment. Called once
/// per message: right before an outgoing send starts, and the first time
/// an incoming transfer's `messageId` is seen.
typedef CreatePendingMessage = Future<void> Function({
  required String messageId,
  required MediaAttachment media,
  required bool isOutgoing,
});

/// Applies an updated status/progress to the existing chat message
/// identified by [messageId]. Called repeatedly as a transfer moves.
typedef UpdateMessageMedia = Future<void> Function({
  required String messageId,
  required MediaTransferStatus status,
  required int bytesTransferred,
  String? localPath,
  String? errorMessage,
});

class ChatMediaCoordinator {
  ChatMediaCoordinator({
    required MediaRepository mediaRepository,
    required AppMediaFileStorage storage,
    required CreatePendingMessage createPendingMessage,
    required UpdateMessageMedia updateMessageMedia,
    Uuid? uuid,
  })  : _media = mediaRepository,
        _storage = storage,
        _createPendingMessage = createPendingMessage,
        _updateMessageMedia = updateMessageMedia,
        _uuid = uuid ?? const Uuid() {
    _sendSub = _media.sendingProgress.listen(_onSendProgress);
    _receiveSub = _media.receivingProgress.listen(_onReceiveProgress);
  }

  final MediaRepository _media;
  final AppMediaFileStorage _storage;
  final CreatePendingMessage _createPendingMessage;
  final UpdateMessageMedia _updateMessageMedia;
  final Uuid _uuid;

  late final StreamSubscription<MediaTransferProgress> _sendSub;
  late final StreamSubscription<MediaReceiveProgress> _receiveSub;

  /// transferId -> messageId, so an outgoing progress event (keyed by
  /// transferId) can be applied to the right chat message. Populated
  /// *synchronously* right after each `_media.sendX(...)` call, before any
  /// `await`, so the first progress event — which can only fire once this
  /// method yields control back to the event loop — can never arrive
  /// before the mapping exists.
  final Map<String, String> _outgoingTransferToMessage = {};

  /// messageIds this coordinator has already created a row for, so a
  /// second progress event for the same incoming transfer updates rather
  /// than re-creates it.
  final Set<String> _knownIncomingMessages = {};

  Future<String> sendImage({
    required File file,
    required int width,
    required int height,
  }) async {
    final messageId = _uuid.v4();
    final storedFile =
        await _storage.storeSentFile(original: file, messageId: messageId);
    final fileSize = await storedFile.length();

    final handle = _media.sendImage(
      messageId: messageId,
      file: storedFile,
      width: width,
      height: height,
    );
    _outgoingTransferToMessage[handle.transferId] = messageId;

    await _createPendingMessage(
      messageId: messageId,
      isOutgoing: true,
      media: MediaAttachment(
        type: ChatMediaType.image,
        transferId: handle.transferId,
        filename: storedFile.uri.pathSegments.last,
        mimeType: 'image/jpeg',
        fileSize: fileSize,
        status: MediaTransferStatus.sending,
        localPath: storedFile.path,
        width: width,
        height: height,
      ),
    );
    return messageId;
  }

  Future<String> sendVideo({
    required File file,
    required int width,
    required int height,
    required int durationMs,
    File? thumbnail,
  }) async {
    final messageId = _uuid.v4();
    final storedFile =
        await _storage.storeSentFile(original: file, messageId: messageId);
    final fileSize = await storedFile.length();

    final handle = _media.sendVideo(
      messageId: messageId,
      file: storedFile,
      width: width,
      height: height,
      durationMs: durationMs,
      thumbnail: thumbnail,
    );
    _outgoingTransferToMessage[handle.transferId] = messageId;

    await _createPendingMessage(
      messageId: messageId,
      isOutgoing: true,
      media: MediaAttachment(
        type: ChatMediaType.video,
        transferId: handle.transferId,
        filename: storedFile.uri.pathSegments.last,
        mimeType: 'video/mp4',
        fileSize: fileSize,
        status: MediaTransferStatus.sending,
        localPath: storedFile.path,
        thumbnailPath: thumbnail?.path,
        width: width,
        height: height,
        durationMs: durationMs,
      ),
    );
    return messageId;
  }

  /// Alias for [sendVoiceMessage] — both exist because chat UIs sometimes
  /// distinguish "sent an audio file" (via Document/Gallery) from "recorded
  /// a voice note", but they travel through the same transfer path.
  Future<String> sendAudio({required File file, required int durationMs}) =>
      sendVoiceMessage(file: file, durationMs: durationMs);

  Future<String> sendVoiceMessage({
    required File file,
    required int durationMs,
  }) async {
    final messageId = _uuid.v4();
    final storedFile =
        await _storage.storeSentFile(original: file, messageId: messageId);
    final fileSize = await storedFile.length();

    final handle = _media.sendVoiceNote(
      messageId: messageId,
      file: storedFile,
      durationMs: durationMs,
    );
    _outgoingTransferToMessage[handle.transferId] = messageId;

    await _createPendingMessage(
      messageId: messageId,
      isOutgoing: true,
      media: MediaAttachment(
        type: ChatMediaType.audio,
        transferId: handle.transferId,
        filename: storedFile.uri.pathSegments.last,
        mimeType: 'audio/m4a',
        fileSize: fileSize,
        status: MediaTransferStatus.sending,
        localPath: storedFile.path,
        durationMs: durationMs,
      ),
    );
    return messageId;
  }

  Future<String> sendDocument({
    required File file,
    required String filename,
  }) async {
    final messageId = _uuid.v4();
    final storedFile =
        await _storage.storeSentFile(original: file, messageId: messageId);
    final fileSize = await storedFile.length();

    final handle = _media.sendDocument(
      messageId: messageId,
      file: storedFile,
      filename: filename,
    );
    _outgoingTransferToMessage[handle.transferId] = messageId;

    await _createPendingMessage(
      messageId: messageId,
      isOutgoing: true,
      media: MediaAttachment(
        type: ChatMediaType.document,
        transferId: handle.transferId,
        filename: filename,
        mimeType: 'application/octet-stream',
        fileSize: fileSize,
        status: MediaTransferStatus.sending,
        localPath: storedFile.path,
      ),
    );
    return messageId;
  }

  void _onSendProgress(MediaTransferProgress progress) {
    final messageId = _outgoingTransferToMessage[progress.transferId];
    if (messageId == null) return;

    final status = _outgoingStatus(progress.state);

    unawaited(_updateMessageMedia(
      messageId: messageId,
      status: status,
      bytesTransferred: progress.bytesSent,
      errorMessage: progress.errorMessage,
    ));

    if (status != MediaTransferStatus.sending) {
      _outgoingTransferToMessage.remove(progress.transferId);
    }
  }

  void _onReceiveProgress(MediaReceiveProgress progress) {
    final messageId = progress.messageId;
    if (messageId == null) return;

    final status = _incomingStatus(progress.state);

    if (!_knownIncomingMessages.contains(messageId)) {
      _knownIncomingMessages.add(messageId);
      unawaited(_createPendingMessage(
        messageId: messageId,
        isOutgoing: false,
        media: MediaAttachment(
          type: _inferKind(progress.extraMetadata, progress.mimeType),
          transferId: progress.transferId,
          filename: progress.filename ?? 'file',
          mimeType: progress.mimeType ?? 'application/octet-stream',
          fileSize: progress.totalBytes,
          status: status,
          bytesTransferred: progress.bytesReceived,
          localPath: progress.localPath,
          width: (progress.extraMetadata['width'] as num?)?.toInt(),
          height: (progress.extraMetadata['height'] as num?)?.toInt(),
          durationMs: (progress.extraMetadata['durationMs'] as num?)?.toInt(),
        ),
      ));
    } else {
      unawaited(_updateMessageMedia(
        messageId: messageId,
        status: status,
        bytesTransferred: progress.bytesReceived,
        localPath: progress.localPath,
        errorMessage: progress.errorMessage,
      ));
    }

    if (status == MediaTransferStatus.completed ||
        status == MediaTransferStatus.failed ||
        status == MediaTransferStatus.cancelled) {
      _knownIncomingMessages.remove(messageId);
    }
  }

  ChatMediaType _inferKind(Map<String, dynamic> extraMetadata, String? mimeType) {
    switch (extraMetadata['kind'] as String?) {
      case 'image':
        return ChatMediaType.image;
      case 'video':
        return ChatMediaType.video;
      case 'voice':
        return ChatMediaType.audio;
      case 'document':
        return ChatMediaType.document;
    }
    // Fall back to sniffing the mime type if the sender omitted `kind`.
    final mime = mimeType ?? '';
    if (mime.startsWith('image/')) return ChatMediaType.image;
    if (mime.startsWith('video/')) return ChatMediaType.video;
    if (mime.startsWith('audio/')) return ChatMediaType.audio;
    return ChatMediaType.document;
  }

  MediaTransferStatus _outgoingStatus(MediaTransferState state) {
    switch (state) {
      case MediaTransferState.sending:
        return MediaTransferStatus.sending;
      case MediaTransferState.completed:
        return MediaTransferStatus.completed;
      case MediaTransferState.cancelled:
        return MediaTransferStatus.cancelled;
      case MediaTransferState.failed:
        return MediaTransferStatus.failed;
    }
  }

  MediaTransferStatus _incomingStatus(MediaReceiveState state) {
    switch (state) {
      case MediaReceiveState.receiving:
      case MediaReceiveState.verifying:
        return MediaTransferStatus.receiving;
      case MediaReceiveState.completed:
        return MediaTransferStatus.completed;
      case MediaReceiveState.cancelled:
        return MediaTransferStatus.cancelled;
      case MediaReceiveState.failed:
        return MediaTransferStatus.failed;
    }
  }

  void cancelSend(String transferId) => _media.cancelSend(transferId);

  Future<void> cancelReceive(String transferId) =>
      _media.cancelReceive(transferId);

  Future<void> dispose() async {
    await _sendSub.cancel();
    await _receiveSub.cancel();
  }
}

/// Single entry point the chat feature uses to send and receive media —
/// composes [ChunkedFileSender] and [ChunkedFileReceiver] behind one
/// repository so the UI layer never touches transfer/frame internals
/// directly. This is the class the chat message-send flow and media
/// bubbles talk to.
library media_repository;

import 'dart:async';
import 'dart:io';

import 'package:mime/mime.dart';

import 'chunked_file_receiver.dart';
import 'chunked_file_sender.dart';

class MediaRepository {
  MediaRepository({
    required ChunkedFileSender sender,
    required ChunkedFileReceiver receiver,
  })  : _sender = sender,
        _receiver = receiver;

  final ChunkedFileSender _sender;
  final ChunkedFileReceiver _receiver;

  final StreamController<MediaTransferProgress> _sendingController =
      StreamController<MediaTransferProgress>.broadcast();

  /// Progress for every outgoing transfer started through this repository,
  /// merged onto one stream. Widgets filter by `transferId`/`messageId`.
  Stream<MediaTransferProgress> get sendingProgress =>
      _sendingController.stream;

  /// Progress for every incoming transfer this session has seen.
  Stream<MediaReceiveProgress> get receivingProgress => _receiver.events;

  MediaTransferHandle sendImage({
    required String messageId,
    required File file,
    required int width,
    required int height,
  }) {
    return _send(
      messageId: messageId,
      file: file,
      mimeType: lookupMimeType(file.path) ?? 'image/jpeg',
      extraMetadata: {'kind': 'image', 'width': width, 'height': height},
    );
  }

  MediaTransferHandle sendVideo({
    required String messageId,
    required File file,
    required int width,
    required int height,
    required int durationMs,
    File? thumbnail,
  }) {
    return _send(
      messageId: messageId,
      file: file,
      mimeType: lookupMimeType(file.path) ?? 'video/mp4',
      extraMetadata: {
        'kind': 'video',
        'width': width,
        'height': height,
        'durationMs': durationMs,
      },
    );
  }

  MediaTransferHandle sendVoiceNote({
    required String messageId,
    required File file,
    required int durationMs,
  }) {
    return _send(
      messageId: messageId,
      file: file,
      mimeType: lookupMimeType(file.path) ?? 'audio/m4a',
      extraMetadata: {'kind': 'voice', 'durationMs': durationMs},
    );
  }

  MediaTransferHandle sendDocument({
    required String messageId,
    required File file,
    required String filename,
  }) {
    return _send(
      messageId: messageId,
      file: file,
      mimeType: lookupMimeType(file.path) ?? 'application/octet-stream',
      extraMetadata: {'kind': 'document'},
    );
  }

  MediaTransferHandle _send({
    required String messageId,
    required File file,
    required String mimeType,
    required Map<String, dynamic> extraMetadata,
  }) {
    final handle = _sender.sendFile(
      messageId: messageId,
      file: file,
      mimeType: mimeType,
      extraMetadata: extraMetadata,
    );
    handle.progress.listen(
      _sendingController.add,
      onError: _sendingController.addError,
    );
    return handle;
  }

  /// Cancel an outgoing transfer the user initiated (e.g. tapped the
  /// cancel button on a sending bubble).
  void cancelSend(String transferId) => _sender.cancel(transferId);

  /// Cancel an incoming transfer the user doesn't want to finish
  /// receiving.
  Future<void> cancelReceive(String transferId) =>
      _receiver.cancel(transferId);

  Future<void> dispose() async {
    await _sendingController.close();
    await _receiver.dispose();
  }
}

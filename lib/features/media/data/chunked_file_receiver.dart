/// Consumes binary frames from the shared [MediaDataChannel], reassembles
/// them into local files without buffering the whole file in memory, and
/// verifies integrity against the sender's whole-file SHA-256 before
/// marking a transfer complete.
///
/// Assumes the underlying DataChannel is ordered and reliable (the default
/// for `RTCDataChannel` unless explicitly configured otherwise), so chunks
/// are expected to arrive in index order; an out-of-order or skipped chunk
/// is treated as a protocol error and fails that transfer rather than
/// being silently reordered.
library chunked_file_receiver;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../../../core/media/media_channel.dart';
import '../../../core/media/media_transfer_protocol.dart';
import '../../../core/media/session_cipher.dart';

/// Resolves where an incoming transfer's bytes get written. Backed by the
/// app's local storage layer (app documents / media directory), so the
/// receiver never hardcodes a path scheme.
abstract class MediaFileStorage {
  /// Creates the destination file for a new incoming transfer.
  /// Implementations should pick a collision-free path — typically
  /// namespaced by [transferId] — while preserving [suggestedFilename]'s
  /// extension so the OS/app can associate the right viewer/opener with it.
  Future<File> createDestinationFile({
    required String transferId,
    required String suggestedFilename,
    required String mimeType,
  });

  /// Best-effort free space check before accepting a large transfer.
  /// Return null if unknown/unsupported on the current platform.
  Future<int?> availableDiskSpaceBytes();

  Future<void> deleteFile(File file);
}

/// Persists incoming-transfer/progress state, backed by the existing
/// `MediaMetadata` Drift table.
abstract class MediaReceiveProgressStore {
  Future<void> createIncomingTransfer({
    required String transferId,
    required String messageId,
    required String filename,
    required String mimeType,
    required int totalBytes,
    required int totalChunks,
    required String localPath,
    required Map<String, dynamic> extraMetadata,
  });

  Future<void> updateProgress({
    required String transferId,
    required int bytesReceived,
    required int chunksReceived,
  });

  Future<void> markCompleted({
    required String transferId,
    required String localPath,
  });

  Future<void> markFailed({
    required String transferId,
    required String reason,
  });

  Future<void> markCancelled({required String transferId});
}

enum MediaReceiveState { receiving, verifying, completed, cancelled, failed }

class MediaReceiveProgress {
  final String transferId;
  final String? messageId;
  final int bytesReceived;
  final int totalBytes;
  final int chunksReceived;
  final int totalChunks;
  final MediaReceiveState state;
  final String? localPath;
  final String? errorMessage;

  /// Present from the very first (`receiving`, 0 bytes) event onward, so a
  /// consumer that hasn't seen this transferId before has everything it
  /// needs to create a chat message row without a separate lookup.
  final String? filename;
  final String? mimeType;

  /// Sender-supplied extras from the init frame (`kind`, `width`,
  /// `height`, `durationMs`, ...) — whatever [ChunkedFileSender.sendFile]
  /// was called with as `extraMetadata`.
  final Map<String, dynamic> extraMetadata;

  const MediaReceiveProgress({
    required this.transferId,
    this.messageId,
    required this.bytesReceived,
    required this.totalBytes,
    required this.chunksReceived,
    required this.totalChunks,
    required this.state,
    this.localPath,
    this.errorMessage,
    this.filename,
    this.mimeType,
    this.extraMetadata = const {},
  });

  double get fraction => totalBytes == 0 ? 0 : bytesReceived / totalBytes;
}

class MediaReceiveException implements Exception {
  final String message;
  const MediaReceiveException(this.message);
  @override
  String toString() => 'MediaReceiveException: $message';
}

class _IncomingTransfer {
  _IncomingTransfer({
    required this.transferId,
    required this.messageId,
    required this.file,
    required this.sink,
    required this.totalBytes,
    required this.totalChunks,
    required this.filename,
    required this.mimeType,
    required this.extraMetadata,
  });

  final String transferId;
  final String messageId;
  final File file;
  final IOSink sink;
  final int totalBytes;
  final int totalChunks;
  final String filename;
  final String mimeType;
  final Map<String, dynamic> extraMetadata;

  final AccumulatorSink<Digest> hashAccumulator = AccumulatorSink<Digest>();
  late final ByteConversionSink hashInput =
      sha256.startChunkedConversion(hashAccumulator);

  int bytesReceived = 0;
  int chunksReceived = 0;
  int nextExpectedChunk = 0;
  bool cancelled = false;

  Future<void> close() => sink.close();
}

class ChunkedFileReceiver {
  ChunkedFileReceiver({
    required MediaDataChannel channel,
    required SessionCipher cipher,
    required MediaFileStorage storage,
    required MediaReceiveProgressStore progressStore,
  })  : _channel = channel,
        _cipher = cipher,
        _storage = storage,
        _progressStore = progressStore {
    _subscription = _channel.incomingMessages.listen(
      _handleMessage,
      onError: (Object e, StackTrace st) {
        // A transport-level stream error isn't attributable to a single
        // transfer; surface it without touching per-transfer state.
        _eventsController.addError(e, st);
      },
    );
  }

  final MediaDataChannel _channel;
  final SessionCipher _cipher;
  final MediaFileStorage _storage;
  final MediaReceiveProgressStore _progressStore;

  final Map<String, _IncomingTransfer> _transfers = {};
  final StreamController<MediaReceiveProgress> _eventsController =
      StreamController<MediaReceiveProgress>.broadcast();
  late final StreamSubscription<Uint8List> _subscription;

  /// All incoming-transfer progress events, across every transfer this
  /// receiver has seen. The UI filters by `transferId` (or by `messageId`
  /// to key off the chat bubble it's already showing).
  Stream<MediaReceiveProgress> get events => _eventsController.stream;

  Future<void> _handleMessage(Uint8List data) async {
    try {
      switch (peekFrameType(data)) {
        case MediaFrameType.init:
          await _handleInit(MediaInitFrame.decode(data));
          break;
        case MediaFrameType.chunk:
          await _handleChunk(MediaChunkFrame.decode(data));
          break;
        case MediaFrameType.complete:
          await _handleComplete(MediaCompleteFrame.decode(data));
          break;
        case MediaFrameType.cancel:
          await _handleCancel(MediaCancelFrame.decode(data));
          break;
        case MediaFrameType.error:
          await _handleError(MediaErrorFrame.decode(data));
          break;
        case MediaFrameType.ack:
          // Acks are for the sender's flow control; nothing to do here.
          break;
        default:
          // Unknown frame type: ignore rather than crash, in case a future
          // protocol version adds frame types this build doesn't know.
          break;
      }
    } catch (e) {
      // Never let a malformed/truncated frame take down the channel
      // listener — the whole point of this handler is "never crash".
      _eventsController.addError(
        MediaReceiveException('Failed to process incoming frame: $e'),
      );
    }
  }

  Future<void> _handleInit(MediaInitFrame frame) async {
    final transferId = transferIdString(frame.transferId);
    if (_transfers.containsKey(transferId)) {
      // Duplicate init frame for an active transfer — ignore safely.
      return;
    }

    Map<String, dynamic> metadata;
    try {
      final plaintext = await _cipher.decrypt(frame.encryptedMetadata);
      metadata = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    } catch (e) {
      await _progressStore.markFailed(
        transferId: transferId,
        reason: 'metadata_decrypt_failed',
      );
      _emit(MediaReceiveProgress(
        transferId: transferId,
        bytesReceived: 0,
        totalBytes: 0,
        chunksReceived: 0,
        totalChunks: 0,
        state: MediaReceiveState.failed,
        errorMessage: 'Could not decrypt transfer metadata: $e',
      ));
      return;
    }

    final messageId = metadata['messageId'] as String? ?? transferId;
    final filename = metadata['filename'] as String? ?? 'file';
    final mimeType =
        metadata['mimeType'] as String? ?? 'application/octet-stream';
    final totalBytes = (metadata['totalBytes'] as num?)?.toInt() ?? 0;
    final totalChunks = (metadata['totalChunks'] as num?)?.toInt() ?? 0;

    try {
      final freeSpace = await _storage.availableDiskSpaceBytes();
      if (freeSpace != null && freeSpace < totalBytes) {
        throw const MediaReceiveException('Not enough free storage space');
      }

      final extraMetadata = Map<String, dynamic>.from(metadata)
        ..removeWhere((key, _) => const {
              'messageId',
              'filename',
              'mimeType',
              'totalBytes',
              'totalChunks',
            }.contains(key));

      final file = await _storage.createDestinationFile(
        transferId: transferId,
        suggestedFilename: filename,
        mimeType: mimeType,
      );
      final sink = file.openWrite();

      _transfers[transferId] = _IncomingTransfer(
        transferId: transferId,
        messageId: messageId,
        file: file,
        sink: sink,
        totalBytes: totalBytes,
        totalChunks: totalChunks,
        filename: filename,
        mimeType: mimeType,
        extraMetadata: extraMetadata,
      );

      await _progressStore.createIncomingTransfer(
        transferId: transferId,
        messageId: messageId,
        filename: filename,
        mimeType: mimeType,
        totalBytes: totalBytes,
        totalChunks: totalChunks,
        localPath: file.path,
        extraMetadata: extraMetadata,
      );

      _emit(MediaReceiveProgress(
        transferId: transferId,
        messageId: messageId,
        bytesReceived: 0,
        totalBytes: totalBytes,
        chunksReceived: 0,
        totalChunks: totalChunks,
        state: MediaReceiveState.receiving,
        localPath: file.path,
        filename: filename,
        mimeType: mimeType,
        extraMetadata: extraMetadata,
      ));
    } catch (e) {
      await _progressStore.markFailed(
        transferId: transferId,
        reason: e.toString(),
      );
      _emit(MediaReceiveProgress(
        transferId: transferId,
        messageId: messageId,
        bytesReceived: 0,
        totalBytes: totalBytes,
        chunksReceived: 0,
        totalChunks: totalChunks,
        state: MediaReceiveState.failed,
        errorMessage: e.toString(),
        filename: filename,
        mimeType: mimeType,
      ));
      await _channel.send(MediaErrorFrame(
        transferId: frame.transferId,
        message: 'receiver_setup_failed',
      ).encode());
    }
  }

  Future<void> _handleChunk(MediaChunkFrame frame) async {
    final transferId = transferIdString(frame.transferId);
    final transfer = _transfers[transferId];
    if (transfer == null || transfer.cancelled) return;

    try {
      if (frame.chunkIndex < transfer.nextExpectedChunk) {
        // Duplicate chunk — resend ACK for flow control and return cleanly.
        unawaited(_channel.send(MediaAckFrame(
          transferId: frame.transferId,
          chunkIndex: frame.chunkIndex,
        ).encode()));
        return;
      }

      if (frame.chunkIndex != transfer.nextExpectedChunk) {
        throw MediaReceiveException(
          'Out-of-order chunk: expected ${transfer.nextExpectedChunk}, '
          'got ${frame.chunkIndex}',
        );
      }

      final plaintext = await _cipher.decrypt(frame.encryptedPayload);

      transfer.sink.add(plaintext);
      transfer.hashInput.add(plaintext);
      transfer.bytesReceived += plaintext.length;
      transfer.chunksReceived += 1;
      transfer.nextExpectedChunk += 1;

      unawaited(_progressStore.updateProgress(
        transferId: transferId,
        bytesReceived: transfer.bytesReceived,
        chunksReceived: transfer.chunksReceived,
      ));

      unawaited(_channel.send(MediaAckFrame(
        transferId: frame.transferId,
        chunkIndex: frame.chunkIndex,
      ).encode()));

      _emit(MediaReceiveProgress(
        transferId: transferId,
        messageId: transfer.messageId,
        bytesReceived: transfer.bytesReceived,
        totalBytes: transfer.totalBytes,
        chunksReceived: transfer.chunksReceived,
        totalChunks: transfer.totalChunks,
        state: MediaReceiveState.receiving,
        localPath: transfer.file.path,
        filename: transfer.filename,
        mimeType: transfer.mimeType,
        extraMetadata: transfer.extraMetadata,
      ));
    } catch (e) {
      await _failTransfer(transfer, e.toString());
    }
  }

  Future<void> _handleComplete(MediaCompleteFrame frame) async {
    final transferId = transferIdString(frame.transferId);
    final transfer = _transfers[transferId];
    if (transfer == null || transfer.cancelled) return;

    _emit(MediaReceiveProgress(
      transferId: transferId,
      messageId: transfer.messageId,
      bytesReceived: transfer.bytesReceived,
      totalBytes: transfer.totalBytes,
      chunksReceived: transfer.chunksReceived,
      totalChunks: transfer.totalChunks,
      state: MediaReceiveState.verifying,
      localPath: transfer.file.path,
      filename: transfer.filename,
      mimeType: transfer.mimeType,
      extraMetadata: transfer.extraMetadata,
    ));

    var sinkClosed = false;
    try {
      if (transfer.chunksReceived != transfer.totalChunks ||
          transfer.bytesReceived != transfer.totalBytes) {
        throw MediaReceiveException(
          'Transfer incomplete: received ${transfer.chunksReceived}/'
          '${transfer.totalChunks} chunks, ${transfer.bytesReceived}/'
          '${transfer.totalBytes} bytes',
        );
      }

      transfer.hashInput.close();
      final actualHash = transfer.hashAccumulator.events.single.toString();
      await transfer.close();
      sinkClosed = true;

      if (actualHash != frame.sha256Hex) {
        throw const MediaReceiveException(
          'Checksum mismatch — file is corrupt or was tampered with',
        );
      }

      _transfers.remove(transferId);
      await _progressStore.markCompleted(
        transferId: transferId,
        localPath: transfer.file.path,
      );

      _emit(MediaReceiveProgress(
        transferId: transferId,
        messageId: transfer.messageId,
        bytesReceived: transfer.bytesReceived,
        totalBytes: transfer.totalBytes,
        chunksReceived: transfer.chunksReceived,
        totalChunks: transfer.totalChunks,
        state: MediaReceiveState.completed,
        localPath: transfer.file.path,
        filename: transfer.filename,
        mimeType: transfer.mimeType,
        extraMetadata: transfer.extraMetadata,
      ));
    } catch (e) {
      await _failTransfer(transfer, e.toString(), alreadyClosed: sinkClosed);
    }
  }

  Future<void> _handleCancel(MediaCancelFrame frame) async {
    final transferId = transferIdString(frame.transferId);
    final transfer = _transfers.remove(transferId);
    if (transfer == null) return;

    transfer.cancelled = true;
    await transfer.close();
    await _storage.deleteFile(transfer.file);
    await _progressStore.markCancelled(transferId: transferId);

    _emit(MediaReceiveProgress(
      transferId: transferId,
      messageId: transfer.messageId,
      bytesReceived: transfer.bytesReceived,
      totalBytes: transfer.totalBytes,
      chunksReceived: transfer.chunksReceived,
      totalChunks: transfer.totalChunks,
      state: MediaReceiveState.cancelled,
      filename: transfer.filename,
      mimeType: transfer.mimeType,
      extraMetadata: transfer.extraMetadata,
    ));
  }

  Future<void> _handleError(MediaErrorFrame frame) async {
    final transferId = transferIdString(frame.transferId);
    final transfer = _transfers[transferId];
    if (transfer == null) return;
    await _failTransfer(transfer, frame.message);
  }

  Future<void> _failTransfer(
    _IncomingTransfer transfer,
    String reason, {
    bool alreadyClosed = false,
  }) async {
    transfer.cancelled = true;
    _transfers.remove(transfer.transferId);
    if (!alreadyClosed) {
      await transfer.close();
    }
    await _storage.deleteFile(transfer.file);
    await _progressStore.markFailed(
      transferId: transfer.transferId,
      reason: reason,
    );

    _emit(MediaReceiveProgress(
      transferId: transfer.transferId,
      messageId: transfer.messageId,
      bytesReceived: transfer.bytesReceived,
      totalBytes: transfer.totalBytes,
      chunksReceived: transfer.chunksReceived,
      totalChunks: transfer.totalChunks,
      state: MediaReceiveState.failed,
      errorMessage: reason,
      filename: transfer.filename,
      mimeType: transfer.mimeType,
      extraMetadata: transfer.extraMetadata,
    ));

    await _channel.send(MediaErrorFrame(
      transferId: transferIdBytes(transfer.transferId),
      message: reason,
    ).encode());
  }

  /// Lets the user cancel an in-progress *incoming* transfer (e.g. they
  /// don't want the 500 MB video). Cleans up the partial file and notifies
  /// the sender so it stops transmitting.
  Future<void> cancel(String transferId) async {
    final transfer = _transfers.remove(transferId);
    if (transfer == null) return;

    transfer.cancelled = true;
    await transfer.close();
    await _storage.deleteFile(transfer.file);
    await _progressStore.markCancelled(transferId: transferId);
    await _channel.send(MediaCancelFrame(
      transferId: transferIdBytes(transferId),
      reason: 'receiver_cancelled',
    ).encode());

    _emit(MediaReceiveProgress(
      transferId: transferId,
      messageId: transfer.messageId,
      bytesReceived: transfer.bytesReceived,
      totalBytes: transfer.totalBytes,
      chunksReceived: transfer.chunksReceived,
      totalChunks: transfer.totalChunks,
      state: MediaReceiveState.cancelled,
      filename: transfer.filename,
      mimeType: transfer.mimeType,
      extraMetadata: transfer.extraMetadata,
    ));
  }

  void _emit(MediaReceiveProgress progress) {
    if (!_eventsController.isClosed) {
      _eventsController.add(progress);
    }
  }

  /// Releases the underlying subscription. Call when the chat screen /
  /// data channel is being torn down.
  Future<void> dispose() async {
    await _subscription.cancel();
    await _eventsController.close();
  }
}

// -----------------------------------------------------------------------
// Integration notes
// -----------------------------------------------------------------------
// Construct with the *same* MediaDataChannel instance (e.g.
// RtcMediaDataChannel from chunked_file_sender.dart's integration notes)
// used by the ChunkedFileSender for this peer connection.
//
// MediaFileStorage adapter example (app documents directory, namespaced by
// transfer id to avoid collisions, extension preserved from the sender's
// filename for correct OS file-type association):
//
//   class AppMediaFileStorage implements MediaFileStorage {
//     AppMediaFileStorage(this._mediaDir); // e.g. getApplicationDocumentsDirectory()/media
//     final Directory _mediaDir;
//     @override
//     Future<File> createDestinationFile({
//       required String transferId,
//       required String suggestedFilename,
//       required String mimeType,
//     }) async {
//       final ext = suggestedFilename.contains('.')
//           ? suggestedFilename.substring(suggestedFilename.lastIndexOf('.'))
//           : '';
//       final file = File('${_mediaDir.path}/$transferId$ext');
//       await file.create(recursive: true);
//       return file;
//     }
//     @override
//     Future<int?> availableDiskSpaceBytes() async => null; // or disk_space plugin
//     @override
//     Future<void> deleteFile(File file) async {
//       if (await file.exists()) await file.delete();
//     }
//   }
//
// MediaReceiveProgressStore adapter: implement against the same
// MediaMetadata Drift DAO used by MediaTransferProgressStore in
// chunked_file_sender.dart — an incoming row is just one with
// direction=incoming instead of outgoing.
//
// ChunkedFileSender listens on the same channel for the MediaCancelFrame /
// MediaErrorFrame this receiver sends (from cancel() or a checksum
// failure) and stops sending on the next chunk once one arrives for the
// matching transfer — no further wiring needed for that round trip.

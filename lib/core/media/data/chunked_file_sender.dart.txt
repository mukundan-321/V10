/// Streams a local file to the paired peer as encrypted 64 KB chunks over
/// the WebRTC DataChannel, without ever loading the whole file into memory.
///
/// This module is deliberately decoupled from `flutter_webrtc`, the
/// project's Drift DAOs, and its concrete `SessionCipher` implementation.
/// It depends only on [MediaDataChannel], [SessionCipher], and
/// [MediaTransferProgressStore] below. Wire the real types up by
/// implementing those interfaces once — see the integration notes at the
/// bottom of this file — everything else here is complete and ready to use
/// as-is.
library chunked_file_sender;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../../core/media/media_channel.dart';
import '../../../core/media/media_transfer_protocol.dart';
import '../../../core/media/session_cipher.dart';

/// Persists transfer/progress state. Backed by the existing `MediaMetadata`
/// Drift table — implement this against the generated DAO.
abstract class MediaTransferProgressStore {
  Future<void> createTransfer({
    required String transferId,
    required String messageId,
    required String filename,
    required String mimeType,
    required int totalBytes,
    required int totalChunks,
  });

  Future<void> updateProgress({
    required String transferId,
    required int bytesSent,
    required int chunksSent,
  });

  Future<void> markCompleted({
    required String transferId,
    required String sha256Hex,
  });

  Future<void> markFailed({
    required String transferId,
    required String reason,
  });

  Future<void> markCancelled({required String transferId});
}

enum MediaTransferState { sending, completed, cancelled, failed }

class MediaTransferProgress {
  final String transferId;
  final int bytesSent;
  final int totalBytes;
  final int chunksSent;
  final int totalChunks;
  final MediaTransferState state;
  final String? sha256Hex;
  final String? errorMessage;

  const MediaTransferProgress({
    required this.transferId,
    required this.bytesSent,
    required this.totalBytes,
    required this.chunksSent,
    required this.totalChunks,
    required this.state,
    this.sha256Hex,
    this.errorMessage,
  });

  double get fraction => totalBytes == 0 ? 0 : bytesSent / totalBytes;

  factory MediaTransferProgress.cancelled(String transferId) =>
      MediaTransferProgress(
        transferId: transferId,
        bytesSent: 0,
        totalBytes: 0,
        chunksSent: 0,
        totalChunks: 0,
        state: MediaTransferState.cancelled,
      );

  factory MediaTransferProgress.failed(String transferId, String message) =>
      MediaTransferProgress(
        transferId: transferId,
        bytesSent: 0,
        totalBytes: 0,
        chunksSent: 0,
        totalChunks: 0,
        state: MediaTransferState.failed,
        errorMessage: message,
      );
}

/// Returned by [ChunkedFileSender.sendFile]. The UI subscribes to
/// [progress] to drive the sending progress ring, and calls [cancel] from
/// the bubble's cancel button.
class MediaTransferHandle {
  final String transferId;
  final Stream<MediaTransferProgress> progress;
  final void Function() cancel;

  const MediaTransferHandle({
    required this.transferId,
    required this.progress,
    required this.cancel,
  });
}

class MediaTransferException implements Exception {
  final String message;
  const MediaTransferException(this.message);
  @override
  String toString() => 'MediaTransferException: $message';
}

class _ActiveTransfer {
  bool cancelRequested = false;

  /// Set when the receiver sends a [MediaCancelFrame] or [MediaErrorFrame]
  /// for this transfer — the send loop stops on the next iteration without
  /// echoing another cancel frame back (the peer already knows).
  String? remoteAbortReason;
  bool remoteAbortWasError = false;
}

class ChunkedFileSender {
  ChunkedFileSender({
    required MediaDataChannel channel,
    required SessionCipher cipher,
    required MediaTransferProgressStore progressStore,
    Uuid? uuid,
    int chunkSize = kMediaChunkSize,
    int bufferedAmountHighWaterMark = 1 << 20, // 1 MB queued before pausing
    int bufferedAmountLowWaterMark = 256 * 1024, // resume once drained to this
  })  : _channel = channel,
        _cipher = cipher,
        _progressStore = progressStore,
        _uuid = uuid ?? const Uuid(),
        _chunkSize = chunkSize,
        _highWaterMark = bufferedAmountHighWaterMark,
        _lowWaterMark = bufferedAmountLowWaterMark {
    _incomingSub = _channel.incomingMessages.listen(_handleIncoming);
  }

  final MediaDataChannel _channel;
  final SessionCipher _cipher;
  final MediaTransferProgressStore _progressStore;
  final Uuid _uuid;
  final int _chunkSize;
  final int _highWaterMark;
  final int _lowWaterMark;

  final Map<String, _ActiveTransfer> _activeTransfers = {};
  late final StreamSubscription<Uint8List> _incomingSub;

  /// The sender only cares about frames the *receiver* sends back for a
  /// transfer it started: a cancel (user aborted the incoming file) or an
  /// error (e.g. checksum mismatch). Everything else on this channel
  /// belongs to the receiver side and is ignored here.
  void _handleIncoming(Uint8List data) {
    try {
      final frameType = peekFrameType(data);
      if (frameType == MediaFrameType.cancel) {
        final frame = MediaCancelFrame.decode(data);
        final transferId = transferIdString(frame.transferId);
        final active = _activeTransfers[transferId];
        if (active != null) {
          active.remoteAbortReason = frame.reason.isEmpty
              ? 'receiver_cancelled'
              : frame.reason;
        }
      } else if (frameType == MediaFrameType.error) {
        final frame = MediaErrorFrame.decode(data);
        final transferId = transferIdString(frame.transferId);
        final active = _activeTransfers[transferId];
        if (active != null) {
          active.remoteAbortReason = frame.message;
          active.remoteAbortWasError = true;
        }
      }
    } catch (_) {
      // Malformed frame not addressed to an active outgoing transfer —
      // nothing to do; never let this listener crash the app.
    }
  }

  /// Starts streaming [file] to the peer. Returns immediately with a
  /// handle; the transfer runs in the background and reports progress on
  /// the returned stream.
  ///
  /// [extraMetadata] carries type-specific fields the receiver needs up
  /// front (e.g. `{'width': 1920, 'height': 1080}` for images/video,
  /// `{'durationMs': 4200}` for voice notes/video) — merged into the
  /// encrypted init-frame metadata alongside filename/mimeType/size.
  MediaTransferHandle sendFile({
    required String messageId,
    required File file,
    required String mimeType,
    Map<String, dynamic> extraMetadata = const {},
  }) {
    final transferId = _uuid.v4();
    final controller = StreamController<MediaTransferProgress>.broadcast();
    final active = _ActiveTransfer();
    _activeTransfers[transferId] = active;

    unawaited(_run(
      transferId: transferId,
      messageId: messageId,
      file: file,
      mimeType: mimeType,
      extraMetadata: extraMetadata,
      controller: controller,
      active: active,
    ));

    return MediaTransferHandle(
      transferId: transferId,
      progress: controller.stream,
      cancel: () => active.cancelRequested = true,
    );
  }

  Future<void> _run({
    required String transferId,
    required String messageId,
    required File file,
    required String mimeType,
    required Map<String, dynamic> extraMetadata,
    required StreamController<MediaTransferProgress> controller,
    required _ActiveTransfer active,
  }) async {
    try {
      if (!_channel.isOpen) {
        throw const MediaTransferException('Peer is not connected');
      }
      if (!await file.exists()) {
        throw MediaTransferException('File not found: ${file.path}');
      }

      final totalBytes = await file.length();
      final totalChunks =
          totalBytes == 0 ? 1 : (totalBytes / _chunkSize).ceil();
      final transferIdRaw = transferIdBytes(transferId);
      final filename = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : file.path;

      await _progressStore.createTransfer(
        transferId: transferId,
        messageId: messageId,
        filename: filename,
        mimeType: mimeType,
        totalBytes: totalBytes,
        totalChunks: totalChunks,
      );

      await _sendInitFrame(
        transferIdRaw: transferIdRaw,
        messageId: messageId,
        filename: filename,
        mimeType: mimeType,
        totalBytes: totalBytes,
        totalChunks: totalChunks,
        extraMetadata: extraMetadata,
      );

      final hashSink = AccumulatorSink<Digest>();
      final hashInput = sha256.startChunkedConversion(hashSink);

      var chunkIndex = 0;
      var bytesSent = 0;

      if (totalBytes == 0) {
        // Zero-byte file: still send exactly one (empty) chunk so the
        // receiver's chunk count matches totalChunks and reassembly logic
        // doesn't need a special case.
        await _sendChunk(
          transferIdRaw: transferIdRaw,
          chunkIndex: 0,
          totalChunks: 1,
          bytes: Uint8List(0),
        );
        chunkIndex = 1;
      } else {
        await for (final chunkBytes in _chunkStream(file.openRead())) {
          if (active.remoteAbortReason != null) {
            // The receiver already knows the transfer is aborting (it sent
            // the frame) — stop immediately without echoing another frame
            // back, and record the outcome under the reason the *receiver*
            // gave (checksum failure, disk full, user cancel, etc).
            if (active.remoteAbortWasError) {
              await _progressStore.markFailed(
                transferId: transferId,
                reason: active.remoteAbortReason!,
              );
              controller.add(MediaTransferProgress.failed(
                transferId,
                active.remoteAbortReason!,
              ));
            } else {
              await _progressStore.markCancelled(transferId: transferId);
              controller.add(MediaTransferProgress.cancelled(transferId));
            }
            return;
          }
          if (active.cancelRequested) {
            await _channel.send(MediaCancelFrame(
              transferId: transferIdRaw,
              reason: 'sender_cancelled',
            ).encode());
            await _progressStore.markCancelled(transferId: transferId);
            controller.add(MediaTransferProgress.cancelled(transferId));
            return;
          }
          if (!_channel.isOpen) {
            throw const MediaTransferException(
              'Peer disconnected mid-transfer',
            );
          }

          hashInput.add(chunkBytes);

          await _sendChunk(
            transferIdRaw: transferIdRaw,
            chunkIndex: chunkIndex,
            totalChunks: totalChunks,
            bytes: chunkBytes,
          );

          bytesSent += chunkBytes.length;
          chunkIndex += 1;

          // Fire-and-forget: a single Drift UPDATE per chunk is cheap, but
          // it shouldn't gate the send loop's throughput.
          unawaited(_progressStore.updateProgress(
            transferId: transferId,
            bytesSent: bytesSent,
            chunksSent: chunkIndex,
          ));

          controller.add(MediaTransferProgress(
            transferId: transferId,
            bytesSent: bytesSent,
            totalBytes: totalBytes,
            chunksSent: chunkIndex,
            totalChunks: totalChunks,
            state: MediaTransferState.sending,
          ));
        }
      }

      hashInput.close();
      final sha256Hex = hashSink.events.single.toString();

      await _channel.send(MediaCompleteFrame(
        transferId: transferIdRaw,
        sha256Hex: sha256Hex,
      ).encode());

      await _progressStore.markCompleted(
        transferId: transferId,
        sha256Hex: sha256Hex,
      );

      controller.add(MediaTransferProgress(
        transferId: transferId,
        bytesSent: totalBytes,
        totalBytes: totalBytes,
        chunksSent: totalChunks,
        totalChunks: totalChunks,
        state: MediaTransferState.completed,
        sha256Hex: sha256Hex,
      ));
    } catch (e) {
      await _progressStore.markFailed(
        transferId: transferId,
        reason: e.toString(),
      );
      controller.add(MediaTransferProgress.failed(transferId, e.toString()));
    } finally {
      _activeTransfers.remove(transferId);
      await controller.close();
    }
  }

  Future<void> _sendInitFrame({
    required Uint8List transferIdRaw,
    required String messageId,
    required String filename,
    required String mimeType,
    required int totalBytes,
    required int totalChunks,
    required Map<String, dynamic> extraMetadata,
  }) async {
    final metadataJson = jsonEncode({
      'messageId': messageId,
      'filename': filename,
      'mimeType': mimeType,
      'totalBytes': totalBytes,
      'totalChunks': totalChunks,
      ...extraMetadata,
    });
    final encryptedMetadata =
        await _cipher.encrypt(Uint8List.fromList(utf8.encode(metadataJson)));

    await _waitForBufferSpace();
    await _channel.send(MediaInitFrame(
      transferId: transferIdRaw,
      encryptedMetadata: encryptedMetadata,
    ).encode());
  }

  Future<void> _sendChunk({
    required Uint8List transferIdRaw,
    required int chunkIndex,
    required int totalChunks,
    required Uint8List bytes,
  }) async {
    final encryptedPayload = await _cipher.encrypt(bytes);

    await _waitForBufferSpace();
    await _channel.send(MediaChunkFrame(
      transferId: transferIdRaw,
      chunkIndex: chunkIndex,
      totalChunks: totalChunks,
      encryptedPayload: encryptedPayload,
    ).encode());
  }

  /// Backpressure: if the DataChannel's send queue is above the high water
  /// mark, wait until it drains to the low water mark before queuing more.
  /// Without this a 500 MB file gets encrypted and queued into
  /// `RTCDataChannel.send` far faster than the peer's link can drain it,
  /// growing an unbounded in-process queue.
  Future<void> _waitForBufferSpace() async {
    if (_channel.bufferedAmount < _highWaterMark) return;
    _channel.bufferedAmountLowThreshold = _lowWaterMark;
    await _channel.onBufferedAmountLow.first;
  }

  /// Re-chunks the OS-buffered file stream into fixed-size pieces without
  /// ever materializing the whole file in memory — `File.openRead()` reads
  /// in filesystem-sized blocks (typically far smaller than 64 KB), so this
  /// coalesces/splits those into consistent [_chunkSize] pieces.
  Stream<Uint8List> _chunkStream(Stream<List<int>> input) async* {
    final buffer = BytesBuilder(copy: false);
    await for (final part in input) {
      buffer.add(part);
      while (buffer.length >= _chunkSize) {
        final all = buffer.takeBytes();
        yield Uint8List.fromList(all.sublist(0, _chunkSize));
        buffer.add(all.sublist(_chunkSize));
      }
    }
    if (buffer.length > 0) {
      yield buffer.takeBytes();
    }
  }

  /// True if [transferId] is currently sending (not yet completed,
  /// cancelled, or failed).
  bool isActive(String transferId) => _activeTransfers.containsKey(transferId);

  /// Requests cancellation of an in-flight transfer by id, e.g. if the UI
  /// only has the id (not the original [MediaTransferHandle]) at hand.
  void cancel(String transferId) {
    _activeTransfers[transferId]?.cancelRequested = true;
  }

  /// Releases the underlying subscription. Call when the chat screen /
  /// data channel is being torn down.
  Future<void> dispose() async {
    await _incomingSub.cancel();
  }
}

// -----------------------------------------------------------------------
// Integration notes
// -----------------------------------------------------------------------
// This file has no dependency on flutter_webrtc, Drift, or the concrete
// SessionCipher — wire it up with two small adapters (a third,
// MediaTransferProgressStore, is defined above and backed by your
// MediaMetadata DAO):
//
// 1. SessionCipher adapter around the existing session cipher:
//
//      class AppSessionCipher implements SessionCipher {
//        AppSessionCipher(this._existingCipher);
//        final YourExistingSessionCipher _existingCipher;
//        @override
//        Future<Uint8List> encrypt(Uint8List p) => _existingCipher.encrypt(p);
//        @override
//        Future<Uint8List> decrypt(Uint8List c) => _existingCipher.decrypt(c);
//      }
//
// 2. MediaDataChannel adapter around RTCDataChannel (shared by the sender
//    and the ChunkedFileReceiver in chunked_file_receiver.dart):
//
//      class RtcMediaDataChannel implements MediaDataChannel {
//        RtcMediaDataChannel(this._channel) {
//          _channel.onBufferedAmountLow = (_) => _lowController.add(null);
//          _channel.onMessage = (RTCDataChannelMessage m) {
//            if (m.isBinary) _incomingController.add(m.binary);
//          };
//        }
//        final RTCDataChannel _channel;
//        final _lowController = StreamController<void>.broadcast();
//        final _incomingController = StreamController<Uint8List>.broadcast();
//        @override
//        bool get isOpen => _channel.state == RTCDataChannelState.RTCDataChannelOpen;
//        @override
//        int get bufferedAmount => _channel.bufferedAmount ?? 0;
//        @override
//        set bufferedAmountLowThreshold(int bytes) =>
//            _channel.bufferedAmountLowThreshold = bytes;
//        @override
//        Stream<void> get onBufferedAmountLow => _lowController.stream;
//        @override
//        Stream<Uint8List> get incomingMessages => _incomingController.stream;
//        @override
//        Future<void> send(Uint8List data) =>
//            _channel.send(RTCDataChannelMessage.fromBinary(data));
//      }
//
// Both ChunkedFileSender and ChunkedFileReceiver should be constructed
// with the *same* RtcMediaDataChannel instance for a given peer connection,
// since the channel is bidirectional.
//
// The sender listens on that same incomingMessages stream for cancel/error
// frames the *receiver* sends back (e.g. the user cancelled an incoming
// transfer, or a checksum mismatch), and stops sending on the next chunk
// once one arrives for an active transfer — see _handleIncoming above.
// Call dispose() when tearing down the chat screen / data channel to
// release that subscription.

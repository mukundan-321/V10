/// Backs [MediaTransferProgressStore] (outgoing/uploading transfers) with
/// the existing `MediaMetadata` Drift table. This file defines a small,
/// explicit [MediaMetadataOutgoingDao] contract rather than calling your
/// generated Drift classes directly, since generated table/column names
/// are project-specific — implement that contract against your actual
/// `MediaMetadata` table (one row per transfer, a handful of column
/// updates) and everything else here is complete.
library media_transfer_progress_store;

import 'chunked_file_sender.dart' show MediaTransferProgressStore;

abstract class MediaMetadataOutgoingDao {
  /// Inserts a new `MediaMetadata` row for a transfer this device is
  /// sending. `direction` should be persisted as outgoing/sent.
  Future<void> insertOutgoing({
    required String transferId,
    required String messageId,
    required String filename,
    required String mimeType,
    required int totalBytes,
    required int totalChunks,
  });

  Future<void> updateOutgoingProgress({
    required String transferId,
    required int bytesSent,
    required int chunksSent,
  });

  Future<void> markOutgoingCompleted({
    required String transferId,
    required String sha256Hex,
  });

  Future<void> markOutgoingFailed({
    required String transferId,
    required String reason,
  });

  Future<void> markOutgoingCancelled({required String transferId});
}

class DriftMediaTransferProgressStore implements MediaTransferProgressStore {
  const DriftMediaTransferProgressStore(this._dao);

  final MediaMetadataOutgoingDao _dao;

  @override
  Future<void> createTransfer({
    required String transferId,
    required String messageId,
    required String filename,
    required String mimeType,
    required int totalBytes,
    required int totalChunks,
  }) {
    return _dao.insertOutgoing(
      transferId: transferId,
      messageId: messageId,
      filename: filename,
      mimeType: mimeType,
      totalBytes: totalBytes,
      totalChunks: totalChunks,
    );
  }

  @override
  Future<void> updateProgress({
    required String transferId,
    required int bytesSent,
    required int chunksSent,
  }) {
    return _dao.updateOutgoingProgress(
      transferId: transferId,
      bytesSent: bytesSent,
      chunksSent: chunksSent,
    );
  }

  @override
  Future<void> markCompleted({
    required String transferId,
    required String sha256Hex,
  }) {
    return _dao.markOutgoingCompleted(
      transferId: transferId,
      sha256Hex: sha256Hex,
    );
  }

  @override
  Future<void> markFailed({
    required String transferId,
    required String reason,
  }) {
    return _dao.markOutgoingFailed(transferId: transferId, reason: reason);
  }

  @override
  Future<void> markCancelled({required String transferId}) {
    return _dao.markOutgoingCancelled(transferId: transferId);
  }
}

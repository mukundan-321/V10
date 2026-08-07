import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../media/data/chunked_file_receiver.dart';
import '../../media/data/media_transfer_progress_store.dart';

class MediaMetadataDao
    implements MediaMetadataOutgoingDao, MediaReceiveProgressStore {
  MediaMetadataDao(this.db);

  final AppDatabase db;

  // ---------------------------------------------------------------------------
  // OUTGOING
  // ---------------------------------------------------------------------------

  @override
  Future<void> insertOutgoing({
    required String transferId,
    required String messageId,
    required String filename,
    required String mimeType,
    required int totalBytes,
    required int totalChunks,
  }) {
    return db.into(db.mediaMetadataTable).insert(
          MediaMetadataTableCompanion.insert(
            id: transferId,
            messageId: Value(messageId),
            filename: Value(filename),
            localPath: '',
            mimeType: mimeType,
            sizeBytes: totalBytes,
            checksumSha256: '',
            transferState: 'sending',
            totalChunks: Value(totalChunks),
          ),
        );
  }

  @override
  Future<void> updateOutgoingProgress({
    required String transferId,
    required int bytesSent,
    required int chunksSent,
  }) {
    return (db.update(db.mediaMetadataTable)
          ..where((t) => t.id.equals(transferId)))
        .write(
      MediaMetadataTableCompanion(
        bytesTransferred: Value(bytesSent),
        chunksTransferred: Value(chunksSent),
      ),
    );
  }

  @override
  Future<void> markOutgoingCompleted({
    required String transferId,
    required String sha256Hex,
  }) {
    return (db.update(db.mediaMetadataTable)
          ..where((t) => t.id.equals(transferId)))
        .write(
      MediaMetadataTableCompanion(
        checksumSha256: Value(sha256Hex),
        transferState: const Value('completed'),
        transferProgress: const Value(1.0),
      ),
    );
  }

  @override
  Future<void> markOutgoingFailed({
    required String transferId,
    required String reason,
  }) {
    return (db.update(db.mediaMetadataTable)
          ..where((t) => t.id.equals(transferId)))
        .write(
      const MediaMetadataTableCompanion(
        transferState: Value('failed'),
      ),
    );
  }

  @override
  Future<void> markOutgoingCancelled({
    required String transferId,
  }) {
    return (db.update(db.mediaMetadataTable)
          ..where((t) => t.id.equals(transferId)))
        .write(
      const MediaMetadataTableCompanion(
        transferState: Value('cancelled'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INCOMING
  // ---------------------------------------------------------------------------

  @override
  Future<void> createIncomingTransfer({
    required String transferId,
    required String messageId,
    required String filename,
    required String mimeType,
    required int totalBytes,
    required int totalChunks,
    required String localPath,
    required Map<String, dynamic> extraMetadata,
  }) {
    return db.into(db.mediaMetadataTable).insert(
          MediaMetadataTableCompanion.insert(
            id: transferId,
            messageId: Value(messageId),
            filename: Value(filename),
            localPath: localPath,
            mimeType: mimeType,
            sizeBytes: totalBytes,
            checksumSha256: '',
            transferState: 'receiving',
            totalChunks: Value(totalChunks),
            widthPx: Value(extraMetadata['width'] as int?),
            heightPx: Value(extraMetadata['height'] as int?),
            durationMs: Value(extraMetadata['durationMs'] as int?),
          ),
        );
  }

  @override
  Future<void> updateProgress({
    required String transferId,
    required int bytesReceived,
    required int chunksReceived,
  }) {
    return (db.update(db.mediaMetadataTable)
          ..where((t) => t.id.equals(transferId)))
        .write(
      MediaMetadataTableCompanion(
        bytesTransferred: Value(bytesReceived),
        chunksTransferred: Value(chunksReceived),
      ),
    );
  }

  @override
  Future<void> markCompleted({
    required String transferId,
    required String localPath,
  }) {
    return (db.update(db.mediaMetadataTable)
          ..where((t) => t.id.equals(transferId)))
        .write(
      MediaMetadataTableCompanion(
        localPath: Value(localPath),
        transferState: const Value('completed'),
        transferProgress: const Value(1.0),
      ),
    );
  }

  @override
  Future<void> markFailed({
    required String transferId,
    required String reason,
  }) {
    return (db.update(db.mediaMetadataTable)
          ..where((t) => t.id.equals(transferId)))
        .write(
      const MediaMetadataTableCompanion(
        transferState: Value('failed'),
      ),
    );
  }

  @override
  Future<void> markCancelled({
    required String transferId,
  }) {
    return (db.update(db.mediaMetadataTable)
          ..where((t) => t.id.equals(transferId)))
        .write(
      const MediaMetadataTableCompanion(
        transferState: Value('cancelled'),
      ),
    );
  }
}
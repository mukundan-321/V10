import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'media_transfer_progress_store.dart';

class DriftMediaMetadataDao implements MediaMetadataOutgoingDao {
  DriftMediaMetadataDao(this.db);

  final AppDatabase db;

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
        transferredBytes: const Value(0),
        transferredChunks: const Value(0),
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
        transferredBytes: Value(bytesSent),
        transferredChunks: Value(chunksSent),
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
}

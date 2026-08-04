library media_receive_progress_store;

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'chunked_file_receiver.dart';

class DriftMediaReceiveProgressStore
    implements MediaReceiveProgressStore {
  DriftMediaReceiveProgressStore(this.db);

  final AppDatabase db;

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
        transferredBytes: const Value(0),
        transferredChunks: const Value(0),
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
        transferredBytes: Value(bytesReceived),
        transferredChunks: Value(chunksReceived),
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
        transferState: const Value('completed'),
        transferProgress: const Value(1.0),
        localPath: Value(localPath),
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

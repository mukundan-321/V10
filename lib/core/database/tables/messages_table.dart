import 'package:drift/drift.dart';

/// Messages are stored already-decrypted at rest, because the whole
/// database file is encrypted (SQLCipher) — there's no benefit to a
/// second layer of per-row encryption, and it would make search/edit
/// features far more painful for no real gain.
@TableIndex(name: 'messages_sent_at_idx', columns: {#sentAt})
class Messages extends Table {
  TextColumn get id => text()(); // UUID, generated on send/receive

  TextColumn get senderDeviceId => text()();

  TextColumn get content => text().nullable()(); // null if media-only

  // Deliberately NOT a SQL foreign key: this is a P2P app with no
  // guaranteed delivery order, so a reply can legitimately arrive
  // before the message it replies to has synced.
  TextColumn get replyToMessageId => text().nullable()();

  TextColumn get threadRootId => text().nullable()();

  BoolColumn get isEdited =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get editedAt => dateTime().nullable()();

  BoolColumn get isDeletedForMe =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isDeletedForBoth =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))();

  TextColumn get forwardedFromMessageId => text().nullable()();

  DateTimeColumn get sentAt => dateTime()();

  DateTimeColumn get deliveredAt => dateTime().nullable()();

  DateTimeColumn get readAt => dateTime().nullable()();

  // Links to MediaMetadataTable.id (transferId).
  TextColumn get mediaMetadataId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MediaMetadataRow')
class MediaMetadataTable extends Table {
  /// Transfer ID (UUID)
  TextColumn get id => text()();

  /// Chat message this media belongs to.
  TextColumn get messageId => text().nullable()();

  /// Original filename.
  TextColumn get filename => text().nullable()();

  /// Absolute local file path.
  TextColumn get localPath => text()();

  /// MIME type.
  TextColumn get mimeType => text()();

  /// Total file size in bytes.
  IntColumn get sizeBytes => integer()();

  /// SHA-256 checksum. Unknown until transfer completes.
  TextColumn get checksumSha256 => text().nullable()();

  /// pending / sending / receiving / completed / failed / cancelled
  TextColumn get transferState => text()();

  /// 0.0 → 1.0
  RealColumn get transferProgress =>
      real().withDefault(const Constant(0.0))();

  /// Bytes transferred so far.
  IntColumn get bytesTransferred =>
      integer().withDefault(const Constant(0))();

  /// Chunks transferred so far.
  IntColumn get chunksTransferred =>
      integer().withDefault(const Constant(0))();

  /// Total number of chunks.
  IntColumn get totalChunks =>
      integer().withDefault(const Constant(0))();

  /// Original quality flag.
  BoolColumn get isOriginalQuality =>
      boolean().withDefault(const Constant(true))();

  /// Image / video width.
  IntColumn get widthPx => integer().nullable()();

  /// Image / video height.
  IntColumn get heightPx => integer().nullable()();

  /// Audio / video duration.
  IntColumn get durationMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
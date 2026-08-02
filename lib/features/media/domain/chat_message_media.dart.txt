/// Media-specific data for a chat message. This is designed to be added
/// as a single additional field on the existing `ChatMessage` model —
/// `final MediaAttachment? media;`, defaulting to null — rather than
/// forking or replacing that model, so text messages (where `media` stays
/// null) are completely unaffected.
///
/// Integration (apply to your existing ChatMessage class):
///   1. Add the field: `final MediaAttachment? media;`
///   2. Add it as an optional named param (default null) to the
///      constructor, `copyWith`, `toJson`/`fromJson`, and the Drift row
///      mapper.
///   3. Include it in `==`/`hashCode` if ChatMessage implements those.
/// Every existing call site that constructs a text-only ChatMessage keeps
/// compiling unchanged since the field is optional and defaults to null.
library chat_message_media;

enum ChatMediaType { image, video, audio, document }

enum MediaTransferStatus {
  sending,
  receiving,
  completed,
  failed,
  cancelled,
}

class MediaAttachment {
  const MediaAttachment({
    required this.type,
    required this.transferId,
    required this.filename,
    required this.mimeType,
    required this.fileSize,
    required this.status,
    this.localPath,
    this.thumbnailPath,
    this.durationMs,
    this.width,
    this.height,
    this.bytesTransferred = 0,
    this.errorMessage,
  });

  final ChatMediaType type;
  final String transferId;
  final String filename;
  final String mimeType;
  final int fileSize;
  final MediaTransferStatus status;

  /// Null until the file exists locally (not yet received, or send hasn't
  /// been persisted to permanent storage yet).
  final String? localPath;

  /// Video thumbnails only.
  final String? thumbnailPath;

  /// Video and voice notes.
  final int? durationMs;

  /// Images and video.
  final int? width;
  final int? height;

  final int bytesTransferred;
  final String? errorMessage;

  double get progressFraction =>
      fileSize == 0 ? 0 : bytesTransferred / fileSize;

  MediaAttachment copyWith({
    MediaTransferStatus? status,
    String? localPath,
    int? bytesTransferred,
    String? errorMessage,
  }) {
    return MediaAttachment(
      type: type,
      transferId: transferId,
      filename: filename,
      mimeType: mimeType,
      fileSize: fileSize,
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      thumbnailPath: thumbnailPath,
      durationMs: durationMs,
      width: width,
      height: height,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'transferId': transferId,
        'filename': filename,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'status': status.name,
        'localPath': localPath,
        'thumbnailPath': thumbnailPath,
        'durationMs': durationMs,
        'width': width,
        'height': height,
        'bytesTransferred': bytesTransferred,
        'errorMessage': errorMessage,
      };

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      type: ChatMediaType.values.byName(json['type'] as String),
      transferId: json['transferId'] as String,
      filename: json['filename'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      status: MediaTransferStatus.values.byName(json['status'] as String),
      localPath: json['localPath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      durationMs: json['durationMs'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      bytesTransferred: json['bytesTransferred'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

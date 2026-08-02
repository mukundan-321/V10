import 'package:equatable/equatable.dart';

import '../chat_message_media.dart';

class ChatMessage extends Equatable {
  final String id;
  final String senderDeviceId;

  final String? content;
  final String? replyToMessageId;
  final String? threadRootId;

  final bool isEdited;
  final bool isPinned;
  final bool isDeletedForMe;
  final bool isDeletedForBoth;

  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  final String? mediaMetadataId;

  /// Null for normal text messages.
  final MediaAttachment? media;

  const ChatMessage({
    required this.id,
    required this.senderDeviceId,
    this.content,
    this.replyToMessageId,
    this.threadRootId,
    this.isEdited = false,
    this.isPinned = false,
    this.isDeletedForMe = false,
    this.isDeletedForBoth = false,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.mediaMetadataId,
    this.media,
  });

  bool get isMediaOnly =>
      content == null &&
      (media != null || mediaMetadataId != null);

  ChatMessage copyWith({
    String? content,
    bool? isEdited,
    bool? isPinned,
    bool? isDeletedForMe,
    bool? isDeletedForBoth,
    DateTime? deliveredAt,
    DateTime? readAt,
    MediaAttachment? media,
    bool clearMedia = false,
  }) {
    return ChatMessage(
      id: id,
      senderDeviceId: senderDeviceId,
      content: content ?? this.content,
      replyToMessageId: replyToMessageId,
      threadRootId: threadRootId,
      isEdited: isEdited ?? this.isEdited,
      isPinned: isPinned ?? this.isPinned,
      isDeletedForMe:
          isDeletedForMe ?? this.isDeletedForMe,
      isDeletedForBoth:
          isDeletedForBoth ?? this.isDeletedForBoth,
      sentAt: sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      mediaMetadataId: mediaMetadataId,
      media: clearMedia ? null : media ?? this.media,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderDeviceId,
        content,
        replyToMessageId,
        threadRootId,
        isEdited,
        isPinned,
        isDeletedForMe,
        isDeletedForBoth,
        sentAt,
        deliveredAt,
        readAt,
        mediaMetadataId,
        media,
      ];
}
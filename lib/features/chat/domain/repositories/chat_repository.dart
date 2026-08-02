import 'dart:io';

import 'package:two_person_app/core/utils/result.dart';
import 'package:two_person_app/features/chat/domain/entities/message.dart';

abstract class ChatRepository {
  /// -----------------------------
  /// Text Messages
  /// -----------------------------

  Future<Result<ChatMessage>> sendMessage({
    required String content,
    String? replyToMessageId,
  });

  /// -----------------------------
  /// Media Messages
  /// -----------------------------

  Future<Result<String>> sendImage({
    required File file,
    required int width,
    required int height,
  });

  Future<Result<String>> sendVideo({
    required File file,
    required int width,
    required int height,
    required int durationMs,
    File? thumbnail,
  });

  Future<Result<String>> sendDocument({
    required File file,
    required String filename,
  });

  Future<Result<String>> sendVoiceMessage({
    required File file,
    required int durationMs,
  });

  /// -----------------------------
  /// Message Actions
  /// -----------------------------

  Future<Result<void>> editMessage(
    String messageId,
    String newContent,
  );

  Future<Result<void>> deleteForMe(
    String messageId,
  );

  Future<Result<void>> deleteForBoth(
    String messageId,
  );

  Future<Result<void>> pinMessage(
    String messageId,
    bool pinned,
  );

  Future<Result<void>> addReaction(
    String messageId,
    String emoji,
  );

  /// -----------------------------
  /// Reading
  /// -----------------------------

  Stream<List<ChatMessage>> watchMessages({
    String? threadRootId,
  });

  Future<List<ChatMessage>> searchMessages(
    String query,
  );
}
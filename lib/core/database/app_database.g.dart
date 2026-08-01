// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderDeviceIdMeta =
      const VerificationMeta('senderDeviceId');
  @override
  late final GeneratedColumn<String> senderDeviceId = GeneratedColumn<String>(
      'sender_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _replyToMessageIdMeta =
      const VerificationMeta('replyToMessageId');
  @override
  late final GeneratedColumn<String> replyToMessageId = GeneratedColumn<String>(
      'reply_to_message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _threadRootIdMeta =
      const VerificationMeta('threadRootId');
  @override
  late final GeneratedColumn<String> threadRootId = GeneratedColumn<String>(
      'thread_root_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isEditedMeta =
      const VerificationMeta('isEdited');
  @override
  late final GeneratedColumn<bool> isEdited = GeneratedColumn<bool>(
      'is_edited', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_edited" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _editedAtMeta =
      const VerificationMeta('editedAt');
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
      'edited_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedForMeMeta =
      const VerificationMeta('isDeletedForMe');
  @override
  late final GeneratedColumn<bool> isDeletedForMe = GeneratedColumn<bool>(
      'is_deleted_for_me', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_deleted_for_me" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedForBothMeta =
      const VerificationMeta('isDeletedForBoth');
  @override
  late final GeneratedColumn<bool> isDeletedForBoth = GeneratedColumn<bool>(
      'is_deleted_for_both', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_deleted_for_both" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _forwardedFromMessageIdMeta =
      const VerificationMeta('forwardedFromMessageId');
  @override
  late final GeneratedColumn<String> forwardedFromMessageId =
      GeneratedColumn<String>('forwarded_from_message_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
      'sent_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deliveredAtMeta =
      const VerificationMeta('deliveredAt');
  @override
  late final GeneratedColumn<DateTime> deliveredAt = GeneratedColumn<DateTime>(
      'delivered_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
      'read_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _mediaMetadataIdMeta =
      const VerificationMeta('mediaMetadataId');
  @override
  late final GeneratedColumn<String> mediaMetadataId = GeneratedColumn<String>(
      'media_metadata_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        senderDeviceId,
        content,
        replyToMessageId,
        threadRootId,
        isEdited,
        editedAt,
        isDeletedForMe,
        isDeletedForBoth,
        isPinned,
        forwardedFromMessageId,
        sentAt,
        deliveredAt,
        readAt,
        mediaMetadataId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sender_device_id')) {
      context.handle(
          _senderDeviceIdMeta,
          senderDeviceId.isAcceptableOrUnknown(
              data['sender_device_id']!, _senderDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_senderDeviceIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('reply_to_message_id')) {
      context.handle(
          _replyToMessageIdMeta,
          replyToMessageId.isAcceptableOrUnknown(
              data['reply_to_message_id']!, _replyToMessageIdMeta));
    }
    if (data.containsKey('thread_root_id')) {
      context.handle(
          _threadRootIdMeta,
          threadRootId.isAcceptableOrUnknown(
              data['thread_root_id']!, _threadRootIdMeta));
    }
    if (data.containsKey('is_edited')) {
      context.handle(_isEditedMeta,
          isEdited.isAcceptableOrUnknown(data['is_edited']!, _isEditedMeta));
    }
    if (data.containsKey('edited_at')) {
      context.handle(_editedAtMeta,
          editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta));
    }
    if (data.containsKey('is_deleted_for_me')) {
      context.handle(
          _isDeletedForMeMeta,
          isDeletedForMe.isAcceptableOrUnknown(
              data['is_deleted_for_me']!, _isDeletedForMeMeta));
    }
    if (data.containsKey('is_deleted_for_both')) {
      context.handle(
          _isDeletedForBothMeta,
          isDeletedForBoth.isAcceptableOrUnknown(
              data['is_deleted_for_both']!, _isDeletedForBothMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('forwarded_from_message_id')) {
      context.handle(
          _forwardedFromMessageIdMeta,
          forwardedFromMessageId.isAcceptableOrUnknown(
              data['forwarded_from_message_id']!, _forwardedFromMessageIdMeta));
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta,
          sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
          _deliveredAtMeta,
          deliveredAt.isAcceptableOrUnknown(
              data['delivered_at']!, _deliveredAtMeta));
    }
    if (data.containsKey('read_at')) {
      context.handle(_readAtMeta,
          readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta));
    }
    if (data.containsKey('media_metadata_id')) {
      context.handle(
          _mediaMetadataIdMeta,
          mediaMetadataId.isAcceptableOrUnknown(
              data['media_metadata_id']!, _mediaMetadataIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      senderDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sender_device_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      replyToMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reply_to_message_id']),
      threadRootId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thread_root_id']),
      isEdited: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_edited'])!,
      editedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}edited_at']),
      isDeletedForMe: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_deleted_for_me'])!,
      isDeletedForBoth: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_deleted_for_both'])!,
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      forwardedFromMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}forwarded_from_message_id']),
      sentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}sent_at'])!,
      deliveredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}delivered_at']),
      readAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}read_at']),
      mediaMetadataId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}media_metadata_id']),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String senderDeviceId;
  final String? content;
  final String? replyToMessageId;
  final String? threadRootId;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeletedForMe;
  final bool isDeletedForBoth;
  final bool isPinned;
  final String? forwardedFromMessageId;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? mediaMetadataId;
  const Message(
      {required this.id,
      required this.senderDeviceId,
      this.content,
      this.replyToMessageId,
      this.threadRootId,
      required this.isEdited,
      this.editedAt,
      required this.isDeletedForMe,
      required this.isDeletedForBoth,
      required this.isPinned,
      this.forwardedFromMessageId,
      required this.sentAt,
      this.deliveredAt,
      this.readAt,
      this.mediaMetadataId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sender_device_id'] = Variable<String>(senderDeviceId);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || replyToMessageId != null) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId);
    }
    if (!nullToAbsent || threadRootId != null) {
      map['thread_root_id'] = Variable<String>(threadRootId);
    }
    map['is_edited'] = Variable<bool>(isEdited);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    map['is_deleted_for_me'] = Variable<bool>(isDeletedForMe);
    map['is_deleted_for_both'] = Variable<bool>(isDeletedForBoth);
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || forwardedFromMessageId != null) {
      map['forwarded_from_message_id'] =
          Variable<String>(forwardedFromMessageId);
    }
    map['sent_at'] = Variable<DateTime>(sentAt);
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt);
    }
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    if (!nullToAbsent || mediaMetadataId != null) {
      map['media_metadata_id'] = Variable<String>(mediaMetadataId);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      senderDeviceId: Value(senderDeviceId),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      replyToMessageId: replyToMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToMessageId),
      threadRootId: threadRootId == null && nullToAbsent
          ? const Value.absent()
          : Value(threadRootId),
      isEdited: Value(isEdited),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      isDeletedForMe: Value(isDeletedForMe),
      isDeletedForBoth: Value(isDeletedForBoth),
      isPinned: Value(isPinned),
      forwardedFromMessageId: forwardedFromMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(forwardedFromMessageId),
      sentAt: Value(sentAt),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
      readAt:
          readAt == null && nullToAbsent ? const Value.absent() : Value(readAt),
      mediaMetadataId: mediaMetadataId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaMetadataId),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      senderDeviceId: serializer.fromJson<String>(json['senderDeviceId']),
      content: serializer.fromJson<String?>(json['content']),
      replyToMessageId: serializer.fromJson<String?>(json['replyToMessageId']),
      threadRootId: serializer.fromJson<String?>(json['threadRootId']),
      isEdited: serializer.fromJson<bool>(json['isEdited']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      isDeletedForMe: serializer.fromJson<bool>(json['isDeletedForMe']),
      isDeletedForBoth: serializer.fromJson<bool>(json['isDeletedForBoth']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      forwardedFromMessageId:
          serializer.fromJson<String?>(json['forwardedFromMessageId']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      deliveredAt: serializer.fromJson<DateTime?>(json['deliveredAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      mediaMetadataId: serializer.fromJson<String?>(json['mediaMetadataId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'senderDeviceId': serializer.toJson<String>(senderDeviceId),
      'content': serializer.toJson<String?>(content),
      'replyToMessageId': serializer.toJson<String?>(replyToMessageId),
      'threadRootId': serializer.toJson<String?>(threadRootId),
      'isEdited': serializer.toJson<bool>(isEdited),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'isDeletedForMe': serializer.toJson<bool>(isDeletedForMe),
      'isDeletedForBoth': serializer.toJson<bool>(isDeletedForBoth),
      'isPinned': serializer.toJson<bool>(isPinned),
      'forwardedFromMessageId':
          serializer.toJson<String?>(forwardedFromMessageId),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'deliveredAt': serializer.toJson<DateTime?>(deliveredAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'mediaMetadataId': serializer.toJson<String?>(mediaMetadataId),
    };
  }

  Message copyWith(
          {String? id,
          String? senderDeviceId,
          Value<String?> content = const Value.absent(),
          Value<String?> replyToMessageId = const Value.absent(),
          Value<String?> threadRootId = const Value.absent(),
          bool? isEdited,
          Value<DateTime?> editedAt = const Value.absent(),
          bool? isDeletedForMe,
          bool? isDeletedForBoth,
          bool? isPinned,
          Value<String?> forwardedFromMessageId = const Value.absent(),
          DateTime? sentAt,
          Value<DateTime?> deliveredAt = const Value.absent(),
          Value<DateTime?> readAt = const Value.absent(),
          Value<String?> mediaMetadataId = const Value.absent()}) =>
      Message(
        id: id ?? this.id,
        senderDeviceId: senderDeviceId ?? this.senderDeviceId,
        content: content.present ? content.value : this.content,
        replyToMessageId: replyToMessageId.present
            ? replyToMessageId.value
            : this.replyToMessageId,
        threadRootId:
            threadRootId.present ? threadRootId.value : this.threadRootId,
        isEdited: isEdited ?? this.isEdited,
        editedAt: editedAt.present ? editedAt.value : this.editedAt,
        isDeletedForMe: isDeletedForMe ?? this.isDeletedForMe,
        isDeletedForBoth: isDeletedForBoth ?? this.isDeletedForBoth,
        isPinned: isPinned ?? this.isPinned,
        forwardedFromMessageId: forwardedFromMessageId.present
            ? forwardedFromMessageId.value
            : this.forwardedFromMessageId,
        sentAt: sentAt ?? this.sentAt,
        deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
        readAt: readAt.present ? readAt.value : this.readAt,
        mediaMetadataId: mediaMetadataId.present
            ? mediaMetadataId.value
            : this.mediaMetadataId,
      );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      senderDeviceId: data.senderDeviceId.present
          ? data.senderDeviceId.value
          : this.senderDeviceId,
      content: data.content.present ? data.content.value : this.content,
      replyToMessageId: data.replyToMessageId.present
          ? data.replyToMessageId.value
          : this.replyToMessageId,
      threadRootId: data.threadRootId.present
          ? data.threadRootId.value
          : this.threadRootId,
      isEdited: data.isEdited.present ? data.isEdited.value : this.isEdited,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      isDeletedForMe: data.isDeletedForMe.present
          ? data.isDeletedForMe.value
          : this.isDeletedForMe,
      isDeletedForBoth: data.isDeletedForBoth.present
          ? data.isDeletedForBoth.value
          : this.isDeletedForBoth,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      forwardedFromMessageId: data.forwardedFromMessageId.present
          ? data.forwardedFromMessageId.value
          : this.forwardedFromMessageId,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      deliveredAt:
          data.deliveredAt.present ? data.deliveredAt.value : this.deliveredAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      mediaMetadataId: data.mediaMetadataId.present
          ? data.mediaMetadataId.value
          : this.mediaMetadataId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('content: $content, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('threadRootId: $threadRootId, ')
          ..write('isEdited: $isEdited, ')
          ..write('editedAt: $editedAt, ')
          ..write('isDeletedForMe: $isDeletedForMe, ')
          ..write('isDeletedForBoth: $isDeletedForBoth, ')
          ..write('isPinned: $isPinned, ')
          ..write('forwardedFromMessageId: $forwardedFromMessageId, ')
          ..write('sentAt: $sentAt, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('readAt: $readAt, ')
          ..write('mediaMetadataId: $mediaMetadataId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      senderDeviceId,
      content,
      replyToMessageId,
      threadRootId,
      isEdited,
      editedAt,
      isDeletedForMe,
      isDeletedForBoth,
      isPinned,
      forwardedFromMessageId,
      sentAt,
      deliveredAt,
      readAt,
      mediaMetadataId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.senderDeviceId == this.senderDeviceId &&
          other.content == this.content &&
          other.replyToMessageId == this.replyToMessageId &&
          other.threadRootId == this.threadRootId &&
          other.isEdited == this.isEdited &&
          other.editedAt == this.editedAt &&
          other.isDeletedForMe == this.isDeletedForMe &&
          other.isDeletedForBoth == this.isDeletedForBoth &&
          other.isPinned == this.isPinned &&
          other.forwardedFromMessageId == this.forwardedFromMessageId &&
          other.sentAt == this.sentAt &&
          other.deliveredAt == this.deliveredAt &&
          other.readAt == this.readAt &&
          other.mediaMetadataId == this.mediaMetadataId);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> senderDeviceId;
  final Value<String?> content;
  final Value<String?> replyToMessageId;
  final Value<String?> threadRootId;
  final Value<bool> isEdited;
  final Value<DateTime?> editedAt;
  final Value<bool> isDeletedForMe;
  final Value<bool> isDeletedForBoth;
  final Value<bool> isPinned;
  final Value<String?> forwardedFromMessageId;
  final Value<DateTime> sentAt;
  final Value<DateTime?> deliveredAt;
  final Value<DateTime?> readAt;
  final Value<String?> mediaMetadataId;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.senderDeviceId = const Value.absent(),
    this.content = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.threadRootId = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.isDeletedForMe = const Value.absent(),
    this.isDeletedForBoth = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.forwardedFromMessageId = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.mediaMetadataId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String senderDeviceId,
    this.content = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.threadRootId = const Value.absent(),
    this.isEdited = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.isDeletedForMe = const Value.absent(),
    this.isDeletedForBoth = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.forwardedFromMessageId = const Value.absent(),
    required DateTime sentAt,
    this.deliveredAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.mediaMetadataId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        senderDeviceId = Value(senderDeviceId),
        sentAt = Value(sentAt);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? senderDeviceId,
    Expression<String>? content,
    Expression<String>? replyToMessageId,
    Expression<String>? threadRootId,
    Expression<bool>? isEdited,
    Expression<DateTime>? editedAt,
    Expression<bool>? isDeletedForMe,
    Expression<bool>? isDeletedForBoth,
    Expression<bool>? isPinned,
    Expression<String>? forwardedFromMessageId,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? deliveredAt,
    Expression<DateTime>? readAt,
    Expression<String>? mediaMetadataId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderDeviceId != null) 'sender_device_id': senderDeviceId,
      if (content != null) 'content': content,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (threadRootId != null) 'thread_root_id': threadRootId,
      if (isEdited != null) 'is_edited': isEdited,
      if (editedAt != null) 'edited_at': editedAt,
      if (isDeletedForMe != null) 'is_deleted_for_me': isDeletedForMe,
      if (isDeletedForBoth != null) 'is_deleted_for_both': isDeletedForBoth,
      if (isPinned != null) 'is_pinned': isPinned,
      if (forwardedFromMessageId != null)
        'forwarded_from_message_id': forwardedFromMessageId,
      if (sentAt != null) 'sent_at': sentAt,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (readAt != null) 'read_at': readAt,
      if (mediaMetadataId != null) 'media_metadata_id': mediaMetadataId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? senderDeviceId,
      Value<String?>? content,
      Value<String?>? replyToMessageId,
      Value<String?>? threadRootId,
      Value<bool>? isEdited,
      Value<DateTime?>? editedAt,
      Value<bool>? isDeletedForMe,
      Value<bool>? isDeletedForBoth,
      Value<bool>? isPinned,
      Value<String?>? forwardedFromMessageId,
      Value<DateTime>? sentAt,
      Value<DateTime?>? deliveredAt,
      Value<DateTime?>? readAt,
      Value<String?>? mediaMetadataId,
      Value<int>? rowid}) {
    return MessagesCompanion(
      id: id ?? this.id,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      content: content ?? this.content,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      threadRootId: threadRootId ?? this.threadRootId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeletedForMe: isDeletedForMe ?? this.isDeletedForMe,
      isDeletedForBoth: isDeletedForBoth ?? this.isDeletedForBoth,
      isPinned: isPinned ?? this.isPinned,
      forwardedFromMessageId:
          forwardedFromMessageId ?? this.forwardedFromMessageId,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      mediaMetadataId: mediaMetadataId ?? this.mediaMetadataId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (senderDeviceId.present) {
      map['sender_device_id'] = Variable<String>(senderDeviceId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (replyToMessageId.present) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId.value);
    }
    if (threadRootId.present) {
      map['thread_root_id'] = Variable<String>(threadRootId.value);
    }
    if (isEdited.present) {
      map['is_edited'] = Variable<bool>(isEdited.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (isDeletedForMe.present) {
      map['is_deleted_for_me'] = Variable<bool>(isDeletedForMe.value);
    }
    if (isDeletedForBoth.present) {
      map['is_deleted_for_both'] = Variable<bool>(isDeletedForBoth.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (forwardedFromMessageId.present) {
      map['forwarded_from_message_id'] =
          Variable<String>(forwardedFromMessageId.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (mediaMetadataId.present) {
      map['media_metadata_id'] = Variable<String>(mediaMetadataId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('content: $content, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('threadRootId: $threadRootId, ')
          ..write('isEdited: $isEdited, ')
          ..write('editedAt: $editedAt, ')
          ..write('isDeletedForMe: $isDeletedForMe, ')
          ..write('isDeletedForBoth: $isDeletedForBoth, ')
          ..write('isPinned: $isPinned, ')
          ..write('forwardedFromMessageId: $forwardedFromMessageId, ')
          ..write('sentAt: $sentAt, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('readAt: $readAt, ')
          ..write('mediaMetadataId: $mediaMetadataId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaMetadataTableTable extends MediaMetadataTable
    with TableInfo<$MediaMetadataTableTable, MediaMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaMetadataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _checksumSha256Meta =
      const VerificationMeta('checksumSha256');
  @override
  late final GeneratedColumn<String> checksumSha256 = GeneratedColumn<String>(
      'checksum_sha256', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transferStateMeta =
      const VerificationMeta('transferState');
  @override
  late final GeneratedColumn<String> transferState = GeneratedColumn<String>(
      'transfer_state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transferProgressMeta =
      const VerificationMeta('transferProgress');
  @override
  late final GeneratedColumn<double> transferProgress = GeneratedColumn<double>(
      'transfer_progress', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isOriginalQualityMeta =
      const VerificationMeta('isOriginalQuality');
  @override
  late final GeneratedColumn<bool> isOriginalQuality = GeneratedColumn<bool>(
      'is_original_quality', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_original_quality" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _widthPxMeta =
      const VerificationMeta('widthPx');
  @override
  late final GeneratedColumn<int> widthPx = GeneratedColumn<int>(
      'width_px', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightPxMeta =
      const VerificationMeta('heightPx');
  @override
  late final GeneratedColumn<int> heightPx = GeneratedColumn<int>(
      'height_px', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        localPath,
        mimeType,
        sizeBytes,
        checksumSha256,
        transferState,
        transferProgress,
        isOriginalQuality,
        widthPx,
        heightPx,
        durationMs
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_metadata_table';
  @override
  VerificationContext validateIntegrity(Insertable<MediaMetadataRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('checksum_sha256')) {
      context.handle(
          _checksumSha256Meta,
          checksumSha256.isAcceptableOrUnknown(
              data['checksum_sha256']!, _checksumSha256Meta));
    } else if (isInserting) {
      context.missing(_checksumSha256Meta);
    }
    if (data.containsKey('transfer_state')) {
      context.handle(
          _transferStateMeta,
          transferState.isAcceptableOrUnknown(
              data['transfer_state']!, _transferStateMeta));
    } else if (isInserting) {
      context.missing(_transferStateMeta);
    }
    if (data.containsKey('transfer_progress')) {
      context.handle(
          _transferProgressMeta,
          transferProgress.isAcceptableOrUnknown(
              data['transfer_progress']!, _transferProgressMeta));
    }
    if (data.containsKey('is_original_quality')) {
      context.handle(
          _isOriginalQualityMeta,
          isOriginalQuality.isAcceptableOrUnknown(
              data['is_original_quality']!, _isOriginalQualityMeta));
    }
    if (data.containsKey('width_px')) {
      context.handle(_widthPxMeta,
          widthPx.isAcceptableOrUnknown(data['width_px']!, _widthPxMeta));
    }
    if (data.containsKey('height_px')) {
      context.handle(_heightPxMeta,
          heightPx.isAcceptableOrUnknown(data['height_px']!, _heightPxMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaMetadataRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      checksumSha256: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}checksum_sha256'])!,
      transferState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transfer_state'])!,
      transferProgress: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}transfer_progress'])!,
      isOriginalQuality: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_original_quality'])!,
      widthPx: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width_px']),
      heightPx: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height_px']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
    );
  }

  @override
  $MediaMetadataTableTable createAlias(String alias) {
    return $MediaMetadataTableTable(attachedDatabase, alias);
  }
}

class MediaMetadataRow extends DataClass
    implements Insertable<MediaMetadataRow> {
  final String id;
  final String localPath;
  final String mimeType;
  final int sizeBytes;
  final String checksumSha256;
  final String transferState;
  final double transferProgress;
  final bool isOriginalQuality;
  final int? widthPx;
  final int? heightPx;
  final int? durationMs;
  const MediaMetadataRow(
      {required this.id,
      required this.localPath,
      required this.mimeType,
      required this.sizeBytes,
      required this.checksumSha256,
      required this.transferState,
      required this.transferProgress,
      required this.isOriginalQuality,
      this.widthPx,
      this.heightPx,
      this.durationMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_path'] = Variable<String>(localPath);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['checksum_sha256'] = Variable<String>(checksumSha256);
    map['transfer_state'] = Variable<String>(transferState);
    map['transfer_progress'] = Variable<double>(transferProgress);
    map['is_original_quality'] = Variable<bool>(isOriginalQuality);
    if (!nullToAbsent || widthPx != null) {
      map['width_px'] = Variable<int>(widthPx);
    }
    if (!nullToAbsent || heightPx != null) {
      map['height_px'] = Variable<int>(heightPx);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    return map;
  }

  MediaMetadataTableCompanion toCompanion(bool nullToAbsent) {
    return MediaMetadataTableCompanion(
      id: Value(id),
      localPath: Value(localPath),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      checksumSha256: Value(checksumSha256),
      transferState: Value(transferState),
      transferProgress: Value(transferProgress),
      isOriginalQuality: Value(isOriginalQuality),
      widthPx: widthPx == null && nullToAbsent
          ? const Value.absent()
          : Value(widthPx),
      heightPx: heightPx == null && nullToAbsent
          ? const Value.absent()
          : Value(heightPx),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
    );
  }

  factory MediaMetadataRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaMetadataRow(
      id: serializer.fromJson<String>(json['id']),
      localPath: serializer.fromJson<String>(json['localPath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      checksumSha256: serializer.fromJson<String>(json['checksumSha256']),
      transferState: serializer.fromJson<String>(json['transferState']),
      transferProgress: serializer.fromJson<double>(json['transferProgress']),
      isOriginalQuality: serializer.fromJson<bool>(json['isOriginalQuality']),
      widthPx: serializer.fromJson<int?>(json['widthPx']),
      heightPx: serializer.fromJson<int?>(json['heightPx']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localPath': serializer.toJson<String>(localPath),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'checksumSha256': serializer.toJson<String>(checksumSha256),
      'transferState': serializer.toJson<String>(transferState),
      'transferProgress': serializer.toJson<double>(transferProgress),
      'isOriginalQuality': serializer.toJson<bool>(isOriginalQuality),
      'widthPx': serializer.toJson<int?>(widthPx),
      'heightPx': serializer.toJson<int?>(heightPx),
      'durationMs': serializer.toJson<int?>(durationMs),
    };
  }

  MediaMetadataRow copyWith(
          {String? id,
          String? localPath,
          String? mimeType,
          int? sizeBytes,
          String? checksumSha256,
          String? transferState,
          double? transferProgress,
          bool? isOriginalQuality,
          Value<int?> widthPx = const Value.absent(),
          Value<int?> heightPx = const Value.absent(),
          Value<int?> durationMs = const Value.absent()}) =>
      MediaMetadataRow(
        id: id ?? this.id,
        localPath: localPath ?? this.localPath,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        checksumSha256: checksumSha256 ?? this.checksumSha256,
        transferState: transferState ?? this.transferState,
        transferProgress: transferProgress ?? this.transferProgress,
        isOriginalQuality: isOriginalQuality ?? this.isOriginalQuality,
        widthPx: widthPx.present ? widthPx.value : this.widthPx,
        heightPx: heightPx.present ? heightPx.value : this.heightPx,
        durationMs: durationMs.present ? durationMs.value : this.durationMs,
      );
  MediaMetadataRow copyWithCompanion(MediaMetadataTableCompanion data) {
    return MediaMetadataRow(
      id: data.id.present ? data.id.value : this.id,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      checksumSha256: data.checksumSha256.present
          ? data.checksumSha256.value
          : this.checksumSha256,
      transferState: data.transferState.present
          ? data.transferState.value
          : this.transferState,
      transferProgress: data.transferProgress.present
          ? data.transferProgress.value
          : this.transferProgress,
      isOriginalQuality: data.isOriginalQuality.present
          ? data.isOriginalQuality.value
          : this.isOriginalQuality,
      widthPx: data.widthPx.present ? data.widthPx.value : this.widthPx,
      heightPx: data.heightPx.present ? data.heightPx.value : this.heightPx,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaMetadataRow(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('checksumSha256: $checksumSha256, ')
          ..write('transferState: $transferState, ')
          ..write('transferProgress: $transferProgress, ')
          ..write('isOriginalQuality: $isOriginalQuality, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      localPath,
      mimeType,
      sizeBytes,
      checksumSha256,
      transferState,
      transferProgress,
      isOriginalQuality,
      widthPx,
      heightPx,
      durationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaMetadataRow &&
          other.id == this.id &&
          other.localPath == this.localPath &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.checksumSha256 == this.checksumSha256 &&
          other.transferState == this.transferState &&
          other.transferProgress == this.transferProgress &&
          other.isOriginalQuality == this.isOriginalQuality &&
          other.widthPx == this.widthPx &&
          other.heightPx == this.heightPx &&
          other.durationMs == this.durationMs);
}

class MediaMetadataTableCompanion extends UpdateCompanion<MediaMetadataRow> {
  final Value<String> id;
  final Value<String> localPath;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String> checksumSha256;
  final Value<String> transferState;
  final Value<double> transferProgress;
  final Value<bool> isOriginalQuality;
  final Value<int?> widthPx;
  final Value<int?> heightPx;
  final Value<int?> durationMs;
  final Value<int> rowid;
  const MediaMetadataTableCompanion({
    this.id = const Value.absent(),
    this.localPath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.checksumSha256 = const Value.absent(),
    this.transferState = const Value.absent(),
    this.transferProgress = const Value.absent(),
    this.isOriginalQuality = const Value.absent(),
    this.widthPx = const Value.absent(),
    this.heightPx = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaMetadataTableCompanion.insert({
    required String id,
    required String localPath,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
    required String transferState,
    this.transferProgress = const Value.absent(),
    this.isOriginalQuality = const Value.absent(),
    this.widthPx = const Value.absent(),
    this.heightPx = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        localPath = Value(localPath),
        mimeType = Value(mimeType),
        sizeBytes = Value(sizeBytes),
        checksumSha256 = Value(checksumSha256),
        transferState = Value(transferState);
  static Insertable<MediaMetadataRow> custom({
    Expression<String>? id,
    Expression<String>? localPath,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? checksumSha256,
    Expression<String>? transferState,
    Expression<double>? transferProgress,
    Expression<bool>? isOriginalQuality,
    Expression<int>? widthPx,
    Expression<int>? heightPx,
    Expression<int>? durationMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localPath != null) 'local_path': localPath,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (checksumSha256 != null) 'checksum_sha256': checksumSha256,
      if (transferState != null) 'transfer_state': transferState,
      if (transferProgress != null) 'transfer_progress': transferProgress,
      if (isOriginalQuality != null) 'is_original_quality': isOriginalQuality,
      if (widthPx != null) 'width_px': widthPx,
      if (heightPx != null) 'height_px': heightPx,
      if (durationMs != null) 'duration_ms': durationMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaMetadataTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? localPath,
      Value<String>? mimeType,
      Value<int>? sizeBytes,
      Value<String>? checksumSha256,
      Value<String>? transferState,
      Value<double>? transferProgress,
      Value<bool>? isOriginalQuality,
      Value<int?>? widthPx,
      Value<int?>? heightPx,
      Value<int?>? durationMs,
      Value<int>? rowid}) {
    return MediaMetadataTableCompanion(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      transferState: transferState ?? this.transferState,
      transferProgress: transferProgress ?? this.transferProgress,
      isOriginalQuality: isOriginalQuality ?? this.isOriginalQuality,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      durationMs: durationMs ?? this.durationMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (checksumSha256.present) {
      map['checksum_sha256'] = Variable<String>(checksumSha256.value);
    }
    if (transferState.present) {
      map['transfer_state'] = Variable<String>(transferState.value);
    }
    if (transferProgress.present) {
      map['transfer_progress'] = Variable<double>(transferProgress.value);
    }
    if (isOriginalQuality.present) {
      map['is_original_quality'] = Variable<bool>(isOriginalQuality.value);
    }
    if (widthPx.present) {
      map['width_px'] = Variable<int>(widthPx.value);
    }
    if (heightPx.present) {
      map['height_px'] = Variable<int>(heightPx.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaMetadataTableCompanion(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('checksumSha256: $checksumSha256, ')
          ..write('transferState: $transferState, ')
          ..write('transferProgress: $transferProgress, ')
          ..write('isOriginalQuality: $isOriginalQuality, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('durationMs: $durationMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReactionsTable extends Reactions
    with TableInfo<$ReactionsTable, Reaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetIdMeta =
      const VerificationMeta('targetId');
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
      'target_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetTypeMeta =
      const VerificationMeta('targetType');
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
      'target_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reactorDeviceIdMeta =
      const VerificationMeta('reactorDeviceId');
  @override
  late final GeneratedColumn<String> reactorDeviceId = GeneratedColumn<String>(
      'reactor_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reactedAtMeta =
      const VerificationMeta('reactedAt');
  @override
  late final GeneratedColumn<DateTime> reactedAt = GeneratedColumn<DateTime>(
      'reacted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, targetId, targetType, reactorDeviceId, emoji, reactedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reactions';
  @override
  VerificationContext validateIntegrity(Insertable<Reaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(_targetIdMeta,
          targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta));
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
          _targetTypeMeta,
          targetType.isAcceptableOrUnknown(
              data['target_type']!, _targetTypeMeta));
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('reactor_device_id')) {
      context.handle(
          _reactorDeviceIdMeta,
          reactorDeviceId.isAcceptableOrUnknown(
              data['reactor_device_id']!, _reactorDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_reactorDeviceIdMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('reacted_at')) {
      context.handle(_reactedAtMeta,
          reactedAt.isAcceptableOrUnknown(data['reacted_at']!, _reactedAtMeta));
    } else if (isInserting) {
      context.missing(_reactedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      targetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_id'])!,
      targetType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_type'])!,
      reactorDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reactor_device_id'])!,
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji'])!,
      reactedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reacted_at'])!,
    );
  }

  @override
  $ReactionsTable createAlias(String alias) {
    return $ReactionsTable(attachedDatabase, alias);
  }
}

class Reaction extends DataClass implements Insertable<Reaction> {
  final String id;
  final String targetId;
  final String targetType;
  final String reactorDeviceId;
  final String emoji;
  final DateTime reactedAt;
  const Reaction(
      {required this.id,
      required this.targetId,
      required this.targetType,
      required this.reactorDeviceId,
      required this.emoji,
      required this.reactedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_id'] = Variable<String>(targetId);
    map['target_type'] = Variable<String>(targetType);
    map['reactor_device_id'] = Variable<String>(reactorDeviceId);
    map['emoji'] = Variable<String>(emoji);
    map['reacted_at'] = Variable<DateTime>(reactedAt);
    return map;
  }

  ReactionsCompanion toCompanion(bool nullToAbsent) {
    return ReactionsCompanion(
      id: Value(id),
      targetId: Value(targetId),
      targetType: Value(targetType),
      reactorDeviceId: Value(reactorDeviceId),
      emoji: Value(emoji),
      reactedAt: Value(reactedAt),
    );
  }

  factory Reaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reaction(
      id: serializer.fromJson<String>(json['id']),
      targetId: serializer.fromJson<String>(json['targetId']),
      targetType: serializer.fromJson<String>(json['targetType']),
      reactorDeviceId: serializer.fromJson<String>(json['reactorDeviceId']),
      emoji: serializer.fromJson<String>(json['emoji']),
      reactedAt: serializer.fromJson<DateTime>(json['reactedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetId': serializer.toJson<String>(targetId),
      'targetType': serializer.toJson<String>(targetType),
      'reactorDeviceId': serializer.toJson<String>(reactorDeviceId),
      'emoji': serializer.toJson<String>(emoji),
      'reactedAt': serializer.toJson<DateTime>(reactedAt),
    };
  }

  Reaction copyWith(
          {String? id,
          String? targetId,
          String? targetType,
          String? reactorDeviceId,
          String? emoji,
          DateTime? reactedAt}) =>
      Reaction(
        id: id ?? this.id,
        targetId: targetId ?? this.targetId,
        targetType: targetType ?? this.targetType,
        reactorDeviceId: reactorDeviceId ?? this.reactorDeviceId,
        emoji: emoji ?? this.emoji,
        reactedAt: reactedAt ?? this.reactedAt,
      );
  Reaction copyWithCompanion(ReactionsCompanion data) {
    return Reaction(
      id: data.id.present ? data.id.value : this.id,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      targetType:
          data.targetType.present ? data.targetType.value : this.targetType,
      reactorDeviceId: data.reactorDeviceId.present
          ? data.reactorDeviceId.value
          : this.reactorDeviceId,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      reactedAt: data.reactedAt.present ? data.reactedAt.value : this.reactedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reaction(')
          ..write('id: $id, ')
          ..write('targetId: $targetId, ')
          ..write('targetType: $targetType, ')
          ..write('reactorDeviceId: $reactorDeviceId, ')
          ..write('emoji: $emoji, ')
          ..write('reactedAt: $reactedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, targetId, targetType, reactorDeviceId, emoji, reactedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reaction &&
          other.id == this.id &&
          other.targetId == this.targetId &&
          other.targetType == this.targetType &&
          other.reactorDeviceId == this.reactorDeviceId &&
          other.emoji == this.emoji &&
          other.reactedAt == this.reactedAt);
}

class ReactionsCompanion extends UpdateCompanion<Reaction> {
  final Value<String> id;
  final Value<String> targetId;
  final Value<String> targetType;
  final Value<String> reactorDeviceId;
  final Value<String> emoji;
  final Value<DateTime> reactedAt;
  final Value<int> rowid;
  const ReactionsCompanion({
    this.id = const Value.absent(),
    this.targetId = const Value.absent(),
    this.targetType = const Value.absent(),
    this.reactorDeviceId = const Value.absent(),
    this.emoji = const Value.absent(),
    this.reactedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReactionsCompanion.insert({
    required String id,
    required String targetId,
    required String targetType,
    required String reactorDeviceId,
    required String emoji,
    required DateTime reactedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        targetId = Value(targetId),
        targetType = Value(targetType),
        reactorDeviceId = Value(reactorDeviceId),
        emoji = Value(emoji),
        reactedAt = Value(reactedAt);
  static Insertable<Reaction> custom({
    Expression<String>? id,
    Expression<String>? targetId,
    Expression<String>? targetType,
    Expression<String>? reactorDeviceId,
    Expression<String>? emoji,
    Expression<DateTime>? reactedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetId != null) 'target_id': targetId,
      if (targetType != null) 'target_type': targetType,
      if (reactorDeviceId != null) 'reactor_device_id': reactorDeviceId,
      if (emoji != null) 'emoji': emoji,
      if (reactedAt != null) 'reacted_at': reactedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? targetId,
      Value<String>? targetType,
      Value<String>? reactorDeviceId,
      Value<String>? emoji,
      Value<DateTime>? reactedAt,
      Value<int>? rowid}) {
    return ReactionsCompanion(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      reactorDeviceId: reactorDeviceId ?? this.reactorDeviceId,
      emoji: emoji ?? this.emoji,
      reactedAt: reactedAt ?? this.reactedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (reactorDeviceId.present) {
      map['reactor_device_id'] = Variable<String>(reactorDeviceId.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (reactedAt.present) {
      map['reacted_at'] = Variable<DateTime>(reactedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReactionsCompanion(')
          ..write('id: $id, ')
          ..write('targetId: $targetId, ')
          ..write('targetType: $targetType, ')
          ..write('reactorDeviceId: $reactorDeviceId, ')
          ..write('emoji: $emoji, ')
          ..write('reactedAt: $reactedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyRecordsTable extends KeyRecords
    with TableInfo<$KeyRecordsTable, KeyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyTypeMeta =
      const VerificationMeta('keyType');
  @override
  late final GeneratedColumn<String> keyType = GeneratedColumn<String>(
      'key_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _publicKeyBase64Meta =
      const VerificationMeta('publicKeyBase64');
  @override
  late final GeneratedColumn<String> publicKeyBase64 = GeneratedColumn<String>(
      'public_key_base64', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fingerprintMeta =
      const VerificationMeta('fingerprint');
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
      'fingerprint', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fingerprintVerifiedByUserMeta =
      const VerificationMeta('fingerprintVerifiedByUser');
  @override
  late final GeneratedColumn<bool> fingerprintVerifiedByUser =
      GeneratedColumn<bool>('fingerprint_verified_by_user', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("fingerprint_verified_by_user" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _rotatedAtMeta =
      const VerificationMeta('rotatedAt');
  @override
  late final GeneratedColumn<DateTime> rotatedAt = GeneratedColumn<DateTime>(
      'rotated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        keyType,
        publicKeyBase64,
        fingerprint,
        fingerprintVerifiedByUser,
        createdAt,
        rotatedAt,
        expiresAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_records';
  @override
  VerificationContext validateIntegrity(Insertable<KeyRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('key_type')) {
      context.handle(_keyTypeMeta,
          keyType.isAcceptableOrUnknown(data['key_type']!, _keyTypeMeta));
    } else if (isInserting) {
      context.missing(_keyTypeMeta);
    }
    if (data.containsKey('public_key_base64')) {
      context.handle(
          _publicKeyBase64Meta,
          publicKeyBase64.isAcceptableOrUnknown(
              data['public_key_base64']!, _publicKeyBase64Meta));
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
          _fingerprintMeta,
          fingerprint.isAcceptableOrUnknown(
              data['fingerprint']!, _fingerprintMeta));
    }
    if (data.containsKey('fingerprint_verified_by_user')) {
      context.handle(
          _fingerprintVerifiedByUserMeta,
          fingerprintVerifiedByUser.isAcceptableOrUnknown(
              data['fingerprint_verified_by_user']!,
              _fingerprintVerifiedByUserMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('rotated_at')) {
      context.handle(_rotatedAtMeta,
          rotatedAt.isAcceptableOrUnknown(data['rotated_at']!, _rotatedAtMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KeyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      keyType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_type'])!,
      publicKeyBase64: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}public_key_base64']),
      fingerprint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fingerprint']),
      fingerprintVerifiedByUser: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}fingerprint_verified_by_user'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      rotatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}rotated_at']),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
    );
  }

  @override
  $KeyRecordsTable createAlias(String alias) {
    return $KeyRecordsTable(attachedDatabase, alias);
  }
}

class KeyRecord extends DataClass implements Insertable<KeyRecord> {
  final String id;
  final String keyType;
  final String? publicKeyBase64;
  final String? fingerprint;
  final bool fingerprintVerifiedByUser;
  final DateTime createdAt;
  final DateTime? rotatedAt;
  final DateTime? expiresAt;
  const KeyRecord(
      {required this.id,
      required this.keyType,
      this.publicKeyBase64,
      this.fingerprint,
      required this.fingerprintVerifiedByUser,
      required this.createdAt,
      this.rotatedAt,
      this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['key_type'] = Variable<String>(keyType);
    if (!nullToAbsent || publicKeyBase64 != null) {
      map['public_key_base64'] = Variable<String>(publicKeyBase64);
    }
    if (!nullToAbsent || fingerprint != null) {
      map['fingerprint'] = Variable<String>(fingerprint);
    }
    map['fingerprint_verified_by_user'] =
        Variable<bool>(fingerprintVerifiedByUser);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || rotatedAt != null) {
      map['rotated_at'] = Variable<DateTime>(rotatedAt);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    return map;
  }

  KeyRecordsCompanion toCompanion(bool nullToAbsent) {
    return KeyRecordsCompanion(
      id: Value(id),
      keyType: Value(keyType),
      publicKeyBase64: publicKeyBase64 == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKeyBase64),
      fingerprint: fingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(fingerprint),
      fingerprintVerifiedByUser: Value(fingerprintVerifiedByUser),
      createdAt: Value(createdAt),
      rotatedAt: rotatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(rotatedAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory KeyRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyRecord(
      id: serializer.fromJson<String>(json['id']),
      keyType: serializer.fromJson<String>(json['keyType']),
      publicKeyBase64: serializer.fromJson<String?>(json['publicKeyBase64']),
      fingerprint: serializer.fromJson<String?>(json['fingerprint']),
      fingerprintVerifiedByUser:
          serializer.fromJson<bool>(json['fingerprintVerifiedByUser']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      rotatedAt: serializer.fromJson<DateTime?>(json['rotatedAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'keyType': serializer.toJson<String>(keyType),
      'publicKeyBase64': serializer.toJson<String?>(publicKeyBase64),
      'fingerprint': serializer.toJson<String?>(fingerprint),
      'fingerprintVerifiedByUser':
          serializer.toJson<bool>(fingerprintVerifiedByUser),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'rotatedAt': serializer.toJson<DateTime?>(rotatedAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
    };
  }

  KeyRecord copyWith(
          {String? id,
          String? keyType,
          Value<String?> publicKeyBase64 = const Value.absent(),
          Value<String?> fingerprint = const Value.absent(),
          bool? fingerprintVerifiedByUser,
          DateTime? createdAt,
          Value<DateTime?> rotatedAt = const Value.absent(),
          Value<DateTime?> expiresAt = const Value.absent()}) =>
      KeyRecord(
        id: id ?? this.id,
        keyType: keyType ?? this.keyType,
        publicKeyBase64: publicKeyBase64.present
            ? publicKeyBase64.value
            : this.publicKeyBase64,
        fingerprint: fingerprint.present ? fingerprint.value : this.fingerprint,
        fingerprintVerifiedByUser:
            fingerprintVerifiedByUser ?? this.fingerprintVerifiedByUser,
        createdAt: createdAt ?? this.createdAt,
        rotatedAt: rotatedAt.present ? rotatedAt.value : this.rotatedAt,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
      );
  KeyRecord copyWithCompanion(KeyRecordsCompanion data) {
    return KeyRecord(
      id: data.id.present ? data.id.value : this.id,
      keyType: data.keyType.present ? data.keyType.value : this.keyType,
      publicKeyBase64: data.publicKeyBase64.present
          ? data.publicKeyBase64.value
          : this.publicKeyBase64,
      fingerprint:
          data.fingerprint.present ? data.fingerprint.value : this.fingerprint,
      fingerprintVerifiedByUser: data.fingerprintVerifiedByUser.present
          ? data.fingerprintVerifiedByUser.value
          : this.fingerprintVerifiedByUser,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      rotatedAt: data.rotatedAt.present ? data.rotatedAt.value : this.rotatedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyRecord(')
          ..write('id: $id, ')
          ..write('keyType: $keyType, ')
          ..write('publicKeyBase64: $publicKeyBase64, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('fingerprintVerifiedByUser: $fingerprintVerifiedByUser, ')
          ..write('createdAt: $createdAt, ')
          ..write('rotatedAt: $rotatedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyType, publicKeyBase64, fingerprint,
      fingerprintVerifiedByUser, createdAt, rotatedAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyRecord &&
          other.id == this.id &&
          other.keyType == this.keyType &&
          other.publicKeyBase64 == this.publicKeyBase64 &&
          other.fingerprint == this.fingerprint &&
          other.fingerprintVerifiedByUser == this.fingerprintVerifiedByUser &&
          other.createdAt == this.createdAt &&
          other.rotatedAt == this.rotatedAt &&
          other.expiresAt == this.expiresAt);
}

class KeyRecordsCompanion extends UpdateCompanion<KeyRecord> {
  final Value<String> id;
  final Value<String> keyType;
  final Value<String?> publicKeyBase64;
  final Value<String?> fingerprint;
  final Value<bool> fingerprintVerifiedByUser;
  final Value<DateTime> createdAt;
  final Value<DateTime?> rotatedAt;
  final Value<DateTime?> expiresAt;
  final Value<int> rowid;
  const KeyRecordsCompanion({
    this.id = const Value.absent(),
    this.keyType = const Value.absent(),
    this.publicKeyBase64 = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.fingerprintVerifiedByUser = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rotatedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyRecordsCompanion.insert({
    required String id,
    required String keyType,
    this.publicKeyBase64 = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.fingerprintVerifiedByUser = const Value.absent(),
    required DateTime createdAt,
    this.rotatedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        keyType = Value(keyType),
        createdAt = Value(createdAt);
  static Insertable<KeyRecord> custom({
    Expression<String>? id,
    Expression<String>? keyType,
    Expression<String>? publicKeyBase64,
    Expression<String>? fingerprint,
    Expression<bool>? fingerprintVerifiedByUser,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? rotatedAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyType != null) 'key_type': keyType,
      if (publicKeyBase64 != null) 'public_key_base64': publicKeyBase64,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (fingerprintVerifiedByUser != null)
        'fingerprint_verified_by_user': fingerprintVerifiedByUser,
      if (createdAt != null) 'created_at': createdAt,
      if (rotatedAt != null) 'rotated_at': rotatedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? keyType,
      Value<String?>? publicKeyBase64,
      Value<String?>? fingerprint,
      Value<bool>? fingerprintVerifiedByUser,
      Value<DateTime>? createdAt,
      Value<DateTime?>? rotatedAt,
      Value<DateTime?>? expiresAt,
      Value<int>? rowid}) {
    return KeyRecordsCompanion(
      id: id ?? this.id,
      keyType: keyType ?? this.keyType,
      publicKeyBase64: publicKeyBase64 ?? this.publicKeyBase64,
      fingerprint: fingerprint ?? this.fingerprint,
      fingerprintVerifiedByUser:
          fingerprintVerifiedByUser ?? this.fingerprintVerifiedByUser,
      createdAt: createdAt ?? this.createdAt,
      rotatedAt: rotatedAt ?? this.rotatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (keyType.present) {
      map['key_type'] = Variable<String>(keyType.value);
    }
    if (publicKeyBase64.present) {
      map['public_key_base64'] = Variable<String>(publicKeyBase64.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (fingerprintVerifiedByUser.present) {
      map['fingerprint_verified_by_user'] =
          Variable<bool>(fingerprintVerifiedByUser.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rotatedAt.present) {
      map['rotated_at'] = Variable<DateTime>(rotatedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyRecordsCompanion(')
          ..write('id: $id, ')
          ..write('keyType: $keyType, ')
          ..write('publicKeyBase64: $publicKeyBase64, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('fingerprintVerifiedByUser: $fingerprintVerifiedByUser, ')
          ..write('createdAt: $createdAt, ')
          ..write('rotatedAt: $rotatedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) => Setting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MediaMetadataTableTable mediaMetadataTable =
      $MediaMetadataTableTable(this);
  late final $ReactionsTable reactions = $ReactionsTable(this);
  late final $KeyRecordsTable keyRecords = $KeyRecordsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index messagesSentAtIdx = Index('messages_sent_at_idx',
      'CREATE INDEX messages_sent_at_idx ON messages (sent_at)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        messages,
        mediaMetadataTable,
        reactions,
        keyRecords,
        settings,
        messagesSentAtIdx
      ];
}

typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String id,
  required String senderDeviceId,
  Value<String?> content,
  Value<String?> replyToMessageId,
  Value<String?> threadRootId,
  Value<bool> isEdited,
  Value<DateTime?> editedAt,
  Value<bool> isDeletedForMe,
  Value<bool> isDeletedForBoth,
  Value<bool> isPinned,
  Value<String?> forwardedFromMessageId,
  required DateTime sentAt,
  Value<DateTime?> deliveredAt,
  Value<DateTime?> readAt,
  Value<String?> mediaMetadataId,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> id,
  Value<String> senderDeviceId,
  Value<String?> content,
  Value<String?> replyToMessageId,
  Value<String?> threadRootId,
  Value<bool> isEdited,
  Value<DateTime?> editedAt,
  Value<bool> isDeletedForMe,
  Value<bool> isDeletedForBoth,
  Value<bool> isPinned,
  Value<String?> forwardedFromMessageId,
  Value<DateTime> sentAt,
  Value<DateTime?> deliveredAt,
  Value<DateTime?> readAt,
  Value<String?> mediaMetadataId,
  Value<int> rowid,
});

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderDeviceId => $composableBuilder(
      column: $table.senderDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get replyToMessageId => $composableBuilder(
      column: $table.replyToMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get threadRootId => $composableBuilder(
      column: $table.threadRootId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEdited => $composableBuilder(
      column: $table.isEdited, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get editedAt => $composableBuilder(
      column: $table.editedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeletedForMe => $composableBuilder(
      column: $table.isDeletedForMe,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeletedForBoth => $composableBuilder(
      column: $table.isDeletedForBoth,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get forwardedFromMessageId => $composableBuilder(
      column: $table.forwardedFromMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deliveredAt => $composableBuilder(
      column: $table.deliveredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get readAt => $composableBuilder(
      column: $table.readAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaMetadataId => $composableBuilder(
      column: $table.mediaMetadataId,
      builder: (column) => ColumnFilters(column));
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderDeviceId => $composableBuilder(
      column: $table.senderDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get replyToMessageId => $composableBuilder(
      column: $table.replyToMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get threadRootId => $composableBuilder(
      column: $table.threadRootId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEdited => $composableBuilder(
      column: $table.isEdited, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get editedAt => $composableBuilder(
      column: $table.editedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeletedForMe => $composableBuilder(
      column: $table.isDeletedForMe,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeletedForBoth => $composableBuilder(
      column: $table.isDeletedForBoth,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get forwardedFromMessageId => $composableBuilder(
      column: $table.forwardedFromMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deliveredAt => $composableBuilder(
      column: $table.deliveredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
      column: $table.readAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaMetadataId => $composableBuilder(
      column: $table.mediaMetadataId,
      builder: (column) => ColumnOrderings(column));
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get senderDeviceId => $composableBuilder(
      column: $table.senderDeviceId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get replyToMessageId => $composableBuilder(
      column: $table.replyToMessageId, builder: (column) => column);

  GeneratedColumn<String> get threadRootId => $composableBuilder(
      column: $table.threadRootId, builder: (column) => column);

  GeneratedColumn<bool> get isEdited =>
      $composableBuilder(column: $table.isEdited, builder: (column) => column);

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeletedForMe => $composableBuilder(
      column: $table.isDeletedForMe, builder: (column) => column);

  GeneratedColumn<bool> get isDeletedForBoth => $composableBuilder(
      column: $table.isDeletedForBoth, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<String> get forwardedFromMessageId => $composableBuilder(
      column: $table.forwardedFromMessageId, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deliveredAt => $composableBuilder(
      column: $table.deliveredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<String> get mediaMetadataId => $composableBuilder(
      column: $table.mediaMetadataId, builder: (column) => column);
}

class $$MessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()> {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> senderDeviceId = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String?> replyToMessageId = const Value.absent(),
            Value<String?> threadRootId = const Value.absent(),
            Value<bool> isEdited = const Value.absent(),
            Value<DateTime?> editedAt = const Value.absent(),
            Value<bool> isDeletedForMe = const Value.absent(),
            Value<bool> isDeletedForBoth = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<String?> forwardedFromMessageId = const Value.absent(),
            Value<DateTime> sentAt = const Value.absent(),
            Value<DateTime?> deliveredAt = const Value.absent(),
            Value<DateTime?> readAt = const Value.absent(),
            Value<String?> mediaMetadataId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion(
            id: id,
            senderDeviceId: senderDeviceId,
            content: content,
            replyToMessageId: replyToMessageId,
            threadRootId: threadRootId,
            isEdited: isEdited,
            editedAt: editedAt,
            isDeletedForMe: isDeletedForMe,
            isDeletedForBoth: isDeletedForBoth,
            isPinned: isPinned,
            forwardedFromMessageId: forwardedFromMessageId,
            sentAt: sentAt,
            deliveredAt: deliveredAt,
            readAt: readAt,
            mediaMetadataId: mediaMetadataId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String senderDeviceId,
            Value<String?> content = const Value.absent(),
            Value<String?> replyToMessageId = const Value.absent(),
            Value<String?> threadRootId = const Value.absent(),
            Value<bool> isEdited = const Value.absent(),
            Value<DateTime?> editedAt = const Value.absent(),
            Value<bool> isDeletedForMe = const Value.absent(),
            Value<bool> isDeletedForBoth = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<String?> forwardedFromMessageId = const Value.absent(),
            required DateTime sentAt,
            Value<DateTime?> deliveredAt = const Value.absent(),
            Value<DateTime?> readAt = const Value.absent(),
            Value<String?> mediaMetadataId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            id: id,
            senderDeviceId: senderDeviceId,
            content: content,
            replyToMessageId: replyToMessageId,
            threadRootId: threadRootId,
            isEdited: isEdited,
            editedAt: editedAt,
            isDeletedForMe: isDeletedForMe,
            isDeletedForBoth: isDeletedForBoth,
            isPinned: isPinned,
            forwardedFromMessageId: forwardedFromMessageId,
            sentAt: sentAt,
            deliveredAt: deliveredAt,
            readAt: readAt,
            mediaMetadataId: mediaMetadataId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
    Message,
    PrefetchHooks Function()>;
typedef $$MediaMetadataTableTableCreateCompanionBuilder
    = MediaMetadataTableCompanion Function({
  required String id,
  required String localPath,
  required String mimeType,
  required int sizeBytes,
  required String checksumSha256,
  required String transferState,
  Value<double> transferProgress,
  Value<bool> isOriginalQuality,
  Value<int?> widthPx,
  Value<int?> heightPx,
  Value<int?> durationMs,
  Value<int> rowid,
});
typedef $$MediaMetadataTableTableUpdateCompanionBuilder
    = MediaMetadataTableCompanion Function({
  Value<String> id,
  Value<String> localPath,
  Value<String> mimeType,
  Value<int> sizeBytes,
  Value<String> checksumSha256,
  Value<String> transferState,
  Value<double> transferProgress,
  Value<bool> isOriginalQuality,
  Value<int?> widthPx,
  Value<int?> heightPx,
  Value<int?> durationMs,
  Value<int> rowid,
});

class $$MediaMetadataTableTableFilterComposer
    extends Composer<_$AppDatabase, $MediaMetadataTableTable> {
  $$MediaMetadataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checksumSha256 => $composableBuilder(
      column: $table.checksumSha256,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transferState => $composableBuilder(
      column: $table.transferState, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get transferProgress => $composableBuilder(
      column: $table.transferProgress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOriginalQuality => $composableBuilder(
      column: $table.isOriginalQuality,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get widthPx => $composableBuilder(
      column: $table.widthPx, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get heightPx => $composableBuilder(
      column: $table.heightPx, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));
}

class $$MediaMetadataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaMetadataTableTable> {
  $$MediaMetadataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checksumSha256 => $composableBuilder(
      column: $table.checksumSha256,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transferState => $composableBuilder(
      column: $table.transferState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get transferProgress => $composableBuilder(
      column: $table.transferProgress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOriginalQuality => $composableBuilder(
      column: $table.isOriginalQuality,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get widthPx => $composableBuilder(
      column: $table.widthPx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get heightPx => $composableBuilder(
      column: $table.heightPx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));
}

class $$MediaMetadataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaMetadataTableTable> {
  $$MediaMetadataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get checksumSha256 => $composableBuilder(
      column: $table.checksumSha256, builder: (column) => column);

  GeneratedColumn<String> get transferState => $composableBuilder(
      column: $table.transferState, builder: (column) => column);

  GeneratedColumn<double> get transferProgress => $composableBuilder(
      column: $table.transferProgress, builder: (column) => column);

  GeneratedColumn<bool> get isOriginalQuality => $composableBuilder(
      column: $table.isOriginalQuality, builder: (column) => column);

  GeneratedColumn<int> get widthPx =>
      $composableBuilder(column: $table.widthPx, builder: (column) => column);

  GeneratedColumn<int> get heightPx =>
      $composableBuilder(column: $table.heightPx, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);
}

class $$MediaMetadataTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaMetadataTableTable,
    MediaMetadataRow,
    $$MediaMetadataTableTableFilterComposer,
    $$MediaMetadataTableTableOrderingComposer,
    $$MediaMetadataTableTableAnnotationComposer,
    $$MediaMetadataTableTableCreateCompanionBuilder,
    $$MediaMetadataTableTableUpdateCompanionBuilder,
    (
      MediaMetadataRow,
      BaseReferences<_$AppDatabase, $MediaMetadataTableTable, MediaMetadataRow>
    ),
    MediaMetadataRow,
    PrefetchHooks Function()> {
  $$MediaMetadataTableTableTableManager(
      _$AppDatabase db, $MediaMetadataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaMetadataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaMetadataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaMetadataTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<String> checksumSha256 = const Value.absent(),
            Value<String> transferState = const Value.absent(),
            Value<double> transferProgress = const Value.absent(),
            Value<bool> isOriginalQuality = const Value.absent(),
            Value<int?> widthPx = const Value.absent(),
            Value<int?> heightPx = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaMetadataTableCompanion(
            id: id,
            localPath: localPath,
            mimeType: mimeType,
            sizeBytes: sizeBytes,
            checksumSha256: checksumSha256,
            transferState: transferState,
            transferProgress: transferProgress,
            isOriginalQuality: isOriginalQuality,
            widthPx: widthPx,
            heightPx: heightPx,
            durationMs: durationMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String localPath,
            required String mimeType,
            required int sizeBytes,
            required String checksumSha256,
            required String transferState,
            Value<double> transferProgress = const Value.absent(),
            Value<bool> isOriginalQuality = const Value.absent(),
            Value<int?> widthPx = const Value.absent(),
            Value<int?> heightPx = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaMetadataTableCompanion.insert(
            id: id,
            localPath: localPath,
            mimeType: mimeType,
            sizeBytes: sizeBytes,
            checksumSha256: checksumSha256,
            transferState: transferState,
            transferProgress: transferProgress,
            isOriginalQuality: isOriginalQuality,
            widthPx: widthPx,
            heightPx: heightPx,
            durationMs: durationMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaMetadataTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaMetadataTableTable,
    MediaMetadataRow,
    $$MediaMetadataTableTableFilterComposer,
    $$MediaMetadataTableTableOrderingComposer,
    $$MediaMetadataTableTableAnnotationComposer,
    $$MediaMetadataTableTableCreateCompanionBuilder,
    $$MediaMetadataTableTableUpdateCompanionBuilder,
    (
      MediaMetadataRow,
      BaseReferences<_$AppDatabase, $MediaMetadataTableTable, MediaMetadataRow>
    ),
    MediaMetadataRow,
    PrefetchHooks Function()>;
typedef $$ReactionsTableCreateCompanionBuilder = ReactionsCompanion Function({
  required String id,
  required String targetId,
  required String targetType,
  required String reactorDeviceId,
  required String emoji,
  required DateTime reactedAt,
  Value<int> rowid,
});
typedef $$ReactionsTableUpdateCompanionBuilder = ReactionsCompanion Function({
  Value<String> id,
  Value<String> targetId,
  Value<String> targetType,
  Value<String> reactorDeviceId,
  Value<String> emoji,
  Value<DateTime> reactedAt,
  Value<int> rowid,
});

class $$ReactionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetId => $composableBuilder(
      column: $table.targetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetType => $composableBuilder(
      column: $table.targetType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reactorDeviceId => $composableBuilder(
      column: $table.reactorDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reactedAt => $composableBuilder(
      column: $table.reactedAt, builder: (column) => ColumnFilters(column));
}

class $$ReactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetId => $composableBuilder(
      column: $table.targetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetType => $composableBuilder(
      column: $table.targetType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reactorDeviceId => $composableBuilder(
      column: $table.reactorDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reactedAt => $composableBuilder(
      column: $table.reactedAt, builder: (column) => ColumnOrderings(column));
}

class $$ReactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
      column: $table.targetType, builder: (column) => column);

  GeneratedColumn<String> get reactorDeviceId => $composableBuilder(
      column: $table.reactorDeviceId, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get reactedAt =>
      $composableBuilder(column: $table.reactedAt, builder: (column) => column);
}

class $$ReactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReactionsTable,
    Reaction,
    $$ReactionsTableFilterComposer,
    $$ReactionsTableOrderingComposer,
    $$ReactionsTableAnnotationComposer,
    $$ReactionsTableCreateCompanionBuilder,
    $$ReactionsTableUpdateCompanionBuilder,
    (Reaction, BaseReferences<_$AppDatabase, $ReactionsTable, Reaction>),
    Reaction,
    PrefetchHooks Function()> {
  $$ReactionsTableTableManager(_$AppDatabase db, $ReactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> targetId = const Value.absent(),
            Value<String> targetType = const Value.absent(),
            Value<String> reactorDeviceId = const Value.absent(),
            Value<String> emoji = const Value.absent(),
            Value<DateTime> reactedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReactionsCompanion(
            id: id,
            targetId: targetId,
            targetType: targetType,
            reactorDeviceId: reactorDeviceId,
            emoji: emoji,
            reactedAt: reactedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String targetId,
            required String targetType,
            required String reactorDeviceId,
            required String emoji,
            required DateTime reactedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReactionsCompanion.insert(
            id: id,
            targetId: targetId,
            targetType: targetType,
            reactorDeviceId: reactorDeviceId,
            emoji: emoji,
            reactedAt: reactedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReactionsTable,
    Reaction,
    $$ReactionsTableFilterComposer,
    $$ReactionsTableOrderingComposer,
    $$ReactionsTableAnnotationComposer,
    $$ReactionsTableCreateCompanionBuilder,
    $$ReactionsTableUpdateCompanionBuilder,
    (Reaction, BaseReferences<_$AppDatabase, $ReactionsTable, Reaction>),
    Reaction,
    PrefetchHooks Function()>;
typedef $$KeyRecordsTableCreateCompanionBuilder = KeyRecordsCompanion Function({
  required String id,
  required String keyType,
  Value<String?> publicKeyBase64,
  Value<String?> fingerprint,
  Value<bool> fingerprintVerifiedByUser,
  required DateTime createdAt,
  Value<DateTime?> rotatedAt,
  Value<DateTime?> expiresAt,
  Value<int> rowid,
});
typedef $$KeyRecordsTableUpdateCompanionBuilder = KeyRecordsCompanion Function({
  Value<String> id,
  Value<String> keyType,
  Value<String?> publicKeyBase64,
  Value<String?> fingerprint,
  Value<bool> fingerprintVerifiedByUser,
  Value<DateTime> createdAt,
  Value<DateTime?> rotatedAt,
  Value<DateTime?> expiresAt,
  Value<int> rowid,
});

class $$KeyRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $KeyRecordsTable> {
  $$KeyRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyType => $composableBuilder(
      column: $table.keyType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicKeyBase64 => $composableBuilder(
      column: $table.publicKeyBase64,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get fingerprintVerifiedByUser => $composableBuilder(
      column: $table.fingerprintVerifiedByUser,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get rotatedAt => $composableBuilder(
      column: $table.rotatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));
}

class $$KeyRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyRecordsTable> {
  $$KeyRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyType => $composableBuilder(
      column: $table.keyType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicKeyBase64 => $composableBuilder(
      column: $table.publicKeyBase64,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get fingerprintVerifiedByUser => $composableBuilder(
      column: $table.fingerprintVerifiedByUser,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get rotatedAt => $composableBuilder(
      column: $table.rotatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));
}

class $$KeyRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyRecordsTable> {
  $$KeyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get keyType =>
      $composableBuilder(column: $table.keyType, builder: (column) => column);

  GeneratedColumn<String> get publicKeyBase64 => $composableBuilder(
      column: $table.publicKeyBase64, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => column);

  GeneratedColumn<bool> get fingerprintVerifiedByUser => $composableBuilder(
      column: $table.fingerprintVerifiedByUser, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get rotatedAt =>
      $composableBuilder(column: $table.rotatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$KeyRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KeyRecordsTable,
    KeyRecord,
    $$KeyRecordsTableFilterComposer,
    $$KeyRecordsTableOrderingComposer,
    $$KeyRecordsTableAnnotationComposer,
    $$KeyRecordsTableCreateCompanionBuilder,
    $$KeyRecordsTableUpdateCompanionBuilder,
    (KeyRecord, BaseReferences<_$AppDatabase, $KeyRecordsTable, KeyRecord>),
    KeyRecord,
    PrefetchHooks Function()> {
  $$KeyRecordsTableTableManager(_$AppDatabase db, $KeyRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> keyType = const Value.absent(),
            Value<String?> publicKeyBase64 = const Value.absent(),
            Value<String?> fingerprint = const Value.absent(),
            Value<bool> fingerprintVerifiedByUser = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> rotatedAt = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KeyRecordsCompanion(
            id: id,
            keyType: keyType,
            publicKeyBase64: publicKeyBase64,
            fingerprint: fingerprint,
            fingerprintVerifiedByUser: fingerprintVerifiedByUser,
            createdAt: createdAt,
            rotatedAt: rotatedAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String keyType,
            Value<String?> publicKeyBase64 = const Value.absent(),
            Value<String?> fingerprint = const Value.absent(),
            Value<bool> fingerprintVerifiedByUser = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> rotatedAt = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KeyRecordsCompanion.insert(
            id: id,
            keyType: keyType,
            publicKeyBase64: publicKeyBase64,
            fingerprint: fingerprint,
            fingerprintVerifiedByUser: fingerprintVerifiedByUser,
            createdAt: createdAt,
            rotatedAt: rotatedAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KeyRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KeyRecordsTable,
    KeyRecord,
    $$KeyRecordsTableFilterComposer,
    $$KeyRecordsTableOrderingComposer,
    $$KeyRecordsTableAnnotationComposer,
    $$KeyRecordsTableCreateCompanionBuilder,
    $$KeyRecordsTableUpdateCompanionBuilder,
    (KeyRecord, BaseReferences<_$AppDatabase, $KeyRecordsTable, KeyRecord>),
    KeyRecord,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MediaMetadataTableTableTableManager get mediaMetadataTable =>
      $$MediaMetadataTableTableTableManager(_db, _db.mediaMetadataTable);
  $$ReactionsTableTableManager get reactions =>
      $$ReactionsTableTableManager(_db, _db.reactions);
  $$KeyRecordsTableTableManager get keyRecords =>
      $$KeyRecordsTableTableManager(_db, _db.keyRecords);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}

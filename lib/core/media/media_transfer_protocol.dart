/// Wire protocol for binary media transfer over the paired WebRTC
/// DataChannel.
///
/// All multi-byte integers are big-endian. The opaque payloads carried by
/// these frames (chunk bytes, metadata JSON) are expected to already be
/// ciphertext produced by the app's `SessionCipher` before they reach this
/// layer — this file only frames/unframes bytes, it never handles
/// plaintext media.
library media_transfer_protocol;

import 'dart:convert';
import 'dart:typed_data';

/// Frame type tags. First byte of every DataChannel binary message.
class MediaFrameType {
  static const int init = 0x01;
  static const int chunk = 0x02;
  static const int complete = 0x03;
  static const int cancel = 0x04;
  static const int ack = 0x05; // receiver -> sender, per-chunk flow control
  static const int error = 0x06;
}

/// Chunk payload size, per spec: 64 KB per frame (pre-encryption).
const int kMediaChunkSize = 64 * 1024;

/// Raw 16-byte transfer id (v4 UUID bytes, not the hyphenated string form)
/// to keep frame headers small.
typedef TransferId = Uint8List;

/// Reads the frame type tag without decoding the rest of the frame.
int peekFrameType(Uint8List data) {
  if (data.isEmpty) {
    throw const FormatException('Empty frame');
  }
  return data[0];
}

Uint8List uint32be(int value) {
  final bytes = ByteData(4)..setUint32(0, value, Endian.big);
  return bytes.buffer.asUint8List();
}

int readUint32be(Uint8List data, int offset) {
  return ByteData.sublistView(data).getUint32(offset, Endian.big);
}

/// Converts a hyphenated UUID string into its raw 16-byte form.
Uint8List transferIdBytes(String uuid) {
  final hex = uuid.replaceAll('-', '');
  if (hex.length != 32) {
    throw FormatException('Not a valid UUID: $uuid');
  }
  final bytes = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

/// Converts raw 16-byte transfer id bytes back to a hyphenated UUID string.
String transferIdString(Uint8List bytes) {
  if (bytes.length != 16) {
    throw const FormatException('Transfer id must be 16 bytes');
  }
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Sent once, before any chunks, so the receiver can pre-create the
/// MediaMetadata row and show a "receiving..." bubble immediately.
///
/// Layout: [type:1][transferId:16][metaLen:4][encryptedMetadata:metaLen]
class MediaInitFrame {
  final TransferId transferId;
  final Uint8List encryptedMetadata;

  const MediaInitFrame({
    required this.transferId,
    required this.encryptedMetadata,
  });

  Uint8List encode() {
    final builder = BytesBuilder(copy: false)
      ..addByte(MediaFrameType.init)
      ..add(transferId)
      ..add(uint32be(encryptedMetadata.length))
      ..add(encryptedMetadata);
    return builder.toBytes();
  }

  static MediaInitFrame decode(Uint8List data) {
    if (peekFrameType(data) != MediaFrameType.init) {
      throw const FormatException('Not an init frame');
    }
    final transferId = data.sublist(1, 17);
    final metaLen = readUint32be(data, 17);
    final metaStart = 21;
    final metaEnd = metaStart + metaLen;
    if (metaEnd > data.length) {
      throw const FormatException('Truncated init frame');
    }
    return MediaInitFrame(
      transferId: transferId,
      encryptedMetadata: data.sublist(metaStart, metaEnd),
    );
  }
}

/// One 64 KB (pre-encryption) chunk of file data.
///
/// Layout:
/// [type:1][transferId:16][chunkIndex:4][totalChunks:4][payloadLen:4][payload:N]
class MediaChunkFrame {
  final TransferId transferId;
  final int chunkIndex;
  final int totalChunks;
  final Uint8List encryptedPayload;

  const MediaChunkFrame({
    required this.transferId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.encryptedPayload,
  });

  Uint8List encode() {
    final builder = BytesBuilder(copy: false)
      ..addByte(MediaFrameType.chunk)
      ..add(transferId)
      ..add(uint32be(chunkIndex))
      ..add(uint32be(totalChunks))
      ..add(uint32be(encryptedPayload.length))
      ..add(encryptedPayload);
    return builder.toBytes();
  }

  static MediaChunkFrame decode(Uint8List data) {
    if (peekFrameType(data) != MediaFrameType.chunk) {
      throw const FormatException('Not a chunk frame');
    }
    final transferId = data.sublist(1, 17);
    final chunkIndex = readUint32be(data, 17);
    final totalChunks = readUint32be(data, 21);
    final payloadLen = readUint32be(data, 25);
    final payloadStart = 29;
    final payloadEnd = payloadStart + payloadLen;
    if (payloadEnd > data.length) {
      throw const FormatException('Truncated chunk frame');
    }
    return MediaChunkFrame(
      transferId: transferId,
      chunkIndex: chunkIndex,
      totalChunks: totalChunks,
      encryptedPayload: data.sublist(payloadStart, payloadEnd),
    );
  }
}

/// Sent by the sender once every chunk has been transmitted. Carries the
/// whole-file SHA-256 so the receiver can verify integrity after
/// reassembly, per spec.
///
/// Layout: [type:1][transferId:16][hashLen:1][hash (utf8 hex):hashLen]
class MediaCompleteFrame {
  final TransferId transferId;
  final String sha256Hex;

  const MediaCompleteFrame({
    required this.transferId,
    required this.sha256Hex,
  });

  Uint8List encode() {
    final hashBytes = utf8.encode(sha256Hex);
    final builder = BytesBuilder(copy: false)
      ..addByte(MediaFrameType.complete)
      ..add(transferId)
      ..addByte(hashBytes.length)
      ..add(hashBytes);
    return builder.toBytes();
  }

  static MediaCompleteFrame decode(Uint8List data) {
    if (peekFrameType(data) != MediaFrameType.complete) {
      throw const FormatException('Not a complete frame');
    }
    final transferId = data.sublist(1, 17);
    final hashLen = data[17];
    final hashBytes = data.sublist(18, 18 + hashLen);
    return MediaCompleteFrame(
      transferId: transferId,
      sha256Hex: utf8.decode(hashBytes),
    );
  }
}

/// Sent by either side to abort an in-progress transfer (user cancelled,
/// disk full, etc). The receiving side must delete any partial file.
///
/// Layout: [type:1][transferId:16][reasonLen:4][reason (utf8):reasonLen]
class MediaCancelFrame {
  final TransferId transferId;
  final String reason;

  const MediaCancelFrame({required this.transferId, this.reason = ''});

  Uint8List encode() {
    final reasonBytes = utf8.encode(reason);
    final builder = BytesBuilder(copy: false)
      ..addByte(MediaFrameType.cancel)
      ..add(transferId)
      ..add(uint32be(reasonBytes.length))
      ..add(reasonBytes);
    return builder.toBytes();
  }

  static MediaCancelFrame decode(Uint8List data) {
    if (peekFrameType(data) != MediaFrameType.cancel) {
      throw const FormatException('Not a cancel frame');
    }
    final transferId = data.sublist(1, 17);
    final reasonLen = readUint32be(data, 17);
    final reasonBytes = data.sublist(21, 21 + reasonLen);
    return MediaCancelFrame(
      transferId: transferId,
      reason: utf8.decode(reasonBytes),
    );
  }
}

/// Sent by either side to report a fatal, non-retryable protocol error
/// for a transfer (e.g. checksum mismatch on the receiver).
///
/// Layout: [type:1][transferId:16][messageLen:4][message (utf8):messageLen]
class MediaErrorFrame {
  final TransferId transferId;
  final String message;

  const MediaErrorFrame({required this.transferId, required this.message});

  Uint8List encode() {
    final messageBytes = utf8.encode(message);
    final builder = BytesBuilder(copy: false)
      ..addByte(MediaFrameType.error)
      ..add(transferId)
      ..add(uint32be(messageBytes.length))
      ..add(messageBytes);
    return builder.toBytes();
  }

  static MediaErrorFrame decode(Uint8List data) {
    if (peekFrameType(data) != MediaFrameType.error) {
      throw const FormatException('Not an error frame');
    }
    final transferId = data.sublist(1, 17);
    final messageLen = readUint32be(data, 17);
    final messageBytes = data.sublist(21, 21 + messageLen);
    return MediaErrorFrame(
      transferId: transferId,
      message: utf8.decode(messageBytes),
    );
  }
}

/// Sent by the receiver after each chunk (or batched) so the sender has an
/// application-level signal in addition to `bufferedAmount` — a receiver
/// that has stopped reading (e.g. blocked on disk I/O) becomes a stalled
/// transfer instead of the sender spinning against a DataChannel that
/// looks writable but isn't actually being drained.
///
/// Layout: [type:1][transferId:16][chunkIndex:4]
class MediaAckFrame {
  final TransferId transferId;
  final int chunkIndex;

  const MediaAckFrame({required this.transferId, required this.chunkIndex});

  Uint8List encode() {
    final builder = BytesBuilder(copy: false)
      ..addByte(MediaFrameType.ack)
      ..add(transferId)
      ..add(uint32be(chunkIndex));
    return builder.toBytes();
  }

  static MediaAckFrame decode(Uint8List data) {
    if (peekFrameType(data) != MediaFrameType.ack) {
      throw const FormatException('Not an ack frame');
    }
    final transferId = data.sublist(1, 17);
    final chunkIndex = readUint32be(data, 17);
    return MediaAckFrame(transferId: transferId, chunkIndex: chunkIndex);
  }
}

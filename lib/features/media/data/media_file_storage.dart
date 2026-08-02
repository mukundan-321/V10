/// App-local media storage. Received files land under `media/received/`;
/// files queued for sending get copied into `media/sent/` so a transfer
/// can safely stream from a stable path even if the OS clears the
/// picker's/recorder's original temp file mid-transfer. Both are
/// namespaced by transfer/message id to avoid collisions and keep the
/// original file extension for correct OS/app file-type association.
library media_file_storage;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'chunked_file_receiver.dart' show MediaFileStorage;

class AppMediaFileStorage implements MediaFileStorage {
  AppMediaFileStorage._(this._receivedDir, this._sentDir);

  final Directory _receivedDir;
  final Directory _sentDir;

  static Future<AppMediaFileStorage> create() async {
    final root = await getApplicationDocumentsDirectory();
    final received = Directory(p.join(root.path, 'media', 'received'));
    final sent = Directory(p.join(root.path, 'media', 'sent'));
    await received.create(recursive: true);
    await sent.create(recursive: true);
    return AppMediaFileStorage._(received, sent);
  }

  @override
  Future<File> createDestinationFile({
    required String transferId,
    required String suggestedFilename,
    required String mimeType,
  }) async {
    final file = File(
      p.join(_receivedDir.path, '$transferId${_extensionOf(suggestedFilename)}'),
    );
    if (await file.exists()) {
      await file.delete();
    }
    await file.create(recursive: true);
    return file;
  }

  /// Copies a picker/recorder-produced file into permanent app storage
  /// before it's handed to [ChunkedFileSender], keyed by the chat
  /// message id it belongs to.
  Future<File> storeSentFile({
    required File original,
    required String messageId,
  }) async {
    final destination =
        File(p.join(_sentDir.path, '$messageId${_extensionOf(original.path)}'));
    return original.copy(destination.path);
  }

  @override
  Future<int?> availableDiskSpaceBytes() async {
    // dart:io has no cross-platform free-disk-space API. Returning null is
    // the documented "unknown — don't block on it" contract; add a plugin
    // (e.g. disk_space_2) and wire it in here if a hard pre-flight check
    // becomes a requirement.
    return null;
  }

  @override
  Future<void> deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _extensionOf(String path) => p.extension(path);
}

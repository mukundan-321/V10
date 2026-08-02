library media_file_storage_impl;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'chunked_file_receiver.dart';

class AppMediaFileStorage implements MediaFileStorage {
  Future<Directory> _mediaDirectory() async {
    final root = await getApplicationDocumentsDirectory();

    final dir = Directory(
      p.join(root.path, "media"),
    );

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  @override
  Future<File> createDestinationFile({
    required String transferId,
    required String suggestedFilename,
    required String mimeType,
  }) async {
    final dir = await _mediaDirectory();

    final extension = p.extension(suggestedFilename);

    return File(
      p.join(
        dir.path,
        "$transferId$extension",
      ),
    );
  }

  Future<File> storeSentFile({
    required File original,
    required String messageId,
  }) async {
    final dir = await _mediaDirectory();

    final extension = p.extension(original.path);

    final destination = File(
      p.join(
        dir.path,
        "$messageId$extension",
      ),
    );

    return original.copy(destination.path);
  }

  @override
  Future<int?> availableDiskSpaceBytes() async {
    // Platform-independent free-space APIs aren't available.
    // Returning null tells the receiver to skip the pre-check.
    return null;
  }

  @override
  Future<void> deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}

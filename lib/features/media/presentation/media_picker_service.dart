/// Wraps `image_picker` and `file_picker` behind one service that returns
/// ready-to-send [PickedMedia]: large images pre-compressed, video
/// thumbnails and durations already extracted, so the composer and
/// repository don't touch picker/codec plugins directly.
library media_picker_service;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

import 'media_permissions.dart';

enum PickedMediaKind { image, video, document }

class PickedMedia {
  final File file;
  final PickedMediaKind kind;
  final String mimeType;
  final String filename;
  final int? width;
  final int? height;
  final int? durationMs;
  final File? thumbnail;

  const PickedMedia({
    required this.file,
    required this.kind,
    required this.mimeType,
    required this.filename,
    this.width,
    this.height,
    this.durationMs,
    this.thumbnail,
  });
}

/// Images larger than this get compressed before sending, per spec
/// ("compress very large images").
const int _imageCompressionThresholdBytes = 2 * 1024 * 1024;

/// Thrown when the user denies a permission a picker action needs.
/// Callers (typically the attachment sheet) should catch this and show
/// a prompt to open Settings via [MediaPermissions.openSettings].
class MediaPermissionDeniedException implements Exception {
  final String permissionName;
  const MediaPermissionDeniedException(this.permissionName);
  @override
  String toString() => 'MediaPermissionDeniedException: $permissionName';
}

class MediaPickerService {
  MediaPickerService({ImagePicker? imagePicker, MediaPermissions? permissions})
      : _imagePicker = imagePicker ?? ImagePicker(),
        _permissions = permissions ?? const MediaPermissions();

  final ImagePicker _imagePicker;
  final MediaPermissions _permissions;

  Future<List<PickedMedia>> pickImagesFromGallery() async {
    if (!await _permissions.ensurePhotos()) {
      throw const MediaPermissionDeniedException('photos');
    }
    final files = await _imagePicker.pickMultiImage(imageQuality: 90);
    final result = <PickedMedia>[];
    for (final x in files) {
      result.add(await _buildImageMedia(File(x.path)));
    }
    return result;
  }

  Future<PickedMedia?> captureImageFromCamera() async {
    if (!await _permissions.ensureCamera()) {
      throw const MediaPermissionDeniedException('camera');
    }
    final x =
        await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (x == null) return null;
    return _buildImageMedia(File(x.path));
  }

  Future<PickedMedia?> pickVideoFromGallery() async {
    if (!await _permissions.ensureVideos()) {
      throw const MediaPermissionDeniedException('videos');
    }
    final x = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (x == null) return null;
    return _buildVideoMedia(File(x.path));
  }

  Future<PickedMedia?> captureVideoFromCamera() async {
    if (!await _permissions.ensureCamera()) {
      throw const MediaPermissionDeniedException('camera');
    }
    final x = await _imagePicker.pickVideo(source: ImageSource.camera);
    if (x == null) return null;
    return _buildVideoMedia(File(x.path));
  }

  Future<List<PickedMedia>> pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );
    if (result == null) return [];

    return result.files
        .where((f) => f.path != null)
        .map((f) => PickedMedia(
              file: File(f.path!),
              kind: PickedMediaKind.document,
              mimeType: lookupMimeType(f.path!) ?? 'application/octet-stream',
              filename: f.name,
            ))
        .toList();
  }

  Future<PickedMedia> _buildImageMedia(File file) async {
    final sendFile = await _compressImageIfNeeded(file);
    final dimensions = await _decodeImageDimensions(sendFile);
    return PickedMedia(
      file: sendFile,
      kind: PickedMediaKind.image,
      mimeType: lookupMimeType(sendFile.path) ?? 'image/jpeg',
      filename: p.basename(sendFile.path),
      width: dimensions?.width,
      height: dimensions?.height,
    );
  }

  Future<File> _compressImageIfNeeded(File file) async {
    final size = await file.length();
    if (size <= _imageCompressionThresholdBytes) return file;

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${p.basenameWithoutExtension(file.path)}_compressed.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 1920,
      minHeight: 1920,
      keepExif: false,
    );
    return result != null ? File(result.path) : file;
  }

  Future<ui.Size?> _decodeImageDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = ui.Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  Future<PickedMedia> _buildVideoMedia(File file) async {
    final dir = await getTemporaryDirectory();
    final thumbPath = await vt.VideoThumbnail.thumbnailFile(
      video: file.path,
      thumbnailPath: dir.path,
      imageFormat: vt.ImageFormat.JPEG,
      quality: 70,
    );

    final controller = VideoPlayerController.file(file);
    int? durationMs;
    int? width;
    int? height;
    try {
      await controller.initialize();
      durationMs = controller.value.duration.inMilliseconds;
      width = controller.value.size.width.toInt();
      height = controller.value.size.height.toInt();
    } finally {
      await controller.dispose();
    }

    return PickedMedia(
      file: file,
      kind: PickedMediaKind.video,
      mimeType: lookupMimeType(file.path) ?? 'video/mp4',
      filename: p.basename(file.path),
      width: width,
      height: height,
      durationMs: durationMs,
      thumbnail: thumbPath != null ? File(thumbPath) : null,
    );
  }
}
